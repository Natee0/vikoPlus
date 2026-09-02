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

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage group contributions with confidence'**
  String get welcomeTitle;

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
  /// **'Sofia Wajukuu'**
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
  /// **'July 2026 - June 2027'**
  String get financialYearValue;

  /// No description provided for @contributionRule.
  ///
  /// In en, this message translates to:
  /// **'Joining fee TZS 10,000 and monthly dues TZS 5,000'**
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
