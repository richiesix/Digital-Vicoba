<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class Device extends Model
{
    protected $fillable = [
        'user_id', 'device_uuid', 'device_name', 'platform',
        'fcm_token', 'is_verified', 'last_seen_at', 'bound_at',
    ];

    protected function casts(): array
    {
        return [
            'is_verified' => 'boolean',
            'last_seen_at' => 'datetime',
            'bound_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
