import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../core/groups/groups_repository.dart';
import '../../core/loans/loans_repository.dart';
import '../../core/auth/profile_provider.dart';
import '../../core/formatters/app_formatters.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../common/vikoplus_screen.dart';
import '../common/vikoplus_components.dart';
import '../notifications/notification_icon_button.dart';

class TreasurerDashboardScreen extends ConsumerStatefulWidget {
  const TreasurerDashboardScreen({super.key});

  @override
  ConsumerState<TreasurerDashboardScreen> createState() =>
      _TreasurerDashboardState();
}

class _TreasurerDashboardState extends ConsumerState<TreasurerDashboardScreen> {
  String? _groupId;
  Future<
    (GroupDashboardResult, ContributionPaymentsResult, LoanApplicationsResult)
  >?
  _future;

  Future<
    (GroupDashboardResult, ContributionPaymentsResult, LoanApplicationsResult)
  >
  _load(String id) async {
    final repo = ref.read(groupsRepositoryProvider);
    final dashboard = await repo.dashboard(id);
    final payments = await repo.contributionPayments(id);
    final loans = await ref.read(loansRepositoryProvider).applications(id);
    return (dashboard, payments, loans);
  }

  Future<void> _refresh() async {
    final id = ref.read(activeGroupProvider)?.id;
    if (id == null) return;
    final future = _load(id);
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (_groupId != group?.id) {
      _groupId = group?.id;
      _future = group == null ? null : _load(group.id);
    }
    final format = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final displayName = ref.watch(profileDisplayNameProvider);
    final treasurerName = displayName.isEmpty
        ? AppLocalizations.of(context).welcomeTitle
        : displayName;
    return VikoplusScreen(
      title: group?.name ?? AppLocalizations.of(context).treasurerTitle,
      bottomNavigationIndex: 0,
      onRefresh: _refresh,
      actions: [
        const NotificationIconButton(),
        IconButton(
          tooltip: AppLocalizations.of(context).myGroups,
          onPressed: () => context.go('/groups'),
          icon: const Icon(Icons.groups_outlined),
        ),
        const AuthLogoutIconButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _timeGreeting(context),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            treasurerName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            AppLocalizations.of(context).treasurySummary,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<
            (
              GroupDashboardResult,
              ContributionPaymentsResult,
              LoanApplicationsResult,
            )
          >(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(AppLocalizations.of(context).dashboardLoadError),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context).retryAction),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final metrics = snapshot.data!.$1.metrics;
              final payments = [...snapshot.data!.$2.payments]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final pending = payments
                  .where(
                    (p) =>
                        p.status == 'SUBMITTED' ||
                        p.status == 'PENDING_VERIFICATION',
                  )
                  .length;
              final total = metrics.collectedMinor + metrics.outstandingMinor;
              final progress = total > 0
                  ? (metrics.collectedMinor / total).clamp(0.0, 1.0)
                  : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.onPrimaryContainer,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).totalContributions,
                                style: TextStyle(color: AppColors.onPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          format.money(metrics.collectedMinor),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text(
                              'Outstanding\n${format.compactMoney(metrics.outstandingMinor)}',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                              ),
                            ),
                            Text(
                              'Members\n${metrics.membersCount}',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                              ),
                            ),
                            Text(
                              'Awaiting review\n$pending',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppLocalizations.of(context).treasuryQueue,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ReviewQueue(
                    title: AppLocalizations.of(context).unreviewedPayments,
                    count: pending,
                    icon: Icons.fact_check_outlined,
                    route: '/contributions',
                    color: AppColors.tertiaryFixed,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ReviewQueue(
                    title: AppLocalizations.of(context).pendingLoanApplications,
                    count: snapshot.data!.$3.applications
                        .where((loan) => loan.status == 'SUBMITTED')
                        .length,
                    icon: Icons.assignment_outlined,
                    route: '/loans/applications',
                    color: AppColors.progressTrack,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppLocalizations.of(context).collectionOverview,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    format.money(metrics.collectedMinor),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${format.compactPercent(progress)} collected',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: AppSpacing.xs,
                    borderRadius: BorderRadius.circular(AppRadii.base),
                    backgroundColor: AppColors.progressTrack,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppLocalizations.of(context).treasuryOperations,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ActionTile(
                    title: AppLocalizations.of(context).recordPayment,
                    subtitle: AppLocalizations.of(context)
                        .allocatePaymentDescription,
                    icon: Icons.add_card_outlined,
                    route: '/contributions/record',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ActionTile(
                    title: context.vt('Group expenses'),
                    subtitle: context.vt('Record group spending for approval'),
                    icon: Icons.receipt_long_outlined,
                    route: '/expenses',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ActionTile(
                    title: AppLocalizations.of(context).reviewPayments,
                    subtitle: AppLocalizations.of(context).verifyMemberPayments,
                    icon: Icons.fact_check_outlined,
                    route: '/contributions',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ActionTile(
                    title: AppLocalizations.of(context).sendReminder,
                    subtitle: AppLocalizations.of(context)
                        .contactOutstandingMembers,
                    icon: Icons.notifications_active_outlined,
                    route: '/reminders/new',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ActionTile(
                    title: AppLocalizations.of(context).myLoans,
                    subtitle: AppLocalizations.of(context).trackBorrowing,
                    icon: Icons.account_balance_outlined,
                    route: '/loans',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ActionTile(
                    title: AppLocalizations.of(context).loanReviews,
                    subtitle: AppLocalizations.of(context)
                        .reviewLoanDescription,
                    icon: Icons.assignment_outlined,
                    route: '/loans/applications',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).treasuryActivity,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/contributions'),
                        child: Text(AppLocalizations.of(context).viewAll),
                      ),
                    ],
                  ),
                  if (payments.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(AppLocalizations.of(context).noPaymentsYet),
                    ),
                  for (final payment in payments.take(5))
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.progressTrack,
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(payment.memberName),
                        subtitle: Text(
                          '${format.money(payment.amountMinor, currency: payment.currency)}\n${format.date(payment.paidAt ?? payment.createdAt)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          payment.status.replaceAll('_', ' ').toLowerCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                        onTap: () => context.go('/contributions'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _timeGreeting(BuildContext context) {
    final isSwahili = Localizations.localeOf(context).languageCode == 'sw';
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isSwahili ? 'Habari za asubuhi,' : 'Good morning,';
    }
    if (hour < 17) {
      return isSwahili ? 'Habari za mchana,' : 'Good afternoon,';
    }
    return isSwahili ? 'Habari za jioni,' : 'Good evening,';
  }
}

class _ReviewQueue extends StatelessWidget {
  const _ReviewQueue({
    required this.title,
    required this.count,
    required this.icon,
    required this.route,
    required this.color,
  });
  final String title;
  final int count;
  final IconData icon;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.base),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.base),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      count == 0
                          ? AppLocalizations.of(context).nothingAwaitingReview
                          : '$count awaiting review',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
