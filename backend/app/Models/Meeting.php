<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

final class Meeting extends Model
{
    protected $fillable = [
        'uuid', 'group_id', 'cycle_id', 'scheduled_at', 'started_at', 'ended_at',
        'location', 'agenda', 'notes', 'quorum_required', 'quorum_met',
        'cash_on_hand', 'cash_reconciled', 'status', 'created_by',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'quorum_met' => 'boolean',
            'cash_on_hand' => 'decimal:2',
            'cash_reconciled' => 'decimal:2',
        ];
    }

    public function attendance(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }
}
