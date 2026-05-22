<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Election;
use App\Models\ElectionCandidate;
use App\Models\ElectionVote;
use App\Models\LeadershipRole;
use App\Models\Member;
use App\Models\User;
use App\Models\VicobaGroup;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class ElectionService
{
    public function __construct(
        private readonly LeadershipService $leadership,
        private readonly AuditService $audit,
        private readonly NotificationService $notifications,
    ) {}

    public function createElection(VicobaGroup $group, User $creator, array $data): Election
    {
        $election = Election::query()->create([
            'group_id' => $group->id,
            'election_type' => $data['election_type'] ?? 'leadership',
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'quorum_percent' => $data['quorum_percent'] ?? 50,
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'status' => $data['status'] ?? 'draft',
            'created_by' => $creator->id,
            'positions' => $data['positions'] ?? LeadershipRole::POSITIONS,
        ]);

        $this->logElection($election, $creator, 'election_created', $data);

        return $election;
    }

    public function openElection(Election $election, User $user): Election
    {
        $election->update(['status' => 'open']);
        $this->logElection($election, $user, 'election_opened');
        $this->notifications->notifyGroup(
            $election->group_id,
            'election_opened',
            'Uchaguzi umefunguliwa',
            $election->title,
            ['election_id' => $election->id]
        );

        return $election->fresh();
    }

    public function nominate(Election $election, Member $member, string $position, ?User $nominator = null, ?string $manifesto = null): ElectionCandidate
    {
        return ElectionCandidate::query()->updateOrCreate(
            [
                'election_id' => $election->id,
                'member_id' => $member->id,
                'position' => $position,
            ],
            [
                'manifesto' => $manifesto,
                'nominated_by' => $nominator?->id,
            ]
        );
    }

    public function castVote(
        Election $election,
        Member $voter,
        int $candidateId,
        ?string $clientId = null,
        ?Request $request = null,
    ): ElectionVote {
        if ($election->status !== 'open') {
            throw new \InvalidArgumentException('Uchaguzi hauko wazi');
        }

        if (now()->lt($election->start_date) || now()->gt($election->end_date)) {
            throw new \InvalidArgumentException('Kipindi cha kupiga kura kimeisha au bado hakijaanza');
        }

        $candidate = ElectionCandidate::query()
            ->where('election_id', $election->id)
            ->findOrFail($candidateId);

        $existing = ElectionVote::query()
            ->where('election_id', $election->id)
            ->where('voter_member_id', $voter->id)
            ->first();

        if ($existing) {
            throw new \InvalidArgumentException('Tayari umepiga kura');
        }

        if ($clientId) {
            $dup = ElectionVote::query()
                ->where('election_id', $election->id)
                ->where('client_id', $clientId)
                ->exists();
            if ($dup) {
                return ElectionVote::query()
                    ->where('election_id', $election->id)
                    ->where('client_id', $clientId)
                    ->firstOrFail();
            }
        }

        $payload = ['candidate_id' => $candidate->id, 'position' => $candidate->position];
        $encrypted = Crypt::encryptString(json_encode($payload, JSON_THROW_ON_ERROR));
        $hash = hash('sha256', $election->id.'|'.$voter->id.'|'.$encrypted.'|'.config('app.key'));

        $vote = ElectionVote::query()->create([
            'election_id' => $election->id,
            'voter_member_id' => $voter->id,
            'candidate_id' => $candidate->id,
            'encrypted_ballot' => $encrypted,
            'ballot_hash' => $hash,
            'client_id' => $clientId,
            'voted_at' => now(),
        ]);

        $this->logElection($election, $voter->user, 'vote_cast', ['voter_member_id' => $voter->id], $request);

        return $vote;
    }

    public function hasVoted(Election $election, int $memberId): bool
    {
        return ElectionVote::query()
            ->where('election_id', $election->id)
            ->where('voter_member_id', $memberId)
            ->exists();
    }

    public function closeAndTally(Election $election, User $user): array
    {
        $election->update(['status' => 'closed']);

        $group = $election->group;
        $activeMembers = Member::query()
            ->where('group_id', $group->id)
            ->where('status', 'active')
            ->count();

        $votesCast = ElectionVote::query()->where('election_id', $election->id)->count();
        $quorumMet = $activeMembers > 0
            && ($votesCast / $activeMembers * 100) >= $election->quorum_percent;

        $results = $this->tallyResults($election);

        if ($quorumMet && $election->election_type === 'leadership') {
            $this->leadership->applyElectionResults($election, $results, $user);
            $election->update(['status' => 'completed']);
        }

        $this->logElection($election, $user, 'election_closed', [
            'quorum_met' => $quorumMet,
            'votes_cast' => $votesCast,
            'results' => $results,
        ]);

        $this->notifications->notifyGroup(
            $election->group_id,
            'election_results',
            'Matokeo ya uchaguzi',
            $election->title,
            ['election_id' => $election->id, 'results' => $results]
        );

        return [
            'quorum_met' => $quorumMet,
            'votes_cast' => $votesCast,
            'active_members' => $activeMembers,
            'results' => $results,
            'status' => $election->fresh()->status,
        ];
    }

    /** @return array<string, array<int, array{candidate_id: int, member_id: int, votes: int}>> */
    public function tallyResults(Election $election): array
    {
        $counts = ElectionVote::query()
            ->where('election_id', $election->id)
            ->select('candidate_id', DB::raw('count(*) as vote_count'))
            ->groupBy('candidate_id')
            ->pluck('vote_count', 'candidate_id');

        $candidates = ElectionCandidate::query()
            ->where('election_id', $election->id)
            ->with('member')
            ->get();

        $byPosition = [];
        foreach ($candidates as $candidate) {
            $votes = (int) ($counts[$candidate->id] ?? 0);
            $byPosition[$candidate->position][] = [
                'candidate_id' => $candidate->id,
                'member_id' => $candidate->member_id,
                'member_name' => trim(($candidate->member->first_name ?? '').' '.($candidate->member->last_name ?? '')),
                'votes' => $votes,
            ];
        }

        foreach ($byPosition as $position => &$rows) {
            usort($rows, fn ($a, $b) => $b['votes'] <=> $a['votes']);
            $rows[0]['elected'] = ($rows[0]['votes'] ?? 0) > 0;
        }

        return $byPosition;
    }

    public function listForGroup(int $groupId, ?string $status = null): Collection
    {
        return Election::query()
            ->where('group_id', $groupId)
            ->when($status, fn ($q, $s) => $q->where('status', $s))
            ->withCount(['candidates', 'votes'])
            ->latest()
            ->get();
    }

    private function logElection(
        Election $election,
        ?User $user,
        string $action,
        ?array $metadata = null,
        ?Request $request = null,
    ): void {
        DB::table('election_audit_logs')->insert([
            'election_id' => $election->id,
            'user_id' => $user?->id,
            'action' => $action,
            'metadata' => $metadata ? json_encode($metadata) : null,
            'created_at' => now(),
        ]);

        $this->audit->log($user, $action, 'election', $election->id, null, [
            'group_id' => $election->group_id,
            ...($metadata ?? []),
        ], $request);
    }
}
