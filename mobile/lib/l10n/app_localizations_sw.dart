// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Digital Vikoba';

  @override
  String get appTagline => 'Akiba za jamii kwa uwazi';

  @override
  String get login => 'Ingia';

  @override
  String get register => 'Jisajili';

  @override
  String get phoneNumber => 'Nambari ya simu';

  @override
  String get enterPin => 'Weka PIN';

  @override
  String get confirmPin => 'Thibitisha PIN';

  @override
  String get choosePinHint => 'Chagua PIN ya tarakimu 4';

  @override
  String get finish => 'Maliza';

  @override
  String get continueButton => 'Endelea';

  @override
  String get sendOtp => 'Tuma OTP';

  @override
  String get verifyOtp => 'Thibitisha nambari';

  @override
  String otpSentTo(String phone) {
    return 'OTP imetumwa kwa $phone';
  }

  @override
  String get noAccount => 'Huna akaunti? Jisajili';

  @override
  String get demoAccounts =>
      'Demo:\nMsimamizi: +255712000001\nMhasibu: +255712000002\nMwanachama: +255712000003\nPIN: 1234 (wote)';

  @override
  String get dashboard => 'Dashibodi';

  @override
  String get groups => 'Vikundi';

  @override
  String get members => 'Wanachama';

  @override
  String get savings => 'Akiba';

  @override
  String get loans => 'Mikopo';

  @override
  String get meetings => 'Mikutano';

  @override
  String get reports => 'Ripoti';

  @override
  String get notifications => 'Arifa';

  @override
  String get shareOut => 'Mgawanyo';

  @override
  String get profile => 'Wasifu';

  @override
  String get syncStatus => 'Hali ya Usawazishaji';

  @override
  String get offline => 'Huna mtandao';

  @override
  String get offlineDetail => 'Huna mtandao - data itasawazishwa baadaye';

  @override
  String get online => 'Uko mtandaoni';

  @override
  String get totalSavings => 'Jumla ya Akiba';

  @override
  String get activeLoans => 'Mikopo Hai';

  @override
  String get recordShare => 'Rekodi Hisa';

  @override
  String get applyLoan => 'Omba Mkopo';

  @override
  String get approveLoan => 'Idhinisha Mkopo';

  @override
  String get attendance => 'Mahudhurio';

  @override
  String get balance => 'Salio';

  @override
  String get amount => 'Kiasi';

  @override
  String get save => 'Hifadhi';

  @override
  String get cancel => 'Ghairi';

  @override
  String get reject => 'Kataa';

  @override
  String get approve => 'Idhinisha';

  @override
  String get pending => 'Inasubiri';

  @override
  String get overdue => 'Imechelewa';

  @override
  String get completed => 'Imekamilika';

  @override
  String get language => 'Lugha';

  @override
  String get languageSettings => 'Mipangilio ya Lugha';

  @override
  String get chooseLanguage => 'Chagua lugha unayopendelea';

  @override
  String get swahili => 'Kiswahili';

  @override
  String get english => 'Kiingereza';

  @override
  String get languageChanged => 'Lugha imebadilishwa';

  @override
  String get voiceSwahili => 'Sauti (Kiswahili)';

  @override
  String get biometric => 'Biometriki';

  @override
  String get logout => 'Toka';

  @override
  String get user => 'Mtumiaji';

  @override
  String get home => 'Nyumbani';

  @override
  String get finance => 'Fedha';

  @override
  String get payments => 'Malipo';

  @override
  String get analytics => 'Takwimu';

  @override
  String get meetingTabUpcoming => 'Ijayo';

  @override
  String get startMeeting => 'Anza Mkutano';

  @override
  String get viewAttendance => 'Angalia Mahudhurio';

  @override
  String get attendanceTab => 'Mahudhurio';

  @override
  String get saveAttendance => 'Hifadhi Mahudhurio';

  @override
  String get saveMyAttendance => 'Hifadhi Mahudhurio Yangu';

  @override
  String get meetingStarted => 'Mkutano umeanza';

  @override
  String get noMeetingScheduled => 'Hakuna mkutano uliopangwa';

  @override
  String get waitForLeader => 'Subiri mwenyekiti au katibu aanzishe mkutano';

  @override
  String get startMeetingFirst => 'Anza mkutano kwanza';

  @override
  String get attendanceSaved => 'Mahudhurio yamehifadhiwa';

  @override
  String get startMeetingHint =>
      'Bonyeza \"Anza Mkutano\" kwenye kichupo cha Ijayo kwanza.';

  @override
  String get meetingsSubtitle => 'Panga na fuatilia mikutano ya kikundi';

  @override
  String get quorumLabel => 'Idadi ya waliohudhuria';

  @override
  String get markAllPresent => 'Wote wapo';

  @override
  String get searchMember => 'Tafuta mwanachama';

  @override
  String get pastMeetings => 'Mikutano iliyopita';

  @override
  String get noMeetingsYet => 'Hakuna mkutano uliopangwa';

  @override
  String get meetingLive => 'Mkutano unaendelea';

  @override
  String attendanceProgress(int present, int total) {
    return '$present kati ya $total';
  }

  @override
  String startsIn(String time) {
    return 'Inaanza baada ya $time';
  }

  @override
  String get locationLabel => 'Mahali';

  @override
  String get weeklyMeeting => 'Mkutano wa Wiki';

  @override
  String get scheduled => 'Imepangwa';

  @override
  String get inProgress => 'Unaendelea';

  @override
  String get roleSuperAdmin => 'Msimamizi Mkuu';

  @override
  String get roleSuperAdminFull => 'Msimamizi Mkuu wa Mfumo';

  @override
  String get roleTreasurer => 'Mhasibu wa Kikundi';

  @override
  String get roleChairperson => 'Mwenyekiti';

  @override
  String get roleProvisionalChair => 'Mwenyekiti wa Muda';

  @override
  String get interimChairBanner =>
      'Wewe ni mwenyekiti wa muda hadi uongozi ukamilike. Unaweza kusajili wanachama na kuweka uongozi pekee. Shughuli nyingine za kikundi zitafunguliwa baada ya kuweka mwenyekiti, katibu na mhasibu.';

  @override
  String get setupGovernanceTitle => 'Anza hapa';

  @override
  String get setupGovernance => 'Weka uongozi';

  @override
  String get governanceLockedMessage =>
      'Kamilisha uongozi kwanza. Sajili wanachama na weka mwenyekiti, katibu na mhasibu.';

  @override
  String get roleSecretary => 'Katibu';

  @override
  String get roleMember => 'Mwanachama';

  @override
  String get roleMoneyCounter => 'Mhesabu Fedha';

  @override
  String get roleKeyHolder => 'Mwenye Funguo';

  @override
  String get governance => 'Utawala';

  @override
  String get currentLeadership => 'Uongozi wa Sasa';

  @override
  String get elections => 'Uchaguzi';

  @override
  String get createElection => 'Unda Uchaguzi';

  @override
  String get assignLeadership => 'Teua Uongozi';

  @override
  String get registerMember => 'Sajili mwanachama';

  @override
  String get governanceSetupTitle => 'Kuandaa kikundi';

  @override
  String get governanceStep1 =>
      'Sajili wanachama wengine (angalau mmoja zaidi)';

  @override
  String get governanceStep2 =>
      'Teua mwenyekiti, katibu, mhasibu na mhesabaji wa fedha';

  @override
  String get memberCountLabel => 'Wanachama wa kikundi';

  @override
  String memberCountValue(int count) {
    return '$count hai';
  }

  @override
  String get membersNeededForLeadership =>
      'Ongeza angalau mwanachama mmoja kabla ya kuteua uongozi';

  @override
  String get governancePermissionHint =>
      'Unahitaji ruhusa ya kusimamia wanachama na kuteua uongozi. Ukiwa ndiye uliyeunda kikundi, toka kisha ingia tena ili kusasisha nafasi yako.';

  @override
  String get governanceReloginHint => 'Sasisha kikao';

  @override
  String get assignLeadershipSetupHint =>
      'Wakati wa kuandaa, nafasi zinateuliwa mara moja. Teua mwenyekiti, katibu na mhasibu ili kufungua huduma kamili za kikundi.';

  @override
  String get selectMember => 'Chagua mwanachama';

  @override
  String get assignRole => 'Teua nafasi';

  @override
  String get leadershipAssigned => 'Nafasi ya uongozi imeteuliwa';

  @override
  String get viewAll => 'Angalia zote';

  @override
  String get noLeadershipYet =>
      'Hakuna uongozi uliochaguliwa. Fanya uchaguzi kuteua viongozi.';

  @override
  String get noOpenElections => 'Hakuna uchaguzi ulio wazi';

  @override
  String get noCandidatesYet => 'Hakuna wagombea bado';

  @override
  String get candidates => 'Wagombea';

  @override
  String get electionResults => 'Matokeo ya Uchaguzi';

  @override
  String get openElection => 'Fungua Kupiga Kura';

  @override
  String get closeElection => 'Funga na Hesabu';

  @override
  String get votingScreen => 'Kupiga Kura';

  @override
  String get voteRecorded => 'Kura yako imehifadhiwa';

  @override
  String get electionCreated => 'Uchaguzi umeundwa';

  @override
  String get electionTitle => 'Jina la uchaguzi';

  @override
  String get description => 'Maelezo';

  @override
  String get quorumPercent => 'Quorum';

  @override
  String get manualAssignmentHint =>
      'Pendekeza nafasi ya uongozi. Wanachama lazima waidhinishe kufikia quorum.';

  @override
  String get role => 'Nafasi';

  @override
  String get memberId => 'Nambari ya Mwanachama';

  @override
  String get reason => 'Sababu';

  @override
  String get submitForApproval => 'Wasilisha kwa idhini ya wanachama';

  @override
  String get assignmentProposed =>
      'Pendekezo limewasilishwa — linasubiri kura za wanachama';

  @override
  String get platformAdminWebOnly =>
      'Usimamizi wa jukwaa unapatikana tu kwenye Web Admin Panel. Tumia akaunti ya mwanachama wa VICOBA katika programu hii.';

  @override
  String get dashboardAdmin => 'Dashibodi — Msimamizi';

  @override
  String get dashboardTreasurer => 'Dashibodi — Mhasibu';

  @override
  String get dashboardMember => 'Dashibodi — Mwanachama';

  @override
  String get totalGroups => 'Jumla vikundi';

  @override
  String get totalMembers => 'Wanachama';

  @override
  String get groupBalance => 'Salio la Kikundi';

  @override
  String get pendingRepayments => 'Malipo Yanayosubiri';

  @override
  String get mySavings => 'Akiba Yangu';

  @override
  String get loanDebt => 'Deni la Mkopo';

  @override
  String get shares => 'Hisa';

  @override
  String get myGroups => 'Vikundi Vyangu';

  @override
  String get createGroup => 'Unda Kikundi';

  @override
  String get submitLoan => 'Wasilisha Ombi';

  @override
  String get loanAmountLabel => 'Kiasi cha mkopo (TZS)';

  @override
  String get loanPurposeLabel => 'Sababu ya mkopo';

  @override
  String get loanTermWeeks => 'Muda wa mkopo';

  @override
  String weeksCount(int n) {
    return '$n wiki';
  }

  @override
  String get maxEligible => 'Kikomo chako';

  @override
  String yourSharesValue(String amount) {
    return 'Thamani ya hisa: $amount';
  }

  @override
  String get quickAmounts => 'Chagua kiasi haraka';

  @override
  String get selectGuarantors => 'Chagua wadhamini (angalau 1)';

  @override
  String guarantorsSelected(int n) {
    return '$n wamechaguliwa';
  }

  @override
  String get loanSubmitted => 'Ombi la mkopo limewasilishwa';

  @override
  String get loanSubmitFailed => 'Imeshindwa kuwasilisha ombi';

  @override
  String get estimatedRepayment => 'Makadirio ya malipo kwa wiki';

  @override
  String get approvalFlow =>
      'Ombi litaenda kwa wadhamini, katibu, mhasibu na mwenyekiti';

  @override
  String get fillAllFields => 'Jaza kiasi, muda na wadhamini';

  @override
  String get noGuarantorsAvailable => 'Hakuna wanachama wengine kwa sasa';

  @override
  String get loanLimit => 'Kikomo cha mkopo';

  @override
  String get loanLimitHint => 'Hadi mara 3 ya thamani ya hisa zako';

  @override
  String get approveLoans => 'Idhinisha Mikopo';

  @override
  String memberLabel(int n) {
    return 'Mwanachama $n';
  }

  @override
  String get savingsManagement => 'Usimamizi wa Akiba';

  @override
  String get savingsAndShares => 'Akiba na Hisa';

  @override
  String get treasurerHint =>
      'Unaweza kuthibitisha michango ya wanachama. Vitendo vya fedha nyingi vinahitaji PIN na idhini ya viongozi.';

  @override
  String get typeSavings => 'Akiba';

  @override
  String get typeEmergency => 'Dharura';

  @override
  String get typeSocial => 'Kijamii';

  @override
  String get amountTzs => 'Kiasi (TZS)';

  @override
  String get amountReceived => 'Kiasi kilichopokelewa (TZS)';

  @override
  String get paymentMethod => 'Njia ya malipo';

  @override
  String get cash => 'Fedha taslimu';

  @override
  String get confirmAndRecord => 'Thibitisha na Rekodi';

  @override
  String get contributeBuyShares => 'Changia / Nunua Hisa';

  @override
  String get contributeTab => 'Changia';

  @override
  String get buySharesTab => 'Nunua Hisa';

  @override
  String get recentActivity => 'Shughuli za Hivi Karibuni';

  @override
  String get shareQuantity => 'Idadi ya hisa';

  @override
  String sharePriceEach(String price) {
    return 'Bei kwa hisa: $price';
  }

  @override
  String get totalPayable => 'Jumla ya kulipa';

  @override
  String get yourBalances => 'Salio lako';

  @override
  String get emergencyBalance => 'Dharura';

  @override
  String get socialBalance => 'Kijamii';

  @override
  String get contributionSaved => 'Mchango umehifadhiwa';

  @override
  String get sharesPurchased => 'Hisa zimenunuliwa';

  @override
  String get noRecentActivity => 'Hakuna shughuli bado';

  @override
  String get recordForMember => 'Rekodi kwa mwanachama';

  @override
  String get savedWillSync => 'Imehifadhiwa - itasawazishwa';

  @override
  String get confirmedSaved => 'Imethibitishwa na kuhifadhiwa';

  @override
  String get shareOutTitle => 'Mgawanyo (Share-out)';

  @override
  String get poolTotal => 'Jumla ya Mfuko';

  @override
  String get shareOutLeaderOnly =>
      'Mgawanyo unaonekana tu kwa Mhasibu na viongozi.';

  @override
  String get calculateShareOut => 'Hesabu Mgawanyo';

  @override
  String get approveShareOut => 'Idhinisha Mgawanyo';

  @override
  String get payShareOut => 'Lipa (Idhini kamili inahitajika)';

  @override
  String get multiSignRequired =>
      'Malipo makubwa yanahitaji saini za Mhasibu, Mwenyekiti na Katibu.';

  @override
  String get syncNow => 'Sawazisha Sasa';

  @override
  String get syncing => 'Inasawazisha...';

  @override
  String get syncComplete => 'Usawazishaji umekamilika';

  @override
  String get allDataSynced => 'Data zimesawazishwa';

  @override
  String recordsPending(int count) {
    return 'Rekodi $count zinasubiri';
  }

  @override
  String get pageNotFound => 'Ukurasa haupatikani';

  @override
  String get error => 'Hitilafu';

  @override
  String get failed => 'Imeshindwa';

  @override
  String get pinMustBe4 => 'PIN lazima iwe tarakimu 4';

  @override
  String get invalidCredentials => 'Nambari ya simu au PIN si sahihi';

  @override
  String get loginFailed => 'Imeshindwa kuingia';

  @override
  String currency(String amount) {
    return 'TZS $amount';
  }

  @override
  String greetingHello(String name) {
    return 'Habari, $name';
  }

  @override
  String get quickActionsTitle => 'Vitendo vya Haraka';

  @override
  String get platformOverview => 'Muhtasari wa Mfumo';

  @override
  String get groupFinances => 'Fedha za Kikundi';

  @override
  String get myWallet => 'Pochi Yangu';

  @override
  String get nationalSavings => 'Akiba za Taifa';

  @override
  String get fraudAlerts => 'Tahadhari Udanganyifu';

  @override
  String get systemHealth => 'Afya ya Mfumo';

  @override
  String get mobileMoneyStatus => 'Malipo ya Simu';

  @override
  String get operational => 'Inafanya kazi';

  @override
  String get healthy => 'Salama';

  @override
  String get emergencyFund => 'Mfuko wa Dharura';

  @override
  String get socialFund => 'Mfuko wa Kijamii';

  @override
  String get meetingsSoon => 'Mikutano';

  @override
  String get unreadAlerts => 'Arifa';

  @override
  String get tapToOpen => 'Gusa kufungua';

  @override
  String get manageUsers => 'Watumiaji';

  @override
  String get fraudMonitor => 'Udanganyifu';

  @override
  String get systemLogs => 'Kumbukumbu';

  @override
  String get shareOutAction => 'Mgawanyo';

  @override
  String get historyAction => 'Historia';

  @override
  String get pullToRefresh => 'Vuta kusasisha';

  @override
  String get accountSettings => 'Mipangilio ya Akaunti';

  @override
  String get preferences => 'Mapendeleo';

  @override
  String get securityPrivacy => 'Usalama na Faragha';

  @override
  String get logoutConfirmTitle => 'Toka kwenye programu?';

  @override
  String get logoutConfirmMessage => 'Utahitaji kuingia tena kwa PIN yako';

  @override
  String get confirmLogout => 'Ndio, Toka';

  @override
  String get voiceEnabled => 'Sauti imewashwa';

  @override
  String get voiceDisabled => 'Sauti imezimwa';

  @override
  String get biometricEnabled => 'Biometriki imewashwa';

  @override
  String get biometricDisabled => 'Biometriki imezimwa';

  @override
  String pendingSyncCount(int n) {
    return '$n zinasubiri kusawazishwa';
  }

  @override
  String get allSynced => 'Data zimesawazishwa';

  @override
  String memberIdLabel(String id) {
    return 'Nambari: $id';
  }

  @override
  String get helpSupport => 'Msaada na Usaidizi';

  @override
  String get digitalVicobaMember => 'Mwanachama wa Digital Vikoba';

  @override
  String get membersSubtitle => 'Simamia wanachama na salio lao';

  @override
  String get searchMembersHint => 'Tafuta kwa jina, simu au nambari...';

  @override
  String get addMember => 'Ongeza Mwanachama';

  @override
  String get memberAdded => 'Mwanachama ameongezwa';

  @override
  String get memberActivationRegister =>
      'Waombe wafungue programu → Jisajili → namba hii hiyo → OTP → PIN tarakimu 4. Kisha waingie.';

  @override
  String get memberActivationLogin =>
      'Tayari ana akaunti. Anaweza kuingia kwa namba hii na PIN yake.';

  @override
  String get temporaryPinTitle => 'PIN ya muda imetengenezwa';

  @override
  String temporaryPinMessage(String name) {
    return 'Mpe $name PIN hii. Aingie kwa namba ya simu na PIN hii, kisha achague PIN mpya.';
  }

  @override
  String temporaryPinValue(String pin) {
    return 'PIN ya muda: $pin';
  }

  @override
  String get temporaryPinDevHint =>
      'Katika maendeleo, PIN ya muda kawaida ni tarakimu 4 za mwisho za namba ya simu.';

  @override
  String get changePinRequiredTitle => 'Unda PIN yako mpya';

  @override
  String get changePinRequiredSubtitle =>
      'Umeingia kwa PIN ya muda. Chagua PIN mpya ya tarakimu 4 ili kuendelea — huwezi kuruka hatua hii.';

  @override
  String get pinCannotMatchTemporary =>
      'PIN mpya lazima iwe tofauti na PIN ya muda.';

  @override
  String get changeProfilePhoto => 'Badilisha picha ya wasifu';

  @override
  String get uploadFromGallery => 'Chagua kutoka ghala';

  @override
  String get takePhoto => 'Piga picha';

  @override
  String get removeProfilePhoto => 'Ondoa picha';

  @override
  String get profilePhotoUpdated => 'Picha ya wasifu imesasishwa';

  @override
  String get profilePhotoRemoved => 'Picha ya wasifu imeondolewa';

  @override
  String get profilePhotoUploadFailed => 'Imeshindwa kupakia picha ya wasifu';

  @override
  String get cameraNotAvailableOnWeb =>
      'Kamera haipatikani kwenye kivinjari. Chagua kutoka ghala.';

  @override
  String get filterAll => 'Wote';

  @override
  String get filterActive => 'Hai';

  @override
  String get filterWithLoan => 'Na mkopo';

  @override
  String get sortByName => 'Jina';

  @override
  String get sortBySavings => 'Akiba';

  @override
  String get memberDetails => 'Maelezo ya mwanachama';

  @override
  String get totalGroupSavings => 'Jumla akiba';

  @override
  String get activeMembers => 'Wanachama hai';

  @override
  String get statusActive => 'Hai';

  @override
  String get statusInactive => 'Haijaamilishwa';

  @override
  String sharesAndSavings(int shares, String amount) {
    return 'Hisa: $shares | Akiba: $amount';
  }

  @override
  String get noMembersFound => 'Hakuna mwanachama aliyepatikana';

  @override
  String get firstName => 'Jina la kwanza';

  @override
  String get lastName => 'Jina la mwisho';

  @override
  String get loanBalance => 'Mkopo';

  @override
  String get callMember => 'Piga simu';

  @override
  String get viewProfile => 'Angalia wasifu';

  @override
  String get fieldRequired => 'Sehemu hii inahitajika';

  @override
  String get groupsSubtitle => 'Simamia vikundi vyote vya mfumo';

  @override
  String get searchGroupsHint => 'Tafuta kikundi kwa jina au eneo...';

  @override
  String get groupCreated => 'Kikundi kimeundwa';

  @override
  String get groupDetails => 'Maelezo ya kikundi';

  @override
  String get groupName => 'Jina la kikundi';

  @override
  String get activeGroupsLabel => 'Vikundi hai';

  @override
  String membersCount(int n) {
    return 'Wanachama: $n';
  }

  @override
  String get noGroupsFound => 'Hakuna kikundi kilichopatikana';

  @override
  String get filterForming => 'Kinaundwa';

  @override
  String get groupStatusForming => 'Kinaundwa';

  @override
  String get groupStatusActive => 'Hai';

  @override
  String get groupStatusShareOut => 'Mgawanyo';

  @override
  String get groupStatusDormant => 'Imelala';

  @override
  String get groupStatusClosed => 'Imefungwa';

  @override
  String get sharePriceLabel => 'Bei ya hisa';

  @override
  String get wardLabel => 'Kata';

  @override
  String get villageLabel => 'Kijiji';

  @override
  String get viewMembers => 'Wanachama';

  @override
  String get manageGroup => 'Simamia kikundi';

  @override
  String get interestRateLabel => 'Riba ya mkopo';

  @override
  String get meetingFrequencyLabel => 'Mkutano';

  @override
  String get reportsSubtitle => 'Pakua ripoti na uone takwimu za kikundi';

  @override
  String get reportSavingsGrowth => 'Ukuaji wa Akiba';

  @override
  String get reportLoanPerformance => 'Utendaji wa Mikopo';

  @override
  String get reportPaymentTrends => 'Mwenendo wa Malipo';

  @override
  String get reportDefaultRisk => 'Hatari ya Default';

  @override
  String get downloadReport => 'Pakua ripoti';

  @override
  String get generatingReport => 'Inatengeneza ripoti...';

  @override
  String get reportReady => 'Ripoti iko tayari';

  @override
  String activeLoansCount(int n) {
    return 'Mikopo hai: $n';
  }

  @override
  String overdueLoansCount(int n) {
    return 'Mikopo iliyochelewa: $n';
  }

  @override
  String get riskInsight => 'Ushauri';

  @override
  String get tapToGenerate => 'Gusa kutengeneza';

  @override
  String get downloadedReports => 'Ripoti zilizopakuliwa';

  @override
  String get viewReport => 'Fungua ripoti';

  @override
  String get reportSaved => 'Ripoti imehifadhiwa kwenye kifaa';

  @override
  String get openReport => 'Angalia data';

  @override
  String reportRows(int n) {
    return 'Rekodi $n';
  }

  @override
  String get reportDownloadBrowser =>
      'Faili CSV inapakuliwa — angalia folda ya Downloads kwenye Chrome';

  @override
  String get loginWelcome => 'Karibu tena';

  @override
  String get loginSubtitle => 'Ingia kwa nambari ya simu na PIN';

  @override
  String get welcomeTitle => 'Karibu Digital Vikoba';

  @override
  String get welcomeSubtitle =>
      'Jisajili kikundi chako, okoa pamoja, na simamia mikopo kwa uwazi.';

  @override
  String get getStarted => 'Anza sasa';

  @override
  String get alreadyHaveAccount => 'Tayari nina akaunti';

  @override
  String get alreadyHaveAccountLogin => 'Umesajiliwa? Ingia';

  @override
  String get backToWelcome => 'Rudi';

  @override
  String get registerSubtitle =>
      'Unda akaunti yako kwa nambari ya simu. Tutakutumia nambari ya uthibitisho.';

  @override
  String get registerChooseLanguageTitle => 'Chagua lugha yako';

  @override
  String get registerChooseLanguageSubtitle =>
      'Chagua lugha unayopendelea kabla ya kujisajili. Unaweza kubadilisha baadaye.';

  @override
  String get registerContinue => 'Endelea na usajili';

  @override
  String get changeLanguage => 'Badilisha lugha';

  @override
  String get invalidPhone => 'Weka nambari sahihi ya Tanzania (mf. 0712345678)';

  @override
  String get pinMismatch => 'PIN hazifanani';

  @override
  String get pinMatches => 'PIN zinafanana';

  @override
  String get otpMustBe6 => 'Weka nambari 6 za uthibitisho';

  @override
  String get invalidOtp => 'Nambari si sahihi au imekwisha';

  @override
  String get otpSendFailed => 'Imeshindwa kutuma nambari ya uthibitisho';

  @override
  String get otpResent => 'Nambari imetumwa tena';

  @override
  String get resendOtp => 'Tuma tena';

  @override
  String resendIn(int seconds) {
    return 'Tuma tena baada ya ${seconds}s';
  }

  @override
  String get otpEnterSubtitle =>
      'Weka nambari 6 za uthibitisho zilizotumwa kwenye simu yako';

  @override
  String get registrationExpired => 'Muda wa usajili umeisha. Anza upya.';

  @override
  String get pinSetupSubtitle =>
      'Chagua PIN ya tarakimu 4. Utaitumia kuingia kwa usalama.';

  @override
  String get onboardingTitle => 'Sanidi kikundi chako';

  @override
  String get onboardingSubtitle =>
      'Hujajiunga na kikundi cha VICOBA. Unda kikundi kama mwanachama wa kwanza, au jiunge kwa mwaliko.';

  @override
  String get createYourGroup => 'Unda kikundi chako cha VICOBA';

  @override
  String get createGroupHint =>
      'Kama mwanachama wa kwanza, unaweza kuanzisha kikundi na kuwaalika wengine.';

  @override
  String get joinWithInvite => 'Nina mwaliko';

  @override
  String get inviteComingSoon =>
      'Viungo vya mwaliko vitapatikana hivi karibuni. Muulize katibu wa kikundi akuongeze kwa nambari ya simu.';

  @override
  String get connectionError =>
      'Haiwezi kuunganisha na seva. Hakikisha backend inaendesha.';

  @override
  String get devOtpHint => 'Maendeleo: nambari ya uthibitisho ni 123456';

  @override
  String get notificationsSubtitle => 'Arifa za kikundi na mfumo';

  @override
  String get markAllRead => 'Soma zote';

  @override
  String get noNotifications => 'Hakuna arifa kwa sasa';

  @override
  String get filterUnread => 'Zisizosomwa';

  @override
  String get meetingReminder => 'Kumbusho la mkutano';

  @override
  String get paymentReminder => 'Kumbusho la malipo';

  @override
  String get notificationDetail => 'Maelezo ya arifa';

  @override
  String todayAt(String time) {
    return 'Leo, $time';
  }

  @override
  String get newNotifications => 'Arifa mpya';

  @override
  String get oldNotifications => 'Arifa zilizosomwa';

  @override
  String showOldNotifications(int n) {
    return 'Onyesha arifa za zamani ($n)';
  }

  @override
  String get hideOldNotifications => 'Ficha arifa za zamani';

  @override
  String get notificationOpened => 'Imefunguliwa';

  @override
  String get noNewNotifications => 'Hakuna arifa mpya — zote zimesomwa';
}
