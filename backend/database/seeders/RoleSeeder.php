<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

final class RoleSeeder extends Seeder
{
    public function run(): void
    {
        $roles = [
            ['name' => 'Super Admin', 'slug' => 'super_admin', 'description' => 'Platform-wide administration', 'is_system' => true],
            ['name' => 'Regional Admin', 'slug' => 'regional_admin', 'description' => 'Regional oversight', 'is_system' => true],
            ['name' => 'Provisional Chairperson', 'slug' => 'provisional_chair', 'description' => 'Interim group founder until governance is established', 'is_system' => false],
            ['name' => 'Group Chairperson', 'slug' => 'chairperson', 'description' => 'Group leadership', 'is_system' => false],
            ['name' => 'Secretary', 'slug' => 'secretary', 'description' => 'Records and meetings', 'is_system' => false],
            ['name' => 'Treasurer', 'slug' => 'treasurer', 'description' => 'Group financial operations', 'is_system' => false],
            ['name' => 'Money Counter', 'slug' => 'money_counter', 'description' => 'Cash verification', 'is_system' => false],
            ['name' => 'Key Holder', 'slug' => 'key_holder', 'description' => 'Safe custody', 'is_system' => false],
            ['name' => 'Member', 'slug' => 'member', 'description' => 'Group participant', 'is_system' => false],
            ['name' => 'Trainer / Field Officer', 'slug' => 'trainer', 'description' => 'Field training', 'is_system' => true],
        ];

        foreach ($roles as $role) {
            DB::table('roles')->updateOrInsert(
                ['slug' => $role['slug']],
                [...$role, 'created_at' => now(), 'updated_at' => now()]
            );
        }

        $regions = [
            ['name' => 'Dar es Salaam', 'code' => 'DSM'],
            ['name' => 'Mwanza', 'code' => 'MWZ'],
            ['name' => 'Arusha', 'code' => 'ARK'],
            ['name' => 'Dodoma', 'code' => 'DDM'],
        ];

        foreach ($regions as $region) {
            DB::table('regions')->updateOrInsert(['code' => $region['code']], [...$region, 'created_at' => now()]);
        }
    }
}
