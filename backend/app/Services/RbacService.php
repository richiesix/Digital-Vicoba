<?php

declare(strict_types=1);

namespace App\Services;

use App\Data\UserRoleRow;
use App\Models\Member;
use App\Models\User;
use App\Models\VicobaGroup;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

final class RbacService
{
    /** Platform-only roles — never primary role inside the mobile VICOBA app. */
    private const PLATFORM_ROLE_SLUGS = [
        'super_admin',
        'regional_admin',
        'trainer',
    ];

    /** Permissions no role may hold (immutable audit / invisible bypass). */
    private const FORBIDDEN_SLUGS = [
        'delete_audit_logs',
        'bypass_approval_workflow',
        'delete_completed_financial_permanent',
    ];

    /** @return Collection<int, UserRoleRow> */
    public function getUserRoles(User $user, ?int $groupId = null): Collection
    {
        $query = DB::table('user_roles')
            ->join('roles', 'roles.id', '=', 'user_roles.role_id')
            ->where('user_roles.user_id', $user->id)
            ->select('roles.slug', 'roles.name', 'user_roles.group_id', 'user_roles.region_id');

        if ($groupId !== null) {
            $query->where(function ($q) use ($groupId): void {
                $q->whereNull('user_roles.group_id')
                    ->orWhere('user_roles.group_id', $groupId);
            });
        }

        return $query->get()->map(static fn (object $row): UserRoleRow => new UserRoleRow(
            slug: (string) $row->slug,
            name: (string) $row->name,
            group_id: $row->group_id !== null ? (int) $row->group_id : null,
            region_id: $row->region_id !== null ? (int) $row->region_id : null,
        ));
    }

    public function getPermissions(User $user, ?int $groupId = null): array
    {
        $roleIds = DB::table('user_roles')
            ->where('user_id', $user->id)
            ->when($groupId !== null, function ($q) use ($groupId): void {
                $q->where(function ($inner) use ($groupId): void {
                    $inner->whereNull('group_id')->orWhere('group_id', $groupId);
                });
            })
            ->pluck('role_id');

        if ($roleIds->isEmpty()) {
            return [];
        }

        return DB::table('role_permissions')
            ->join('permissions', 'permissions.id', '=', 'role_permissions.permission_id')
            ->whereIn('role_permissions.role_id', $roleIds)
            ->whereNotIn('permissions.slug', self::FORBIDDEN_SLUGS)
            ->distinct()
            ->pluck('permissions.slug')
            ->all();
    }

    public function primaryRoleSlug(User $user, ?int $groupId = null, bool $forMobile = false): string
    {
        $priority = $forMobile
            ? ['provisional_chair', 'chairperson', 'treasurer', 'secretary', 'money_counter', 'key_holder', 'member']
            : ['super_admin', 'regional_admin', 'provisional_chair', 'chairperson', 'treasurer', 'secretary', 'money_counter', 'key_holder', 'trainer', 'member'];

        $slugs = $this->getUserRoles($user, $groupId)->map(static fn (UserRoleRow $role): string => $role->slug)->all();

        if ($forMobile) {
            $slugs = array_values(array_diff($slugs, self::PLATFORM_ROLE_SLUGS));
        }

        foreach ($priority as $role) {
            if (in_array($role, $slugs, true)) {
                return $role;
            }
        }

        return 'member';
    }

    /** @return list<string> */
    private function permissionsForRoleSlug(string $slug): array
    {
        $roleId = DB::table('roles')->where('slug', $slug)->value('id');
        if (! $roleId) {
            return [];
        }

        return DB::table('role_permissions')
            ->join('permissions', 'permissions.id', '=', 'role_permissions.permission_id')
            ->where('role_permissions.role_id', $roleId)
            ->whereNotIn('permissions.slug', self::FORBIDDEN_SLUGS)
            ->distinct()
            ->pluck('permissions.slug')
            ->all();
    }

    public function hasPermission(User $user, string $permission, ?int $groupId = null): bool
    {
        if (in_array($permission, self::FORBIDDEN_SLUGS, true)) {
            return false;
        }

        $permissions = $this->mergeInterimChairPermissions($user, $groupId, $this->getPermissions($user, $groupId));

        if (in_array('platform.full_access', $permissions, true)) {
            return true;
        }

        return in_array($permission, $permissions, true);
    }

    /**
     * Interim group founders may act before formal leadership exists (matches buildAuthProfile).
     *
     * @param  list<string>  $permissions
     * @return list<string>
     */
    private function mergeInterimChairPermissions(User $user, ?int $groupId, array $permissions): array
    {
        if ($groupId === null) {
            return $permissions;
        }

        $group = VicobaGroup::query()->find($groupId);
        if ($group === null || $group->governance_complete) {
            return $permissions;
        }

        $isInterimChair = (int) $group->interim_chair_user_id === $user->id
            || (int) $group->created_by === $user->id;

        if (! $isInterimChair) {
            return $permissions;
        }

        return array_values(array_unique(array_merge(
            $permissions,
            $this->permissionsForRoleSlug('provisional_chair')
        )));
    }

    public function canAccessGroup(User $user, int $groupId): bool
    {
        if ($this->hasPermission($user, 'platform.full_access')) {
            return true;
        }

        if ($this->hasPermission($user, 'groups.access_all')) {
            return true;
        }

        return DB::table('user_roles')
            ->where('user_id', $user->id)
            ->where(function ($q) use ($groupId): void {
                $q->whereNull('group_id')->orWhere('group_id', $groupId);
            })
            ->exists()
            || Member::query()->where('user_id', $user->id)->where('group_id', $groupId)->exists();
    }

    public function buildAuthProfile(User $user, ?int $groupId = null, bool $forMobile = false): array
    {
        $member = $groupId
            ? Member::query()->where('user_id', $user->id)->where('group_id', $groupId)->first()
            : Member::query()->where('user_id', $user->id)->first();

        $resolvedGroupId = $groupId ?? $member?->group_id;
        $group = $resolvedGroupId ? VicobaGroup::query()->find($resolvedGroupId) : null;

        $roles = $this->getUserRoles($user, $groupId);
        $permissions = $this->getPermissions($user, $groupId);
        $primaryRole = $this->primaryRoleSlug($user, $groupId, $forMobile);

        if (
            $forMobile
            && $group !== null
            && ! $group->governance_complete
            && (int) $group->interim_chair_user_id === $user->id
        ) {
            $primaryRole = 'provisional_chair';
        }

        if ($forMobile) {
            $permissions = array_values(array_filter(
                $permissions,
                fn (string $slug): bool => ! str_starts_with($slug, 'platform.') && $slug !== 'groups.access_all'
            ));
            $roles = $roles->filter(
                static fn (UserRoleRow $role): bool => ! in_array($role->slug, self::PLATFORM_ROLE_SLUGS, true)
            )->values();
        }
        $governanceComplete = $group === null || $group->governance_complete;
        $isInterimChair = $primaryRole === 'provisional_chair'
            || ($group !== null && ! $group->governance_complete && (
                (int) $group->interim_chair_user_id === $user->id
                || (int) $group->created_by === $user->id
            ));

        if ($forMobile && $isInterimChair && ! $governanceComplete) {
            $permissions = $this->mergeInterimChairPermissions($user, $resolvedGroupId, $permissions);
        }

        $hasGroupMembership = $member !== null
            || Member::query()->where('user_id', $user->id)->exists();

        $isPlatformOnly = $forMobile
            && ! $hasGroupMembership
            && $this->getUserRoles($user)->map(static fn (UserRoleRow $role): string => $role->slug)
                ->intersect(self::PLATFORM_ROLE_SLUGS)->isNotEmpty();

        return [
            'user' => $user,
            'primary_role' => $primaryRole,
            'roles' => $roles->map(static fn (UserRoleRow $role): array => $role->toArray())->values(),
            'permissions' => $permissions,
            'group_id' => $groupId ?? $member?->group_id,
            'member_id' => $member?->id,
            'dashboard_type' => $isPlatformOnly
                ? 'platform_redirect'
                : match ($primaryRole) {
                    'provisional_chair' => 'provisional_chair',
                    'treasurer' => 'treasurer',
                    'chairperson' => 'chairperson',
                    'secretary' => 'secretary',
                    'money_counter' => 'money_counter',
                    'key_holder' => 'key_holder',
                    default => 'member',
                },
            'is_platform_only' => $isPlatformOnly,
            'governance_complete' => $governanceComplete,
            'is_interim_chair' => $isInterimChair,
            'group_status' => $group?->status,
            'must_change_pin' => (bool) $user->must_change_pin,
            'requires_pin_change' => (bool) $user->must_change_pin,
        ];
    }
}
