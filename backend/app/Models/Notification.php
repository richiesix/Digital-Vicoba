<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Notification extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id', 'group_id', 'type', 'title', 'body',
        'channel', 'is_read', 'metadata',
    ];

    protected function casts(): array
    {
        return ['is_read' => 'boolean', 'metadata' => 'array'];
    }
}
