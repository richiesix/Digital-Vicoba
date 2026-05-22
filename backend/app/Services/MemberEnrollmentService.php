<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Member;
use App\Models\User;
use App\Models\VicobaGroup;
use App\Support\PhoneNumber;
use Illuminate\Support\Facades\Hash;

final class MemberEnrollmentService
{
    public function __construct(
        private readonly LeadershipService $leadership,
        private readonly SmsService $sms,
    ) {}

    /** @param array<string, mixed> $data */
    public function createGroupMember(VicobaGroup $group, array $data): array
    {
        $data['phone_number'] = PhoneNumber::normalize($data['phone_number']);

        $number = (string) ($group->members()->count() + 1);

        $member = $group->members()->create([
            ...$data,
            'member_number' => str_pad($number, 3, '0', STR_PAD_LEFT),
            'join_date' => $data['join_date'] ?? now()->toDateString(),
            'status' => 'active',
        ]);

        $user = User::query()->where('phone_number', $data['phone_number'])->first();
        $temporaryPin = null;

        if ($user) {
            $member->update(['user_id' => $user->id]);
            $this->leadership->syncMemberAccountRoles($member->fresh());
        } else {
            [$user, $temporaryPin] = $this->provisionUserWithTemporaryPin($data);
            $member->update(['user_id' => $user->id]);
            $this->leadership->syncMemberAccountRoles($member->fresh());
        }

        return [
            'member' => $member->fresh(),
            'linked_existing_user' => $temporaryPin === null && $user->must_change_pin === false,
            'requires_app_registration' => false,
            'requires_temporary_pin_login' => $temporaryPin !== null,
            'temporary_pin' => $temporaryPin,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array{0: User, 1: string}
     */
    private function provisionUserWithTemporaryPin(array $data): array
    {
        $phone = $data['phone_number'];
        $temporaryPin = $this->generateTemporaryPin($phone);

        /** @var User $user */
        $user = User::query()->create([
            'phone_number' => $phone,
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'national_id' => $data['national_id'] ?? null,
            'preferred_language' => 'sw',
            'phone_verified_at' => now(),
            'pin_hash' => Hash::make($temporaryPin),
            'must_change_pin' => true,
            'temporary_pin_issued_at' => now(),
            'is_active' => true,
        ]);

        if (app()->environment('production')) {
            $this->sms->send(
                $phone,
                "Karibu Digital Vikoba. PIN yako ya muda ni: {$temporaryPin}. Ingia na ubadilishe PIN mara ya kwanza."
            );
        }

        return [$user, $temporaryPin];
    }

    private function generateTemporaryPin(string $phone): string
    {
        if (! app()->environment('production')) {
            $digits = preg_replace('/\D+/', '', $phone) ?? '';

            return substr(str_pad($digits, 4, '0', STR_PAD_LEFT), -4);
        }

        return str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
    }

    public function linkPendingMembersForUser(User $user): int
    {
        $phone = PhoneNumber::normalize($user->phone_number);

        $pending = Member::query()
            ->where('phone_number', $phone)
            ->whereNull('user_id')
            ->get();

        $pending->each(function (Member $member) use ($user): void {
            $member->update(['user_id' => $user->id]);
            $this->leadership->syncMemberAccountRoles($member->fresh());
        });

        return $pending->count();
    }
}
