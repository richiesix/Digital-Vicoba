<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

final class ElectionCandidate extends Model
{
    protected $fillable = [
        'election_id', 'member_id', 'position', 'manifesto', 'nominated_by',
    ];

    public function election(): BelongsTo
    {
        return $this->belongsTo(Election::class);
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function votes(): HasMany
    {
        return $this->hasMany(ElectionVote::class, 'candidate_id');
    }
}
