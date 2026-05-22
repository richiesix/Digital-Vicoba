<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\GroupCycle;
use App\Models\Meeting;
use App\Models\Member;
use App\Models\User;
use App\Models\VicobaGroup;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class GroupSeeder extends Seeder
{
    public function run(): void
    {
        $group = VicobaGroup::query()->updateOrCreate(
            ['name' => 'Vikoba vya Mama Shujaa'],
            [
                'uuid' => (string) Str::uuid(),
                'share_price' => 5000,
                'loan_interest_rate' => 10,
                'penalty_rate' => 5,
                'meeting_frequency' => 'weekly',
                'status' => 'active',
                'governance_complete' => true,
                'formed_at' => now()->subMonths(6)->toDateString(),
            ]
        );

        $cycle = GroupCycle::query()->updateOrCreate(
            ['group_id' => $group->id, 'cycle_number' => 1],
            [
                'start_date' => now()->subMonths(6)->toDateString(),
                'status' => 'active',
                'total_savings' => 1250000,
                'total_shares' => 250,
            ]
        );

        $nextWednesday = now()->startOfWeek()->addDays(2)->setTime(14, 0);
        if ($nextWednesday->isPast()) {
            $nextWednesday = $nextWednesday->addWeek();
        }

        Meeting::query()->updateOrCreate(
            ['group_id' => $group->id, 'status' => 'scheduled'],
            [
                'uuid' => (string) Str::uuid(),
                'cycle_id' => $cycle->id,
                'scheduled_at' => $nextWednesday,
                'location' => 'Ofisi ya Kikundi',
                'agenda' => 'Mkutano wa wiki — akiba, mikopo, mahudhurio',
                'quorum_required' => 13,
                'status' => 'scheduled',
            ]
        );

        $users = User::query()->orderBy('id')->get();
        $roles = ['chairperson', 'treasurer', 'member'];
        $memberData = [
            ['Asha', 'Mohamed', '001'],
            ['Fatuma', 'Ali', '002'],
            ['Neema', 'Joseph', '003'],
        ];

        foreach ($users as $i => $user) {
            $roleSlug = $roles[$i] ?? 'member';
            $roleId = DB::table('roles')->where('slug', $roleSlug)->value('id');

            DB::table('user_roles')->updateOrInsert(
                [
                    'user_id' => $user->id,
                    'role_id' => $roleId,
                    'group_id' => $group->id,
                ],
                [
                    'region_id' => null,
                    'assigned_at' => now(),
                ]
            );

            $member = Member::query()->updateOrCreate(
                ['group_id' => $group->id, 'phone_number' => $user->phone_number],
                [
                    'uuid' => (string) Str::uuid(),
                    'user_id' => $user->id,
                    'member_number' => $memberData[$i][2] ?? '00'.($i + 1),
                    'first_name' => $memberData[$i][0],
                    'last_name' => $memberData[$i][1],
                    'join_date' => now()->subMonths(5)->toDateString(),
                    'status' => 'active',
                    'total_shares' => ($i + 1) * 5,
                    'savings_balance' => ($i + 1) * 50000,
                ]
            );

            if (in_array($roleSlug, ['chairperson', 'treasurer'], true)) {
                DB::table('leadership_roles')->updateOrInsert(
                    [
                        'group_id' => $group->id,
                        'role_name' => $roleSlug,
                        'active' => true,
                    ],
                    [
                        'member_id' => $member->id,
                        'start_date' => now()->subMonths(5)->toDateString(),
                        'end_date' => null,
                        'assigned_by' => $user->id,
                        'assignment_method' => 'manual',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        }
    }
}
