<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('groups')
            ->where('governance_complete', false)
            ->whereNull('interim_chair_user_id')
            ->whereNotNull('created_by')
            ->update([
                'interim_chair_user_id' => DB::raw('created_by'),
            ]);

        $provisionalRoleId = DB::table('roles')->where('slug', 'provisional_chair')->value('id');
        if (! $provisionalRoleId) {
            return;
        }

        $groups = DB::table('groups')
            ->where('governance_complete', false)
            ->whereNotNull('interim_chair_user_id')
            ->get(['id', 'interim_chair_user_id']);

        foreach ($groups as $group) {
            DB::table('user_roles')->updateOrInsert(
                [
                    'user_id' => $group->interim_chair_user_id,
                    'role_id' => $provisionalRoleId,
                    'group_id' => $group->id,
                ],
                [
                    'assigned_by' => $group->interim_chair_user_id,
                    'assigned_at' => now(),
                ]
            );
        }
    }

    public function down(): void
    {
        // Non-destructive backfill; no rollback required.
    }
};
