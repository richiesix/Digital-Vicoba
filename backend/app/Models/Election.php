<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

final class Election extends Model
{
    protected $fillable = [
        'uuid', 'group_id', 'election_type', 'title', 'description',
        'quorum_percent', 'start_date', 'end_date', 'status', 'created_by', 'positions',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'datetime',
            'end_date' => 'datetime',
            'positions' => 'array',
            'quorum_percent' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Election $election): void {
            $election->uuid ??= (string) Str::uuid();
        });
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(VicobaGroup::class, 'group_id');
    }

    public function candidates(): HasMany
    {
        return $this->hasMany(ElectionCandidate::class);
    }

    public function votes(): HasMany
    {
        return $this->hasMany(ElectionVote::class);
    }
}
