<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Election;
use App\Models\LeadershipAssignment;
use App\Models\LeadershipAssignmentVote;
use App\Models\LeadershipRole;
use App\Models\Member;
use App\Models\User;
use App\Models\VicobaGroup;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

final class LeadershipService
{
    private const ROLE_TO_SLUG = [
        'chairperson' => 'chairperson',
        'secretary' => 'secretary',
        'treasurer' => 'treasurer',
        'money_counter' => 'money_counter',
        'key_holder' => 'key_holder',
    ];

    public function __construct(
        private readonly AuditService $audit,
        private readonly NotificationService $notifications,
        private readonly GroupGovernanceService $governance,
    ) {}

    public function currentLeadership(int $groupId): Collection
    {
        return LeadershipRole::query()
            ->where('group_id', $groupId)
            ->where('active', true)
            ->with('member')
            ->get();
    }

    /** @param array<string, array<int, array<string, mixed>>> $results */
    public function applyElectionResults(Election $election, array $results, User $assignedBy): void
    {
        foreach ($results as $position => $candidates) {
            if (empty($candidates) || empty($candidates[0]['elected'])) {
                continue;
            }

            $winnerMemberId = (int) $candidates[0]['member_id'];
            $this->assignRole(
                $election->group_id,
                $winnerMemberId,
                $position,
                $assignedBy,
                'election',
                $election->id
            );
        }
    }

    public function assignRole(
        int $groupId,
        int $memberId,
        string $roleName,
        User $assignedBy,
        string $method = 'manual',
        ?int $electionId = null,
    ): LeadershipRole {
        return DB::transaction(function () use ($groupId, $memberId, $roleName, $assignedBy, $method, $electionId): LeadershipRole {
            LeadershipRole::query()
                ->where('group_id', $groupId)
                ->where('role_name', $roleName)
                ->where('active', true)
                ->update(['active' => false, 'end_date' => now()->toDateString()]);

            $role = LeadershipRole::query()->create([
                'group_id' => $groupId,
                'member_id' => $memberId,
                'role_name' => $roleName,
                'start_date' => now()->toDateString(),
                'active' => true,
                'assigned_by' => $assignedBy->id,
                'election_id' => $electionId,
                'assignment_method' => $method,
            ]);

            $this->syncUserRole($groupId, $memberId, $roleName, $assignedBy->id);
            $this->audit->log($assignedBy, 'leadership_assigned', 'leadership_role', $role->id, null, [
                'group_id' => $groupId,
                'role_name' => $roleName,
                'member_id' => $memberId,
            ]);

            $this->notifications->notifyGroup(
                $groupId,
                'leadership_change',
                'Mabadiliko ya uongozi',
                "Mwanachama ameteuliwa kama {$roleName}",
                ['role_name' => $roleName, 'member_id' => $memberId]
            );

            $this->governance->tryMarkComplete($groupId);

            return $role;
        });
    }

    public function proposeManualAssignment(
        VicobaGroup $group,
        User $proposer,
        int $memberId,
        string $roleName,
        ?string $reason = null,
        ?int $quorumRequired = null,
    ): LeadershipAssignment {
        if (! $group->governance_complete) {
            $this->assignRole($group->id, $memberId, $roleName, $proposer, 'manual');

            return LeadershipAssignment::query()->create([
                'group_id' => $group->id,
                'member_id' => $memberId,
                'role_name' => $roleName,
                'proposed_by' => $proposer->id,
                'status' => 'approved',
                'quorum_required' => 1,
                'approvals_count' => 1,
                'reason' => $reason,
                'resolved_at' => now(),
            ]);
        }

        $activeMembers = Member::query()
            ->where('group_id', $group->id)
            ->where('status', 'active')
            ->count();

        return LeadershipAssignment::query()->create([
            'group_id' => $group->id,
            'member_id' => $memberId,
            'role_name' => $roleName,
            'proposed_by' => $proposer->id,
            'status' => 'pending',
            'quorum_required' => $quorumRequired ?? max(1, (int) ceil($activeMembers * 0.5)),
            'reason' => $reason,
        ]);
    }

    public function voteOnAssignment(LeadershipAssignment $assignment, Member $voter, bool $approved): LeadershipAssignment
    {
        LeadershipAssignmentVote::query()->updateOrCreate(
            ['assignment_id' => $assignment->id, 'member_id' => $voter->id],
            ['approved' => $approved]
        );

        $approvals = LeadershipAssignmentVote::query()
            ->where('assignment_id', $assignment->id)
            ->where('approved', true)
            ->count();

        $assignment->update(['approvals_count' => $approvals]);

        if ($approvals >= $assignment->quorum_required) {
            $proposer = User::query()->findOrFail($assignment->proposed_by);
            $this->assignRole(
                $assignment->group_id,
                $assignment->member_id,
                $assignment->role_name,
                $proposer,
                'manual'
            );
            $assignment->update(['status' => 'approved', 'resolved_at' => now()]);
        }

        return $assignment->fresh();
    }

    public function syncMemberAccountRoles(Member $member, ?int $assignedBy = null): void
    {
        if (! $member->user_id) {
            return;
        }

        $assignedBy ??= $member->user_id;

        $activeLeadership = LeadershipRole::query()
            ->where('member_id', $member->id)
            ->where('active', true)
            ->get();

        if ($activeLeadership->isEmpty()) {
            $this->ensureDefaultMemberRole($member);

            return;
        }

        foreach ($activeLeadership as $role) {
            $this->syncUserRole($member->group_id, $member->id, $role->role_name, $assignedBy);
        }
    }

    private function ensureDefaultMemberRole(Member $member): void
    {
        if (! $member->user_id) {
            return;
        }

        $hasGroupRole = DB::table('user_roles')
            ->where('user_id', $member->user_id)
            ->where('group_id', $member->group_id)
            ->exists();

        if ($hasGroupRole) {
            return;
        }

        $roleId = DB::table('roles')->where('slug', 'member')->value('id');
        if (! $roleId) {
            return;
        }

        DB::table('user_roles')->updateOrInsert(
            ['user_id' => $member->user_id, 'role_id' => $roleId, 'group_id' => $member->group_id],
            ['assigned_by' => $member->user_id, 'assigned_at' => now()]
        );
    }

    private function syncUserRole(int $groupId, int $memberId, string $roleName, int $assignedBy): void
    {
        $member = Member::query()->find($memberId);
        if (! $member?->user_id) {
            return;
        }

        $slug = self::ROLE_TO_SLUG[$roleName] ?? null;
        if (! $slug) {
            return;
        }

        $roleId = DB::table('roles')->where('slug', $slug)->value('id');
        if (! $roleId) {
            return;
        }

        DB::table('user_roles')
            ->where('user_id', $member->user_id)
            ->where('group_id', $groupId)
            ->whereIn('role_id', function ($q): void {
                $q->select('id')->from('roles')->whereIn('slug', array_values(self::ROLE_TO_SLUG));
            })
            ->delete();

        DB::table('user_roles')->updateOrInsert(
            ['user_id' => $member->user_id, 'role_id' => $roleId, 'group_id' => $groupId],
            ['assigned_by' => $assignedBy, 'assigned_at' => now()]
        );
    }
}
