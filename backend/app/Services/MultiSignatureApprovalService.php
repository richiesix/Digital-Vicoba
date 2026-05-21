<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class MultiSignatureApprovalService
{
    /** Sensitive actions require Treasurer + Chairperson + Secretary. */
    private const REQUIRED_ROLES = ['treasurer', 'chairperson', 'secretary'];

    private const SENSITIVE_ACTIONS = [
        'withdrawal',
        'share_out_disburse',
        'bank_transfer',
        'leadership_change',
        'large_payout',
    ];

    public function isSensitive(string $actionType, float $amount = 0): bool
    {
        if (in_array($actionType, self::SENSITIVE_ACTIONS, true)) {
            return true;
        }

        return $amount >= 500_000;
    }

    public function initiate(int $groupId, string $actionType, User $user, ?float $amount = null): string
    {
        $reference = Str::uuid()->toString();

        DB::table('financial_approvals')->insert([
            'group_id' => $groupId,
            'action_type' => $actionType,
            'reference' => $reference,
            'amount' => $amount,
            'required_roles' => json_encode(self::REQUIRED_ROLES),
            'signatures' => json_encode([]),
            'status' => 'pending',
            'initiated_by' => $user->id,
            'expires_at' => now()->addHours(48),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $reference;
    }

    public function sign(string $reference, User $user, string $roleSlug, ?string $pin = null, ?string $otp = null): bool
    {
        $row = DB::table('financial_approvals')->where('reference', $reference)->first();
        if (! $row || $row->status !== 'pending') {
            return false;
        }

        $required = json_decode($row->required_roles, true) ?: [];
        if (! in_array($roleSlug, $required, true)) {
            return false;
        }

        $signatures = json_decode($row->signatures ?? '[]', true) ?: [];
        foreach ($signatures as $sig) {
            if (($sig['role'] ?? '') === $roleSlug) {
                return false;
            }
        }

        $signatures[] = [
            'user_id' => $user->id,
            'role' => $roleSlug,
            'signed_at' => now()->toIso8601String(),
            'pin_verified' => $pin !== null,
            'otp_verified' => $otp !== null,
        ];

        $status = count($signatures) >= count($required) ? 'approved' : 'pending';

        DB::table('financial_approvals')->where('reference', $reference)->update([
            'signatures' => json_encode($signatures),
            'status' => $status,
            'updated_at' => now(),
        ]);

        return $status === 'approved';
    }

    public function isApproved(string $reference): bool
    {
        $row = DB::table('financial_approvals')->where('reference', $reference)->first();

        return $row && $row->status === 'approved';
    }

    public function requireApprovedOrFail(?string $reference): ?JsonResponse
    {
        if ($reference === null || ! $this->isApproved($reference)) {
            return response()->json([
                'message' => 'Inahitaji idhini ya Mhasibu, Mwenyekiti na Katibu',
                'required_roles' => self::REQUIRED_ROLES,
            ], 422);
        }

        return null;
    }
}
