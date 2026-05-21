<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

final class OtpVerifyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'phone_number' => 'required|string',
            'otp' => 'required|string|size:6',
            'purpose' => 'required|in:register,login,reset_pin,bind_device',
        ];
    }
}
