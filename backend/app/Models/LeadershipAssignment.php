<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

final class LeadershipAssignment extends Model
{
    protected $fillable = [
        'uuid', 'group_id', 'member_id', 'role_name', 'proposed_by',
        'status', 'quorum_required', 'approvals_count', 'reason', 'resolved_at',
    ];

    protected function casts(): array
    {
        return ['resolved_at' => 'datetime'];
    }

    protected static function booted(): void
    {
        static::creating(function (LeadershipAssignment $assignment): void {
            $assignment->uuid ??= (string) Str::uuid();
        });
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(VicobaGroup::class, 'group_id');
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function approvalVotes(): HasMany
    {
        return $this->hasMany(LeadershipAssignmentVote::class, 'assignment_id');
    }
}
