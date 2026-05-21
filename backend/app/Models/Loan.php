<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

final class Loan extends Model
{
    protected $fillable = [
        'uuid', 'group_id', 'member_id', 'cycle_id', 'principal_amount',
        'interest_rate', 'interest_amount', 'total_amount', 'outstanding_balance',
        'term_weeks', 'purpose', 'status', 'disbursement_method', 'disbursed_at',
        'due_date', 'client_id', 'recorded_at',
    ];

    protected function casts(): array
    {
        return [
            'principal_amount' => 'decimal:2',
            'interest_rate' => 'decimal:2',
            'interest_amount' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'outstanding_balance' => 'decimal:2',
            'disbursed_at' => 'datetime',
            'due_date' => 'date',
            'recorded_at' => 'datetime',
        ];
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function repayments(): HasMany
    {
        return $this->hasMany(Repayment::class);
    }
}
