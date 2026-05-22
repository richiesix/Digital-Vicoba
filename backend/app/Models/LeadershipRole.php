<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class LeadershipRole extends Model
{
    public const POSITIONS = [
        'chairperson',
        'secretary',
        'treasurer',
        'money_counter',
        'key_holder',
    ];

    protected $fillable = [
        'group_id', 'member_id', 'role_name', 'start_date', 'end_date',
        'active', 'assigned_by', 'election_id', 'assignment_method',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'active' => 'boolean',
        ];
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(VicobaGroup::class, 'group_id');
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function election(): BelongsTo
    {
        return $this->belongsTo(Election::class);
    }
}
