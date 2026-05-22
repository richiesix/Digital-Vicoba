<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupCycle;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\RbacService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class GroupController extends Controller
{
    public function __construct(private readonly RbacService $rbac) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = VicobaGroup::query()->when($request->query('status'), fn ($q, $s) => $q->where('status', $s));

        if (! $this->rbac->hasPermission($user, 'platform.full_access')) {
            $groupIds = Member::query()->where('user_id', $user->id)->pluck('group_id')
                ->merge(
                    \Illuminate\Support\Facades\DB::table('user_roles')
                        ->where('user_id', $user->id)
                        ->whereNotNull('group_id')
                        ->pluck('group_id')
                )->unique();
            $query->whereIn('id', $groupIds);
        }

        return response()->json(
            $query->withCount('members')->latest()->paginate(20)
        );
    }

    public function show(VicobaGroup $group): JsonResponse
    {
        if (! $this->rbac->canAccessGroup(request()->user(), $group->id)) {
            return response()->json(['message' => 'Huna ruhusa'], 403);
        }

        return response()->json(['group' => $group->load(['activeCycle', 'members'])]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:200',
            'region_id' => 'nullable|integer',
            'ward' => 'nullable|string|max:100',
            'village' => 'nullable|string|max:100',
            'share_price' => 'required|numeric|min:0',
            'loan_interest_rate' => 'nullable|numeric|min:0|max:100',
            'meeting_day' => 'nullable|string',
            'meeting_frequency' => 'nullable|in:weekly,biweekly,monthly',
        ]);

        $user = $request->user();

        $canManageGroups = $this->rbac->hasPermission($user, 'platform.manage_groups')
            || $this->rbac->hasPermission($user, 'platform.full_access');

        if (! $canManageGroups && Member::query()->where('user_id', $user->id)->exists()) {
            return response()->json([
                'message' => 'Tayari uko katika kikundi. Tumia mwaliko kujiunga na kikundi kingine.',
            ], 422);
        }

        $group = VicobaGroup::query()->create([
            ...$data,
            'created_by' => $user->id,
            'interim_chair_user_id' => $user->id,
            'governance_complete' => false,
            'status' => 'forming',
        ]);

        GroupCycle::query()->create([
            'group_id' => $group->id,
            'cycle_number' => 1,
            'start_date' => now()->toDateString(),
            'status' => 'active',
        ]);

        $provisionalRoleId = \Illuminate\Support\Facades\DB::table('roles')->where('slug', 'provisional_chair')->value('id');
        if ($provisionalRoleId) {
            \Illuminate\Support\Facades\DB::table('user_roles')->updateOrInsert(
                ['user_id' => $user->id, 'role_id' => $provisionalRoleId, 'group_id' => $group->id],
                ['assigned_by' => $user->id, 'assigned_at' => now()]
            );
        }

        Member::query()->create([
            'group_id' => $group->id,
            'user_id' => $user->id,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'phone_number' => $user->phone_number,
            'member_number' => '001',
            'join_date' => now()->toDateString(),
            'status' => 'active',
        ]);

        return response()->json([
            'group' => $group->load('activeCycle'),
            'message' => 'Kikundi kimeundwa. Sajili wanachama kisha weka uongozi wa kikundi.',
            'is_interim_chair' => true,
            'governance_complete' => false,
        ], 201);
    }

    public function dashboard(VicobaGroup $group): JsonResponse
    {
        $cycle = $group->activeCycle;

        return response()->json([
            'group' => $group,
            'total_savings' => $cycle?->total_savings ?? 0,
            'total_shares' => $cycle?->total_shares ?? 0,
            'loans_outstanding' => $cycle?->total_loans_outstanding ?? 0,
            'active_members' => $group->members()->where('status', 'active')->count(),
            'emergency_fund' => $cycle?->emergency_fund_balance ?? 0,
            'social_fund' => $cycle?->social_fund_balance ?? 0,
        ]);
    }

    public function update(Request $request, VicobaGroup $group): JsonResponse
    {
        $group->update($request->validate([
            'name' => 'sometimes|string|max:200',
            'share_price' => 'sometimes|numeric|min:0',
            'loan_interest_rate' => 'sometimes|numeric|min:0|max:100',
            'penalty_rate' => 'sometimes|numeric|min:0|max:100',
            'status' => 'sometimes|in:forming,active,share_out,dormant,closed',
            'constitution_json' => 'sometimes|array',
        ]));

        return response()->json(['group' => $group]);
    }

    public function invite(Request $request, VicobaGroup $group): JsonResponse
    {
        $request->validate(['phone_number' => 'required|string']);

        return response()->json(['message' => 'Mwaliko umetumwa', 'group_id' => $group->id]);
    }
}
