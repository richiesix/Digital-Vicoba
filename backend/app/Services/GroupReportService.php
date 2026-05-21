<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Contribution;
use App\Models\Loan;
use App\Models\Member;
use App\Models\VicobaGroup;
use Illuminate\Support\Str;

final class GroupReportService
{
    private const TYPES = ['savings_growth', 'loan_performance', 'payment_trends', 'default_risk'];

    public function isValidType(string $type): bool
    {
        return in_array($type, self::TYPES, true);
    }

    /**
     * @return array<string, mixed>
     */
    public function build(VicobaGroup $group, string $type): array
    {
        return match ($type) {
            'savings_growth' => $this->savingsGrowth($group),
            'loan_performance' => $this->loanPerformance($group),
            'payment_trends' => $this->paymentTrends($group),
            'default_risk' => $this->defaultRisk($group),
            default => throw new \InvalidArgumentException('Invalid report type'),
        };
    }

    /**
     * @return array<string, mixed>
     */
    private function savingsGrowth(VicobaGroup $group): array
    {
        $members = $group->members()->orderBy('last_name')->get();
        $columns = ['Nambari', 'Jina', 'Hisa', 'Akiba (TZS)', 'Hali'];
        $rows = [];
        $totalSavings = 0.0;

        foreach ($members as $m) {
            $savings = (float) $m->savings_balance;
            $totalSavings += $savings;
            $rows[] = [
                $m->member_number,
                trim("{$m->first_name} {$m->last_name}"),
                (string) $m->total_shares,
                number_format($savings, 2, '.', ''),
                $m->status,
            ];
        }

        $cycle = $group->activeCycle;

        return $this->package(
            $group,
            'savings_growth',
            'Ukuaji wa Akiba',
            $columns,
            $rows,
            [
                'group_name' => $group->name,
                'total_savings' => $cycle?->total_savings ?? $totalSavings,
                'member_count' => $members->count(),
                'total_shares' => $cycle?->total_shares ?? $members->sum('total_shares'),
            ]
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function loanPerformance(VicobaGroup $group): array
    {
        $loans = Loan::query()->where('group_id', $group->id)->with('member')->latest()->get();
        $columns = ['Mkopo #', 'Mwanachama', 'Kiasi', 'Salio', 'Riba %', 'Hali', 'Tarehe'];
        $rows = [];

        foreach ($loans as $loan) {
            $member = $loan->member;
            $rows[] = [
                (string) $loan->id,
                $member ? trim("{$member->first_name} {$member->last_name}") : '—',
                number_format((float) $loan->principal_amount, 2, '.', ''),
                number_format((float) $loan->outstanding_balance, 2, '.', ''),
                (string) $loan->interest_rate,
                $loan->status,
                $loan->disbursed_at?->toDateString() ?? $loan->created_at?->toDateString() ?? '',
            ];
        }

        $active = $loans->whereIn('status', ['active', 'disbursed'])->count();
        $outstanding = $loans->sum(fn ($l) => (float) $l->outstanding_balance);

        return $this->package(
            $group,
            'loan_performance',
            'Utendaji wa Mikopo',
            $columns,
            $rows,
            [
                'group_name' => $group->name,
                'active_loans' => $active,
                'total_outstanding' => $outstanding,
                'loan_count' => $loans->count(),
            ]
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function paymentTrends(VicobaGroup $group): array
    {
        $contributions = Contribution::query()
            ->where('group_id', $group->id)
            ->orderByDesc('recorded_at')
            ->limit(100)
            ->get();

        $columns = ['Tarehe', 'Aina', 'Kiasi (TZS)', 'Njia', 'Mwanachama ID'];
        $rows = [];
        $total = 0.0;

        foreach ($contributions as $c) {
            $amount = (float) $c->amount;
            $total += $amount;
            $rows[] = [
                $c->recorded_at?->toDateString() ?? '',
                $c->type,
                number_format($amount, 2, '.', ''),
                $c->payment_method ?? '',
                (string) $c->member_id,
            ];
        }

        return $this->package(
            $group,
            'payment_trends',
            'Mwenendo wa Malipo',
            $columns,
            $rows,
            [
                'group_name' => $group->name,
                'transaction_count' => $contributions->count(),
                'total_amount' => $total,
            ]
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function defaultRisk(VicobaGroup $group): array
    {
        $overdue = Loan::query()
            ->where('group_id', $group->id)
            ->where('due_date', '<', now())
            ->where('outstanding_balance', '>', 0)
            ->with('member')
            ->get();

        $columns = ['Mkopo #', 'Mwanachama', 'Salio', 'Tarehe ya mwisho', 'Siku zilizopita'];
        $rows = [];

        foreach ($overdue as $loan) {
            $member = $loan->member;
            $days = $loan->due_date ? now()->diffInDays($loan->due_date, false) : 0;
            $rows[] = [
                (string) $loan->id,
                $member ? trim("{$member->first_name} {$member->last_name}") : '—',
                number_format((float) $loan->outstanding_balance, 2, '.', ''),
                $loan->due_date?->toDateString() ?? '',
                (string) abs((int) $days),
            ];
        }

        $highRisk = Member::query()
            ->where('group_id', $group->id)
            ->where('loan_balance', '>', 0)
            ->count();

        return $this->package(
            $group,
            'default_risk',
            'Hatari ya Default',
            $columns,
            $rows,
            [
                'group_name' => $group->name,
                'overdue_loans' => $overdue->count(),
                'members_with_loans' => $highRisk,
                'risk_level' => $overdue->count() > 2 ? 'high' : ($overdue->count() > 0 ? 'medium' : 'low'),
            ]
        );
    }

    /**
     * @param  list<string>  $columns
     * @param  list<list<string>>  $rows
     * @param  array<string, mixed>  $summary
     * @return array<string, mixed>
     */
    private function package(
        VicobaGroup $group,
        string $type,
        string $title,
        array $columns,
        array $rows,
        array $summary,
    ): array {
        $generatedAt = now();
        $filename = sprintf(
            '%s_%s_%s.csv',
            Str::slug($group->name),
            $type,
            $generatedAt->format('Y-m-d_His')
        );

        return [
            'id' => (string) Str::uuid(),
            'type' => $type,
            'title' => $title,
            'group_id' => $group->id,
            'group_name' => $group->name,
            'filename' => $filename,
            'generated_at' => $generatedAt->toIso8601String(),
            'summary' => $summary,
            'columns' => $columns,
            'rows' => $rows,
            'csv_content' => $this->toCsv($columns, $rows),
        ];
    }

    /**
     * @param  list<string>  $columns
     * @param  list<list<string>>  $rows
     */
    private function toCsv(array $columns, array $rows): string
    {
        $escape = static function (string $value): string {
            if (str_contains($value, ',') || str_contains($value, '"') || str_contains($value, "\n")) {
                return '"'.str_replace('"', '""', $value).'"';
            }

            return $value;
        };

        $lines = [implode(',', array_map($escape, $columns))];
        foreach ($rows as $row) {
            $lines[] = implode(',', array_map($escape, array_map(strval(...), $row)));
        }

        return implode("\n", $lines);
    }
}
