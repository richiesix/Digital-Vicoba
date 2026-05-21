<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Loan;
use App\Models\MobileMoneyTransaction;
use App\Models\Transaction;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

final class MobileMoneyService
{
    public function deposit(string $provider, string $phone, float $amount, ?int $groupId = null): array
    {
        $txn = $this->createTransaction('deposit', $amount, $provider, $groupId);

        $mm = MobileMoneyTransaction::query()->create([
            'transaction_id' => $txn->id,
            'provider' => $provider,
            'direction' => 'inbound',
            'phone_number' => $phone,
            'amount' => $amount,
            'status' => 'initiated',
        ]);

        $this->initiateProviderRequest($provider, $phone, $amount, $mm);

        return ['reference' => $txn->reference, 'status' => 'initiated'];
    }

    public function withdraw(string $provider, string $phone, float $amount, int $groupId): array
    {
        $txn = $this->createTransaction('withdrawal', $amount, $provider, $groupId);

        MobileMoneyTransaction::query()->create([
            'transaction_id' => $txn->id,
            'provider' => $provider,
            'direction' => 'outbound',
            'phone_number' => $phone,
            'amount' => $amount,
            'status' => 'initiated',
        ]);

        return ['reference' => $txn->reference, 'status' => 'initiated'];
    }

    public function disburse(Loan $loan, string $provider): void
    {
        $phone = $loan->member->phone_number;
        $this->withdraw($provider, $phone, (float) $loan->principal_amount, $loan->group_id);
    }

    public function handleCallback(string $provider, array $payload): void
    {
        Log::info("Mobile money callback [{$provider}]", $payload);

        $reference = $payload['reference'] ?? $payload['TransID'] ?? null;
        if (! $reference) {
            return;
        }

        $mm = MobileMoneyTransaction::query()
            ->where('provider', $provider)
            ->where('provider_reference', $reference)
            ->first();

        $mm?->update([
            'status' => ($payload['status'] ?? 'success') === 'success' ? 'success' : 'failed',
            'callback_payload' => $payload,
            'completed_at' => now(),
        ]);
    }

    private function createTransaction(string $type, float $amount, string $provider, ?int $groupId): Transaction
    {
        return Transaction::query()->create([
            'uuid' => (string) Str::uuid(),
            'group_id' => $groupId,
            'type' => $type,
            'amount' => $amount,
            'payment_method' => $provider,
            'status' => 'pending',
            'reference' => 'DV'.strtoupper(Str::random(10)),
            'recorded_at' => now(),
        ]);
    }

    private function initiateProviderRequest(string $provider, string $phone, float $amount, MobileMoneyTransaction $mm): void
    {
        Log::info("Initiating {$provider} payment", ['phone' => $phone, 'amount' => $amount]);
        $mm->update(['status' => 'pending']);
    }
}
