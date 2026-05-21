<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class GroupCycle extends Model
{
    protected $fillable = [
        'group_id', 'cycle_number', 'start_date', 'end_date', 'total_shares',
        'total_savings', 'total_loans_outstanding', 'emergency_fund_balance',
        'social_fund_balance', 'status', 'share_out_completed_at',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'total_savings' => 'decimal:2',
            'total_loans_outstanding' => 'decimal:2',
            'emergency_fund_balance' => 'decimal:2',
            'social_fund_balance' => 'decimal:2',
            'share_out_completed_at' => 'datetime',
        ];
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(VicobaGroup::class, 'group_id');
    }
}
