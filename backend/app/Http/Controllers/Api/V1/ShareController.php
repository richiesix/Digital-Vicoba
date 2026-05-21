<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\ShareService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class ShareController extends Controller
{
    public function __construct(private readonly ShareService $shares) {}

    public function index(VicobaGroup $group): JsonResponse
    {
        return response()->json([
            'shares' => $group->hasMany(\App\Models\Share::class)->latest('recorded_at')->paginate(30),
        ]);
    }

    public function store(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer|exists:members,id',
            'quantity' => 'required|integer|min:1',
            'payment_method' => 'required|in:cash,mpesa,airtel,mixx,halopesa,group_wallet',
            'reference' => 'nullable|string|max:100',
            'client_id' => 'nullable|string|max:64',
        ]);

        $member = Member::query()->where('group_id', $group->id)->findOrFail($data['member_id']);
        $share = $this->shares->record($group, $member, $data);

        return response()->json(['share' => $share], 201);
    }
}
