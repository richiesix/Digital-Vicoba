<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('groups', function (Blueprint $table): void {
            $table->boolean('governance_complete')->default(false)->after('status');
            $table->foreignId('interim_chair_user_id')->nullable()->after('created_by')
                ->constrained('users')->nullOnDelete();
        });

        $required = ['chairperson', 'secretary', 'treasurer'];
        $groupIds = \Illuminate\Support\Facades\DB::table('leadership_roles')
            ->where('active', true)
            ->whereIn('role_name', $required)
            ->select('group_id')
            ->groupBy('group_id')
            ->havingRaw('COUNT(DISTINCT role_name) >= ?', [count($required)])
            ->pluck('group_id');

        if ($groupIds->isNotEmpty()) {
            \Illuminate\Support\Facades\DB::table('groups')
                ->whereIn('id', $groupIds)
                ->update(['governance_complete' => true, 'interim_chair_user_id' => null]);
        }
    }

    public function down(): void
    {
        Schema::table('groups', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('interim_chair_user_id');
            $table->dropColumn('governance_complete');
        });
    }
};
