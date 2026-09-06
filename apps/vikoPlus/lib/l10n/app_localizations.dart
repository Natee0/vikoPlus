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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'vikoPlus'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Group contributions, made clear.'**
  String get splashTagline;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage group contributions with confidence'**
  String get onboardingWelcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track joining fees, monthly dues, receipts, reminders, reports and subscription access from one secure Android app.'**
  String get welcomeBody;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get languageSwahili;

  /// No description provided for @languageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get languageSaved;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Vikoplus plan'**
  String get plansTitle;

  /// No description provided for @plansBody.
  ///
  /// In en, this message translates to:
  /// **'Platform access uses automatic payment only. Group contribution payments are recorded separately inside each group.'**
  String get plansBody;

  /// No description provided for @starterPlanName.
  ///
  /// In en, this message translates to:
  /// **'Starter Monthly'**
  String get starterPlanName;

  /// No description provided for @starterPlanBody.
  ///
  /// In en, this message translates to:
  /// **'For family and small community groups.'**
  String get starterPlanBody;

  /// No description provided for @growthPlanName.
  ///
  /// In en, this message translates to:
  /// **'Growth Annual'**
  String get growthPlanName;

  /// No description provided for @growthPlanBody.
  ///
  /// In en, this message translates to:
  /// **'For larger groups that need audit history and reporting.'**
  String get growthPlanBody;

  /// No description provided for @automaticPayment.
  ///
  /// In en, this message translates to:
  /// **'Automatic payment'**
  String get automaticPayment;

  /// No description provided for @startCheckout.
  ///
  /// In en, this message translates to:
  /// **'Start secure checkout'**
  String get startCheckout;

  /// No description provided for @billingOverview.
  ///
  /// In en, this message translates to:
  /// **'Billing overview'**
  String get billingOverview;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription active'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial access'**
  String get subscriptionStatusTrial;

  /// No description provided for @nextBillingDate.
  ///
  /// In en, this message translates to:
  /// **'Next automatic payment'**
  String get nextBillingDate;

  /// No description provided for @cancelRenewal.
  ///
  /// In en, this message translates to:
  /// **'Cancel renewal'**
  String get cancelRenewal;

  /// No description provided for @resumeRenewal.
  ///
  /// In en, this message translates to:
  /// **'Resume renewal'**
  String get resumeRenewal;

  /// No description provided for @updatePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Update payment method'**
  String get updatePaymentMethod;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @totalContributions.
  ///
  /// In en, this message translates to:
  /// **'Total contributions'**
  String get totalContributions;

  /// No description provided for @joiningFees.
  ///
  /// In en, this message translates to:
  /// **'Joining fees'**
  String get joiningFees;

  /// No description provided for @monthlyFees.
  ///
  /// In en, this message translates to:
  /// **'Monthly fees'**
  String get monthlyFees;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @financialYear.
  ///
  /// In en, this message translates to:
  /// **'Financial year'**
  String get financialYear;

  /// No description provided for @financialYearValue.
  ///
  /// In en, this message translates to:
  /// **'Current financial year'**
  String get financialYearValue;

  /// No description provided for @contributionRule.
  ///
  /// In en, this message translates to:
  /// **'Contribution rules come from the active group setup.'**
  String get contributionRule;

  /// No description provided for @billingNotice.
  ///
  /// In en, this message translates to:
  /// **'Billing controls Vikoplus access. Contributions remain group financial records.'**
  String get billingNotice;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlans;

  /// No description provided for @viewDashboard.
  ///
  /// In en, this message translates to:
  /// **'View dashboard'**
  String get viewDashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accessibilityOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get accessibilityOpenSettings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @registerTab.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTab;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInTitle;

  /// No description provided for @identifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number or email'**
  String get identifierLabel;

  /// No description provided for @identifierHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your detail'**
  String get identifierHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @changeLanguageLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later from app settings.'**
  String get changeLanguageLater;

  /// No description provided for @reportFilters.
  ///
  /// In en, this message translates to:
  /// **'Report Filters'**
  String get reportFilters;

  /// No description provided for @memberStatus.
  ///
  /// In en, this message translates to:
  /// **'Member status'**
  String get memberStatus;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export format'**
  String get exportFormat;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @chooseGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose Group'**
  String get chooseGroup;

  /// No description provided for @configureFinancialYear.
  ///
  /// In en, this message translates to:
  /// **'Configure Financial Year'**
  String get configureFinancialYear;

  /// No description provided for @memberProfile.
  ///
  /// In en, this message translates to:
  /// **'Member Profile'**
  String get memberProfile;

  /// No description provided for @memberNumber.
  ///
  /// In en, this message translates to:
  /// **'Member number'**
  String get memberNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @assignRole.
  ///
  /// In en, this message translates to:
  /// **'Assign Role'**
  String get assignRole;

  /// No description provided for @updatingRole.
  ///
  /// In en, this message translates to:
  /// **'Updating role'**
  String get updatingRole;

  /// No description provided for @suspendMember.
  ///
  /// In en, this message translates to:
  /// **'Suspend member'**
  String get suspendMember;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @restoreAccess.
  ///
  /// In en, this message translates to:
  /// **'Restore access'**
  String get restoreAccess;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @usePhone.
  ///
  /// In en, this message translates to:
  /// **'Use Phone Instead'**
  String get usePhone;

  /// No description provided for @useEmail.
  ///
  /// In en, this message translates to:
  /// **'Use Email Instead'**
  String get useEmail;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters long.'**
  String get passwordLength;

  /// No description provided for @communityJoin.
  ///
  /// In en, this message translates to:
  /// **'Join the modern financial community.'**
  String get communityJoin;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeTerms;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy.'**
  String get privacy;

  /// No description provided for @emailVerifyNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a secure verification code to this email.'**
  String get emailVerifyNote;

  /// No description provided for @verifyNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this for secure verification.'**
  String get verifyNote;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @selectGroupTools.
  ///
  /// In en, this message translates to:
  /// **'Select a group to load live administration tools.'**
  String get selectGroupTools;

  /// No description provided for @manageGroupSummary.
  ///
  /// In en, this message translates to:
  /// **'Manage contributions, members, loans and reminders.'**
  String get manageGroupSummary;

  /// No description provided for @monthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get monthlyTrend;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @allocatePaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Allocate a contribution across one or more periods'**
  String get allocatePaymentDescription;

  /// No description provided for @memberReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Review balances, roles and contact details'**
  String get memberReviewDescription;

  /// No description provided for @loanReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Borrowing power, active loans and repayment tracking'**
  String get loanReviewDescription;

  /// No description provided for @reportReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'View outstanding dues and member analysis'**
  String get reportReviewDescription;

  /// No description provided for @reminderCentre.
  ///
  /// In en, this message translates to:
  /// **'Reminder Centre'**
  String get reminderCentre;

  /// No description provided for @reminderReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Create campaigns, templates and delivery tracking'**
  String get reminderReviewDescription;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin settings'**
  String get adminSettings;

  /// No description provided for @adminSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Roles, fees, penalties, security and audit logs'**
  String get adminSettingsDescription;

  /// No description provided for @switchGroupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch groups, create another group or join by invitation'**
  String get switchGroupsDescription;

  /// No description provided for @contributionSetup.
  ///
  /// In en, this message translates to:
  /// **'Contribution setup'**
  String get contributionSetup;

  /// No description provided for @contributionSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Set joining fee, membership contribution and payment rules'**
  String get contributionSetupDescription;

  /// No description provided for @historicalRecords.
  ///
  /// In en, this message translates to:
  /// **'Historical records'**
  String get historicalRecords;

  /// No description provided for @historicalRecordsDescription.
  ///
  /// In en, this message translates to:
  /// **'Import old contribution data one by one or in bulk'**
  String get historicalRecordsDescription;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @memberPortal.
  ///
  /// In en, this message translates to:
  /// **'Member Portal'**
  String get memberPortal;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select a group'**
  String get selectGroup;

  /// No description provided for @checkContributionBalance.
  ///
  /// In en, this message translates to:
  /// **'Check your current contribution balance'**
  String get checkContributionBalance;

  /// No description provided for @switchCreateJoin.
  ///
  /// In en, this message translates to:
  /// **'Switch, create or join group'**
  String get switchCreateJoin;

  /// No description provided for @treasurerTitle.
  ///
  /// In en, this message translates to:
  /// **'Treasurer'**
  String get treasurerTitle;

  /// No description provided for @treasurySummary.
  ///
  /// In en, this message translates to:
  /// **'Track collections and review member payments.'**
  String get treasurySummary;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your dashboard. Please try again.'**
  String get dashboardLoadError;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @treasuryQueue.
  ///
  /// In en, this message translates to:
  /// **'Urgent treasury queue'**
  String get treasuryQueue;

  /// No description provided for @unreviewedPayments.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed payments'**
  String get unreviewedPayments;

  /// No description provided for @pendingLoanApplications.
  ///
  /// In en, this message translates to:
  /// **'Pending loan applications'**
  String get pendingLoanApplications;

  /// No description provided for @collectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Collection overview'**
  String get collectionOverview;

  /// No description provided for @treasuryOperations.
  ///
  /// In en, this message translates to:
  /// **'Treasury operations'**
  String get treasuryOperations;

  /// No description provided for @reviewPayments.
  ///
  /// In en, this message translates to:
  /// **'Review payments'**
  String get reviewPayments;

  /// No description provided for @verifyMemberPayments.
  ///
  /// In en, this message translates to:
  /// **'Verify submitted member payments'**
  String get verifyMemberPayments;

  /// No description provided for @contactOutstandingMembers.
  ///
  /// In en, this message translates to:
  /// **'Contact members about outstanding dues'**
  String get contactOutstandingMembers;

  /// No description provided for @myLoans.
  ///
  /// In en, this message translates to:
  /// **'My loans'**
  String get myLoans;

  /// No description provided for @trackBorrowing.
  ///
  /// In en, this message translates to:
  /// **'View borrowing power and track repayments'**
  String get trackBorrowing;

  /// No description provided for @loanReviews.
  ///
  /// In en, this message translates to:
  /// **'Loan reviews'**
  String get loanReviews;

  /// No description provided for @reviewLoanDescription.
  ///
  /// In en, this message translates to:
  /// **'Review applications and guarantor confirmations'**
  String get reviewLoanDescription;

  /// No description provided for @treasuryActivity.
  ///
  /// In en, this message translates to:
  /// **'Live treasury activity'**
  String get treasuryActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get noPaymentsYet;

  /// No description provided for @nothingAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing awaiting review'**
  String get nothingAwaitingReview;
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
