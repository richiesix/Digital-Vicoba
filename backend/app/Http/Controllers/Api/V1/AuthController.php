<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\OtpSendRequest;
use App\Http\Requests\Auth\OtpVerifyRequest;
use App\Http\Requests\Auth\PinSetupRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Models\User;
use App\Services\AuthService;
use App\Services\JwtService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $auth,
        private readonly JwtService $jwt,
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        if (! $this->auth->verifyOtp($request->phone_number, $request->otp, 'register')) {
            return response()->json(['message' => 'OTP si sahihi'], 422);
        }

        $user = $this->auth->register($request->validated());

        return response()->json([
            'message' => 'Usajili umefanikiwa',
            'requires_pin_setup' => true,
            ...$this->auth->buildMobileAuthResponse($user),
        ], 201);
    }

    public function sendOtp(OtpSendRequest $request): JsonResponse
    {
        $phone = \App\Support\PhoneNumber::normalize($request->phone_number);
        $this->auth->sendOtp($phone, $request->purpose);

        return response()->json(['message' => 'OTP imetumwa']);
    }

    public function verifyOtp(OtpVerifyRequest $request): JsonResponse
    {
        $valid = $this->auth->verifyOtp($request->phone_number, $request->otp, $request->purpose);

        return response()->json(['verified' => $valid]);
    }

    public function setupPin(PinSetupRequest $request): JsonResponse
    {
        $this->auth->setupPin($request->user(), $request->pin);

        return response()->json(['message' => 'PIN imewekwa']);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->auth->loginWithPin($request->phone_number, $request->pin);

        if (! $result) {
            return response()->json(['message' => 'Nambari ya simu au PIN si sahihi'], 401);
        }

        return response()->json($result);
    }

    public function refresh(Request $request): JsonResponse
    {
        $payload = $this->jwt->decode($request->input('refresh_token', ''));
        if (! $payload || ($payload->type ?? '') !== 'refresh') {
            return response()->json(['message' => 'Invalid refresh token'], 401);
        }

        $user = User::query()->find($payload->sub);
        if (! $user) {
            return response()->json(['message' => 'User not found'], 401);
        }

        return response()->json([
            'access_token' => $this->jwt->createAccessToken($user),
            'refresh_token' => $this->jwt->createRefreshToken($user),
            'token_type' => 'Bearer',
            'expires_in' => config('vicoba.jwt_access_ttl', 1800),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $profile = app(\App\Services\RbacService::class)->buildAuthProfile(
            $request->user(),
            $request->integer('group_id') ?: null,
            forMobile: true
        );

        return response()->json($profile);
    }

    public function bindDevice(Request $request): JsonResponse
    {
        $device = $this->auth->bindDevice($request->user(), $request->validate([
            'device_uuid' => 'required|uuid',
            'device_name' => 'nullable|string|max:100',
            'platform' => 'nullable|in:android,ios,web',
            'fcm_token' => 'nullable|string|max:500',
        ]));

        return response()->json(['device' => $device]);
    }

    public function logout(): JsonResponse
    {
        return response()->json(['message' => 'Logged out']);
    }

    public function resetPin(Request $request): JsonResponse
    {
        $request->validate([
            'phone_number' => 'required|string',
            'otp' => 'required|string|size:6',
            'pin' => 'required|string|size:4|regex:/^\d{4}$/',
        ]);

        if (! $this->auth->verifyOtp($request->phone_number, $request->otp, 'reset_pin')) {
            return response()->json(['message' => 'OTP si sahihi'], 422);
        }

        $user = User::query()->where('phone_number', $request->phone_number)->firstOrFail();
        $this->auth->setupPin($user, $request->pin);

        return response()->json(['message' => 'PIN imewekwa upya']);
    }
}
