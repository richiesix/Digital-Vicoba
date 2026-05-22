<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

/**
 * @property int $group_id
 * @property int|null $user_id
 */
final class Member extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'uuid', 'group_id', 'user_id', 'member_number', 'first_name', 'last_name',
        'phone_number', 'national_id', 'sumaku_group_id', 'join_date', 'status',
        'total_shares', 'savings_balance', 'loan_balance', 'financial_score',
    ];

    protected function casts(): array
    {
        return [
            'join_date' => 'date',
            'savings_balance' => 'decimal:2',
            'loan_balance' => 'decimal:2',
            'financial_score' => 'decimal:2',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Member $member): void {
            $member->uuid ??= (string) Str::uuid();
        });
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(VicobaGroup::class, 'group_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
