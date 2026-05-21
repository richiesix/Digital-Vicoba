<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\AuditService;
use App\Services\MultiSignatureApprovalService;
use App\Services\RbacService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class ApprovalController extends Controller
{
    public function __construct(
        private readonly MultiSignatureApprovalService $approvals,
        private readonly RbacService $rbac,
        private readonly AuditService $audit,
    ) {}

    public function initiate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'group_id' => 'required|integer',
            'action_type' => 'required|string|max:64',
            'amount' => 'nullable|numeric|min:0',
        ]);

        $user = $request->user();
        if (! $this->rbac->canAccessGroup($user, (int) $data['group_id'])) {
            return response()->json(['message' => 'Huna ruhusa'], 403);
        }

        $reference = $this->approvals->initiate(
            (int) $data['group_id'],
            $data['action_type'],
            $user,
            isset($data['amount']) ? (float) $data['amount'] : null,
        );

        $this->audit->log($user, 'approval.initiated', 'financial_approval', null, null, [
            'reference' => $reference,
            'action_type' => $data['action_type'],
            'group_id' => $data['group_id'],
        ], $request);

        return response()->json([
            'reference' => $reference,
            'required_roles' => ['treasurer', 'chairperson', 'secretary'],
            'message' => 'Ombi la idhini limeanzishwa',
        ], 201);
    }

    public function sign(Request $request, string $reference): JsonResponse
    {
        $data = $request->validate([
            'role' => 'required|in:treasurer,chairperson,secretary',
            'pin' => 'nullable|string|size:4',
            'otp' => 'nullable|string|size:6',
        ]);

        $user = $request->user();
        $approved = $this->approvals->sign(
            $reference,
            $user,
            $data['role'],
            $data['pin'] ?? null,
            $data['otp'] ?? null,
        );

        $this->audit->log($user, 'approval.signed', 'financial_approval', null, null, [
            'reference' => $reference,
            'role' => $data['role'],
            'fully_approved' => $approved,
        ], $request);

        return response()->json([
            'approved' => $approved,
            'message' => $approved ? 'Idhini kamili imekamilika' : 'Saini imeandikwa',
        ]);
    }
}
