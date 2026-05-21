<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\FinancialScoringService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class MemberController extends Controller
{
    public function __construct(private readonly FinancialScoringService $scoring) {}

    public function index(VicobaGroup $group): JsonResponse
    {
        return response()->json([
            'members' => $group->members()->with('user')->paginate(30),
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

        $number = (string) ($group->members()->count() + 1);

        $member = $group->members()->create([
            ...$data,
            'member_number' => str_pad($number, 3, '0', STR_PAD_LEFT),
            'join_date' => $data['join_date'] ?? now()->toDateString(),
            'status' => 'active',
        ]);

        return response()->json(['member' => $member], 201);
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
