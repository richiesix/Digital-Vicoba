<?php

declare(strict_types=1);

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ContributionController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\GroupController;
use App\Http\Controllers\Api\V1\LoanController;
use App\Http\Controllers\Api\V1\MeetingController;
use App\Http\Controllers\Api\V1\MemberController;
use App\Http\Controllers\Api\V1\MobileMoneyController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\ShareController;
use App\Http\Controllers\Api\V1\ShareOutController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Controllers\Api\V1\UssdController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/otp/send', [AuthController::class, 'sendOtp']);
    Route::post('auth/otp/verify', [AuthController::class, 'verifyOtp']);
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/refresh', [AuthController::class, 'refresh']);
    Route::post('auth/pin/reset', [AuthController::class, 'resetPin']);

    Route::post('ussd/callback', [UssdController::class, 'callback']);
    Route::post('mobile-money/{provider}/callback', [MobileMoneyController::class, 'callback']);

    Route::middleware('auth.jwt')->group(function (): void {
        Route::get('dashboard', [DashboardController::class, 'index']);
        Route::get('auth/me', [AuthController::class, 'me']);
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::post('auth/pin/setup', [AuthController::class, 'setupPin'])->middleware('permission:view_dashboard');
        Route::post('auth/device/bind', [AuthController::class, 'bindDevice']);

        Route::get('groups', [GroupController::class, 'index'])->middleware('permission:view_dashboard');
        Route::post('groups', [GroupController::class, 'store'])->middleware('permission:platform.manage_groups');

        Route::middleware('group.access')->group(function (): void {
        Route::get('groups/{group}', [GroupController::class, 'show'])->middleware('permission:view_dashboard');
        Route::put('groups/{group}', [GroupController::class, 'update'])->middleware('permission:platform.manage_groups');
        Route::post('groups/{group}/invite', [GroupController::class, 'invite'])->middleware('permission:group.manage_members');

        Route::get('groups/{group}/members', [MemberController::class, 'index'])->middleware('permission:group.manage_members|member.view_own_balance');
        Route::post('groups/{group}/members', [MemberController::class, 'store'])->middleware('permission:group.manage_members');
        Route::get('groups/{group}/members/search', [MemberController::class, 'search'])->middleware('permission:group.manage_members');

        Route::post('groups/{group}/shares', [ShareController::class, 'store'])->middleware('permission:group.record_shares|member.buy_shares');
        Route::get('groups/{group}/shares', [ShareController::class, 'index'])->middleware('permission:group.view_finances|member.view_own_history');

        Route::post('groups/{group}/contributions', [ContributionController::class, 'store'])->middleware('permission:group.record_contribution|member.buy_shares');
        Route::get('groups/{group}/contributions', [ContributionController::class, 'index'])->middleware('permission:group.view_finances|member.view_own_history');

        Route::get('groups/{group}/loans', [LoanController::class, 'index'])->middleware('permission:group.view_finances|member.view_own_history');
        Route::post('groups/{group}/loans', [LoanController::class, 'store'])->middleware('permission:member.apply_loan');
        Route::post('loans/{loan}/guarantors/{member}/respond', [LoanController::class, 'guarantorRespond'])->middleware(['group.access', 'permission:member.vote']);
        Route::post('loans/{loan}/vote', [LoanController::class, 'vote'])->middleware(['group.access', 'permission:member.vote|group.approve_loan']);
        Route::post('loans/{loan}/disburse', [LoanController::class, 'disburse'])->middleware(['group.access', 'permission:group.disburse_loan']);
        Route::post('loans/{loan}/repayments', [LoanController::class, 'repay'])->middleware(['group.access', 'permission:group.verify_repayments|member.repay_loan']);

        Route::get('groups/{group}/meetings', [MeetingController::class, 'index'])->middleware('permission:group.manage_meetings|member.view_meetings');
        Route::post('groups/{group}/meetings', [MeetingController::class, 'store'])->middleware('permission:group.manage_meetings');
        Route::post('meetings/{meeting}/start', [MeetingController::class, 'start'])->middleware(['group.access', 'permission:group.manage_meetings|member.view_meetings']);
        Route::post('meetings/{meeting}/attendance', [MeetingController::class, 'recordAttendance'])->middleware(['group.access', 'permission:group.manage_meetings|member.view_meetings']);
        Route::post('meetings/{meeting}/reconcile', [MeetingController::class, 'reconcile'])->middleware(['group.access', 'permission:group.approve_treasury']);

        Route::post('groups/{group}/share-out/calculate', [ShareOutController::class, 'calculate'])->middleware('permission:group.share_out_verify');
        Route::post('groups/{group}/share-out/approve', [ShareOutController::class, 'approve'])->middleware('permission:group.share_out_verify');
        Route::post('groups/{group}/share-out/disburse', [ShareOutController::class, 'disburse'])->middleware('permission:group.approve_treasury');
        Route::get('groups/{group}/share-out/history', [ShareOutController::class, 'history'])->middleware('permission:group.view_finances');

        Route::get('groups/{group}/reports/{type}', [ReportController::class, 'generate'])->middleware('permission:group.generate_reports|platform.national_analytics');
        Route::get('groups/{group}/reports/{type}/download', [ReportController::class, 'download'])->middleware('permission:group.generate_reports|platform.national_analytics');
        Route::get('groups/{group}/analytics', [ReportController::class, 'analytics'])->middleware('permission:group.generate_reports|platform.national_analytics');
        });

        Route::get('notifications', [NotificationController::class, 'index'])->middleware('permission:member.view_notifications|view_dashboard');
        Route::patch('notifications/{notification}/read', [NotificationController::class, 'markRead']);

        Route::post('approvals/initiate', [\App\Http\Controllers\Api\V1\ApprovalController::class, 'initiate'])
            ->middleware('permission:group.approve_treasury|group.share_out_verify');
        Route::post('approvals/{reference}/sign', [\App\Http\Controllers\Api\V1\ApprovalController::class, 'sign'])
            ->middleware('permission:group.approve_treasury|group.approve_loan|group.share_out_verify');

        Route::post('mobile-money/deposit', [MobileMoneyController::class, 'deposit'])->middleware('permission:group.manage_mobile_money');
        Route::post('mobile-money/withdraw', [MobileMoneyController::class, 'withdraw'])->middleware('permission:group.manage_mobile_money');
        Route::get('mobile-money/status/{reference}', [MobileMoneyController::class, 'status']);

        Route::post('sync/push', [SyncController::class, 'push'])->middleware('permission:sync.data');
        Route::get('sync/pull', [SyncController::class, 'pull'])->middleware('permission:sync.data');
        Route::get('sync/status', [SyncController::class, 'status'])->middleware('permission:sync.data');
        Route::post('sync/conflicts/{clientId}/resolve', [SyncController::class, 'resolveConflict'])->middleware('permission:sync.data');
    });
});
