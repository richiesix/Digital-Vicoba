<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\LoanGuarantor;
use App\Models\Member;
use App\Models\VicobaGroup;
use App\Services\AuditService;
use App\Services\LoanService;
use App\Services\MobileMoneyService;
use App\Services\MultiSignatureApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class LoanController extends Controller
{
    public function __construct(
        private readonly LoanService $loans,
        private readonly MobileMoneyService $mobileMoney,
        private readonly MultiSignatureApprovalService $approvals,
        private readonly AuditService $audit,
    ) {}

    public function index(VicobaGroup $group): JsonResponse
    {
        return response()->json([
            'loans' => Loan::query()->where('group_id', $group->id)->with('member')->paginate(20),
        ]);
    }

    public function store(Request $request, VicobaGroup $group): JsonResponse
    {
        $data = $request->validate([
            'member_id' => 'required|integer',
            'principal_amount' => 'required|numeric|min:1000',
            'term_weeks' => 'required|integer|min:1|max:52',
            'purpose' => 'nullable|string',
            'guarantor_ids' => 'required|array|min:1',
            'guarantor_ids.*' => 'integer|exists:members,id',
            'client_id' => 'nullable|string|max:64',
        ]);

        $member = Member::query()->where('group_id', $group->id)->findOrFail($data['member_id']);
        $loan = $this->loans->apply($member, $group, $data);

        foreach ($data['guarantor_ids'] as $guarantorId) {
            LoanGuarantor::query()->create([
                'loan_id' => $loan->id,
                'guarantor_member_id' => $guarantorId,
            ]);
        }

        return response()->json(['loan' => $loan], 201);
    }

    public function guarantorRespond(Request $request, Loan $loan, Member $member): JsonResponse
    {
        $request->validate(['status' => 'required|in:approved,rejected']);

        LoanGuarantor::query()
            ->where('loan_id', $loan->id)
            ->where('guarantor_member_id', $member->id)
            ->update(['status' => $request->status, 'responded_at' => now()]);

        $pending = LoanGuarantor::query()->where('loan_id', $loan->id)->where('status', 'pending')->count();
        if ($pending === 0) {
            $loan->update(['status' => 'pending_vote']);
        }

        return response()->json(['message' => 'Imehifadhiwa']);
    }

    public function vote(Request $request, Loan $loan): JsonResponse
    {
        $request->validate(['vote' => 'required|in:approve,reject,abstain']);

        DB::table('loan_votes')->updateOrInsert(
            ['loan_id' => $loan->id, 'member_id' => $request->input('member_id')],
            ['vote' => $request->vote, 'voted_at' => now()]
        );

        return response()->json(['message' => 'Kura imehesabiwa']);
    }

    public function disburse(Request $request, Loan $loan): JsonResponse
    {
        $request->validate([
            'disbursement_method' => 'required|in:cash,mpesa,airtel,mixx,halopesa,group_wallet',
            'approval_reference' => 'required|string',
        ]);

        if ($loan->status !== 'approved') {
            return response()->json(['message' => 'Mkopo haujaidhinishwa na viongozi'], 422);
        }

        if ($blocked = $this->approvals->requireApprovedOrFail($request->approval_reference)) {
            return $blocked;
        }

        if (in_array($request->disbursement_method, ['mpesa', 'airtel', 'mixx', 'halopesa'], true)) {
            $this->mobileMoney->disburse($loan, $request->disbursement_method);
        }

        $loan->update([
            'status' => 'disbursed',
            'disbursement_method' => $request->disbursement_method,
            'disbursed_at' => now(),
        ]);
        $loan->member->increment('loan_balance', $loan->total_amount);

        $this->audit->log($request->user(), 'loan.disburse', 'loan', $loan->id, null, [
            'group_id' => $loan->group_id,
            'amount' => $loan->total_amount,
        ], $request);

        return response()->json(['loan' => $loan]);
    }

    public function repay(Request $request, Loan $loan): JsonResponse
    {
        $data = $request->validate([
            'amount' => 'required|numeric|min:1',
            'payment_method' => 'required|in:cash,mpesa,airtel,mixx,halopesa,group_wallet',
            'client_id' => 'nullable|string|max:64',
        ]);

        $repayment = $this->loans->recordRepayment($loan, $data);

        return response()->json(['repayment' => $repayment], 201);
    }
}
