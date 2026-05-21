<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\ContributionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class ContributionController extends Controller
{
    public function __construct(private readonly ContributionService $contributions) {}

    public function index(VicobaGroup $group): JsonResponse
    {
        return response()->json([
            'contributions' => \App\Models\Contribution::query()
                ->where('group_id', $group->id)
                ->latest('recorded_at')
                ->paginate(30),
        ]);
    }

    public function store(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer',
            'amount' => 'required|numeric|min:1',
            'type' => 'required|in:savings,emergency,social,penalty,fine',
            'payment_method' => 'required|in:cash,mpesa,airtel,mixx,halopesa,group_wallet',
            'client_id' => 'nullable|string|max:64',
        ]);

        $member = Member::query()->where('group_id', $group->id)->findOrFail($data['member_id']);
        $contribution = $this->contributions->record($group, $member, $data);

        return response()->json(['contribution' => $contribution], 201);
    }
}
