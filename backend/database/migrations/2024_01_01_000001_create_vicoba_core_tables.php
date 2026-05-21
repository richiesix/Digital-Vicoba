<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table): void {
            $table->id();
            $table->string('name', 50)->unique();
            $table->string('slug', 50)->unique();
            $table->text('description')->nullable();
            $table->boolean('is_system')->default(false);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('permissions', function (Blueprint $table): void {
            $table->id();
            $table->string('name', 100);
            $table->string('slug', 100)->unique();
            $table->string('module', 50);
            $table->text('description')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('role_permissions', function (Blueprint $table): void {
            $table->foreignId('role_id')->constrained()->cascadeOnDelete();
            $table->foreignId('permission_id')->constrained()->cascadeOnDelete();
            $table->primary(['role_id', 'permission_id']);
        });

        Schema::create('regions', function (Blueprint $table): void {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 10)->unique();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('phone_number', 20)->unique();
            $table->timestamp('phone_verified_at')->nullable();
            $table->string('national_id', 30)->nullable()->index();
            $table->string('voter_id', 30)->nullable();
            $table->string('first_name', 100);
            $table->string('last_name', 100);
            $table->string('email')->nullable();
            $table->string('pin_hash')->nullable();
            $table->string('profile_photo_url', 500)->nullable();
            $table->enum('preferred_language', ['sw', 'en'])->default('sw');
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('devices', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('device_uuid')->unique();
            $table->string('device_name', 100)->nullable();
            $table->enum('platform', ['android', 'ios', 'web', 'ussd'])->default('android');
            $table->string('fcm_token', 500)->nullable();
            $table->boolean('is_verified')->default(false);
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamp('bound_at')->nullable();
            $table->timestamps();
        });

        Schema::create('otp_verifications', function (Blueprint $table): void {
            $table->id();
            $table->string('phone_number', 20)->index();
            $table->string('otp_hash');
            $table->enum('purpose', ['register', 'login', 'reset_pin', 'bind_device']);
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('expires_at');
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('refresh_tokens', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('token_hash')->index();
            $table->timestamp('expires_at');
            $table->timestamp('revoked_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('groups', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('name', 200);
            $table->string('registration_number', 50)->nullable();
            $table->foreignId('region_id')->nullable()->constrained()->nullOnDelete();
            $table->string('ward', 100)->nullable();
            $table->string('village', 100)->nullable();
            $table->decimal('share_price', 15, 2)->default(0);
            $table->char('currency', 3)->default('TZS');
            $table->decimal('max_loan_multiplier', 5, 2)->default(3);
            $table->decimal('loan_interest_rate', 5, 2)->default(10);
            $table->decimal('penalty_rate', 5, 2)->default(5);
            $table->string('meeting_day', 20)->nullable();
            $table->enum('meeting_frequency', ['weekly', 'biweekly', 'monthly'])->default('weekly');
            $table->json('constitution_json')->nullable();
            $table->enum('status', ['forming', 'active', 'share_out', 'dormant', 'closed'])->default('forming')->index();
            $table->date('formed_at')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('group_cycles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('cycle_number')->default(1);
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->unsignedInteger('total_shares')->default(0);
            $table->decimal('total_savings', 15, 2)->default(0);
            $table->decimal('total_loans_outstanding', 15, 2)->default(0);
            $table->decimal('emergency_fund_balance', 15, 2)->default(0);
            $table->decimal('social_fund_balance', 15, 2)->default(0);
            $table->enum('status', ['active', 'share_out_pending', 'completed'])->default('active');
            $table->timestamp('share_out_completed_at')->nullable();
            $table->timestamps();
            $table->unique(['group_id', 'cycle_number']);
        });

        Schema::create('sumaku_groups', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('members', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('member_number', 20);
            $table->string('first_name', 100);
            $table->string('last_name', 100);
            $table->string('phone_number', 20)->index();
            $table->string('national_id', 30)->nullable();
            $table->foreignId('sumaku_group_id')->nullable()->constrained('sumaku_groups')->nullOnDelete();
            $table->date('join_date');
            $table->enum('status', ['pending', 'active', 'suspended', 'exited'])->default('pending')->index();
            $table->unsignedInteger('total_shares')->default(0);
            $table->decimal('savings_balance', 15, 2)->default(0);
            $table->decimal('loan_balance', 15, 2)->default(0);
            $table->decimal('financial_score', 5, 2)->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['group_id', 'member_number']);
        });

        Schema::create('shares', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cycle_id')->constrained('group_cycles')->cascadeOnDelete();
            $table->unsignedInteger('quantity')->default(1);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('total_amount', 15, 2);
            $table->enum('payment_method', ['cash', 'mpesa', 'airtel', 'mixx', 'halopesa', 'group_wallet'])->default('cash');
            $table->string('reference', 100)->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('recorded_at');
            $table->timestamp('synced_at')->nullable();
            $table->string('client_id', 64)->nullable()->index();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('contributions', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cycle_id')->constrained('group_cycles')->cascadeOnDelete();
            $table->enum('type', ['savings', 'emergency', 'social', 'penalty', 'fine'])->default('savings');
            $table->decimal('amount', 15, 2);
            $table->enum('payment_method', ['cash', 'mpesa', 'airtel', 'mixx', 'halopesa', 'group_wallet'])->default('cash');
            $table->string('reference', 100)->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('recorded_at');
            $table->string('client_id', 64)->nullable()->index();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('loans', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cycle_id')->constrained('group_cycles')->cascadeOnDelete();
            $table->decimal('principal_amount', 15, 2);
            $table->decimal('interest_rate', 5, 2);
            $table->decimal('interest_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2);
            $table->decimal('outstanding_balance', 15, 2);
            $table->unsignedInteger('term_weeks');
            $table->text('purpose')->nullable();
            $table->enum('status', ['draft', 'pending_guarantors', 'pending_vote', 'approved', 'disbursed', 'active', 'completed', 'defaulted', 'rejected'])->default('draft')->index();
            $table->enum('disbursement_method', ['cash', 'mpesa', 'airtel', 'mixx', 'halopesa', 'group_wallet'])->nullable();
            $table->timestamp('disbursed_at')->nullable();
            $table->date('due_date')->nullable();
            $table->string('client_id', 64)->nullable()->index();
            $table->timestamps();
        });

        Schema::create('loan_guarantors', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('loan_id')->constrained()->cascadeOnDelete();
            $table->foreignId('guarantor_member_id')->constrained('members')->cascadeOnDelete();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->timestamp('responded_at')->nullable();
            $table->unique(['loan_id', 'guarantor_member_id']);
        });

        Schema::create('repayments', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('loan_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 15, 2);
            $table->decimal('principal_portion', 15, 2)->default(0);
            $table->decimal('interest_portion', 15, 2)->default(0);
            $table->decimal('penalty_amount', 15, 2)->default(0);
            $table->enum('payment_method', ['cash', 'mpesa', 'airtel', 'mixx', 'halopesa', 'group_wallet'])->default('cash');
            $table->string('reference', 100)->nullable();
            $table->timestamp('recorded_at');
            $table->string('client_id', 64)->nullable()->index();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('meetings', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cycle_id')->constrained('group_cycles')->cascadeOnDelete();
            $table->timestamp('scheduled_at')->index();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->string('location', 255)->nullable();
            $table->text('agenda')->nullable();
            $table->text('notes')->nullable();
            $table->unsignedInteger('quorum_required')->default(0);
            $table->boolean('quorum_met')->nullable();
            $table->decimal('cash_on_hand', 15, 2)->nullable();
            $table->decimal('cash_reconciled', 15, 2)->nullable();
            $table->enum('status', ['scheduled', 'in_progress', 'completed', 'cancelled'])->default('scheduled');
            $table->timestamps();
        });

        Schema::create('attendance', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('meeting_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['present', 'late', 'absent', 'excused'])->default('absent');
            $table->timestamp('arrived_at')->nullable();
            $table->unique(['meeting_id', 'member_id']);
        });

        Schema::create('sync_queue', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('client_id', 64)->unique();
            $table->string('entity_type', 50);
            $table->string('entity_id', 64)->nullable();
            $table->enum('operation', ['create', 'update', 'delete']);
            $table->json('payload');
            $table->timestamp('client_timestamp', 3);
            $table->enum('status', ['pending', 'processing', 'completed', 'conflict', 'failed'])->default('pending')->index();
            $table->enum('conflict_resolution', ['server_wins', 'client_wins', 'manual'])->nullable();
            $table->unsignedTinyInteger('retry_count')->default(0);
            $table->text('error_message')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('audit_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('group_id')->nullable()->constrained()->nullOnDelete();
            $table->string('action', 100)->index();
            $table->string('entity_type', 50)->nullable();
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 500)->nullable();
            $table->timestamp('created_at')->useCurrent()->index();
        });

        Schema::create('notifications', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('group_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type', 50);
            $table->string('title', 200);
            $table->text('body');
            $table->enum('channel', ['push', 'sms', 'in_app'])->default('in_app');
            $table->boolean('is_read')->default(false);
            $table->json('metadata')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('transactions', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('member_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type', 30);
            $table->decimal('amount', 15, 2);
            $table->char('currency', 3)->default('TZS');
            $table->enum('payment_method', ['cash', 'mpesa', 'airtel', 'mixx', 'halopesa', 'group_wallet']);
            $table->enum('status', ['pending', 'processing', 'completed', 'failed', 'reversed'])->default('pending')->index();
            $table->string('reference', 100)->nullable()->index();
            $table->timestamp('recorded_at');
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('mobile_money_transactions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('transaction_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('provider', ['mpesa', 'airtel', 'mixx', 'halopesa']);
            $table->enum('direction', ['inbound', 'outbound']);
            $table->string('phone_number', 20);
            $table->decimal('amount', 15, 2);
            $table->string('provider_reference', 100)->nullable();
            $table->json('callback_payload')->nullable();
            $table->enum('status', ['initiated', 'pending', 'success', 'failed', 'timeout'])->default('initiated');
            $table->unsignedTinyInteger('retry_count')->default(0);
            $table->timestamp('initiated_at')->useCurrent();
            $table->timestamp('completed_at')->nullable();
        });

        Schema::create('ussd_sessions', function (Blueprint $table): void {
            $table->id();
            $table->string('session_id', 50)->unique();
            $table->string('phone_number', 20);
            $table->unsignedTinyInteger('menu_level')->default(1);
            $table->string('menu_state', 100)->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('expires_at');
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        $tables = [
            'ussd_sessions', 'mobile_money_transactions', 'transactions', 'notifications',
            'audit_logs', 'sync_queue', 'attendance', 'meetings', 'repayments',
            'loan_guarantors', 'loans', 'contributions', 'shares', 'members',
            'sumaku_groups', 'group_cycles', 'groups', 'refresh_tokens', 'otp_verifications',
            'devices', 'users', 'regions', 'role_permissions', 'permissions', 'roles',
        ];
        foreach ($tables as $table) {
            Schema::dropIfExists($table);
        }
    }
};
