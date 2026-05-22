<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Support\Str;

/**
 * @property int $id
 * @property string $uuid
 * @property string $phone_number
 * @property string $first_name
 * @property string $last_name
 * @property string|null $profile_photo_url
 * @property string|null $pin_hash
 * @property bool $must_change_pin
 * @property \Illuminate\Support\Carbon|null $temporary_pin_issued_at
 * @property bool $is_active
 */
final class User extends Authenticatable
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'phone_number', 'phone_verified_at', 'national_id', 'voter_id',
        'first_name', 'last_name', 'email', 'pin_hash', 'profile_photo_url',
        'preferred_language', 'is_active', 'last_login_at', 'must_change_pin', 'temporary_pin_issued_at',
    ];

    protected $hidden = ['pin_hash', 'password_hash'];

    protected function casts(): array
    {
        return [
            'phone_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'is_active' => 'boolean',
            'must_change_pin' => 'boolean',
            'temporary_pin_issued_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (User $user): void {
            $user->uuid ??= (string) Str::uuid();
        });
    }

    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    public function members(): HasMany
    {
        return $this->hasMany(Member::class);
    }

    public function getFullNameAttribute(): string
    {
        return trim("{$this->first_name} {$this->last_name}");
    }
}
