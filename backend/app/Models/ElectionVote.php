<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class ElectionVote extends Model
{
    protected $fillable = [
        'election_id', 'voter_member_id', 'candidate_id',
        'encrypted_ballot', 'ballot_hash', 'client_id', 'voted_at',
    ];

    protected function casts(): array
    {
        return ['voted_at' => 'datetime'];
    }

    public function election(): BelongsTo
    {
        return $this->belongsTo(Election::class);
    }

    public function candidate(): BelongsTo
    {
        return $this->belongsTo(ElectionCandidate::class, 'candidate_id');
    }
}
