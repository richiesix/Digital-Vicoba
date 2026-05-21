<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\Member;
use App\Models\User;
use App\Models\VicobaGroup;
use App\Services\RbacService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class DashboardController extends Controller
{
    public function __construct(private readonly RbacService $rbac) {}

    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $groupId = $request->integer('group_id') ?: null;
        $profile = $this->rbac->buildAuthProfile($user, $groupId);

        $dashboard = match ($profile['dashboard_type']) {
            'super_admin' => $this->superAdminDashboard(),
            'treasurer' => $this->treasurerDashboard($user, $profile['group_id']),
            default => $this->memberDashboard($user, $profile['group_id'], $profile['member_id']),
        };

        return response()->json([
            'profile' => [
                'primary_role' => $profile['primary_role'],
                'dashboard_type' => $profile['dashboard_type'],
                'permissions' => $profile['permissions'],
                'roles' => $profile['roles'],
                'group_id' => $profile['group_id'],
                'member_id' => $profile['member_id'],
            ],
            'widgets' => $dashboard,
        ]);
    }

    private function superAdminDashboard(): array
    {
        return [
            'total_groups' => VicobaGroup::query()->where('status', 'active')->count(),
            'total_members' => Member::query()->where('status', 'active')->count(),
            'active_loans' => Loan::query()->whereIn('status', ['active', 'disbursed'])->count(),
            'total_savings' => (float) DB::table('group_cycles')->sum('total_savings'),
            'fraud_alerts' => DB::table('audit_logs')->where('action', 'like', '%fraud%')->count(),
            'mobile_money_status' => 'operational',
            'api_health' => 'healthy',
            'quick_actions' => [
                ['key' => 'users', 'label' => 'Usimamizi wa Watumiaji', 'permission' => 'platform.manage_users'],
                ['key' => 'groups', 'label' => 'Vikundi', 'permission' => 'platform.manage_groups'],
                ['key' => 'analytics', 'label' => 'Takwimu za Kitaifa', 'permission' => 'platform.national_analytics'],
                ['key' => 'fraud', 'label' => 'Tahadhari za Udanganyifu', 'permission' => 'platform.fraud_alerts'],
                ['key' => 'logs', 'label' => 'Kumbukumbu za Mfumo', 'permission' => 'platform.system_logs'],
            ],
        ];
    }

    private function treasurerDashboard(User $user, ?int $groupId): array
    {
        if (! $groupId || ! $this->rbac->canAccessGroup($user, $groupId)) {
            return ['error' => 'Hakuna kikundi kilichounganishwa'];
        }

        $group = VicobaGroup::query()->with('activeCycle')->find($groupId);
        $cycle = $group?->activeCycle;

        return [
            'group_name' => $group?->name,
            'group_balance' => (float) ($cycle?->total_savings ?? 0),
            'savings_total' => (float) ($cycle?->total_savings ?? 0),
            'pending_repayments' => Loan::query()->where('group_id', $groupId)->where('status', 'active')->count(),
            'overdue_loans' => Loan::query()->where('group_id', $groupId)->where('due_date', '<', now())->where('outstanding_balance', '>', 0)->count(),
            'emergency_fund' => (float) ($cycle?->emergency_fund_balance ?? 0),
            'social_fund' => (float) ($cycle?->social_fund_balance ?? 0),
            'quick_actions' => [
                ['key' => 'record_contribution', 'label' => 'Rekodi Mchango', 'permission' => 'group.record_contribution'],
                ['key' => 'verify_repayment', 'label' => 'Thibitisha Malipo', 'permission' => 'group.verify_repayments'],
                ['key' => 'reports', 'label' => 'Ripoti za Kikundi', 'permission' => 'group.generate_reports'],
                ['key' => 'share_out', 'label' => 'Mgawanyo', 'permission' => 'group.share_out_verify'],
            ],
        ];
    }

    private function memberDashboard(User $user, ?int $groupId, ?int $memberId): array
    {
        $member = $memberId
            ? Member::query()->find($memberId)
            : Member::query()->where('user_id', $user->id)->when($groupId, fn ($q) => $q->where('group_id', $groupId))->first();

        return [
            'current_savings' => (float) ($member?->savings_balance ?? 0),
            'loan_balance' => (float) ($member?->loan_balance ?? 0),
            'total_shares' => (int) ($member?->total_shares ?? 0),
            'group_name' => $member ? VicobaGroup::query()->find($member->group_id)?->name : null,
            'upcoming_meetings' => 1,
            'notifications_unread' => 2,
            'quick_actions' => [
                ['key' => 'buy_shares', 'label' => 'Nunua Hisa', 'permission' => 'member.buy_shares'],
                ['key' => 'apply_loan', 'label' => 'Omba Mkopo', 'permission' => 'member.apply_loan'],
                ['key' => 'history', 'label' => 'Historia', 'permission' => 'member.view_own_history'],
                ['key' => 'meetings', 'label' => 'Mikutano', 'permission' => 'member.view_meetings'],
            ],
        ];
    }
}
