<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class MobileMoneyTransaction extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'transaction_id', 'provider', 'direction', 'phone_number', 'amount',
        'provider_reference', 'callback_payload', 'status', 'retry_count',
        'initiated_at', 'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'callback_payload' => 'array',
            'completed_at' => 'datetime',
        ];
    }
}
