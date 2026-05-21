<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

final class VicobaGroup extends Model
{
    use SoftDeletes;

    protected $table = 'groups';

    protected $fillable = [
        'uuid', 'name', 'registration_number', 'region_id', 'ward', 'village',
        'share_price', 'currency', 'max_loan_multiplier', 'loan_interest_rate',
        'penalty_rate', 'meeting_day', 'meeting_frequency', 'constitution_json',
        'status', 'formed_at', 'created_by',
    ];

    protected function casts(): array
    {
        return [
            'share_price' => 'decimal:2',
            'max_loan_multiplier' => 'decimal:2',
            'loan_interest_rate' => 'decimal:2',
            'penalty_rate' => 'decimal:2',
            'constitution_json' => 'array',
            'formed_at' => 'date',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (VicobaGroup $group): void {
            $group->uuid ??= (string) Str::uuid();
        });
    }

    public function members(): HasMany
    {
        return $this->hasMany(Member::class, 'group_id');
    }

    public function cycles(): HasMany
    {
        return $this->hasMany(GroupCycle::class, 'group_id');
    }

    public function activeCycle(): HasOne
    {
        return $this->hasOne(GroupCycle::class, 'group_id')->where('status', 'active');
    }
}
