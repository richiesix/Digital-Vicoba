<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Member;
use App\Models\Notification;

final class NotificationService
{
    public function notifyGroup(int $groupId, string $type, string $title, string $body, array $metadata = []): void
    {
        $userIds = Member::query()
            ->where('group_id', $groupId)
            ->where('status', 'active')
            ->whereNotNull('user_id')
            ->pluck('user_id');

        foreach ($userIds as $userId) {
            Notification::query()->create([
                'user_id' => $userId,
                'group_id' => $groupId,
                'type' => $type,
                'title' => $title,
                'body' => $body,
                'channel' => 'in_app',
                'is_read' => false,
                'metadata' => $metadata,
            ]);
        }
    }
}
