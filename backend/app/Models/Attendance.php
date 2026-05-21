<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Attendance extends Model
{
    public $timestamps = false;

    protected $table = 'attendance';

    protected $fillable = ['meeting_id', 'member_id', 'status', 'arrived_at', 'recorded_by'];

    protected function casts(): array
    {
        return ['arrived_at' => 'datetime'];
    }
}
