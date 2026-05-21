<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\GroupCycle;
use App\Models\Member;
use App\Models\Share;
use App\Models\SyncQueue;
use App\Models\VicobaGroup;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class ShareService
{
    public function record(VicobaGroup $group, Member $member, array $data): Share
    {
        return DB::transaction(function () use ($group, $member, $data) {
            $cycle = $group->activeCycle ?? GroupCycle::query()->create([
                'group_id' => $group->id,
                'cycle_number' => 1,
                'start_date' => now()->toDateString(),
                'status' => 'active',
            ]);

            $qty = (int) ($data['quantity'] ?? 1);
            $unitPrice = (float) $group->share_price;
            $total = $qty * $unitPrice;

            $share = Share::query()->create([
                'uuid' => (string) Str::uuid(),
                'group_id' => $group->id,
                'member_id' => $member->id,
                'cycle_id' => $cycle->id,
                'quantity' => $qty,
                'unit_price' => $unitPrice,
                'total_amount' => $total,
                'payment_method' => $data['payment_method'] ?? 'cash',
                'reference' => $data['reference'] ?? null,
                'recorded_by' => auth()->id(),
                'recorded_at' => now(),
                'client_id' => $data['client_id'] ?? null,
            ]);

            $member->increment('total_shares', $qty);
            $member->increment('savings_balance', $total);
            $cycle->increment('total_shares', $qty);
            $cycle->increment('total_savings', $total);

            return $share;
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
