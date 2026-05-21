<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

final class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'phone_number' => 'required|string|regex:/^\+?255\d{9}$/|unique:users,phone_number',
            'otp' => 'required|string|size:6',
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'national_id' => 'nullable|string|max:30',
            'voter_id' => 'nullable|string|max:30',
            'preferred_language' => 'nullable|in:sw,en',
        ];
    }
}
