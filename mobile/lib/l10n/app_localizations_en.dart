// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Digital Vikoba';

  @override
  String get appTagline => 'Transparent community savings';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get choosePinHint => 'Choose a 4-digit PIN';

  @override
  String get finish => 'Finish';

  @override
  String get continueButton => 'Continue';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyOtp => 'Verify code';

  @override
  String otpSentTo(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get noAccount => 'No account? Register';

  @override
  String get demoAccounts =>
      'Demo:\nChairperson: +255712000001\nTreasurer: +255712000002\nMember: +255712000003\nPIN: 1234 (all)';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get groups => 'Groups';

  @override
  String get members => 'Members';

  @override
  String get savings => 'Savings';

  @override
  String get loans => 'Loans';

  @override
  String get meetings => 'Meetings';

  @override
  String get reports => 'Reports';

  @override
  String get notifications => 'Notifications';

  @override
  String get shareOut => 'Share-out';

  @override
  String get profile => 'Profile';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get offline => 'You are offline';

  @override
  String get offlineDetail => 'You are offline — data will sync later';

  @override
  String get online => 'You are online';

  @override
  String get totalSavings => 'Total Savings';

  @override
  String get activeLoans => 'Active Loans';

  @override
  String get recordShare => 'Record Share';

  @override
  String get applyLoan => 'Apply for Loan';

  @override
  String get approveLoan => 'Approve Loan';

  @override
  String get attendance => 'Attendance';

  @override
  String get balance => 'Balance';

  @override
  String get amount => 'Amount';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String get pending => 'Pending';

  @override
  String get overdue => 'Overdue';

  @override
  String get completed => 'Completed';

  @override
  String get language => 'Language';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get chooseLanguage => 'Choose your preferred language';

  @override
  String get swahili => 'Swahili';

  @override
  String get english => 'English';

  @override
  String get languageChanged => 'Language updated';

  @override
  String get voiceSwahili => 'Voice (Swahili)';

  @override
  String get biometric => 'Biometric';

  @override
  String get logout => 'Log out';

  @override
  String get user => 'User';

  @override
  String get home => 'Home';

  @override
  String get finance => 'Finance';

  @override
  String get payments => 'Payments';

  @override
  String get analytics => 'Analytics';

  @override
  String get meetingTabUpcoming => 'Upcoming';

  @override
  String get startMeeting => 'Start Meeting';

  @override
  String get viewAttendance => 'View Attendance';

  @override
  String get attendanceTab => 'Attendance';

  @override
  String get saveAttendance => 'Save Attendance';

  @override
  String get saveMyAttendance => 'Save My Attendance';

  @override
  String get meetingStarted => 'Meeting started';

  @override
  String get noMeetingScheduled => 'No meeting scheduled';

  @override
  String get waitForLeader =>
      'Wait for the chairperson or secretary to start the meeting';

  @override
  String get startMeetingFirst => 'Start the meeting first';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get startMeetingHint =>
      'Tap \"Start Meeting\" on the Upcoming tab first.';

  @override
  String get meetingsSubtitle => 'Schedule and track group meetings';

  @override
  String get quorumLabel => 'Attendance count';

  @override
  String get markAllPresent => 'Mark all present';

  @override
  String get searchMember => 'Search member';

  @override
  String get pastMeetings => 'Past meetings';

  @override
  String get noMeetingsYet => 'No meetings scheduled yet';

  @override
  String get meetingLive => 'Meeting in progress';

  @override
  String attendanceProgress(int present, int total) {
    return '$present of $total';
  }

  @override
  String startsIn(String time) {
    return 'Starts in $time';
  }

  @override
  String get locationLabel => 'Location';

  @override
  String get weeklyMeeting => 'Weekly Meeting';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get inProgress => 'In progress';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get roleSuperAdminFull => 'System Super Admin';

  @override
  String get roleTreasurer => 'Group Treasurer';

  @override
  String get roleChairperson => 'Chairperson';

  @override
  String get roleProvisionalChair => 'Temporary Chairperson';

  @override
  String get interimChairBanner =>
      'You are the temporary chairperson until leadership is assigned. You can register members and set up governance only. Other group operations unlock after chairperson, secretary, and treasurer are in place.';

  @override
  String get setupGovernanceTitle => 'Get started';

  @override
  String get setupGovernance => 'Set up leadership';

  @override
  String get governanceLockedMessage =>
      'Complete leadership setup first. Register members and assign chairperson, secretary, and treasurer.';

  @override
  String get roleSecretary => 'Secretary';

  @override
  String get roleMember => 'Member';

  @override
  String get roleMoneyCounter => 'Money Counter';

  @override
  String get roleKeyHolder => 'Key Holder';

  @override
  String get governance => 'Governance';

  @override
  String get currentLeadership => 'Current Leadership';

  @override
  String get elections => 'Elections';

  @override
  String get createElection => 'Create Election';

  @override
  String get assignLeadership => 'Assign Leadership';

  @override
  String get registerMember => 'Register member';

  @override
  String get governanceSetupTitle => 'Group setup';

  @override
  String get governanceStep1 => 'Register other members (at least one more)';

  @override
  String get governanceStep2 =>
      'Assign chairperson, secretary, treasurer & money counter';

  @override
  String get memberCountLabel => 'Group members';

  @override
  String memberCountValue(int count) {
    return '$count active';
  }

  @override
  String get membersNeededForLeadership =>
      'Add at least one more member before assigning leadership';

  @override
  String get governancePermissionHint =>
      'You need permission to manage members and assign leadership. If you created this group, log out and sign in again to refresh your role.';

  @override
  String get governanceReloginHint => 'Refresh session';

  @override
  String get assignLeadershipSetupHint =>
      'During setup, roles are applied immediately. Assign chairperson, secretary, and treasurer to unlock full group features.';

  @override
  String get selectMember => 'Select member';

  @override
  String get assignRole => 'Assign role';

  @override
  String get leadershipAssigned => 'Leadership role assigned';

  @override
  String get viewAll => 'View all';

  @override
  String get noLeadershipYet =>
      'No leadership elected yet. Run an election to assign roles.';

  @override
  String get noOpenElections => 'No open elections';

  @override
  String get noCandidatesYet => 'No candidates nominated yet';

  @override
  String get candidates => 'Candidates';

  @override
  String get electionResults => 'Election Results';

  @override
  String get openElection => 'Open Voting';

  @override
  String get closeElection => 'Close & Tally';

  @override
  String get votingScreen => 'Voting';

  @override
  String get voteRecorded => 'Your vote has been recorded';

  @override
  String get electionCreated => 'Election created';

  @override
  String get electionTitle => 'Election title';

  @override
  String get description => 'Description';

  @override
  String get quorumPercent => 'Quorum';

  @override
  String get manualAssignmentHint =>
      'Propose a leadership role. Members must approve to reach quorum.';

  @override
  String get role => 'Role';

  @override
  String get memberId => 'Member ID';

  @override
  String get reason => 'Reason';

  @override
  String get submitForApproval => 'Submit for member approval';

  @override
  String get assignmentProposed =>
      'Assignment proposed — awaiting member votes';

  @override
  String get platformAdminWebOnly =>
      'Platform administration is only available on the Web Admin Panel. Use a VICOBA member account in this app.';

  @override
  String get dashboardAdmin => 'Dashboard — Admin';

  @override
  String get dashboardTreasurer => 'Dashboard — Treasurer';

  @override
  String get dashboardMember => 'Dashboard — Member';

  @override
  String get totalGroups => 'Total groups';

  @override
  String get totalMembers => 'Members';

  @override
  String get groupBalance => 'Group Balance';

  @override
  String get pendingRepayments => 'Pending Repayments';

  @override
  String get mySavings => 'My Savings';

  @override
  String get loanDebt => 'Loan Balance';

  @override
  String get shares => 'Shares';

  @override
  String get myGroups => 'My Groups';

  @override
  String get createGroup => 'Create Group';

  @override
  String get submitLoan => 'Submit Application';

  @override
  String get loanAmountLabel => 'Loan amount (TZS)';

  @override
  String get loanPurposeLabel => 'Purpose of loan';

  @override
  String get loanTermWeeks => 'Loan term';

  @override
  String weeksCount(int n) {
    return '$n weeks';
  }

  @override
  String get maxEligible => 'Your limit';

  @override
  String yourSharesValue(String amount) {
    return 'Share value: $amount';
  }

  @override
  String get quickAmounts => 'Quick amounts';

  @override
  String get selectGuarantors => 'Select guarantors (at least 1)';

  @override
  String guarantorsSelected(int n) {
    return '$n selected';
  }

  @override
  String get loanSubmitted => 'Loan application submitted';

  @override
  String get loanSubmitFailed => 'Failed to submit application';

  @override
  String get estimatedRepayment => 'Estimated weekly repayment';

  @override
  String get approvalFlow =>
      'Your request goes to guarantors, secretary, treasurer, then chairperson';

  @override
  String get fillAllFields => 'Enter amount, term, and guarantors';

  @override
  String get noGuarantorsAvailable => 'No other members available yet';

  @override
  String get loanLimit => 'Loan limit';

  @override
  String get loanLimitHint => 'Up to 3× the value of your shares';

  @override
  String get approveLoans => 'Approve Loans';

  @override
  String memberLabel(int n) {
    return 'Member $n';
  }

  @override
  String get savingsManagement => 'Savings Management';

  @override
  String get savingsAndShares => 'Savings & Shares';

  @override
  String get treasurerHint =>
      'You can verify member contributions. Large financial actions require PIN and leadership approval.';

  @override
  String get typeSavings => 'Savings';

  @override
  String get typeEmergency => 'Emergency';

  @override
  String get typeSocial => 'Social';

  @override
  String get amountTzs => 'Amount (TZS)';

  @override
  String get amountReceived => 'Amount received (TZS)';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get cash => 'Cash';

  @override
  String get confirmAndRecord => 'Confirm & Record';

  @override
  String get contributeBuyShares => 'Contribute / Buy Shares';

  @override
  String get contributeTab => 'Contribute';

  @override
  String get buySharesTab => 'Buy Shares';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get shareQuantity => 'Number of shares';

  @override
  String sharePriceEach(String price) {
    return 'Price per share: $price';
  }

  @override
  String get totalPayable => 'Total to pay';

  @override
  String get yourBalances => 'Your balances';

  @override
  String get emergencyBalance => 'Emergency';

  @override
  String get socialBalance => 'Social';

  @override
  String get contributionSaved => 'Contribution saved';

  @override
  String get sharesPurchased => 'Shares purchased';

  @override
  String get noRecentActivity => 'No activity yet';

  @override
  String get recordForMember => 'Record for member';

  @override
  String get savedWillSync => 'Saved — will sync when online';

  @override
  String get confirmedSaved => 'Confirmed and saved';

  @override
  String get shareOutTitle => 'Share-out';

  @override
  String get poolTotal => 'Pool Total';

  @override
  String get shareOutLeaderOnly =>
      'Share-out is only available to treasurers and leaders.';

  @override
  String get calculateShareOut => 'Calculate Share-out';

  @override
  String get approveShareOut => 'Approve Share-out';

  @override
  String get payShareOut => 'Pay out (full approval required)';

  @override
  String get multiSignRequired =>
      'Large payouts require signatures from Treasurer, Chairperson, and Secretary.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncComplete => 'Sync completed';

  @override
  String get allDataSynced => 'All data synced';

  @override
  String recordsPending(int count) {
    return '$count records waiting to sync';
  }

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get error => 'Error';

  @override
  String get failed => 'Failed';

  @override
  String get pinMustBe4 => 'PIN must be 4 digits';

  @override
  String get invalidCredentials => 'Invalid phone number or PIN';

  @override
  String get loginFailed => 'Login failed';

  @override
  String currency(String amount) {
    return 'TZS $amount';
  }

  @override
  String greetingHello(String name) {
    return 'Hello, $name';
  }

  @override
  String get quickActionsTitle => 'Quick Actions';

  @override
  String get platformOverview => 'Platform Overview';

  @override
  String get groupFinances => 'Group Finances';

  @override
  String get myWallet => 'My Wallet';

  @override
  String get nationalSavings => 'National Savings';

  @override
  String get fraudAlerts => 'Fraud Alerts';

  @override
  String get systemHealth => 'System Health';

  @override
  String get mobileMoneyStatus => 'Mobile Money';

  @override
  String get operational => 'Operational';

  @override
  String get healthy => 'Healthy';

  @override
  String get emergencyFund => 'Emergency Fund';

  @override
  String get socialFund => 'Social Fund';

  @override
  String get meetingsSoon => 'Meetings';

  @override
  String get unreadAlerts => 'Alerts';

  @override
  String get tapToOpen => 'Tap to open';

  @override
  String get manageUsers => 'Users';

  @override
  String get fraudMonitor => 'Fraud';

  @override
  String get systemLogs => 'Logs';

  @override
  String get shareOutAction => 'Share-out';

  @override
  String get historyAction => 'History';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get securityPrivacy => 'Security & Privacy';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You will need to sign in again with your PIN';

  @override
  String get confirmLogout => 'Yes, log out';

  @override
  String get voiceEnabled => 'Voice prompts on';

  @override
  String get voiceDisabled => 'Voice prompts off';

  @override
  String get biometricEnabled => 'Biometric login on';

  @override
  String get biometricDisabled => 'Biometric login off';

  @override
  String pendingSyncCount(int n) {
    return '$n pending sync';
  }

  @override
  String get allSynced => 'All data synced';

  @override
  String memberIdLabel(String id) {
    return 'Member no: $id';
  }

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get digitalVicobaMember => 'Digital Vikoba member';

  @override
  String get membersSubtitle => 'Manage members and their balances';

  @override
  String get searchMembersHint => 'Search by name, phone or number...';

  @override
  String get addMember => 'Add Member';

  @override
  String get memberAdded => 'Member added successfully';

  @override
  String get memberActivationRegister =>
      'Ask them to open the app → Register → use this same phone → OTP → set a 4-digit PIN. Then they can log in.';

  @override
  String get memberActivationLogin =>
      'They already have an app account. They can log in with this phone number and their PIN.';

  @override
  String get temporaryPinTitle => 'Temporary PIN created';

  @override
  String temporaryPinMessage(String name) {
    return 'Give this PIN to $name. They must log in with their phone number and this PIN, then choose a new PIN.';
  }

  @override
  String temporaryPinValue(String pin) {
    return 'Temporary PIN: $pin';
  }

  @override
  String get temporaryPinDevHint =>
      'In development, the temporary PIN is usually the last 4 digits of the phone number.';

  @override
  String get changePinRequiredTitle => 'Create your new PIN';

  @override
  String get changePinRequiredSubtitle =>
      'You signed in with a temporary PIN. Choose a new 4-digit PIN to continue — you cannot skip this step.';

  @override
  String get pinCannotMatchTemporary =>
      'Your new PIN must be different from the temporary PIN.';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get uploadFromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get removeProfilePhoto => 'Remove photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoRemoved => 'Profile photo removed';

  @override
  String get profilePhotoUploadFailed => 'Could not upload profile photo';

  @override
  String get cameraNotAvailableOnWeb =>
      'Camera is not available in the browser. Please choose from gallery.';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterWithLoan => 'With loan';

  @override
  String get sortByName => 'Name';

  @override
  String get sortBySavings => 'Savings';

  @override
  String get memberDetails => 'Member details';

  @override
  String get totalGroupSavings => 'Total savings';

  @override
  String get activeMembers => 'Active members';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String sharesAndSavings(int shares, String amount) {
    return 'Shares: $shares | Savings: $amount';
  }

  @override
  String get noMembersFound => 'No members found';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get loanBalance => 'Loan';

  @override
  String get callMember => 'Call';

  @override
  String get viewProfile => 'View profile';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get groupsSubtitle => 'Manage all groups on the platform';

  @override
  String get searchGroupsHint => 'Search group by name or location...';

  @override
  String get groupCreated => 'Group created successfully';

  @override
  String get groupDetails => 'Group details';

  @override
  String get groupName => 'Group name';

  @override
  String get activeGroupsLabel => 'Active groups';

  @override
  String membersCount(int n) {
    return 'Members: $n';
  }

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get filterForming => 'Forming';

  @override
  String get groupStatusForming => 'Forming';

  @override
  String get groupStatusActive => 'Active';

  @override
  String get groupStatusShareOut => 'Share-out';

  @override
  String get groupStatusDormant => 'Dormant';

  @override
  String get groupStatusClosed => 'Closed';

  @override
  String get sharePriceLabel => 'Share price';

  @override
  String get wardLabel => 'Ward';

  @override
  String get villageLabel => 'Village';

  @override
  String get viewMembers => 'Members';

  @override
  String get manageGroup => 'Manage group';

  @override
  String get interestRateLabel => 'Loan interest';

  @override
  String get meetingFrequencyLabel => 'Meetings';

  @override
  String get reportsSubtitle => 'Download reports and view group analytics';

  @override
  String get reportSavingsGrowth => 'Savings Growth';

  @override
  String get reportLoanPerformance => 'Loan Performance';

  @override
  String get reportPaymentTrends => 'Payment Trends';

  @override
  String get reportDefaultRisk => 'Default Risk';

  @override
  String get downloadReport => 'Download report';

  @override
  String get generatingReport => 'Generating report...';

  @override
  String get reportReady => 'Report is ready';

  @override
  String activeLoansCount(int n) {
    return 'Active loans: $n';
  }

  @override
  String overdueLoansCount(int n) {
    return 'Overdue loans: $n';
  }

  @override
  String get riskInsight => 'Insight';

  @override
  String get tapToGenerate => 'Tap to generate';

  @override
  String get downloadedReports => 'Downloaded reports';

  @override
  String get viewReport => 'Open report';

  @override
  String get reportSaved => 'Report saved on device';

  @override
  String get openReport => 'View data';

  @override
  String reportRows(int n) {
    return '$n records';
  }

  @override
  String get reportDownloadBrowser =>
      'CSV file downloading — check your Chrome Downloads folder';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in with your phone number and PIN';

  @override
  String get welcomeTitle => 'Welcome to Digital Vikoba';

  @override
  String get welcomeSubtitle =>
      'Register your group, save together, and manage loans transparently.';

  @override
  String get getStarted => 'Get started';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get alreadyHaveAccountLogin => 'Already registered? Sign in';

  @override
  String get backToWelcome => 'Back';

  @override
  String get registerSubtitle =>
      'Create your account with your phone number. We will send you a verification code.';

  @override
  String get registerChooseLanguageTitle => 'Choose your language';

  @override
  String get registerChooseLanguageSubtitle =>
      'Pick your preferred language before registering. You can change it later in your profile.';

  @override
  String get registerContinue => 'Continue to registration';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get invalidPhone =>
      'Enter a valid Tanzania phone number (e.g. 0712345678)';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get pinMatches => 'PINs match';

  @override
  String get otpMustBe6 => 'Enter the 6-digit code';

  @override
  String get invalidOtp => 'Invalid or expired code';

  @override
  String get otpSendFailed => 'Could not send verification code';

  @override
  String get otpResent => 'Verification code sent again';

  @override
  String get resendOtp => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get otpEnterSubtitle =>
      'Enter the 6-digit verification code sent to your phone';

  @override
  String get registrationExpired =>
      'Registration session expired. Please start again.';

  @override
  String get pinSetupSubtitle =>
      'Choose a 4-digit PIN. You will use it to sign in securely.';

  @override
  String get onboardingTitle => 'Set up your group';

  @override
  String get onboardingSubtitle =>
      'You are not in a VICOBA group yet. Create one as the first member, or join with an invitation.';

  @override
  String get createYourGroup => 'Create your VICOBA group';

  @override
  String get createGroupHint =>
      'As the first member, you can set up the group and invite others.';

  @override
  String get joinWithInvite => 'I have an invitation';

  @override
  String get inviteComingSoon =>
      'Invitation links will be available soon. Ask your group secretary to add you by phone number.';

  @override
  String get connectionError =>
      'Cannot reach the server. Ensure the backend is running.';

  @override
  String get devOtpHint => 'Development: verification code is 123456';

  @override
  String get notificationsSubtitle => 'Group and system alerts';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get filterUnread => 'Unread';

  @override
  String get meetingReminder => 'Meeting reminder';

  @override
  String get paymentReminder => 'Payment reminder';

  @override
  String get notificationDetail => 'Notification details';

  @override
  String todayAt(String time) {
    return 'Today, $time';
  }

  @override
  String get newNotifications => 'New notifications';

  @override
  String get oldNotifications => 'Read notifications';

  @override
  String showOldNotifications(int n) {
    return 'Show older notifications ($n)';
  }

  @override
  String get hideOldNotifications => 'Hide older notifications';

  @override
  String get notificationOpened => 'Opened';

  @override
  String get noNewNotifications =>
      'No new notifications — you\'re all caught up';
}
