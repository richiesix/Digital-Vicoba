<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\VicobaGroup;
use App\Services\FinancialScoringService;
use App\Services\GroupReportService;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\StreamedResponse;

final class ReportController extends Controller
{
    public function __construct(
        private readonly FinancialScoringService $scoring,
        private readonly GroupReportService $reports,
    ) {}

    public function analytics(VicobaGroup $group): JsonResponse
    {
        $cycle = $group->activeCycle;

        return response()->json([
            'total_savings' => $cycle?->total_savings ?? 0,
            'active_loans' => Loan::query()->where('group_id', $group->id)->whereIn('status', ['active', 'disbursed'])->count(),
            'overdue_loans' => Loan::query()->where('group_id', $group->id)->where('due_date', '<', now())->where('outstanding_balance', '>', 0)->count(),
            'member_count' => $group->members()->where('status', 'active')->count(),
            'insights' => [
                'risk_level' => 'medium',
                'recommendation' => 'Endelea kuhimiza akiba za kila wiki',
            ],
        ]);
    }

    public function generate(VicobaGroup $group, string $type): JsonResponse
    {
        if (! $this->reports->isValidType($type)) {
            return response()->json(['message' => 'Aina ya ripoti si sahihi'], 422);
        }

        $report = $this->reports->build($group, $type);

        return response()->json([
            'report' => $report,
            'download_url' => url("/api/v1/groups/{$group->id}/reports/{$type}/download"),
        ]);
    }

    public function download(VicobaGroup $group, string $type): StreamedResponse|JsonResponse
    {
        if (! $this->reports->isValidType($type)) {
            return response()->json(['message' => 'Aina ya ripoti si sahihi'], 422);
        }

        $report = $this->reports->build($group, $type);
        $filename = $report['filename'];
        $content = $report['csv_content'];

        return response()->streamDownload(
            static function () use ($content): void {
                echo $content;
            },
            $filename,
            [
                'Content-Type' => 'text/csv; charset=UTF-8',
                'Content-Disposition' => 'attachment; filename="'.$filename.'"',
            ]
        );
    }
}
