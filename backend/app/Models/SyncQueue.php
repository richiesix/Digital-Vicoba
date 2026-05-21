<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

final class SyncQueue extends Model
{
    protected $table = 'sync_queue';

    public $timestamps = false;

    protected $fillable = [
        'device_id', 'user_id', 'client_id', 'entity_type', 'entity_id',
        'operation', 'payload', 'client_timestamp', 'status',
        'conflict_resolution', 'retry_count', 'error_message', 'processed_at',
    ];

    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'client_timestamp' => 'datetime',
            'processed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
