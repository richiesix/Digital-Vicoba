<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loan_votes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('loan_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->enum('vote', ['approve', 'reject', 'abstain']);
            $table->timestamp('voted_at')->useCurrent();
            $table->unique(['loan_id', 'member_id']);
        });

        Schema::create('share_outs', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cycle_id')->constrained('group_cycles')->cascadeOnDelete();
            $table->decimal('total_pool', 15, 2);
            $table->decimal('total_distributed', 15, 2)->default(0);
            $table->enum('status', ['calculating', 'pending_approval', 'approved', 'disbursing', 'completed'])->default('calculating');
            $table->timestamp('calculated_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('share_out_distributions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('share_out_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('shares_count');
            $table->decimal('gross_amount', 15, 2);
            $table->decimal('loan_deduction', 15, 2)->default(0);
            $table->decimal('net_amount', 15, 2);
            $table->enum('disbursement_status', ['pending', 'processing', 'completed', 'failed'])->default('pending');
        });

        Schema::create('fines', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained()->cascadeOnDelete();
            $table->foreignId('member_id')->constrained()->cascadeOnDelete();
            $table->foreignId('meeting_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type', 30);
            $table->decimal('amount', 15, 2);
            $table->text('reason')->nullable();
            $table->enum('status', ['pending', 'paid', 'waived'])->default('pending');
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fines');
        Schema::dropIfExists('share_out_distributions');
        Schema::dropIfExists('share_outs');
        Schema::dropIfExists('loan_votes');
    }
};
