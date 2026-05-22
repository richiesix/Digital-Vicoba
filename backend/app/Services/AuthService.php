<?php

declare(strict_types=1);

namespace App\Services;

use App\Support\PhoneNumber;
use App\Models\Device;
use App\Models\OtpVerification;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

final class AuthService
{
    public function __construct(
        private readonly JwtService $jwt,
        private readonly SmsService $sms,
        private readonly AuditService $audit,
        private readonly RbacService $rbac,
        private readonly MemberEnrollmentService $enrollment,
    ) {}

    public function sendOtp(string $phone, string $purpose): void
    {
        $otp = app()->environment('production') ? (string) random_int(100000, 999999) : '123456';

        OtpVerification::query()->create([
            'phone_number' => $phone,
            'otp_hash' => Hash::make($otp),
            'purpose' => $purpose,
            'expires_at' => Carbon::now()->addMinutes(config('vicoba.otp_expiry_minutes', 10)),
        ]);

        if (app()->environment('production')) {
            $this->sms->send($phone, "Nambari yako ya Digital Vikoba ni: {$otp}");
        }
    }

    public function verifyOtp(string $phone, string $otp, string $purpose): bool
    {
        $record = OtpVerification::query()
            ->where('phone_number', $phone)
            ->where('purpose', $purpose)
            ->whereNull('verified_at')
            ->where('expires_at', '>', now())
            ->latest('id')
            ->first();

        if (! $record || ! Hash::check($otp, $record->otp_hash)) {
            $record?->increment('attempts');
            return false;
        }

        $record->update(['verified_at' => now()]);
        return true;
    }

    public function register(array $data): User
    {
        $data['phone_number'] = PhoneNumber::normalize($data['phone_number']);

        /** @var User $user */
        $user = User::query()->create([
            'phone_number' => $data['phone_number'],
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'national_id' => $data['national_id'] ?? null,
            'voter_id' => $data['voter_id'] ?? null,
            'preferred_language' => $data['preferred_language'] ?? 'sw',
            'phone_verified_at' => now(),
        ]);

        $this->enrollment->linkPendingMembersForUser($user);

        return $user;
    }

    public function setupPin(User $user, string $pin): void
    {
        if ($user->must_change_pin && $user->pin_hash && Hash::check($pin, $user->pin_hash)) {
            throw ValidationException::withMessages([
                'pin' => ['Choose a new PIN that is different from your temporary PIN.'],
            ]);
        }

        $user->update([
            'pin_hash' => Hash::make($pin),
            'must_change_pin' => false,
            'temporary_pin_issued_at' => null,
        ]);
        $this->audit->log($user, 'pin_setup', 'user', $user->id);
    }

    /** @return array<string, mixed> */
    public function buildMobileAuthResponse(User $user): array
    {
        $profile = $this->rbac->buildAuthProfile($user, forMobile: true);

        return [
            'user' => $user,
            'access_token' => $this->jwt->createAccessToken($user),
            'refresh_token' => $this->jwt->createRefreshToken($user),
            'token_type' => 'Bearer',
            'expires_in' => config('vicoba.jwt_access_ttl', 1800),
            'primary_role' => $profile['primary_role'],
            'dashboard_type' => $profile['dashboard_type'],
            'permissions' => $profile['permissions'],
            'roles' => $profile['roles'],
            'group_id' => $profile['group_id'],
            'member_id' => $profile['member_id'],
            'is_platform_only' => $profile['is_platform_only'] ?? false,
            'governance_complete' => $profile['governance_complete'] ?? true,
            'is_interim_chair' => $profile['is_interim_chair'] ?? false,
            'requires_pin_change' => (bool) $user->must_change_pin,
            'must_change_pin' => (bool) $user->must_change_pin,
        ];
    }

    public function loginWithPin(string $phone, string $pin): ?array
    {
        $phone = PhoneNumber::normalize($phone);
        $user = User::query()->where('phone_number', $phone)->where('is_active', true)->first();
        if (! $user instanceof User || ! $user->pin_hash || ! Hash::check($pin, $user->pin_hash)) {
            return null;
        }

        $user->update(['last_login_at' => now()]);
        $this->audit->log($user, 'login', 'user', $user->id);

        return $this->buildMobileAuthResponse($user);
    }

    public function bindDevice(User $user, array $data): Device
    {
        return Device::query()->updateOrCreate(
            ['device_uuid' => $data['device_uuid']],
            [
                'user_id' => $user->id,
                'device_name' => $data['device_name'] ?? null,
                'platform' => $data['platform'] ?? 'android',
                'fcm_token' => $data['fcm_token'] ?? null,
                'is_verified' => true,
                'bound_at' => now(),
                'last_seen_at' => now(),
            ]
        );
    }
}
