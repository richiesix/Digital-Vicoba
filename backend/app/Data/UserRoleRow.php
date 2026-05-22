<?php

declare(strict_types=1);

namespace App\Data;

final readonly class UserRoleRow
{
    public function __construct(
        public string $slug,
        public string $name,
        public ?int $group_id,
        public ?int $region_id,
    ) {}

    /** @return array{slug: string, name: string, group_id: int|null, region_id: int|null} */
    public function toArray(): array
    {
        return [
            'slug' => $this->slug,
            'name' => $this->name,
            'group_id' => $this->group_id,
            'region_id' => $this->region_id,
        ];
    }
}
