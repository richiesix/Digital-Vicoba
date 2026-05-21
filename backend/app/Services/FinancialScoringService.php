<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Loan;
use App\Models\Member;

final class FinancialScoringService
{
    public function calculate(Member $member): float
    {
        $score = 50.0;

        if ($member->total_shares > 0) {
            $score += min(20, $member->total_shares * 2);
        }

        if ((float) $member->savings_balance > 0) {
            $score += 10;
        }

        $completedLoans = Loan::query()
            ->where('member_id', $member->id)
            ->where('status', 'completed')
            ->count();
        $score += min(15, $completedLoans * 5);

        $defaulted = Loan::query()
            ->where('member_id', $member->id)
            ->where('status', 'defaulted')
            ->exists();
        if ($defaulted) {
            $score -= 30;
        }

        if ((float) $member->loan_balance > 0) {
            $ratio = (float) $member->loan_balance / max(1, (float) $member->savings_balance);
            $score -= min(20, $ratio * 10);
        }

        return round(max(0, min(100, $score)), 2);
    }

    public function predictRepaymentRisk(Member $member): string
    {
        $score = $this->calculate($member);

        return match (true) {
            $score >= 70 => 'low',
            $score >= 40 => 'medium',
            default => 'high',
        };
    }
}
