<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\FinancialScoringService;
use App\Services\MemberEnrollmentService;
use App\Services\RbacService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class MemberController extends Controller
{
    public function __construct(
        private readonly FinancialScoringService $scoring,
        private readonly MemberEnrollmentService $enrollment,
        private readonly RbacService $rbac,
    ) {}

    public function index(Request $request, VicobaGroup $group): JsonResponse
    {
        $user = $request->user();
        $query = $group->members()->with('user')->orderBy('member_number');

        if (! $this->rbac->hasPermission($user, 'group.manage_members', $group->id)) {
            $query->where('user_id', $user->id);
        }

        return response()->json([
            'members' => $query->paginate(30),
            'can_manage_members' => $this->rbac->hasPermission($user, 'group.manage_members', $group->id),
        ]);
    }

    public function store(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'phone_number' => 'required|string',
            'national_id' => 'nullable|string|max:30',
            'sumaku_group_id' => 'nullable|integer',
            'join_date' => 'nullable|date',
        ]);

        $result = $this->enrollment->createGroupMember($group, $data);

        $temporaryPin = $result['temporary_pin'] ?? null;

        return response()->json([
            'member' => $result['member'],
            'linked_existing_user' => $result['linked_existing_user'],
            'requires_app_registration' => false,
            'requires_temporary_pin_login' => $temporaryPin !== null,
            'temporary_pin' => $temporaryPin,
            'activation_hint' => $temporaryPin !== null
                ? 'Share the temporary PIN with the member. They must log in and choose a new PIN.'
                : 'Member can log in with their existing phone number and PIN.',
        ], 201);
    }

    public function show(Member $member): JsonResponse
    {
        return response()->json([
            'member' => $member,
            'financial_score' => $this->scoring->calculate($member),
        ]);
    }

    public function search(Request $request, VicobaGroup $group): JsonResponse
    {
        $q = $request->query('q', '');
        $members = $group->members()
            ->where(fn ($query) => $query
                ->where('first_name', 'like', "%{$q}%")
                ->orWhere('last_name', 'like', "%{$q}%")
                ->orWhere('phone_number', 'like', "%{$q}%")
                ->orWhere('member_number', 'like', "%{$q}%"))
            ->limit(20)
            ->get();

        return response()->json(['members' => $members]);
    }
}
