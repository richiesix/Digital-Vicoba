<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Str;

final class JwtService
{
    public function createAccessToken(User $user): string
    {
        $payload = [
            'iss' => config('app.url'),
            'sub' => (string) $user->id,
            'uuid' => $user->uuid,
            'type' => 'access',
            'iat' => time(),
            'exp' => time() + (config('vicoba.jwt_access_ttl', 1800)),
        ];

        return JWT::encode($payload, $this->secret(), 'HS256');
    }

    public function createRefreshToken(User $user): string
    {
        $payload = [
            'iss' => config('app.url'),
            'sub' => (string) $user->id,
            'type' => 'refresh',
            'jti' => Str::uuid()->toString(),
            'iat' => time(),
            'exp' => time() + (config('vicoba.jwt_refresh_ttl', 604800)),
        ];

        return JWT::encode($payload, $this->secret(), 'HS256');
    }

    public function decode(string $token): ?object
    {
        try {
            return JWT::decode($token, new Key($this->secret(), 'HS256'));
        } catch (\Throwable) {
            return null;
        }
    }

    private function secret(): string
    {
        return config('vicoba.jwt_secret', config('app.key'));
    }
}
