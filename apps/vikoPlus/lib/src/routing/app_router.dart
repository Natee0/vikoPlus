import 'package:go_router/go_router.dart';

import '../features/auth/create_account_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/verify_account_screen.dart';
import '../features/billing/billing_overview_screen.dart';
import '../features/billing/subscription_plan_screen.dart';
import '../features/contributions/contribution_register_screen.dart';
import '../features/contributions/digital_receipt_screen.dart';
import '../features/contributions/record_payment_screen.dart';
import '../features/contributions/record_payment_select_member_screen.dart';
import '../features/dashboard/admin_dashboard_screen.dart';
import '../features/dashboard/admin_tab_shell_screen.dart';
import '../features/dashboard/dashboard_empty_state_screen.dart';
import '../features/dashboard/member_dashboard_screen.dart';
import '../features/dashboard/member_tab_shell_screen.dart';
import '../features/groups/verify_group_details_screen.dart';
import '../features/groups/configure_contributions_screen.dart';
import '../features/groups/configure_financial_year_screen.dart';
import '../features/groups/configure_reminders_screen.dart';
import '../features/groups/create_group_screen.dart';
import '../features/groups/create_or_join_group_screen.dart';
import '../features/groups/historical_records_screen.dart';
import '../features/groups/join_group_invitation_screen.dart';
import '../features/groups/my_groups_screen.dart';
import '../features/groups/onboarding_success_screen.dart';
import '../features/member/member_flow_screens.dart';
import '../features/members/add_member_screen.dart';
import '../features/members/invite_members_screen.dart';
import '../features/members/member_list_screen.dart';
import '../features/members/member_profile_screen.dart';
import '../features/loans/loan_screens.dart';
import '../features/more/more_menu_screen.dart';
import '../features/more/stitch_screen_catalog_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/profile/complete_profile_screen.dart';
import '../features/reminders/reminder_detail_screens.dart';
import '../features/reminders/reminder_centre_screen.dart';
import '../features/reports/member_analysis_screen.dart';
import '../features/reports/outstanding_report_screen.dart';
import '../features/reports/report_filters_screen.dart';
import '../features/reports/reports_dashboard_screen.dart';
import '../features/settings/settings_screens.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/create-account',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/verify-account',
      builder: (context, state) {
        final nextRoute =
            state.uri.queryParameters['next'] ?? '/create-or-join-group';
        final backRoute =
            state.uri.queryParameters['back'] ?? '/create-account';
        return VerifyAccountScreen(
          nextRoute: nextRoute,
          backRoute: backRoute,
          challengeId: state.uri.queryParameters['challengeId'],
          destination: state.uri.queryParameters['destination'],
          channel: state.uri.queryParameters['channel'],
        );
      },
    ),
    GoRoute(
      path: '/create-or-join-group',
      builder: (context, state) => const CreateOrJoinGroupScreen(),
    ),
    GoRoute(
      path: '/groups/create',
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/groups/join',
      builder: (context, state) => const JoinGroupInvitationScreen(),
    ),
    GoRoute(
      path: '/groups',
      builder: (context, state) => const MyGroupsScreen(),
    ),
    GoRoute(
      path: '/groups/verify',
      builder: (context, state) => const VerifyGroupDetailsScreen(),
    ),
    GoRoute(
      path: '/groups/financial-year',
      builder: (context, state) => const ConfigureFinancialYearScreen(),
    ),
    GoRoute(
      path: '/groups/financial-year/start',
      builder: (context, state) => const ConfigureFinancialYearScreen(),
    ),
    GoRoute(
      path: '/groups/financial-year/review',
      builder: (context, state) => const ConfigureFinancialYearScreen(),
    ),
    GoRoute(
      path: '/groups/contributions',
      builder: (context, state) => const ConfigureContributionsScreen(),
    ),
    GoRoute(
      path: '/groups/history',
      builder: (context, state) => const HistoricalRecordsScreen(),
    ),
    GoRoute(
      path: '/groups/reminders',
      builder: (context, state) => const ConfigureRemindersScreen(),
    ),
    GoRoute(
      path: '/groups/onboarding-success',
      builder: (context, state) => const OnboardingSuccessScreen(),
    ),
    GoRoute(
      path: '/billing/plans',
      builder: (context, state) => const SubscriptionPlanScreen(),
    ),
    GoRoute(
      path: '/billing',
      builder: (context, state) => const BillingOverviewScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdminTabShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) =>
                  const AdminDashboardScreen(showBottomNavigation: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/members',
              builder: (context, state) =>
                  const MemberListScreen(showBottomNavigation: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/contributions',
              builder: (context, state) =>
                  const ContributionRegisterScreen(showBottomNavigation: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) =>
                  const ReportsDashboardScreen(showBottomNavigation: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) =>
                  const MoreMenuScreen(showBottomNavigation: false),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/dashboard/empty',
      builder: (context, state) => const DashboardEmptyStateScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MemberTabShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/member/dashboard',
              builder: (context, state) =>
                  const MemberDashboardScreen(showBottomNavigation: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/member/contributions',
              builder: (context, state) =>
                  const MyContributionsScreen(showBackButton: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/member/payments/select',
              builder: (context, state) =>
                  const SelectContributionScreen(showBackButton: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/member/profile',
              builder: (context, state) =>
                  const MyProfileScreen(showBackButton: false),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/member/dashboard/new',
      builder: (context, state) => const MemberDashboardNewUserScreen(),
    ),
    GoRoute(
      path: '/member/dues',
      builder: (context, state) => const DuesArrearsScreen(),
    ),
    GoRoute(
      path: '/loans',
      builder: (context, state) => const LoansOverviewScreen(),
    ),
    GoRoute(
      path: '/loans/apply',
      builder: (context, state) => const ApplyForLoanScreen(),
    ),
    GoRoute(
      path: '/loans/repayment',
      builder: (context, state) => const LoanRepaymentScreen(),
    ),
    GoRoute(
      path: '/loans/applications',
      builder: (context, state) => const LoanApplicationsScreen(),
    ),
    GoRoute(
      path: '/loans/applications/:id',
      builder: (context, state) => LoanApplicationReviewScreen(
        applicationId: state.pathParameters['id'] ?? 'david-kiprop',
      ),
    ),
    GoRoute(
      path: '/member/payments/method',
      builder: (context, state) => const PaymentMethodScreen(),
    ),
    GoRoute(
      path: '/member/payments/review',
      builder: (context, state) => const ReviewPaymentScreen(),
    ),
    GoRoute(
      path: '/member/payments/review/mobile-money',
      builder: (context, state) =>
          const ReviewPaymentScreen(method: 'Mobile money'),
    ),
    GoRoute(
      path: '/member/payments/review/cash',
      builder: (context, state) =>
          const ReviewPaymentScreen(method: 'Cash to treasurer'),
    ),
    GoRoute(
      path: '/member/payments/success',
      builder: (context, state) => const PaymentSuccessfulScreen(),
    ),
    GoRoute(
      path: '/member/payments/success/mobile-money',
      builder: (context, state) =>
          const PaymentSuccessfulScreen(method: 'Mobile money'),
    ),
    GoRoute(
      path: '/member/payments/success/cash',
      builder: (context, state) =>
          const PaymentSuccessfulScreen(method: 'Cash to treasurer'),
    ),
    GoRoute(
      path: '/member/receipts/:id',
      builder: (context, state) => const DigitalReceiptScreen(),
    ),
    GoRoute(
      path: '/members/invite',
      builder: (context, state) => const InviteMembersScreen(),
    ),
    GoRoute(
      path: '/members/add',
      builder: (context, state) => const AddMemberScreen(),
    ),
    GoRoute(
      path: '/members/:id/fully-paid',
      builder: (context, state) {
        return MemberProfileScreen(memberId: state.pathParameters['id']);
      },
    ),
    GoRoute(
      path: '/members/:id/outstanding',
      builder: (context, state) {
        return MemberProfileScreen(memberId: state.pathParameters['id']);
      },
    ),
    GoRoute(
      path: '/members/:id',
      builder: (context, state) {
        return MemberProfileScreen(memberId: state.pathParameters['id']);
      },
    ),
    GoRoute(
      path: '/contributions/record',
      builder: (context, state) => const RecordPaymentSelectMemberScreen(),
    ),
    GoRoute(
      path: '/contributions/record/select-member',
      builder: (context, state) => const RecordPaymentSelectMemberScreen(),
    ),
    GoRoute(
      path: '/contributions/record/details',
      builder: (context, state) => const RecordPaymentScreen(),
    ),
    GoRoute(
      path: '/contributions/receipt',
      builder: (context, state) => const DigitalReceiptScreen(),
    ),
    GoRoute(
      path: '/contributions/receipt/:id',
      builder: (context, state) => const DigitalReceiptScreen(),
    ),
    GoRoute(
      path: '/reports/outstanding',
      builder: (context, state) => const OutstandingReportScreen(),
    ),
    GoRoute(
      path: '/reports/member-analysis',
      builder: (context, state) => const MemberAnalysisScreen(),
    ),
    GoRoute(
      path: '/reports/filters',
      builder: (context, state) => const ReportFiltersScreen(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const ReminderCentreScreen(),
    ),
    GoRoute(
      path: '/reminders/new',
      builder: (context, state) => const SendNewReminderScreen(),
    ),
    GoRoute(
      path: '/reminders/templates',
      builder: (context, state) => const MessageTemplatesScreen(),
    ),
    GoRoute(
      path: '/reminders/campaigns/:id',
      builder: (context, state) => const CampaignDetailsScreen(),
    ),
    GoRoute(
      path: '/settings/admin',
      builder: (context, state) => const AdminSettingsDashboardScreen(),
    ),
    GoRoute(
      path: '/settings/app',
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/security/pin',
      builder: (context, state) => const ChangeSecurityPinScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationPreferencesScreen(),
    ),
    GoRoute(
      path: '/settings/roles',
      builder: (context, state) => const MemberRolesPermissionsScreen(),
    ),
    GoRoute(
      path: '/settings/audit',
      builder: (context, state) => const AuditLogsScreen(),
    ),
    GoRoute(
      path: '/settings/currency-fees',
      builder: (context, state) => const CurrencyFeesScreen(),
    ),
    GoRoute(
      path: '/settings/contribution-penalties',
      builder: (context, state) => const ContributionPenaltiesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile/complete',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/stitch-screens',
      builder: (context, state) => const StitchScreenCatalogScreen(),
    ),
  ],
);
