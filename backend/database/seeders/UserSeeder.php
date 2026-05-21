<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

final class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            ['phone' => '+255712000001', 'first_name' => 'Asha', 'last_name' => 'Mohamed', 'pin' => '1234'],
            ['phone' => '+255712000002', 'first_name' => 'Fatuma', 'last_name' => 'Ali', 'pin' => '1234'],
            ['phone' => '+255712000003', 'first_name' => 'Neema', 'last_name' => 'Joseph', 'pin' => '1234'],
        ];

        foreach ($users as $data) {
            User::query()->updateOrCreate(
                ['phone_number' => $data['phone']],
                [
                    'uuid' => (string) Str::uuid(),
                    'first_name' => $data['first_name'],
                    'last_name' => $data['last_name'],
                    'pin_hash' => Hash::make($data['pin']),
                    'phone_verified_at' => now(),
                    'preferred_language' => 'sw',
                    'is_active' => true,
                ]
            );
        }
    }
}
