import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../core/auth/profile_provider.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';
import '../notifications/notification_icon_button.dart';

class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  ConsumerState<MemberDashboardScreen> createState() =>
      _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  String? _loadedSummaryGroupId;
  Future<ContributionReportResult>? _summaryFuture;

  Future<ContributionReportResult>? _summaryFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) return null;
    if (_loadedSummaryGroupId != groupId || _summaryFuture == null) {
      _setSummaryFuture(groupId);
    }
    return _summaryFuture;
  }

  void _setSummaryFuture(
    String groupId, [
    Future<ContributionReportResult>? future,
  ]) {
    _loadedSummaryGroupId = groupId;
    _summaryFuture =
        future ??
        ref.read(groupsRepositoryProvider).contributionReport(groupId);
  }

  Future<void> _refresh() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;
    final future = ref
        .read(groupsRepositoryProvider)
        .contributionReport(activeGroup.id);
    setState(() => _setSummaryFuture(activeGroup.id, future));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final activeGroup = ref.watch(activeGroupProvider);
    final displayName = ref.watch(profileDisplayNameProvider);
    final memberName = displayName.isEmpty ? loc.welcomeTitle : displayName;
    final groupName = activeGroup?.name ?? 'your group';
    final firstDueLabel = activeGroup == null
        ? loc.selectGroup
        : context.vt('Scheduled');

    return VikoplusScreen(
      title: activeGroup?.name ?? loc.memberPortal,
      bottomNavigationIndex: widget.showBottomNavigation ? 0 : null,
      showBottomNavigation: widget.showBottomNavigation,
      showBackButton: false,
      onRefresh: _refresh,
      actions: [
        const NotificationIconButton(),
        IconButton(
          tooltip: loc.myGroups,
          onPressed: () => context.go('/groups'),
          icon: const Icon(Icons.groups_2_outlined),
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
            memberName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ContributionSummaryCard(summaryFuture: _summaryFor(activeGroup?.id)),
          const SizedBox(height: AppSpacing.md),
          const _MemberQuickLinks(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.recentActivities,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/member/contributions'),
                child: Text(loc.viewHistory),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const _ActivityTile(
            title: 'Joined group',
            subtitle: 'Membership confirmed',
            value: 'Today',
            icon: Icons.group_add_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ActivityTile(
            title: 'First contribution due',
            subtitle: groupName,
            value: firstDueLabel,
            icon: Icons.event_available_outlined,
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

class _MemberQuickLinks extends StatelessWidget {
  const _MemberQuickLinks();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _MemberAction(
        title: 'Group members',
        subtitle: 'View fellow members in this group',
        icon: Icons.groups_2_outlined,
        route: '/member/members',
      ),
      _MemberAction(
        title: 'Seek loan',
        subtitle: 'Apply for support or track your loan requests',
        icon: Icons.account_balance_wallet_outlined,
        route: '/loans',
      ),
      _MemberAction(
        title: 'Switch groups',
        subtitle: 'Open another group, create one, or join by code',
        icon: Icons.hub_outlined,
        route: '/groups',
      ),
      _MemberAction(
        title: 'Update language',
        subtitle: 'Choose Kiswahili or English',
        icon: Icons.language_outlined,
        route: '/language',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions) ...[
          ActionTile(
            title: action.title,
            subtitle: action.subtitle,
            icon: action.icon,
            route: action.route,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MemberAction {
  const _MemberAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _ContributionSummaryCard extends StatelessWidget {
  const _ContributionSummaryCard({required this.summaryFuture});

  final Future<ContributionReportResult>? summaryFuture;

  @override
  Widget build(BuildContext context) {
    return _ContributionSummarySurface(
      child: summaryFuture == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthErrorMessage(
                  message: context.vt(
                    'Select a group to load your contribution summary.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => context.go('/groups'),
                  icon: const Icon(Icons.hub_outlined, size: 18),
                  label: Text(context.vt('Choose Group')),
                ),
              ],
            )
          : _LiveContributionSummary(summaryFuture: summaryFuture!),
    );
  }
}

class _LiveContributionSummary extends StatelessWidget {
  const _LiveContributionSummary({required this.summaryFuture});

  final Future<ContributionReportResult> summaryFuture;

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return FutureBuilder<ContributionReportResult>(
      future: summaryFuture,
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
          return AuthErrorMessage(
            message: context.vt('Could not load your contribution summary.'),
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
        final progress = paidMinor + outstandingMinor == 0
            ? 0.0
            : paidMinor / (paidMinor + outstandingMinor);

        return _ContributionSummaryContent(
          paid: formatters.money(paidMinor),
          outstanding: formatters.money(outstandingMinor),
          nextDue: outstandingMinor > 0 ? 'Pending' : 'Cleared',
          progress: progress,
          progressLabel: context.vtf('{count} paid', {'count': paidPeriods}),
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
                context.vt('Contribution Summary'),
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
          context.vt('Total Paid'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          paid,
          style: Theme.of(context).textTheme.displayLarge
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
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
                context.vt('Annual Goal Progress'),
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
          label: Text(context.vt('Make a Payment')),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.go('/member/contributions'),
          icon: const Icon(Icons.pending_actions_outlined, size: 18),
          label: Text(context.vt('View dues')),
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
          context.vt(label),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          context.vt(value),
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
                  context.vt(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.vt(subtitle),
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
            context.vt(value),
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
