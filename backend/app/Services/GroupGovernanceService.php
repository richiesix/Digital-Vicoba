<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\LeadershipRole;
use App\Models\VicobaGroup;
use Illuminate\Support\Facades\DB;

final class GroupGovernanceService
{
    /** Minimum leadership positions before normal group RBAC applies. */
    private const REQUIRED_LEADERSHIP = ['chairperson', 'secretary', 'treasurer'];

    public function isComplete(VicobaGroup $group): bool
    {
        return (bool) $group->governance_complete;
    }

    public function tryMarkComplete(int $groupId): bool
    {
        $group = VicobaGroup::query()->find($groupId);
        if ($group === null) {
            return false;
        }

        if ($group->governance_complete) {
            return true;
        }

        $filled = LeadershipRole::query()
            ->where('group_id', $groupId)
            ->where('active', true)
            ->whereIn('role_name', self::REQUIRED_LEADERSHIP)
            ->pluck('role_name')
            ->unique();

        if ($filled->count() < count(self::REQUIRED_LEADERSHIP)) {
            return false;
        }

        $group->update([
            'governance_complete' => true,
            'interim_chair_user_id' => null,
            'status' => $group->status === 'forming' ? 'active' : $group->status,
        ]);

        $this->revokeProvisionalChairRoles($groupId);

        return true;
    }

    public function revokeProvisionalChairRoles(int $groupId): void
    {
        $roleId = DB::table('roles')->where('slug', 'provisional_chair')->value('id');
        if (! $roleId) {
            return;
        }

        DB::table('user_roles')
            ->where('group_id', $groupId)
            ->where('role_id', $roleId)
            ->delete();
    }
}
