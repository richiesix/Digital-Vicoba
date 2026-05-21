<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\AuditService;
use App\Services\MobileMoneyService;
use App\Services\MultiSignatureApprovalService;
use App\Services\RbacService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class MobileMoneyController extends Controller
{
    public function __construct(
        private readonly MobileMoneyService $mobileMoney,
        private readonly MultiSignatureApprovalService $approvals,
        private readonly RbacService $rbac,
        private readonly AuditService $audit,
    ) {}

    public function deposit(Request $request): JsonResponse
    {
        $data = $request->validate([
            'provider' => 'required|in:mpesa,airtel,mixx,halopesa',
            'phone_number' => 'required|string',
            'amount' => 'required|numeric|min:100',
            'group_id' => 'nullable|integer',
        ]);

        $result = $this->mobileMoney->deposit(
            $data['provider'],
            $data['phone_number'],
            (float) $data['amount'],
            $data['group_id'] ?? null,
        );

        return response()->json($result, 201);
    }

    public function withdraw(Request $request): JsonResponse
    {
        $data = $request->validate([
            'provider' => 'required|in:mpesa,airtel,mixx,halopesa',
            'phone_number' => 'required|string',
            'amount' => 'required|numeric|min:100',
            'group_id' => 'required|integer',
            'approval_reference' => 'required|string',
            'pin' => 'nullable|string|size:4',
            'otp' => 'nullable|string|size:6',
        ]);

        $user = $request->user();
        if (! $this->rbac->canAccessGroup($user, (int) $data['group_id'])) {
            return response()->json(['message' => 'Huna ruhusa'], 403);
        }

        if ($blocked = $this->approvals->requireApprovedOrFail($data['approval_reference'])) {
            return $blocked;
        }

        $result = $this->mobileMoney->withdraw(
            $data['provider'],
            $data['phone_number'],
            (float) $data['amount'],
            $data['group_id'],
        );

        $this->audit->log($user, 'mobile_money.withdraw', 'transaction', null, null, [
            'group_id' => $data['group_id'],
            'amount' => $data['amount'],
            'provider' => $data['provider'],
        ], $request);

        return response()->json($result, 201);
    }

    public function callback(Request $request, string $provider): JsonResponse
    {
        $this->mobileMoney->handleCallback($provider, $request->all());

        return response()->json(['received' => true]);
    }

    public function status(string $reference): JsonResponse
    {
        $txn = \App\Models\Transaction::query()->where('reference', $reference)->first();

        return response()->json(['transaction' => $txn]);
    }
}
