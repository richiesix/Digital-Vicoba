import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In sw, this message translates to:
  /// **'Digital Vikoba'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In sw, this message translates to:
  /// **'Akiba za jamii kwa uwazi'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In sw, this message translates to:
  /// **'Ingia'**
  String get login;

  /// No description provided for @register.
  ///
  /// In sw, this message translates to:
  /// **'Jisajili'**
  String get register;

  /// No description provided for @phoneNumber.
  ///
  /// In sw, this message translates to:
  /// **'Nambari ya simu'**
  String get phoneNumber;

  /// No description provided for @enterPin.
  ///
  /// In sw, this message translates to:
  /// **'Weka PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In sw, this message translates to:
  /// **'Thibitisha PIN'**
  String get confirmPin;

  /// No description provided for @choosePinHint.
  ///
  /// In sw, this message translates to:
  /// **'Chagua PIN ya tarakimu 4'**
  String get choosePinHint;

  /// No description provided for @finish.
  ///
  /// In sw, this message translates to:
  /// **'Maliza'**
  String get finish;

  /// No description provided for @continueButton.
  ///
  /// In sw, this message translates to:
  /// **'Endelea'**
  String get continueButton;

  /// No description provided for @sendOtp.
  ///
  /// In sw, this message translates to:
  /// **'Tuma OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In sw, this message translates to:
  /// **'Thibitisha OTP'**
  String get verifyOtp;

  /// No description provided for @otpSentTo.
  ///
  /// In sw, this message translates to:
  /// **'OTP imetumwa kwa {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @noAccount.
  ///
  /// In sw, this message translates to:
  /// **'Huna akaunti? Jisajili'**
  String get noAccount;

  /// No description provided for @demoAccounts.
  ///
  /// In sw, this message translates to:
  /// **'Demo:\nMsimamizi: +255712000001\nMhasibu: +255712000002\nMwanachama: +255712000003\nPIN: 1234 (wote)'**
  String get demoAccounts;

  /// No description provided for @dashboard.
  ///
  /// In sw, this message translates to:
  /// **'Dashibodi'**
  String get dashboard;

  /// No description provided for @groups.
  ///
  /// In sw, this message translates to:
  /// **'Vikundi'**
  String get groups;

  /// No description provided for @members.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama'**
  String get members;

  /// No description provided for @savings.
  ///
  /// In sw, this message translates to:
  /// **'Akiba'**
  String get savings;

  /// No description provided for @loans.
  ///
  /// In sw, this message translates to:
  /// **'Mikopo'**
  String get loans;

  /// No description provided for @meetings.
  ///
  /// In sw, this message translates to:
  /// **'Mikutano'**
  String get meetings;

  /// No description provided for @reports.
  ///
  /// In sw, this message translates to:
  /// **'Ripoti'**
  String get reports;

  /// No description provided for @notifications.
  ///
  /// In sw, this message translates to:
  /// **'Arifa'**
  String get notifications;

  /// No description provided for @shareOut.
  ///
  /// In sw, this message translates to:
  /// **'Mgawanyo'**
  String get shareOut;

  /// No description provided for @profile.
  ///
  /// In sw, this message translates to:
  /// **'Wasifu'**
  String get profile;

  /// No description provided for @syncStatus.
  ///
  /// In sw, this message translates to:
  /// **'Hali ya Usawazishaji'**
  String get syncStatus;

  /// No description provided for @offline.
  ///
  /// In sw, this message translates to:
  /// **'Huna mtandao'**
  String get offline;

  /// No description provided for @offlineDetail.
  ///
  /// In sw, this message translates to:
  /// **'Huna mtandao - data itasawazishwa baadaye'**
  String get offlineDetail;

  /// No description provided for @online.
  ///
  /// In sw, this message translates to:
  /// **'Uko mtandaoni'**
  String get online;

  /// No description provided for @totalSavings.
  ///
  /// In sw, this message translates to:
  /// **'Jumla ya Akiba'**
  String get totalSavings;

  /// No description provided for @activeLoans.
  ///
  /// In sw, this message translates to:
  /// **'Mikopo Hai'**
  String get activeLoans;

  /// No description provided for @recordShare.
  ///
  /// In sw, this message translates to:
  /// **'Rekodi Hisa'**
  String get recordShare;

  /// No description provided for @applyLoan.
  ///
  /// In sw, this message translates to:
  /// **'Omba Mkopo'**
  String get applyLoan;

  /// No description provided for @approveLoan.
  ///
  /// In sw, this message translates to:
  /// **'Idhinisha Mkopo'**
  String get approveLoan;

  /// No description provided for @attendance.
  ///
  /// In sw, this message translates to:
  /// **'Mahudhurio'**
  String get attendance;

  /// No description provided for @balance.
  ///
  /// In sw, this message translates to:
  /// **'Salio'**
  String get balance;

  /// No description provided for @amount.
  ///
  /// In sw, this message translates to:
  /// **'Kiasi'**
  String get amount;

  /// No description provided for @save.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In sw, this message translates to:
  /// **'Ghairi'**
  String get cancel;

  /// No description provided for @reject.
  ///
  /// In sw, this message translates to:
  /// **'Kataa'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In sw, this message translates to:
  /// **'Idhinisha'**
  String get approve;

  /// No description provided for @pending.
  ///
  /// In sw, this message translates to:
  /// **'Inasubiri'**
  String get pending;

  /// No description provided for @overdue.
  ///
  /// In sw, this message translates to:
  /// **'Imechelewa'**
  String get overdue;

  /// No description provided for @completed.
  ///
  /// In sw, this message translates to:
  /// **'Imekamilika'**
  String get completed;

  /// No description provided for @language.
  ///
  /// In sw, this message translates to:
  /// **'Lugha'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In sw, this message translates to:
  /// **'Mipangilio ya Lugha'**
  String get languageSettings;

  /// No description provided for @chooseLanguage.
  ///
  /// In sw, this message translates to:
  /// **'Chagua lugha unayopendelea'**
  String get chooseLanguage;

  /// No description provided for @swahili.
  ///
  /// In sw, this message translates to:
  /// **'Kiswahili'**
  String get swahili;

  /// No description provided for @english.
  ///
  /// In sw, this message translates to:
  /// **'Kiingereza'**
  String get english;

  /// No description provided for @languageChanged.
  ///
  /// In sw, this message translates to:
  /// **'Lugha imebadilishwa'**
  String get languageChanged;

  /// No description provided for @voiceSwahili.
  ///
  /// In sw, this message translates to:
  /// **'Sauti (Kiswahili)'**
  String get voiceSwahili;

  /// No description provided for @biometric.
  ///
  /// In sw, this message translates to:
  /// **'Biometriki'**
  String get biometric;

  /// No description provided for @logout.
  ///
  /// In sw, this message translates to:
  /// **'Toka'**
  String get logout;

  /// No description provided for @user.
  ///
  /// In sw, this message translates to:
  /// **'Mtumiaji'**
  String get user;

  /// No description provided for @home.
  ///
  /// In sw, this message translates to:
  /// **'Nyumbani'**
  String get home;

  /// No description provided for @finance.
  ///
  /// In sw, this message translates to:
  /// **'Fedha'**
  String get finance;

  /// No description provided for @payments.
  ///
  /// In sw, this message translates to:
  /// **'Malipo'**
  String get payments;

  /// No description provided for @analytics.
  ///
  /// In sw, this message translates to:
  /// **'Takwimu'**
  String get analytics;

  /// No description provided for @meetingTabUpcoming.
  ///
  /// In sw, this message translates to:
  /// **'Ijayo'**
  String get meetingTabUpcoming;

  /// No description provided for @startMeeting.
  ///
  /// In sw, this message translates to:
  /// **'Anza Mkutano'**
  String get startMeeting;

  /// No description provided for @viewAttendance.
  ///
  /// In sw, this message translates to:
  /// **'Angalia Mahudhurio'**
  String get viewAttendance;

  /// No description provided for @attendanceTab.
  ///
  /// In sw, this message translates to:
  /// **'Mahudhurio'**
  String get attendanceTab;

  /// No description provided for @saveAttendance.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi Mahudhurio'**
  String get saveAttendance;

  /// No description provided for @saveMyAttendance.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi Mahudhurio Yangu'**
  String get saveMyAttendance;

  /// No description provided for @meetingStarted.
  ///
  /// In sw, this message translates to:
  /// **'Mkutano umeanza'**
  String get meetingStarted;

  /// No description provided for @noMeetingScheduled.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mkutano uliopangwa'**
  String get noMeetingScheduled;

  /// No description provided for @waitForLeader.
  ///
  /// In sw, this message translates to:
  /// **'Subiri mwenyekiti au katibu aanzishe mkutano'**
  String get waitForLeader;

  /// No description provided for @startMeetingFirst.
  ///
  /// In sw, this message translates to:
  /// **'Anza mkutano kwanza'**
  String get startMeetingFirst;

  /// No description provided for @attendanceSaved.
  ///
  /// In sw, this message translates to:
  /// **'Mahudhurio yamehifadhiwa'**
  String get attendanceSaved;

  /// No description provided for @startMeetingHint.
  ///
  /// In sw, this message translates to:
  /// **'Bonyeza \"Anza Mkutano\" kwenye kichupo cha Ijayo kwanza.'**
  String get startMeetingHint;

  /// No description provided for @meetingsSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Panga na fuatilia mikutano ya kikundi'**
  String get meetingsSubtitle;

  /// No description provided for @quorumLabel.
  ///
  /// In sw, this message translates to:
  /// **'Idadi ya waliohudhuria'**
  String get quorumLabel;

  /// No description provided for @markAllPresent.
  ///
  /// In sw, this message translates to:
  /// **'Wote wapo'**
  String get markAllPresent;

  /// No description provided for @searchMember.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta mwanachama'**
  String get searchMember;

  /// No description provided for @pastMeetings.
  ///
  /// In sw, this message translates to:
  /// **'Mikutano iliyopita'**
  String get pastMeetings;

  /// No description provided for @noMeetingsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mkutano uliopangwa'**
  String get noMeetingsYet;

  /// No description provided for @meetingLive.
  ///
  /// In sw, this message translates to:
  /// **'Mkutano unaendelea'**
  String get meetingLive;

  /// No description provided for @attendanceProgress.
  ///
  /// In sw, this message translates to:
  /// **'{present} kati ya {total}'**
  String attendanceProgress(int present, int total);

  /// No description provided for @startsIn.
  ///
  /// In sw, this message translates to:
  /// **'Inaanza baada ya {time}'**
  String startsIn(String time);

  /// No description provided for @locationLabel.
  ///
  /// In sw, this message translates to:
  /// **'Mahali'**
  String get locationLabel;

  /// No description provided for @weeklyMeeting.
  ///
  /// In sw, this message translates to:
  /// **'Mkutano wa Wiki'**
  String get weeklyMeeting;

  /// No description provided for @scheduled.
  ///
  /// In sw, this message translates to:
  /// **'Imepangwa'**
  String get scheduled;

  /// No description provided for @inProgress.
  ///
  /// In sw, this message translates to:
  /// **'Unaendelea'**
  String get inProgress;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In sw, this message translates to:
  /// **'Msimamizi Mkuu'**
  String get roleSuperAdmin;

  /// No description provided for @roleSuperAdminFull.
  ///
  /// In sw, this message translates to:
  /// **'Msimamizi Mkuu wa Mfumo'**
  String get roleSuperAdminFull;

  /// No description provided for @roleTreasurer.
  ///
  /// In sw, this message translates to:
  /// **'Mhasibu wa Kikundi'**
  String get roleTreasurer;

  /// No description provided for @roleChairperson.
  ///
  /// In sw, this message translates to:
  /// **'Mwenyekiti'**
  String get roleChairperson;

  /// No description provided for @roleSecretary.
  ///
  /// In sw, this message translates to:
  /// **'Katibu'**
  String get roleSecretary;

  /// No description provided for @roleMember.
  ///
  /// In sw, this message translates to:
  /// **'Mwanachama'**
  String get roleMember;

  /// No description provided for @dashboardAdmin.
  ///
  /// In sw, this message translates to:
  /// **'Dashibodi — Msimamizi'**
  String get dashboardAdmin;

  /// No description provided for @dashboardTreasurer.
  ///
  /// In sw, this message translates to:
  /// **'Dashibodi — Mhasibu'**
  String get dashboardTreasurer;

  /// No description provided for @dashboardMember.
  ///
  /// In sw, this message translates to:
  /// **'Dashibodi — Mwanachama'**
  String get dashboardMember;

  /// No description provided for @totalGroups.
  ///
  /// In sw, this message translates to:
  /// **'Jumla vikundi'**
  String get totalGroups;

  /// No description provided for @totalMembers.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama'**
  String get totalMembers;

  /// No description provided for @groupBalance.
  ///
  /// In sw, this message translates to:
  /// **'Salio la Kikundi'**
  String get groupBalance;

  /// No description provided for @pendingRepayments.
  ///
  /// In sw, this message translates to:
  /// **'Malipo Yanayosubiri'**
  String get pendingRepayments;

  /// No description provided for @mySavings.
  ///
  /// In sw, this message translates to:
  /// **'Akiba Yangu'**
  String get mySavings;

  /// No description provided for @loanDebt.
  ///
  /// In sw, this message translates to:
  /// **'Deni la Mkopo'**
  String get loanDebt;

  /// No description provided for @shares.
  ///
  /// In sw, this message translates to:
  /// **'Hisa'**
  String get shares;

  /// No description provided for @myGroups.
  ///
  /// In sw, this message translates to:
  /// **'Vikundi Vyangu'**
  String get myGroups;

  /// No description provided for @createGroup.
  ///
  /// In sw, this message translates to:
  /// **'Unda Kikundi'**
  String get createGroup;

  /// No description provided for @submitLoan.
  ///
  /// In sw, this message translates to:
  /// **'Wasilisha Ombi'**
  String get submitLoan;

  /// No description provided for @loanAmountLabel.
  ///
  /// In sw, this message translates to:
  /// **'Kiasi cha mkopo (TZS)'**
  String get loanAmountLabel;

  /// No description provided for @loanPurposeLabel.
  ///
  /// In sw, this message translates to:
  /// **'Sababu ya mkopo'**
  String get loanPurposeLabel;

  /// No description provided for @loanTermWeeks.
  ///
  /// In sw, this message translates to:
  /// **'Muda wa mkopo'**
  String get loanTermWeeks;

  /// No description provided for @weeksCount.
  ///
  /// In sw, this message translates to:
  /// **'{n} wiki'**
  String weeksCount(int n);

  /// No description provided for @maxEligible.
  ///
  /// In sw, this message translates to:
  /// **'Kikomo chako'**
  String get maxEligible;

  /// No description provided for @yourSharesValue.
  ///
  /// In sw, this message translates to:
  /// **'Thamani ya hisa: {amount}'**
  String yourSharesValue(String amount);

  /// No description provided for @quickAmounts.
  ///
  /// In sw, this message translates to:
  /// **'Chagua kiasi haraka'**
  String get quickAmounts;

  /// No description provided for @selectGuarantors.
  ///
  /// In sw, this message translates to:
  /// **'Chagua wadhamini (angalau 1)'**
  String get selectGuarantors;

  /// No description provided for @guarantorsSelected.
  ///
  /// In sw, this message translates to:
  /// **'{n} wamechaguliwa'**
  String guarantorsSelected(int n);

  /// No description provided for @loanSubmitted.
  ///
  /// In sw, this message translates to:
  /// **'Ombi la mkopo limewasilishwa'**
  String get loanSubmitted;

  /// No description provided for @loanSubmitFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kuwasilisha ombi'**
  String get loanSubmitFailed;

  /// No description provided for @estimatedRepayment.
  ///
  /// In sw, this message translates to:
  /// **'Makadirio ya malipo kwa wiki'**
  String get estimatedRepayment;

  /// No description provided for @approvalFlow.
  ///
  /// In sw, this message translates to:
  /// **'Ombi litaenda kwa wadhamini, katibu, mhasibu na mwenyekiti'**
  String get approvalFlow;

  /// No description provided for @fillAllFields.
  ///
  /// In sw, this message translates to:
  /// **'Jaza kiasi, muda na wadhamini'**
  String get fillAllFields;

  /// No description provided for @noGuarantorsAvailable.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna wanachama wengine kwa sasa'**
  String get noGuarantorsAvailable;

  /// No description provided for @loanLimit.
  ///
  /// In sw, this message translates to:
  /// **'Kikomo cha mkopo'**
  String get loanLimit;

  /// No description provided for @loanLimitHint.
  ///
  /// In sw, this message translates to:
  /// **'Hadi mara 3 ya thamani ya hisa zako'**
  String get loanLimitHint;

  /// No description provided for @approveLoans.
  ///
  /// In sw, this message translates to:
  /// **'Idhinisha Mikopo'**
  String get approveLoans;

  /// No description provided for @memberLabel.
  ///
  /// In sw, this message translates to:
  /// **'Mwanachama {n}'**
  String memberLabel(int n);

  /// No description provided for @savingsManagement.
  ///
  /// In sw, this message translates to:
  /// **'Usimamizi wa Akiba'**
  String get savingsManagement;

  /// No description provided for @savingsAndShares.
  ///
  /// In sw, this message translates to:
  /// **'Akiba na Hisa'**
  String get savingsAndShares;

  /// No description provided for @treasurerHint.
  ///
  /// In sw, this message translates to:
  /// **'Unaweza kuthibitisha michango ya wanachama. Vitendo vya fedha nyingi vinahitaji PIN na idhini ya viongozi.'**
  String get treasurerHint;

  /// No description provided for @typeSavings.
  ///
  /// In sw, this message translates to:
  /// **'Akiba'**
  String get typeSavings;

  /// No description provided for @typeEmergency.
  ///
  /// In sw, this message translates to:
  /// **'Dharura'**
  String get typeEmergency;

  /// No description provided for @typeSocial.
  ///
  /// In sw, this message translates to:
  /// **'Kijamii'**
  String get typeSocial;

  /// No description provided for @amountTzs.
  ///
  /// In sw, this message translates to:
  /// **'Kiasi (TZS)'**
  String get amountTzs;

  /// No description provided for @amountReceived.
  ///
  /// In sw, this message translates to:
  /// **'Kiasi kilichopokelewa (TZS)'**
  String get amountReceived;

  /// No description provided for @paymentMethod.
  ///
  /// In sw, this message translates to:
  /// **'Njia ya malipo'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In sw, this message translates to:
  /// **'Fedha taslimu'**
  String get cash;

  /// No description provided for @confirmAndRecord.
  ///
  /// In sw, this message translates to:
  /// **'Thibitisha na Rekodi'**
  String get confirmAndRecord;

  /// No description provided for @contributeBuyShares.
  ///
  /// In sw, this message translates to:
  /// **'Changia / Nunua Hisa'**
  String get contributeBuyShares;

  /// No description provided for @contributeTab.
  ///
  /// In sw, this message translates to:
  /// **'Changia'**
  String get contributeTab;

  /// No description provided for @buySharesTab.
  ///
  /// In sw, this message translates to:
  /// **'Nunua Hisa'**
  String get buySharesTab;

  /// No description provided for @recentActivity.
  ///
  /// In sw, this message translates to:
  /// **'Shughuli za Hivi Karibuni'**
  String get recentActivity;

  /// No description provided for @selectMember.
  ///
  /// In sw, this message translates to:
  /// **'Chagua mwanachama'**
  String get selectMember;

  /// No description provided for @shareQuantity.
  ///
  /// In sw, this message translates to:
  /// **'Idadi ya hisa'**
  String get shareQuantity;

  /// No description provided for @sharePriceEach.
  ///
  /// In sw, this message translates to:
  /// **'Bei kwa hisa: {price}'**
  String sharePriceEach(String price);

  /// No description provided for @totalPayable.
  ///
  /// In sw, this message translates to:
  /// **'Jumla ya kulipa'**
  String get totalPayable;

  /// No description provided for @yourBalances.
  ///
  /// In sw, this message translates to:
  /// **'Salio lako'**
  String get yourBalances;

  /// No description provided for @emergencyBalance.
  ///
  /// In sw, this message translates to:
  /// **'Dharura'**
  String get emergencyBalance;

  /// No description provided for @socialBalance.
  ///
  /// In sw, this message translates to:
  /// **'Kijamii'**
  String get socialBalance;

  /// No description provided for @contributionSaved.
  ///
  /// In sw, this message translates to:
  /// **'Mchango umehifadhiwa'**
  String get contributionSaved;

  /// No description provided for @sharesPurchased.
  ///
  /// In sw, this message translates to:
  /// **'Hisa zimenunuliwa'**
  String get sharesPurchased;

  /// No description provided for @noRecentActivity.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna shughuli bado'**
  String get noRecentActivity;

  /// No description provided for @recordForMember.
  ///
  /// In sw, this message translates to:
  /// **'Rekodi kwa mwanachama'**
  String get recordForMember;

  /// No description provided for @savedWillSync.
  ///
  /// In sw, this message translates to:
  /// **'Imehifadhiwa - itasawazishwa'**
  String get savedWillSync;

  /// No description provided for @confirmedSaved.
  ///
  /// In sw, this message translates to:
  /// **'Imethibitishwa na kuhifadhiwa'**
  String get confirmedSaved;

  /// No description provided for @shareOutTitle.
  ///
  /// In sw, this message translates to:
  /// **'Mgawanyo (Share-out)'**
  String get shareOutTitle;

  /// No description provided for @poolTotal.
  ///
  /// In sw, this message translates to:
  /// **'Jumla ya Mfuko'**
  String get poolTotal;

  /// No description provided for @shareOutLeaderOnly.
  ///
  /// In sw, this message translates to:
  /// **'Mgawanyo unaonekana tu kwa Mhasibu na viongozi.'**
  String get shareOutLeaderOnly;

  /// No description provided for @calculateShareOut.
  ///
  /// In sw, this message translates to:
  /// **'Hesabu Mgawanyo'**
  String get calculateShareOut;

  /// No description provided for @approveShareOut.
  ///
  /// In sw, this message translates to:
  /// **'Idhinisha Mgawanyo'**
  String get approveShareOut;

  /// No description provided for @payShareOut.
  ///
  /// In sw, this message translates to:
  /// **'Lipa (Idhini kamili inahitajika)'**
  String get payShareOut;

  /// No description provided for @multiSignRequired.
  ///
  /// In sw, this message translates to:
  /// **'Malipo makubwa yanahitaji saini za Mhasibu, Mwenyekiti na Katibu.'**
  String get multiSignRequired;

  /// No description provided for @syncNow.
  ///
  /// In sw, this message translates to:
  /// **'Sawazisha Sasa'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In sw, this message translates to:
  /// **'Inasawazisha...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In sw, this message translates to:
  /// **'Usawazishaji umekamilika'**
  String get syncComplete;

  /// No description provided for @allDataSynced.
  ///
  /// In sw, this message translates to:
  /// **'Data zimesawazishwa'**
  String get allDataSynced;

  /// No description provided for @recordsPending.
  ///
  /// In sw, this message translates to:
  /// **'Rekodi {count} zinasubiri'**
  String recordsPending(int count);

  /// No description provided for @pageNotFound.
  ///
  /// In sw, this message translates to:
  /// **'Ukurasa haupatikani'**
  String get pageNotFound;

  /// No description provided for @error.
  ///
  /// In sw, this message translates to:
  /// **'Hitilafu'**
  String get error;

  /// No description provided for @failed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa'**
  String get failed;

  /// No description provided for @pinMustBe4.
  ///
  /// In sw, this message translates to:
  /// **'PIN lazima iwe tarakimu 4'**
  String get pinMustBe4;

  /// No description provided for @invalidCredentials.
  ///
  /// In sw, this message translates to:
  /// **'Nambari ya simu au PIN si sahihi'**
  String get invalidCredentials;

  /// No description provided for @loginFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kuingia'**
  String get loginFailed;

  /// No description provided for @currency.
  ///
  /// In sw, this message translates to:
  /// **'TZS {amount}'**
  String currency(String amount);

  /// No description provided for @greetingHello.
  ///
  /// In sw, this message translates to:
  /// **'Habari, {name}'**
  String greetingHello(String name);

  /// No description provided for @quickActionsTitle.
  ///
  /// In sw, this message translates to:
  /// **'Vitendo vya Haraka'**
  String get quickActionsTitle;

  /// No description provided for @platformOverview.
  ///
  /// In sw, this message translates to:
  /// **'Muhtasari wa Mfumo'**
  String get platformOverview;

  /// No description provided for @groupFinances.
  ///
  /// In sw, this message translates to:
  /// **'Fedha za Kikundi'**
  String get groupFinances;

  /// No description provided for @myWallet.
  ///
  /// In sw, this message translates to:
  /// **'Pochi Yangu'**
  String get myWallet;

  /// No description provided for @nationalSavings.
  ///
  /// In sw, this message translates to:
  /// **'Akiba za Taifa'**
  String get nationalSavings;

  /// No description provided for @fraudAlerts.
  ///
  /// In sw, this message translates to:
  /// **'Tahadhari Udanganyifu'**
  String get fraudAlerts;

  /// No description provided for @systemHealth.
  ///
  /// In sw, this message translates to:
  /// **'Afya ya Mfumo'**
  String get systemHealth;

  /// No description provided for @mobileMoneyStatus.
  ///
  /// In sw, this message translates to:
  /// **'Malipo ya Simu'**
  String get mobileMoneyStatus;

  /// No description provided for @operational.
  ///
  /// In sw, this message translates to:
  /// **'Inafanya kazi'**
  String get operational;

  /// No description provided for @healthy.
  ///
  /// In sw, this message translates to:
  /// **'Salama'**
  String get healthy;

  /// No description provided for @emergencyFund.
  ///
  /// In sw, this message translates to:
  /// **'Mfuko wa Dharura'**
  String get emergencyFund;

  /// No description provided for @socialFund.
  ///
  /// In sw, this message translates to:
  /// **'Mfuko wa Kijamii'**
  String get socialFund;

  /// No description provided for @meetingsSoon.
  ///
  /// In sw, this message translates to:
  /// **'Mikutano'**
  String get meetingsSoon;

  /// No description provided for @unreadAlerts.
  ///
  /// In sw, this message translates to:
  /// **'Arifa'**
  String get unreadAlerts;

  /// No description provided for @tapToOpen.
  ///
  /// In sw, this message translates to:
  /// **'Gusa kufungua'**
  String get tapToOpen;

  /// No description provided for @manageUsers.
  ///
  /// In sw, this message translates to:
  /// **'Watumiaji'**
  String get manageUsers;

  /// No description provided for @fraudMonitor.
  ///
  /// In sw, this message translates to:
  /// **'Udanganyifu'**
  String get fraudMonitor;

  /// No description provided for @systemLogs.
  ///
  /// In sw, this message translates to:
  /// **'Kumbukumbu'**
  String get systemLogs;

  /// No description provided for @shareOutAction.
  ///
  /// In sw, this message translates to:
  /// **'Mgawanyo'**
  String get shareOutAction;

  /// No description provided for @historyAction.
  ///
  /// In sw, this message translates to:
  /// **'Historia'**
  String get historyAction;

  /// No description provided for @pullToRefresh.
  ///
  /// In sw, this message translates to:
  /// **'Vuta kusasisha'**
  String get pullToRefresh;

  /// No description provided for @accountSettings.
  ///
  /// In sw, this message translates to:
  /// **'Mipangilio ya Akaunti'**
  String get accountSettings;

  /// No description provided for @preferences.
  ///
  /// In sw, this message translates to:
  /// **'Mapendeleo'**
  String get preferences;

  /// No description provided for @securityPrivacy.
  ///
  /// In sw, this message translates to:
  /// **'Usalama na Faragha'**
  String get securityPrivacy;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In sw, this message translates to:
  /// **'Toka kwenye programu?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In sw, this message translates to:
  /// **'Utahitaji kuingia tena kwa PIN yako'**
  String get logoutConfirmMessage;

  /// No description provided for @confirmLogout.
  ///
  /// In sw, this message translates to:
  /// **'Ndio, Toka'**
  String get confirmLogout;

  /// No description provided for @voiceEnabled.
  ///
  /// In sw, this message translates to:
  /// **'Sauti imewashwa'**
  String get voiceEnabled;

  /// No description provided for @voiceDisabled.
  ///
  /// In sw, this message translates to:
  /// **'Sauti imezimwa'**
  String get voiceDisabled;

  /// No description provided for @biometricEnabled.
  ///
  /// In sw, this message translates to:
  /// **'Biometriki imewashwa'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In sw, this message translates to:
  /// **'Biometriki imezimwa'**
  String get biometricDisabled;

  /// No description provided for @pendingSyncCount.
  ///
  /// In sw, this message translates to:
  /// **'{n} zinasubiri kusawazishwa'**
  String pendingSyncCount(int n);

  /// No description provided for @allSynced.
  ///
  /// In sw, this message translates to:
  /// **'Data zimesawazishwa'**
  String get allSynced;

  /// No description provided for @memberIdLabel.
  ///
  /// In sw, this message translates to:
  /// **'Nambari: {id}'**
  String memberIdLabel(String id);

  /// No description provided for @helpSupport.
  ///
  /// In sw, this message translates to:
  /// **'Msaada na Usaidizi'**
  String get helpSupport;

  /// No description provided for @digitalVicobaMember.
  ///
  /// In sw, this message translates to:
  /// **'Mwanachama wa Digital Vikoba'**
  String get digitalVicobaMember;

  /// No description provided for @membersSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Simamia wanachama na salio lao'**
  String get membersSubtitle;

  /// No description provided for @searchMembersHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta kwa jina, simu au nambari...'**
  String get searchMembersHint;

  /// No description provided for @addMember.
  ///
  /// In sw, this message translates to:
  /// **'Ongeza Mwanachama'**
  String get addMember;

  /// No description provided for @memberAdded.
  ///
  /// In sw, this message translates to:
  /// **'Mwanachama ameongezwa'**
  String get memberAdded;

  /// No description provided for @filterAll.
  ///
  /// In sw, this message translates to:
  /// **'Wote'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In sw, this message translates to:
  /// **'Hai'**
  String get filterActive;

  /// No description provided for @filterWithLoan.
  ///
  /// In sw, this message translates to:
  /// **'Na mkopo'**
  String get filterWithLoan;

  /// No description provided for @sortByName.
  ///
  /// In sw, this message translates to:
  /// **'Jina'**
  String get sortByName;

  /// No description provided for @sortBySavings.
  ///
  /// In sw, this message translates to:
  /// **'Akiba'**
  String get sortBySavings;

  /// No description provided for @memberDetails.
  ///
  /// In sw, this message translates to:
  /// **'Maelezo ya mwanachama'**
  String get memberDetails;

  /// No description provided for @totalGroupSavings.
  ///
  /// In sw, this message translates to:
  /// **'Jumla akiba'**
  String get totalGroupSavings;

  /// No description provided for @activeMembers.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama hai'**
  String get activeMembers;

  /// No description provided for @statusActive.
  ///
  /// In sw, this message translates to:
  /// **'Hai'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In sw, this message translates to:
  /// **'Haijaamilishwa'**
  String get statusInactive;

  /// No description provided for @sharesAndSavings.
  ///
  /// In sw, this message translates to:
  /// **'Hisa: {shares} | Akiba: {amount}'**
  String sharesAndSavings(int shares, String amount);

  /// No description provided for @noMembersFound.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mwanachama aliyepatikana'**
  String get noMembersFound;

  /// No description provided for @firstName.
  ///
  /// In sw, this message translates to:
  /// **'Jina la kwanza'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In sw, this message translates to:
  /// **'Jina la mwisho'**
  String get lastName;

  /// No description provided for @loanBalance.
  ///
  /// In sw, this message translates to:
  /// **'Mkopo'**
  String get loanBalance;

  /// No description provided for @callMember.
  ///
  /// In sw, this message translates to:
  /// **'Piga simu'**
  String get callMember;

  /// No description provided for @viewProfile.
  ///
  /// In sw, this message translates to:
  /// **'Angalia wasifu'**
  String get viewProfile;

  /// No description provided for @fieldRequired.
  ///
  /// In sw, this message translates to:
  /// **'Sehemu hii inahitajika'**
  String get fieldRequired;

  /// No description provided for @groupsSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Simamia vikundi vyote vya mfumo'**
  String get groupsSubtitle;

  /// No description provided for @searchGroupsHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta kikundi kwa jina au eneo...'**
  String get searchGroupsHint;

  /// No description provided for @groupCreated.
  ///
  /// In sw, this message translates to:
  /// **'Kikundi kimeundwa'**
  String get groupCreated;

  /// No description provided for @groupDetails.
  ///
  /// In sw, this message translates to:
  /// **'Maelezo ya kikundi'**
  String get groupDetails;

  /// No description provided for @groupName.
  ///
  /// In sw, this message translates to:
  /// **'Jina la kikundi'**
  String get groupName;

  /// No description provided for @activeGroupsLabel.
  ///
  /// In sw, this message translates to:
  /// **'Vikundi hai'**
  String get activeGroupsLabel;

  /// No description provided for @membersCount.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama: {n}'**
  String membersCount(int n);

  /// No description provided for @noGroupsFound.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna kikundi kilichopatikana'**
  String get noGroupsFound;

  /// No description provided for @filterForming.
  ///
  /// In sw, this message translates to:
  /// **'Kinaundwa'**
  String get filterForming;

  /// No description provided for @groupStatusForming.
  ///
  /// In sw, this message translates to:
  /// **'Kinaundwa'**
  String get groupStatusForming;

  /// No description provided for @groupStatusActive.
  ///
  /// In sw, this message translates to:
  /// **'Hai'**
  String get groupStatusActive;

  /// No description provided for @groupStatusShareOut.
  ///
  /// In sw, this message translates to:
  /// **'Mgawanyo'**
  String get groupStatusShareOut;

  /// No description provided for @groupStatusDormant.
  ///
  /// In sw, this message translates to:
  /// **'Imelala'**
  String get groupStatusDormant;

  /// No description provided for @groupStatusClosed.
  ///
  /// In sw, this message translates to:
  /// **'Imefungwa'**
  String get groupStatusClosed;

  /// No description provided for @sharePriceLabel.
  ///
  /// In sw, this message translates to:
  /// **'Bei ya hisa'**
  String get sharePriceLabel;

  /// No description provided for @wardLabel.
  ///
  /// In sw, this message translates to:
  /// **'Kata'**
  String get wardLabel;

  /// No description provided for @villageLabel.
  ///
  /// In sw, this message translates to:
  /// **'Kijiji'**
  String get villageLabel;

  /// No description provided for @viewMembers.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama'**
  String get viewMembers;

  /// No description provided for @manageGroup.
  ///
  /// In sw, this message translates to:
  /// **'Simamia kikundi'**
  String get manageGroup;

  /// No description provided for @interestRateLabel.
  ///
  /// In sw, this message translates to:
  /// **'Riba ya mkopo'**
  String get interestRateLabel;

  /// No description provided for @meetingFrequencyLabel.
  ///
  /// In sw, this message translates to:
  /// **'Mkutano'**
  String get meetingFrequencyLabel;

  /// No description provided for @reportsSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Pakua ripoti na uone takwimu za kikundi'**
  String get reportsSubtitle;

  /// No description provided for @reportSavingsGrowth.
  ///
  /// In sw, this message translates to:
  /// **'Ukuaji wa Akiba'**
  String get reportSavingsGrowth;

  /// No description provided for @reportLoanPerformance.
  ///
  /// In sw, this message translates to:
  /// **'Utendaji wa Mikopo'**
  String get reportLoanPerformance;

  /// No description provided for @reportPaymentTrends.
  ///
  /// In sw, this message translates to:
  /// **'Mwenendo wa Malipo'**
  String get reportPaymentTrends;

  /// No description provided for @reportDefaultRisk.
  ///
  /// In sw, this message translates to:
  /// **'Hatari ya Default'**
  String get reportDefaultRisk;

  /// No description provided for @downloadReport.
  ///
  /// In sw, this message translates to:
  /// **'Pakua ripoti'**
  String get downloadReport;

  /// No description provided for @generatingReport.
  ///
  /// In sw, this message translates to:
  /// **'Inatengeneza ripoti...'**
  String get generatingReport;

  /// No description provided for @reportReady.
  ///
  /// In sw, this message translates to:
  /// **'Ripoti iko tayari'**
  String get reportReady;

  /// No description provided for @activeLoansCount.
  ///
  /// In sw, this message translates to:
  /// **'Mikopo hai: {n}'**
  String activeLoansCount(int n);

  /// No description provided for @overdueLoansCount.
  ///
  /// In sw, this message translates to:
  /// **'Mikopo iliyochelewa: {n}'**
  String overdueLoansCount(int n);

  /// No description provided for @riskInsight.
  ///
  /// In sw, this message translates to:
  /// **'Ushauri'**
  String get riskInsight;

  /// No description provided for @tapToGenerate.
  ///
  /// In sw, this message translates to:
  /// **'Gusa kutengeneza'**
  String get tapToGenerate;

  /// No description provided for @downloadedReports.
  ///
  /// In sw, this message translates to:
  /// **'Ripoti zilizopakuliwa'**
  String get downloadedReports;

  /// No description provided for @viewReport.
  ///
  /// In sw, this message translates to:
  /// **'Fungua ripoti'**
  String get viewReport;

  /// No description provided for @reportSaved.
  ///
  /// In sw, this message translates to:
  /// **'Ripoti imehifadhiwa kwenye kifaa'**
  String get reportSaved;

  /// No description provided for @openReport.
  ///
  /// In sw, this message translates to:
  /// **'Angalia data'**
  String get openReport;

  /// No description provided for @reportRows.
  ///
  /// In sw, this message translates to:
  /// **'Rekodi {n}'**
  String reportRows(int n);

  /// No description provided for @reportDownloadBrowser.
  ///
  /// In sw, this message translates to:
  /// **'Faili CSV inapakuliwa — angalia folda ya Downloads kwenye Chrome'**
  String get reportDownloadBrowser;

  /// No description provided for @loginWelcome.
  ///
  /// In sw, this message translates to:
  /// **'Karibu tena'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Ingia kwa nambari ya simu na PIN'**
  String get loginSubtitle;

  /// No description provided for @tryDemoAccount.
  ///
  /// In sw, this message translates to:
  /// **'Jaribu akaunti ya demo'**
  String get tryDemoAccount;

  /// No description provided for @demoPinLabel.
  ///
  /// In sw, this message translates to:
  /// **'PIN ya demo: 1234'**
  String get demoPinLabel;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Arifa za kikundi na mfumo'**
  String get notificationsSubtitle;

  /// No description provided for @markAllRead.
  ///
  /// In sw, this message translates to:
  /// **'Soma zote'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna arifa kwa sasa'**
  String get noNotifications;

  /// No description provided for @filterUnread.
  ///
  /// In sw, this message translates to:
  /// **'Zisizosomwa'**
  String get filterUnread;

  /// No description provided for @meetingReminder.
  ///
  /// In sw, this message translates to:
  /// **'Kumbusho la mkutano'**
  String get meetingReminder;

  /// No description provided for @paymentReminder.
  ///
  /// In sw, this message translates to:
  /// **'Kumbusho la malipo'**
  String get paymentReminder;

  /// No description provided for @notificationDetail.
  ///
  /// In sw, this message translates to:
  /// **'Maelezo ya arifa'**
  String get notificationDetail;

  /// No description provided for @todayAt.
  ///
  /// In sw, this message translates to:
  /// **'Leo, {time}'**
  String todayAt(String time);

  /// No description provided for @newNotifications.
  ///
  /// In sw, this message translates to:
  /// **'Arifa mpya'**
  String get newNotifications;

  /// No description provided for @oldNotifications.
  ///
  /// In sw, this message translates to:
  /// **'Arifa zilizosomwa'**
  String get oldNotifications;

  /// No description provided for @showOldNotifications.
  ///
  /// In sw, this message translates to:
  /// **'Onyesha arifa za zamani ({n})'**
  String showOldNotifications(int n);

  /// No description provided for @hideOldNotifications.
  ///
  /// In sw, this message translates to:
  /// **'Ficha arifa za zamani'**
  String get hideOldNotifications;

  /// No description provided for @notificationOpened.
  ///
  /// In sw, this message translates to:
  /// **'Imefunguliwa'**
  String get notificationOpened;

  /// No description provided for @noNewNotifications.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna arifa mpya — zote zimesomwa'**
  String get noNewNotifications;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
