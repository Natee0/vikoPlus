import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.screenMobile),
          child: CircleAvatar(
            backgroundColor: AppColors.surfaceContainerHigh,
            child: Icon(Icons.person_outline, color: AppColors.primary),
          ),
        ),
        title: Text(
          'Member Portal',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'My groups',
            onPressed: () => context.go('/groups'),
            icon: const Icon(Icons.groups_2_outlined),
          ),
          const AuthLogoutIconButton(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMobile,
            AppSpacing.md,
            AppSpacing.screenMobile,
            104,
          ),
          children: [
            Text(
              'Good morning,',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Amina Issa',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ContributionSummaryCard(groupId: activeGroup?.id),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Activities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/member/contributions'),
                  child: const Text('View History'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const _ActivityTile(
              title: 'Joined Sofia Wajukuu',
              subtitle: 'Membership confirmed',
              value: 'Today',
              icon: Icons.group_add_outlined,
            ),
            const SizedBox(height: AppSpacing.xs),
            const _ActivityTile(
              title: 'First contribution due',
              subtitle: 'Monthly contribution',
              value: 'TZS 5,000',
              icon: Icons.event_available_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.go('/groups'),
              icon: const Icon(Icons.hub_outlined, size: 18),
              label: const Text('Switch, create or join group'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => context.go('/loans'),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text('Loans'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNavigation
          ? NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (index) {
                if (index == 0) return;

                switch (index) {
                  case 1:
                    context.go('/member/contributions');
                    break;
                  case 2:
                    context.go('/member/payments/select');
                    break;
                  case 3:
                    context.go('/member/profile');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments),
                  label: 'Payments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ],
            )
          : null,
    );
  }
}

class _ContributionSummaryCard extends StatelessWidget {
  const _ContributionSummaryCard({required this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return _ContributionSummarySurface(
      child: groupId == null || groupId!.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthErrorMessage(
                  message: 'Select a group to load your contribution summary.',
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => context.go('/groups'),
                  icon: const Icon(Icons.hub_outlined, size: 18),
                  label: const Text('Choose Group'),
                ),
              ],
            )
          : _LiveContributionSummary(groupId: groupId!),
    );
  }
}

class _LiveContributionSummary extends ConsumerWidget {
  const _LiveContributionSummary({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return FutureBuilder<ContributionReportResult>(
      future: ref.read(groupsRepositoryProvider).contributionReport(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const AuthErrorMessage(
            message: 'Could not load your contribution summary.',
          );
        }
        final report = snapshot.data!;
        final member = report.memberAnalysis.isEmpty
            ? null
            : report.memberAnalysis.first;
        final paidMinor = member?.totalPaidMinor ?? report.totalPaidMinor;
        final outstandingMinor =
            member?.outstandingMinor ?? report.totalOutstandingMinor;
        final paidPeriods = member?.paidRecurringPeriods ?? 0;
        final progress =
            paidMinor + outstandingMinor == 0
                ? 0.0
                : paidMinor / (paidMinor + outstandingMinor);

        return _ContributionSummaryContent(
          paid: formatters.money(paidMinor),
          outstanding: formatters.money(outstandingMinor),
          nextDue: outstandingMinor > 0 ? 'Pending' : 'Cleared',
          progress: progress,
          progressLabel: '$paidPeriods paid',
        );
      },
    );
  }
}

class _ContributionSummaryContent extends StatelessWidget {
  const _ContributionSummaryContent({
    required this.paid,
    required this.outstanding,
    required this.nextDue,
    required this.progress,
    required this.progressLabel,
  });

  final String paid;
  final String outstanding;
  final String nextDue;
  final double progress;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contribution Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Total Paid',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            paid,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Outstanding Balance',
                  value: outstanding,
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  label: 'Next Due',
                  value: nextDue,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Annual Goal Progress',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              Text(
                progressLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0, 1),
              backgroundColor: AppColors.progressTrack,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/member/payments/select'),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Make a Payment'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.go('/member/contributions'),
            icon: const Icon(Icons.pending_actions_outlined, size: 18),
            label: const Text('View dues'),
          ),
      ],
    );
  }
}

class _ContributionSummarySurface extends StatelessWidget {
  const _ContributionSummarySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
