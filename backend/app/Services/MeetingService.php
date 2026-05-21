<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Member;
use App\Models\SyncQueue;
use App\Models\VicobaGroup;
use Illuminate\Support\Str;

final class MeetingService
{
    public function schedule(VicobaGroup $group, array $data): Meeting
    {
        $cycle = $group->activeCycle;

        return Meeting::query()->create([
            'uuid' => (string) Str::uuid(),
            'group_id' => $group->id,
            'cycle_id' => $cycle->id,
            'scheduled_at' => $data['scheduled_at'],
            'location' => $data['location'] ?? null,
            'agenda' => $data['agenda'] ?? null,
            'quorum_required' => $data['quorum_required'] ?? (int) ceil($group->members()->where('status', 'active')->count() * 0.5),
            'status' => 'scheduled',
            'created_by' => auth()->id(),
        ]);
    }

    public function start(Meeting $meeting): Meeting
    {
        if ($meeting->status === 'in_progress') {
            return $meeting;
        }

        if ($meeting->status !== 'scheduled') {
            throw new \InvalidArgumentException('Mkutano huu hauwezi kuanzishwa');
        }

        $meeting->update([
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        return $meeting->fresh();
    }

    public function recordAttendance(Meeting $meeting, array $records): array
    {
        $results = [];
        foreach ($records as $record) {
            $attendance = Attendance::query()->updateOrCreate(
                ['meeting_id' => $meeting->id, 'member_id' => $record['member_id']],
                [
                    'status' => $record['status'],
                    'arrived_at' => $record['arrived_at'] ?? null,
                    'recorded_by' => auth()->id(),
                ]
            );
            $results[] = $attendance;
        }

        $present = Attendance::query()->where('meeting_id', $meeting->id)
            ->whereIn('status', ['present', 'late'])->count();
        $meeting->update(['quorum_met' => $present >= $meeting->quorum_required]);

        return $results;
    }

    public function processSync(SyncQueue $entry): void
    {
        $payload = $entry->payload;
        $meeting = Meeting::query()->findOrFail($payload['meeting_id']);
        $this->recordAttendance($meeting, $payload['attendance'] ?? []);
    }
}
