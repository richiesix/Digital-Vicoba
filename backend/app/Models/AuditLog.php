<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class AuditLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id', 'group_id', 'action', 'entity_type', 'entity_id',
        'old_values', 'new_values', 'ip_address', 'user_agent',
    ];

    protected function casts(): array
    {
        return [
            'old_values' => 'array',
            'new_values' => 'array',
        ];
    }

    public function save(array $options = []): bool
    {
        if ($this->exists) {
            return false;
        }

        return parent::save($options);
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        return false;
    }

    public function delete(): ?bool
    {
        return false;
    }
}
