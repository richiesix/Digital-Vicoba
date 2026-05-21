<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Transaction extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'uuid', 'group_id', 'member_id', 'type', 'amount', 'currency',
        'payment_method', 'status', 'reference', 'external_reference', 'recorded_at',
    ];

    protected function casts(): array
    {
        return ['amount' => 'decimal:2', 'recorded_at' => 'datetime'];
    }
}
