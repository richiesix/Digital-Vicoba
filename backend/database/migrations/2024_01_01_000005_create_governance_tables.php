<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('elections', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained('groups')->cascadeOnDelete();
            $table->string('election_type', 50); // leadership, loan, constitution, suspension, emergency
            $table->string('title');
            $table->text('description')->nullable();
            $table->unsignedTinyInteger('quorum_percent')->default(50);
            $table->dateTime('start_date');
            $table->dateTime('end_date');
            $table->string('status', 20)->default('draft'); // draft, open, closed, cancelled, completed
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->json('positions')->nullable(); // e.g. ["chairperson","treasurer"]
            $table->timestamps();
            $table->index(['group_id', 'status']);
        });

        Schema::create('election_candidates', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('election_id')->constrained('elections')->cascadeOnDelete();
            $table->foreignId('member_id')->constrained('members')->cascadeOnDelete();
            $table->string('position', 50); // chairperson, secretary, treasurer, money_counter, key_holder
            $table->text('manifesto')->nullable();
            $table->foreignId('nominated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['election_id', 'member_id', 'position']);
        });

        Schema::create('election_votes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('election_id')->constrained('elections')->cascadeOnDelete();
            $table->foreignId('voter_member_id')->constrained('members')->cascadeOnDelete();
            $table->foreignId('candidate_id')->constrained('election_candidates')->cascadeOnDelete();
            $table->text('encrypted_ballot'); // Laravel encrypt(candidate_id + position)
            $table->string('ballot_hash', 64); // integrity check
            $table->string('client_id', 64)->nullable(); // offline sync idempotency
            $table->timestamp('voted_at');
            $table->timestamps();
            $table->unique(['election_id', 'voter_member_id']);
            $table->unique(['election_id', 'client_id'], 'election_votes_election_client_unique');
        });

        Schema::create('election_audit_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('election_id')->constrained('elections')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 80);
            $table->json('metadata')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('leadership_roles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('group_id')->constrained('groups')->cascadeOnDelete();
            $table->foreignId('member_id')->constrained('members')->cascadeOnDelete();
            $table->string('role_name', 50);
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->boolean('active')->default(true);
            $table->foreignId('assigned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('election_id')->nullable()->constrained('elections')->nullOnDelete();
            $table->string('assignment_method', 20)->default('election'); // election, manual
            $table->timestamps();
            $table->index(['group_id', 'active']);
            $table->index(['group_id', 'role_name', 'active']);
        });

        Schema::create('leadership_assignments', function (Blueprint $table): void {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('group_id')->constrained('groups')->cascadeOnDelete();
            $table->foreignId('member_id')->constrained('members')->cascadeOnDelete();
            $table->string('role_name', 50);
            $table->foreignId('proposed_by')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('pending'); // pending, approved, rejected
            $table->unsignedSmallInteger('quorum_required')->default(1);
            $table->unsignedSmallInteger('approvals_count')->default(0);
            $table->text('reason')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('leadership_assignment_votes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('assignment_id')->constrained('leadership_assignments')->cascadeOnDelete();
            $table->foreignId('member_id')->constrained('members')->cascadeOnDelete();
            $table->boolean('approved');
            $table->timestamps();
            $table->unique(['assignment_id', 'member_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('leadership_assignment_votes');
        Schema::dropIfExists('leadership_assignments');
        Schema::dropIfExists('leadership_roles');
        Schema::dropIfExists('election_audit_logs');
        Schema::dropIfExists('election_votes');
        Schema::dropIfExists('election_candidates');
        Schema::dropIfExists('elections');
    }
};
