<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Repayment extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'uuid', 'loan_id', 'member_id', 'amount', 'principal_portion',
        'interest_portion', 'penalty_amount', 'payment_method', 'reference',
        'recorded_at', 'client_id',
    ];

    protected function casts(): array
    {
        return ['amount' => 'decimal:2', 'recorded_at' => 'datetime'];
    }
}
