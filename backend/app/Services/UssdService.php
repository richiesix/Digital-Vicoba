<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Member;
use App\Models\UssdSession;
use App\Models\User;
use Carbon\Carbon;

final class UssdService
{
    private const MENU_SW = [
        'main' => "CON Digital Vikoba\n1. Salio\n2. Mkopo\n3. Akiba\n0. Toka",
        'balance' => 'END Salio lako ni TZS {balance}',
        'loan' => 'END Mkopo: {status}. Deni: TZS {balance}',
        'savings' => 'END Akiba yako: TZS {balance}',
    ];

    public function handle(string $sessionId, string $phone, string $text): string
    {
        $session = UssdSession::query()->firstOrCreate(
            ['session_id' => $sessionId],
            [
                'phone_number' => $phone,
                'menu_level' => 1,
                'expires_at' => Carbon::now()->addSeconds(config('vicoba.ussd_session_timeout', 180)),
            ]
        );

        if ($session->expires_at->isPast()) {
            $session->delete();
            return $this->menu('main');
        }

        $user = User::query()->where('phone_number', $phone)->first();
        $session->update(['user_id' => $user?->id]);

        $parts = $text === '' ? [] : explode('*', $text);
        $level = count($parts);

        if ($level === 0) {
            return $this->menu('main');
        }

        return match ($parts[0]) {
            '1' => $this->balanceMenu($user, $level, $parts),
            '2' => $this->loanMenu($user, $level, $parts),
            '3' => $this->savingsMenu($user, $level, $parts),
            '0' => 'END Asante. Kwaheri.',
            default => $this->menu('main'),
        };
    }

    private function balanceMenu(?User $user, int $level, array $parts): string
    {
        if (! $user) {
            return 'END Samahani, hujasajiliwa. Pakua programu ya Digital Vikoba.';
        }

        $member = Member::query()->where('user_id', $user->id)->where('status', 'active')->first();
        if (! $member) {
            return 'END Huna kikundi kilichounganishwa.';
        }

        $balance = number_format((float) $member->savings_balance, 0, '.', ',');

        return str_replace('{balance}', $balance, self::MENU_SW['balance']);
    }

    private function loanMenu(?User $user, int $level, array $parts): string
    {
        if (! $user) {
            return 'END Samahani, hujasajiliwa.';
        }

        $member = Member::query()->where('user_id', $user->id)->first();
        if (! $member) {
            return 'END Huna mkopo.';
        }

        $loan = $member->loan_balance > 0 ? 'Una deni' : 'Huna deni';
        $balance = number_format((float) $member->loan_balance, 0, '.', ',');

        return str_replace(['{status}', '{balance}'], [$loan, $balance], self::MENU_SW['loan']);
    }

    private function savingsMenu(?User $user, int $level, array $parts): string
    {
        if ($level === 1) {
            return "CON Thibitisha akiba\n1. Ndiyo\n0. Ghairi";
        }

        if (! $user) {
            return 'END Samahani, hujasajiliwa.';
        }

        $member = Member::query()->where('user_id', $user->id)->first();
        $balance = number_format((float) ($member?->savings_balance ?? 0), 0, '.', ',');

        return str_replace('{balance}', $balance, self::MENU_SW['savings']);
    }

    private function menu(string $key): string
    {
        return self::MENU_SW[$key];
    }
}
