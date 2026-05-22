<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Election;
use App\Models\LeadershipAssignment;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\ElectionService;
use App\Services\LeadershipService;
use App\Services\RbacService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class GovernanceController extends Controller
{
    public function __construct(
        private readonly ElectionService $elections,
        private readonly LeadershipService $leadership,
        private readonly RbacService $rbac,
    ) {}

    public function leadershipDashboard(Request $request, VicobaGroup $group): JsonResponse
    {
        $user = $request->user();
        $leadership = $this->leadership->currentLeadership($group->id);
        $openElections = $this->elections->listForGroup($group->id, 'open');
        $pendingAssignments = LeadershipAssignment::query()
            ->where('group_id', $group->id)
            ->where('status', 'pending')
            ->with('member')
            ->get();

        $activeMemberCount = Member::query()
            ->where('group_id', $group->id)
            ->where('status', 'active')
            ->count();

        $isInterimChair = ! $group->governance_complete
            && (
                (int) $group->interim_chair_user_id === $user->id
                || (int) $group->created_by === $user->id
            );

        $canManageMembers = $isInterimChair
            || $this->rbac->hasPermission($user, 'group.manage_members', $group->id);

        $canAssignLeadership = $canManageMembers
            && ($activeMemberCount >= 2 || $isInterimChair);

        return response()->json([
            'leadership' => $leadership,
            'open_elections' => $openElections,
            'pending_assignments' => $pendingAssignments,
            'member_count' => $activeMemberCount,
            'governance_complete' => $group->governance_complete,
            'can_assign_leadership' => $canAssignLeadership,
            'can_manage_members' => $canManageMembers,
            'is_interim_chair' => $isInterimChair,
        ]);
    }

    public function listElections(VicobaGroup $group, Request $request): JsonResponse
    {
        return response()->json([
            'elections' => $this->elections->listForGroup($group->id, $request->query('status')),
        ]);
    }

    public function createElection(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'title' => 'required|string|max:200',
            'description' => 'nullable|string',
            'election_type' => 'nullable|in:leadership,loan,constitution,suspension,emergency',
            'quorum_percent' => 'nullable|integer|min:1|max:100',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'positions' => 'nullable|array',
            'positions.*' => 'in:chairperson,secretary,treasurer,money_counter,key_holder',
        ]);

        $election = $this->elections->createElection($group, $request->user(), $data);

        return response()->json(['election' => $election], 201);
    }

    public function showElection(Election $election): JsonResponse
    {
        return response()->json([
            'election' => $election->load(['candidates.member']),
        ]);
    }

    public function openElection(Request $request, Election $election): JsonResponse
    {
        return response()->json([
            'election' => $this->elections->openElection($election, $request->user()),
        ]);
    }

    public function nominate(Request $request, Election $election): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer|exists:members,id',
            'position' => 'required|in:chairperson,secretary,treasurer,money_counter,key_holder',
            'manifesto' => 'nullable|string',
        ]);

        $member = Member::query()
            ->where('group_id', $election->group_id)
            ->findOrFail($data['member_id']);

        $candidate = $this->elections->nominate(
            $election,
            $member,
            $data['position'],
            $request->user(),
            $data['manifesto'] ?? null
        );

        return response()->json(['candidate' => $candidate->load('member')], 201);
    }

    public function castVote(Request $request, Election $election): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer|exists:members,id',
            'candidate_id' => 'required|integer|exists:election_candidates,id',
            'client_id' => 'nullable|string|max:64',
        ]);

        $voter = Member::query()
            ->where('group_id', $election->group_id)
            ->findOrFail($data['member_id']);

        try {
            $vote = $this->elections->castVote(
                $election,
                $voter,
                (int) $data['candidate_id'],
                $data['client_id'] ?? null,
                $request
            );
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(['message' => 'Kura imehifadhiwa', 'vote_id' => $vote->id]);
    }

    public function voteStatus(Request $request, Election $election): JsonResponse
    {
        $request->validate(['member_id' => 'required|integer']);

        return response()->json([
            'has_voted' => $this->elections->hasVoted($election, (int) $request->query('member_id')),
        ]);
    }

    public function results(Election $election): JsonResponse
    {
        return response()->json([
            'results' => $this->elections->tallyResults($election),
            'status' => $election->status,
        ]);
    }

    public function closeElection(Request $request, Election $election): JsonResponse
    {
        if (! $this->rbac->hasPermission($request->user(), 'group.manage_elections', $election->group_id)) {
            return response()->json(['message' => 'Huna ruhusa'], 403);
        }

        return response()->json($this->elections->closeAndTally($election, $request->user()));
    }

    public function proposeAssignment(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer|exists:members,id',
            'role_name' => 'required|in:chairperson,secretary,treasurer,money_counter,key_holder',
            'reason' => 'nullable|string',
            'quorum_required' => 'nullable|integer|min:1',
        ]);

        $assignment = $this->leadership->proposeManualAssignment(
            $group,
            $request->user(),
            (int) $data['member_id'],
            $data['role_name'],
            $data['reason'] ?? null,
            isset($data['quorum_required']) ? (int) $data['quorum_required'] : null
        );

        return response()->json(['assignment' => $assignment], 201);
    }

    public function approveAssignment(Request $request, LeadershipAssignment $assignment): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer|exists:members,id',
            'approved' => 'required|boolean',
        ]);

        $voter = Member::query()
            ->where('group_id', $assignment->group_id)
            ->findOrFail($data['member_id']);

        $updated = $this->leadership->voteOnAssignment($assignment, $voter, (bool) $data['approved']);

        return response()->json(['assignment' => $updated]);
    }

    public function syncVotes(Request $request, Election $election): JsonResponse
    {
        $data = $request->validate([
            'votes' => 'required|array',
            'votes.*.member_id' => 'required|integer',
            'votes.*.candidate_id' => 'required|integer',
            'votes.*.client_id' => 'required|string|max:64',
        ]);

        $synced = [];
        foreach ($data['votes'] as $voteData) {
            $voter = Member::query()
                ->where('group_id', $election->group_id)
                ->findOrFail($voteData['member_id']);

            try {
                $vote = $this->elections->castVote(
                    $election,
                    $voter,
                    (int) $voteData['candidate_id'],
                    $voteData['client_id'],
                    $request
                );
                $synced[] = ['client_id' => $voteData['client_id'], 'status' => 'ok', 'vote_id' => $vote->id];
            } catch (\InvalidArgumentException $e) {
                $synced[] = ['client_id' => $voteData['client_id'], 'status' => 'skipped', 'message' => $e->getMessage()];
            }
        }

        return response()->json(['synced' => $synced]);
    }
}
