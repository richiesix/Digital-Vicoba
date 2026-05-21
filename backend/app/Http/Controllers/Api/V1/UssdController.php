<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\UssdService;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class UssdController extends Controller
{
    public function __construct(private readonly UssdService $ussd) {}

    public function callback(Request $request): Response
    {
        $sessionId = $request->input('sessionId', '');
        $phone = $request->input('phoneNumber', '');
        $text = $request->input('text', '');

        $response = $this->ussd->handle($sessionId, $phone, $text);

        return response($response, 200)->header('Content-Type', 'text/plain');
    }
}
