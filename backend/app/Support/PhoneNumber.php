<?php

declare(strict_types=1);

namespace App\Support;

final class PhoneNumber
{
    public static function normalize(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';

        if (str_starts_with($digits, '255')) {
            return '+'.substr($digits, 0, 12);
        }

        if (str_starts_with($digits, '0') && strlen($digits) === 10) {
            return '+255'.substr($digits, 1);
        }

        if (strlen($digits) === 9) {
            return '+255'.$digits;
        }

        if (str_starts_with($phone, '+')) {
            return $phone;
        }

        return '+'.$digits;
    }
}
