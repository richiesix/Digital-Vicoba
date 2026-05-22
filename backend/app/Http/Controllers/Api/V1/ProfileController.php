<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AuditService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

final class ProfileController extends Controller
{
    public function __construct(private readonly AuditService $audit) {}

    public function uploadPhoto(Request $request): JsonResponse
    {
        $request->validate([
            'photo' => [
                'required',
                'file',
                'max:5120',
                'mimetypes:image/jpeg,image/png,image/webp,image/gif',
            ],
        ]);

        /** @var User $user */
        $user = $request->user();

        $file = $request->file('photo');
        if ($file === null || ! $file->isValid()) {
            return response()->json(['message' => 'Picha haijatolewa au ni batili'], 422);
        }

        $mime = $file->getMimeType() ?? 'image/jpeg';
        $extension = match (true) {
            str_contains($mime, 'png') => 'png',
            str_contains($mime, 'webp') => 'webp',
            str_contains($mime, 'gif') => 'gif',
            default => 'jpg',
        };
        $filename = sprintf('%s_%s.%s', $user->id, Str::uuid(), $extension);
        $directory = 'profile-photos/'.$user->id;

        $this->deleteStoredPhoto($user->profile_photo_url);

        $storedPath = $file->storeAs($directory, $filename, 'public');
        if ($storedPath === false) {
            return response()->json(['message' => 'Imeshindwa kuhifadhi picha'], 500);
        }

        $publicPath = '/storage/'.str_replace('\\', '/', $storedPath);
        $user->update(['profile_photo_url' => $publicPath]);

        $this->audit->log($user, 'profile_photo_updated', 'user', $user->id);

        return response()->json([
            'message' => 'Picha ya wasifu imesasishwa',
            'profile_photo_url' => $publicPath,
            'user' => $user->fresh(),
        ]);
    }

    public function showPhoto(Request $request): BinaryFileResponse|JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $relative = $this->storageRelativePath($user->profile_photo_url);
        if ($relative === null || ! Storage::disk('public')->exists($relative)) {
            return response()->json(['message' => 'Picha haipatikani'], 404);
        }

        $fullPath = Storage::disk('public')->path($relative);
        $mime = Storage::disk('public')->mimeType($relative) ?: 'image/jpeg';

        return response()->file($fullPath, [
            'Content-Type' => $mime,
            'Cache-Control' => 'private, max-age=3600',
        ])->withHeaders([
            'Access-Control-Allow-Origin' => '*',
        ]);
    }

    public function removePhoto(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $this->deleteStoredPhoto($user->profile_photo_url);
        $user->update(['profile_photo_url' => null]);

        $this->audit->log($user, 'profile_photo_removed', 'user', $user->id);

        return response()->json([
            'message' => 'Picha ya wasifu imeondolewa',
            'profile_photo_url' => null,
            'user' => $user->fresh(),
        ]);
    }

    private function deleteStoredPhoto(?string $url): void
    {
        $relative = $this->storageRelativePath($url);
        if ($relative !== null && Storage::disk('public')->exists($relative)) {
            Storage::disk('public')->delete($relative);
        }
    }

    private function storageRelativePath(?string $url): ?string
    {
        if ($url === null || $url === '') {
            return null;
        }

        if (! str_contains($url, '://') && ! str_starts_with($url, '/storage/')) {
            return ltrim($url, '/');
        }

        $path = parse_url($url, PHP_URL_PATH);
        if (! is_string($path)) {
            return null;
        }

        if (str_contains($path, '/storage/')) {
            $relative = ltrim(Str::after($path, '/storage/'), '/');

            return $relative !== '' ? $relative : null;
        }

        return null;
    }
}
