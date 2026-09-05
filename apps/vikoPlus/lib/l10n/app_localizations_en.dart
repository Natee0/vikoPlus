// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'vikoPlus';

  @override
  String get splashTagline => 'Group contributions, made clear.';

  @override
  String get continueAction => 'Continue';

  @override
  String get welcomeTitle => 'Manage group contributions with confidence';

  @override
  String get welcomeBody =>
      'Track joining fees, monthly dues, receipts, reminders, reports and subscription access from one secure Android app.';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Swahili';

  @override
  String get languageSaved => 'Language saved';

  @override
  String get plansTitle => 'Choose a Vikoplus plan';

  @override
  String get plansBody =>
      'Platform access uses automatic payment only. Group contribution payments are recorded separately inside each group.';

  @override
  String get starterPlanName => 'Starter Monthly';

  @override
  String get starterPlanBody => 'For family and small community groups.';

  @override
  String get growthPlanName => 'Growth Annual';

  @override
  String get growthPlanBody =>
      'For larger groups that need audit history and reporting.';

  @override
  String get automaticPayment => 'Automatic payment';

  @override
  String get startCheckout => 'Start secure checkout';

  @override
  String get billingOverview => 'Billing overview';

  @override
  String get subscriptionStatusActive => 'Subscription active';

  @override
  String get subscriptionStatusTrial => 'Trial access';

  @override
  String get nextBillingDate => 'Next automatic payment';

  @override
  String get cancelRenewal => 'Cancel renewal';

  @override
  String get resumeRenewal => 'Resume renewal';

  @override
  String get updatePaymentMethod => 'Update payment method';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get totalContributions => 'Total contributions';

  @override
  String get joiningFees => 'Joining fees';

  @override
  String get monthlyFees => 'Monthly fees';

  @override
  String get members => 'Members';

  @override
  String get financialYear => 'Financial year';

  @override
  String get financialYearValue => 'Current financial year';

  @override
  String get contributionRule =>
      'Contribution rules come from the active group setup.';

  @override
  String get billingNotice =>
      'Billing controls Vikoplus access. Contributions remain group financial records.';

  @override
  String get viewPlans => 'View plans';

  @override
  String get viewDashboard => 'View dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get accessibilityOpenSettings => 'Open settings';
}
