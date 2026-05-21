<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

final class PermissionSeeder extends Seeder
{
    public function run(): void
    {
        $permissions = [
            // Super Admin — platform
            ['name' => 'Full Platform Access', 'slug' => 'platform.full_access', 'module' => 'platform'],
            ['name' => 'Manage Regions', 'slug' => 'platform.manage_regions', 'module' => 'platform'],
            ['name' => 'Manage All Groups', 'slug' => 'platform.manage_groups', 'module' => 'platform'],
            ['name' => 'Manage All Users', 'slug' => 'platform.manage_users', 'module' => 'platform'],
            ['name' => 'Assign Regional Admins', 'slug' => 'platform.assign_regional_admins', 'module' => 'platform'],
            ['name' => 'Monitor System', 'slug' => 'platform.monitor_system', 'module' => 'platform'],
            ['name' => 'View All Transactions', 'slug' => 'platform.view_all_transactions', 'module' => 'platform'],
            ['name' => 'Fraud Alerts', 'slug' => 'platform.fraud_alerts', 'module' => 'platform'],
            ['name' => 'Mobile Money Config', 'slug' => 'platform.mobile_money_config', 'module' => 'platform'],
            ['name' => 'National Analytics', 'slug' => 'platform.national_analytics', 'module' => 'platform'],
            ['name' => 'Support Tickets', 'slug' => 'platform.support_tickets', 'module' => 'platform'],
            ['name' => 'System Logs', 'slug' => 'platform.system_logs', 'module' => 'platform'],
            ['name' => 'Export Platform Data', 'slug' => 'platform.export', 'module' => 'platform'],
            ['name' => 'Access All Groups', 'slug' => 'groups.access_all', 'module' => 'groups'],

            // Treasurer — group financial
            ['name' => 'View Group Finances', 'slug' => 'group.view_finances', 'module' => 'group'],
            ['name' => 'Record Transactions', 'slug' => 'group.record_transactions', 'module' => 'group'],
            ['name' => 'Approve Treasury', 'slug' => 'group.approve_treasury', 'module' => 'group'],
            ['name' => 'Verify Repayments', 'slug' => 'group.verify_repayments', 'module' => 'group'],
            ['name' => 'Generate Group Reports', 'slug' => 'group.generate_reports', 'module' => 'group'],
            ['name' => 'Record Contribution', 'slug' => 'group.record_contribution', 'module' => 'group'],
            ['name' => 'Record Shares', 'slug' => 'group.record_shares', 'module' => 'group'],
            ['name' => 'Disburse Loan', 'slug' => 'group.disburse_loan', 'module' => 'group'],
            ['name' => 'Verify Share Out', 'slug' => 'group.share_out_verify', 'module' => 'group'],
            ['name' => 'Manage Mobile Money', 'slug' => 'group.manage_mobile_money', 'module' => 'group'],

            // Member
            ['name' => 'View Own Balance', 'slug' => 'member.view_own_balance', 'module' => 'member'],
            ['name' => 'View Own History', 'slug' => 'member.view_own_history', 'module' => 'member'],
            ['name' => 'Apply Loan', 'slug' => 'member.apply_loan', 'module' => 'member'],
            ['name' => 'Repay Loan', 'slug' => 'member.repay_loan', 'module' => 'member'],
            ['name' => 'Vote Approvals', 'slug' => 'member.vote', 'module' => 'member'],
            ['name' => 'View Meetings', 'slug' => 'member.view_meetings', 'module' => 'member'],
            ['name' => 'View Notifications', 'slug' => 'member.view_notifications', 'module' => 'member'],
            ['name' => 'Buy Shares', 'slug' => 'member.buy_shares', 'module' => 'member'],

            // Shared
            ['name' => 'View Dashboard', 'slug' => 'view_dashboard', 'module' => 'dashboard'],
            ['name' => 'Sync Data', 'slug' => 'sync.data', 'module' => 'sync'],

            // Leadership (for workflow - future)
            ['name' => 'Approve Loan', 'slug' => 'group.approve_loan', 'module' => 'group'],
            ['name' => 'Manage Members', 'slug' => 'group.manage_members', 'module' => 'group'],
            ['name' => 'Manage Meetings', 'slug' => 'group.manage_meetings', 'module' => 'group'],
        ];

        foreach ($permissions as $perm) {
            DB::table('permissions')->updateOrInsert(
                ['slug' => $perm['slug']],
                [...$perm, 'description' => null]
            );
        }

        $this->assignRolePermissions();
    }

    private function assignRolePermissions(): void
    {
        $map = [
            'super_admin' => [
                'platform.full_access', 'platform.manage_regions', 'platform.manage_groups',
                'platform.manage_users', 'platform.assign_regional_admins', 'platform.monitor_system',
                'platform.view_all_transactions', 'platform.fraud_alerts', 'platform.mobile_money_config',
                'platform.national_analytics', 'platform.support_tickets', 'platform.system_logs',
                'platform.export', 'groups.access_all', 'view_dashboard', 'sync.data',
            ],
            'treasurer' => [
                'view_dashboard', 'group.view_finances', 'group.record_transactions',
                'group.approve_treasury', 'group.verify_repayments', 'group.generate_reports',
                'group.record_contribution', 'group.record_shares', 'group.disburse_loan',
                'group.share_out_verify', 'group.manage_mobile_money', 'group.manage_meetings',
                'sync.data',
            ],
            'member' => [
                'view_dashboard', 'member.view_own_balance', 'member.view_own_history',
                'member.apply_loan', 'member.repay_loan', 'member.vote', 'member.view_meetings',
                'member.view_notifications', 'member.buy_shares', 'sync.data',
            ],
            'chairperson' => [
                'view_dashboard', 'group.manage_members', 'group.approve_loan',
                'group.manage_meetings', 'group.share_out_verify', 'group.generate_reports',
                'member.vote', 'sync.data',
            ],
            'secretary' => [
                'view_dashboard', 'group.manage_members', 'group.manage_meetings',
                'group.generate_reports', 'sync.data',
            ],
        ];

        DB::table('role_permissions')->delete();

        foreach ($map as $roleSlug => $permissionSlugs) {
            $roleId = DB::table('roles')->where('slug', $roleSlug)->value('id');
            if (! $roleId) {
                continue;
            }

            foreach ($permissionSlugs as $slug) {
                $permId = DB::table('permissions')->where('slug', $slug)->value('id');
                if ($permId) {
                    DB::table('role_permissions')->insertOrIgnore([
                        'role_id' => $roleId,
                        'permission_id' => $permId,
                    ]);
                }
            }
        }
    }
}
