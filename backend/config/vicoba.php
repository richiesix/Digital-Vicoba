<?php

declare(strict_types=1);

return [
    'jwt_secret' => env('JWT_SECRET_KEY', env('APP_KEY')),
    'jwt_access_ttl' => (int) env('JWT_ACCESS_TOKEN_EXPIRE_MINUTES', 30) * 60,
    'jwt_refresh_ttl' => (int) env('JWT_REFRESH_TOKEN_EXPIRE_DAYS', 7) * 86400,
    'otp_expiry_minutes' => (int) env('OTP_EXPIRY_MINUTES', 10),
    'ussd_shortcode' => env('AFRICASTALKING_SHORTCODE', '14999'),
    'ussd_session_timeout' => (int) env('USSD_SESSION_TIMEOUT_SECONDS', 180),
    'currency' => 'TZS',
    'default_language' => 'sw',
    'high_value_loan_threshold' => (float) env('HIGH_VALUE_LOAN_THRESHOLD', 500000),
    'required_approval_signatures' => (int) env('REQUIRED_APPROVAL_SIGNATURES', 2),
];
