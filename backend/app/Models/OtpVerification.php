<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * @property string $otp_hash
 * @property int $attempts
 */
final class OtpVerification extends Model
{
    public $timestamps = false;

    protected $fillable = ['phone_number', 'otp_hash', 'purpose', 'attempts', 'expires_at', 'verified_at'];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'verified_at' => 'datetime',
        ];
    }
}
