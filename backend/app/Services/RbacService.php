<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Member;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

final class RbacService
{
    /** Permissions no role may hold (immutable audit / invisible bypass). */
    private const FORBIDDEN_SLUGS = [
        'delete_audit_logs',
        'bypass_approval_workflow',
        'delete_completed_financial_permanent',
    ];

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

        return $query->get();
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

    public function primaryRoleSlug(User $user, ?int $groupId = null): string
    {
        $priority = ['super_admin', 'regional_admin', 'chairperson', 'treasurer', 'secretary', 'money_counter', 'key_holder', 'trainer', 'member'];

        $slugs = $this->getUserRoles($user, $groupId)->pluck('slug')->all();

        foreach ($priority as $role) {
            if (in_array($role, $slugs, true)) {
                return $role;
            }
        }

        return 'member';
    }

    public function hasPermission(User $user, string $permission, ?int $groupId = null): bool
    {
        if (in_array($permission, self::FORBIDDEN_SLUGS, true)) {
            return false;
        }

        $permissions = $this->getPermissions($user, $groupId);

        if (in_array('platform.full_access', $permissions, true)) {
            return true;
        }

        return in_array($permission, $permissions, true);
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

    public function buildAuthProfile(User $user, ?int $groupId = null): array
    {
        $roles = $this->getUserRoles($user, $groupId);
        $permissions = $this->getPermissions($user, $groupId);
        $primaryRole = $this->primaryRoleSlug($user, $groupId);

        $member = $groupId
            ? Member::query()->where('user_id', $user->id)->where('group_id', $groupId)->first()
            : Member::query()->where('user_id', $user->id)->first();

        return [
            'user' => $user,
            'primary_role' => $primaryRole,
            'roles' => $roles,
            'permissions' => $permissions,
            'group_id' => $groupId ?? $member?->group_id,
            'member_id' => $member?->id,
            'dashboard_type' => match ($primaryRole) {
                'super_admin' => 'super_admin',
                'treasurer' => 'treasurer',
                default => 'member',
            },
        ];
    }
}
