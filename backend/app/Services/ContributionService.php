<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Contribution;
use App\Models\Member;
use App\Models\SyncQueue;
use App\Models\VicobaGroup;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class ContributionService
{
    public function record(VicobaGroup $group, Member $member, array $data): Contribution
    {
        return DB::transaction(function () use ($group, $member, $data) {
            $cycle = $group->activeCycle;
            $amount = (float) $data['amount'];
            $type = $data['type'] ?? 'savings';

            $contribution = Contribution::query()->create([
                'uuid' => (string) Str::uuid(),
                'group_id' => $group->id,
                'member_id' => $member->id,
                'cycle_id' => $cycle->id,
                'type' => $type,
                'amount' => $amount,
                'payment_method' => $data['payment_method'] ?? 'cash',
                'reference' => $data['reference'] ?? null,
                'notes' => $data['notes'] ?? null,
                'recorded_by' => auth()->id(),
                'recorded_at' => now(),
                'client_id' => $data['client_id'] ?? null,
            ]);

            if ($type === 'savings') {
                $member->increment('savings_balance', $amount);
                $cycle->increment('total_savings', $amount);
            } elseif ($type === 'emergency') {
                $cycle->increment('emergency_fund_balance', $amount);
            } elseif ($type === 'social') {
                $cycle->increment('social_fund_balance', $amount);
            }

            return $contribution;
        });
    }

    public function processSync(SyncQueue $entry): void
    {
        $payload = $entry->payload;
        $member = Member::query()->findOrFail($payload['member_id']);
        $group = VicobaGroup::query()->findOrFail($payload['group_id']);
        $this->record($group, $member, $payload);
    }
}
