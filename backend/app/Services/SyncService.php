<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Device;
use App\Models\SyncQueue;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

final class SyncService
{
    public function __construct(
        private readonly FraudDetectionService $fraud,
        private readonly AuditService $audit,
    ) {}

    public function push(User $user, Device $device, array $operations): array
    {
        $results = [];

        foreach ($operations as $op) {
            $clientId = $op['client_id'] ?? null;
            if (! $clientId) {
                $results[] = ['client_id' => null, 'status' => 'failed', 'error' => 'Missing client_id'];
                continue;
            }

            if (SyncQueue::query()->where('client_id', $clientId)->exists()) {
                $results[] = ['client_id' => $clientId, 'status' => 'duplicate'];
                continue;
            }

            if ($this->fraud->checkDuplicate($op)) {
                $results[] = ['client_id' => $clientId, 'status' => 'fraud_blocked'];
                continue;
            }

            $entry = SyncQueue::query()->create([
                'device_id' => $device->id,
                'user_id' => $user->id,
                'client_id' => $clientId,
                'entity_type' => $op['entity_type'],
                'entity_id' => $op['entity_id'] ?? null,
                'operation' => $op['operation'],
                'payload' => $op['payload'],
                'client_timestamp' => Carbon::parse($op['client_timestamp']),
                'status' => 'pending',
            ]);

            try {
                $this->processOperation($entry);
                $entry->update(['status' => 'completed', 'processed_at' => now()]);
                $results[] = ['client_id' => $clientId, 'status' => 'completed'];
            } catch (\Throwable $e) {
                $entry->update(['status' => 'failed', 'error_message' => $e->getMessage()]);
                $results[] = ['client_id' => $clientId, 'status' => 'failed', 'error' => $e->getMessage()];
            }
        }

        $this->audit->log($user, 'sync_push', null, null, null, ['count' => count($operations)]);

        return $results;
    }

    public function pull(User $user, ?Carbon $since = null): array
    {
        $since ??= Carbon::now()->subDays(30);

        return [
            'groups' => DB::table('members')
                ->join('groups', 'groups.id', '=', 'members.group_id')
                ->where('members.user_id', $user->id)
                ->where('groups.updated_at', '>=', $since)
                ->select('groups.*')
                ->get(),
            'synced_at' => now()->toIso8601String(),
        ];
    }

    public function resolveConflict(string $clientId, string $resolution): bool
    {
        $entry = SyncQueue::query()->where('client_id', $clientId)->where('status', 'conflict')->first();
        if (! $entry) {
            return false;
        }

        $entry->update([
            'conflict_resolution' => $resolution,
            'status' => $resolution === 'manual' ? 'conflict' : 'pending',
        ]);

        if ($resolution !== 'manual') {
            $this->processOperation($entry);
            $entry->update(['status' => 'completed', 'processed_at' => now()]);
        }

        return true;
    }

    private function processOperation(SyncQueue $entry): void
    {
        $handler = match ($entry->entity_type) {
            'share' => app(ShareService::class),
            'contribution' => app(ContributionService::class),
            'loan' => app(LoanService::class),
            'repayment' => app(LoanService::class),
            'attendance' => app(MeetingService::class),
            default => null,
        };

        if ($handler && method_exists($handler, 'processSync')) {
            $handler->processSync($entry);
        }
    }
}
