<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class ShareOutDistribution extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'share_out_id', 'member_id', 'shares_count', 'gross_amount',
        'loan_deduction', 'net_amount', 'disbursement_status',
    ];

    protected function casts(): array
    {
        return [
            'gross_amount' => 'decimal:2',
            'loan_deduction' => 'decimal:2',
            'net_amount' => 'decimal:2',
        ];
    }
}
