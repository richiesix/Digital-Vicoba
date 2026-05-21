<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Models\VicobaGroup;
use App\Services\RbacService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class CheckPermission
{
    public function __construct(private readonly RbacService $rbac) {}

    public function handle(Request $request, Closure $next, string ...$permissions): Response
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $group = $request->route('group');
        $groupId = $group instanceof VicobaGroup
            ? $group->id
            : (is_numeric($group) ? (int) $group : ($request->integer('group_id') ?: null));

        $required = count($permissions) === 1 && str_contains($permissions[0], '|')
            ? explode('|', $permissions[0])
            : $permissions;

        $allowed = false;
        foreach ($required as $permission) {
            if ($this->rbac->hasPermission($user, trim($permission), $groupId)) {
                $allowed = true;
                break;
            }
        }

        if (! $allowed) {
            return response()->json([
                'message' => 'Huna ruhusa ya kufanya kitendo hiki',
                'required_permissions' => $required,
            ], 403);
        }

        return $next($request);
    }
}
