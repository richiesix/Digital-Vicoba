<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ShareOut;
use App\Models\VicobaGroup;
use App\Services\AuditService;
use App\Services\MultiSignatureApprovalService;
use App\Services\ShareOutService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class ShareOutController extends Controller
{
    public function __construct(
        private readonly ShareOutService $shareOut,
        private readonly MultiSignatureApprovalService $approvals,
        private readonly AuditService $audit,
    ) {}

    public function calculate(VicobaGroup $group): JsonResponse
    {
        $result = $this->shareOut->calculate($group);

        return response()->json(['share_out' => $result], 201);
    }

    public function approve(VicobaGroup $group): JsonResponse
    {
        ShareOut::query()
            ->where('group_id', $group->id)
            ->where('status', 'pending_approval')
            ->update(['status' => 'approved', 'approved_at' => now()]);

        return response()->json(['message' => 'Share-out imeidhinishwa']);
    }

    public function disburse(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate(['approval_reference' => 'required|string']);

        if ($blocked = $this->approvals->requireApprovedOrFail($data['approval_reference'])) {
            return $blocked;
        }

        $this->audit->log($request->user(), 'share_out.disburse', 'share_out', null, null, [
            'group_id' => $group->id,
            'approval_reference' => $data['approval_reference'],
        ], $request);

        return response()->json(['message' => 'Malipo yanaanzishwa']);
    }

    public function history(VicobaGroup $group): JsonResponse
    {
        return response()->json([
            'share_outs' => ShareOut::query()->where('group_id', $group->id)->latest()->get(),
        ]);
    }
}
