<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Member;
use App\Models\ShareOut;
use App\Models\ShareOutDistribution;
use App\Models\VicobaGroup;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class ShareOutService
{
    public function calculate(VicobaGroup $group): ShareOut
    {
        $cycle = $group->activeCycle;
        $totalPool = (float) $cycle->total_savings + (float) $cycle->emergency_fund_balance;
        $totalShares = max(1, (int) $cycle->total_shares);

        $shareOut = ShareOut::query()->create([
            'uuid' => (string) Str::uuid(),
            'group_id' => $group->id,
            'cycle_id' => $cycle->id,
            'total_pool' => $totalPool,
            'status' => 'calculating',
            'calculated_at' => now(),
        ]);

        $members = $group->members()->where('status', 'active')->get();

        foreach ($members as $member) {
            $shareRatio = $member->total_shares / $totalShares;
            $gross = round($totalPool * $shareRatio, 2);
            $loanDeduction = min($gross, (float) $member->loan_balance);
            $net = $gross - $loanDeduction;

            ShareOutDistribution::query()->create([
                'share_out_id' => $shareOut->id,
                'member_id' => $member->id,
                'shares_count' => $member->total_shares,
                'gross_amount' => $gross,
                'loan_deduction' => $loanDeduction,
                'net_amount' => $net,
            ]);
        }

        $shareOut->update(['status' => 'pending_approval']);

        return $shareOut;
    }
}
