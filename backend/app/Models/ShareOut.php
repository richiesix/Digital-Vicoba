<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class ShareOut extends Model
{
    protected $table = 'share_outs';

    protected $fillable = [
        'uuid', 'group_id', 'cycle_id', 'total_pool', 'total_distributed',
        'status', 'calculated_at', 'approved_at', 'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'total_pool' => 'decimal:2',
            'total_distributed' => 'decimal:2',
            'calculated_at' => 'datetime',
            'approved_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }
}
