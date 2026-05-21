<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Contribution extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'uuid', 'group_id', 'member_id', 'cycle_id', 'type', 'amount',
        'payment_method', 'reference', 'notes', 'recorded_by', 'recorded_at', 'client_id',
    ];

    protected function casts(): array
    {
        return ['amount' => 'decimal:2', 'recorded_at' => 'datetime'];
    }
}
