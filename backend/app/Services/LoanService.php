<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\GroupCycle;
use App\Models\Loan;
use App\Models\Member;
use App\Models\Repayment;
use App\Models\SyncQueue;
use App\Models\VicobaGroup;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class LoanService
{
    public function apply(Member $member, VicobaGroup $group, array $data): Loan
    {
        $cycle = $group->activeCycle;
        $maxLoan = $member->total_shares * (float) $group->share_price * (float) $group->max_loan_multiplier;

        if ((float) $data['principal_amount'] > $maxLoan) {
            throw new \InvalidArgumentException('Loan exceeds loan-to-share ratio limit');
        }

        $interestRate = (float) $group->loan_interest_rate;
        $principal = (float) $data['principal_amount'];
        $interest = round($principal * ($interestRate / 100), 2);
        $total = $principal + $interest;

        return Loan::query()->create([
            'uuid' => (string) Str::uuid(),
            'group_id' => $group->id,
            'member_id' => $member->id,
            'cycle_id' => $cycle->id,
            'principal_amount' => $principal,
            'interest_rate' => $interestRate,
            'interest_amount' => $interest,
            'total_amount' => $total,
            'outstanding_balance' => $total,
            'term_weeks' => $data['term_weeks'],
            'purpose' => $data['purpose'] ?? null,
            'status' => 'pending_guarantors',
            'recorded_at' => now(),
            'client_id' => $data['client_id'] ?? null,
        ]);
    }

    public function calculateInterest(float $principal, float $rate): float
    {
        return round($principal * ($rate / 100), 2);
    }

    public function recordRepayment(Loan $loan, array $data): Repayment
    {
        return DB::transaction(function () use ($loan, $data) {
            $amount = (float) $data['amount'];
            $repayment = Repayment::query()->create([
                'uuid' => (string) Str::uuid(),
                'loan_id' => $loan->id,
                'member_id' => $loan->member_id,
                'amount' => $amount,
                'payment_method' => $data['payment_method'] ?? 'cash',
                'reference' => $data['reference'] ?? null,
                'recorded_at' => now(),
                'client_id' => $data['client_id'] ?? null,
            ]);

            $loan->decrement('outstanding_balance', $amount);
            if ($loan->outstanding_balance <= 0) {
                $loan->update(['status' => 'completed', 'outstanding_balance' => 0]);
            }

            $loan->member->decrement('loan_balance', $amount);

            return $repayment;
        });
    }

    public function processSync(SyncQueue $entry): void
    {
        $payload = $entry->payload;
        if ($entry->operation === 'create' && $entry->entity_type === 'loan') {
            $member = Member::query()->findOrFail($payload['member_id']);
            $group = VicobaGroup::query()->findOrFail($payload['group_id']);
            $this->apply($member, $group, $payload);
        }
    }
}
