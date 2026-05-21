<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Models\User;
use App\Services\JwtService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class JwtAuthenticate
{
    public function __construct(private readonly JwtService $jwt) {}

    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->header('Authorization', '');
        if (! str_starts_with($header, 'Bearer ')) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $payload = $this->jwt->decode(substr($header, 7));
        if (! $payload || ($payload->type ?? '') !== 'access') {
            return response()->json(['message' => 'Invalid or expired token'], 401);
        }

        $user = User::query()->where('id', $payload->sub)->where('is_active', true)->first();
        if (! $user) {
            return response()->json(['message' => 'User not found'], 401);
        }

        $request->setUserResolver(fn () => $user);
        auth()->setUser($user);

        return $next($request);
    }
}
