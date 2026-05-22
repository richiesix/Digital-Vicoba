<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class LeadershipAssignmentVote extends Model
{
    protected $fillable = ['assignment_id', 'member_id', 'approved'];

    protected function casts(): array
    {
        return ['approved' => 'boolean'];
    }

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(LeadershipAssignment::class, 'assignment_id');
    }
}
