<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Share extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'uuid', 'group_id', 'member_id', 'cycle_id', 'quantity',
        'unit_price', 'total_amount', 'payment_method', 'reference',
        'recorded_by', 'recorded_at', 'client_id',
    ];

    protected function casts(): array
    {
        return [
            'unit_price' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'recorded_at' => 'datetime',
        ];
    }
}
