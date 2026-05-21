<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\SyncQueue;
use App\Services\SyncService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class SyncController extends Controller
{
    public function __construct(private readonly SyncService $sync) {}

    public function push(Request $request): JsonResponse
    {
        $request->validate([
            'device_uuid' => 'required|uuid',
            'operations' => 'required|array|min:1',
            'operations.*.client_id' => 'required|string|max:64',
            'operations.*.entity_type' => 'required|string',
            'operations.*.operation' => 'required|in:create,update,delete',
            'operations.*.payload' => 'required|array',
            'operations.*.client_timestamp' => 'required|date',
        ]);

        $device = Device::query()
            ->where('device_uuid', $request->device_uuid)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $results = $this->sync->push($request->user(), $device, $request->operations);

        return response()->json(['results' => $results]);
    }

    public function pull(Request $request): JsonResponse
    {
        $since = $request->query('since')
            ? Carbon::parse($request->query('since'))
            : null;

        return response()->json($this->sync->pull($request->user(), $since));
    }

    public function status(Request $request): JsonResponse
    {
        $pending = SyncQueue::query()
            ->where('user_id', $request->user()->id)
            ->whereIn('status', ['pending', 'failed', 'conflict'])
            ->count();

        return response()->json([
            'pending_count' => $pending,
            'is_synced' => $pending === 0,
            'last_sync' => SyncQueue::query()
                ->where('user_id', $request->user()->id)
                ->where('status', 'completed')
                ->max('processed_at'),
        ]);
    }

    public function resolveConflict(Request $request, string $clientId): JsonResponse
    {
        $request->validate(['resolution' => 'required|in:server_wins,client_wins,manual']);

        $resolved = $this->sync->resolveConflict($clientId, $request->resolution);

        return response()->json(['resolved' => $resolved]);
    }
}
