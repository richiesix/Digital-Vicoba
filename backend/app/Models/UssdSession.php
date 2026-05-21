<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class UssdSession extends Model
{
    public $timestamps = false;

    protected $fillable = ['session_id', 'phone_number', 'menu_level', 'menu_state', 'user_id', 'expires_at'];

    protected function casts(): array
    {
        return ['expires_at' => 'datetime'];
    }
}
