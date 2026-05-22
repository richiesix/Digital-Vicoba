<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Models\Election;
use App\Models\LeadershipAssignment;
use App\Models\Loan;
use App\Models\Meeting;
use App\Models\VicobaGroup;
use App\Services\RbacService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class EnsureGroupAccess
{
    public function __construct(private readonly RbacService $rbac) {}

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user === null) {
            return response()->json(['message' => 'Haitambuliki'], 401);
        }

        $groupId = $this->resolveGroupId($request);
        if ($groupId !== null && ! $this->rbac->canAccessGroup($user, $groupId)) {
            return response()->json(['message' => 'Huna ruhusa kwa kikundi hiki'], 403);
        }

        return $next($request);
    }

    private function resolveGroupId(Request $request): ?int
    {
        $group = $request->route('group');
        if ($group instanceof VicobaGroup) {
            return $group->id;
        }

        $loan = $request->route('loan');
        if ($loan instanceof Loan) {
            return $loan->group_id;
        }

        $meeting = $request->route('meeting');
        if ($meeting instanceof Meeting) {
            return $meeting->group_id;
        }

        $election = $request->route('election');
        if ($election instanceof Election) {
            return $election->group_id;
        }

        $assignment = $request->route('assignment');
        if ($assignment instanceof LeadershipAssignment) {
            return $assignment->group_id;
        }

        return null;
    }
}
