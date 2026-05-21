<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\SyncQueue;
use Illuminate\Support\Facades\Cache;

final class FraudDetectionService
{
    public function checkDuplicate(array $operation): bool
    {
        $clientId = $operation['client_id'] ?? '';
        return SyncQueue::query()->where('client_id', $clientId)->exists();
    }

    public function checkRapidWithdrawals(int $groupId, int $memberId): bool
    {
        $key = "withdrawals:{$groupId}:{$memberId}";
        $count = (int) Cache::get($key, 0);
        Cache::put($key, $count + 1, now()->addHour());

        return $count >= 3;
    }

    public function checkOutsideMeetingHours(int $groupId): bool
    {
        $hour = (int) now()->format('H');
        return $hour < 6 || $hour > 20;
    }
}
