<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class LoanGuarantor extends Model
{
    public $timestamps = false;

    protected $fillable = ['loan_id', 'guarantor_member_id', 'status', 'responded_at', 'notes'];

    protected function casts(): array
    {
        return ['responded_at' => 'datetime'];
    }
}
