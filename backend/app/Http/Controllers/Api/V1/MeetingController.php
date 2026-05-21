<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Meeting;
use App\Models\VicobaGroup;
use App\Services\MeetingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class MeetingController extends Controller
{
    public function __construct(private readonly MeetingService $meetings) {}

    public function index(VicobaGroup $group): JsonResponse
    {
        return response()->json([
            'meetings' => Meeting::query()->where('group_id', $group->id)->latest('scheduled_at')->paginate(20),
        ]);
    }

    public function store(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'scheduled_at' => 'required|date',
            'location' => 'nullable|string',
            'agenda' => 'nullable|string',
            'quorum_required' => 'nullable|integer|min:1',
        ]);

        $meeting = $this->meetings->schedule($group, $data);

        return response()->json(['meeting' => $meeting], 201);
    }

    public function start(Meeting $meeting): JsonResponse
    {
        try {
            $meeting = $this->meetings->start($meeting);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'meeting' => $meeting,
            'message' => 'Mkutano umeanza',
        ]);
    }

    public function recordAttendance(Request $request, Meeting $meeting): JsonResponse
    {
        $data = $request->validate([
            'attendance' => 'required|array',
            'attendance.*.member_id' => 'required|integer',
            'attendance.*.status' => 'required|in:present,late,absent,excused',
        ]);

        $results = $this->meetings->recordAttendance($meeting, $data['attendance']);

        return response()->json(['attendance' => $results]);
    }

    public function reconcile(Request $request, Meeting $meeting): JsonResponse
    {
        $data = $request->validate(['cash_reconciled' => 'required|numeric|min:0']);
        $meeting->update(['cash_reconciled' => $data['cash_reconciled'], 'status' => 'completed', 'ended_at' => now()]);

        return response()->json(['meeting' => $meeting]);
    }
}
