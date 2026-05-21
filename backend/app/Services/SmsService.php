<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class SmsService
{
    public function send(string $phone, string $message): bool
    {
        if (! app()->environment('production')) {
            Log::info("SMS to {$phone}: {$message}");
            return true;
        }

        $username = config('services.africastalking.username');
        $apiKey = config('services.africastalking.api_key');

        if (! $username || ! $apiKey) {
            Log::warning('Africa\'s Talking credentials not configured');
            return false;
        }

        $response = Http::withHeaders([
            'apiKey' => $apiKey,
            'Accept' => 'application/json',
        ])->post('https://api.africastalking.com/version1/messaging', [
            'username' => $username,
            'to' => $phone,
            'message' => $message,
        ]);

        return $response->successful();
    }
}
