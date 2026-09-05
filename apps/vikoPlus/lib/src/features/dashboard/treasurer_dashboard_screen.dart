import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/groups/groups_repository.dart';
import '../../core/formatters/app_formatters.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_logout_controls.dart';
import '../common/vikoplus_screen.dart';
import '../notifications/notification_icon_button.dart';

class TreasurerDashboardScreen extends ConsumerStatefulWidget {
  const TreasurerDashboardScreen({super.key});

  @override
  ConsumerState<TreasurerDashboardScreen> createState() =>
      _TreasurerDashboardState();
}

class _TreasurerDashboardState extends ConsumerState<TreasurerDashboardScreen> {
  String? _groupId;
  Future<(GroupDashboardResult, ContributionPaymentsResult)>? _future;

  Future<(GroupDashboardResult, ContributionPaymentsResult)> _load(
    String id,
  ) async {
    final repo = ref.read(groupsRepositoryProvider);
    final dashboard = await repo.dashboard(id);
    final payments = await repo.contributionPayments(id);
    return (dashboard, payments);
  }

  Future<void> _refresh() async {
    final id = ref.read(activeGroupProvider)?.id;
    if (id == null) return;
    final future = _load(id);
    setState(() => _future = future);
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
    return VikoplusScreen(
      title: group?.name ?? 'Treasurer',
      bottomNavigationIndex: 0,
      onRefresh: _refresh,
      actions: [
        const NotificationIconButton(),
        IconButton(
          tooltip: 'My groups',
          onPressed: () => context.go('/groups'),
          icon: const Icon(Icons.groups_outlined),
        ),
        const AuthLogoutIconButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hello, Treasurer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'Track collections and review member payments.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FutureBuilder<(GroupDashboardResult, ContributionPaymentsResult)>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text(
                      'Unable to load your dashboard. Please try again.',
                    ),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth < 320
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _Metric(
                            width: width,
                            label: 'Total contributions',
                            value: format.money(metrics.collectedMinor),
                            icon: Icons.account_balance_wallet_outlined,
                            primary: true,
                          ),
                          _Metric(
                            width: width,
                            label: 'Outstanding dues',
                            value: format.money(metrics.outstandingMinor),
                            icon: Icons.pending_actions_outlined,
                          ),
                          _Metric(
                            width: width,
                            label: 'Total members',
                            value: '${metrics.membersCount}',
                            icon: Icons.groups_outlined,
                          ),
                          _Metric(
                            width: width,
                            label: 'Payments to review',
                            value: '$pending',
                            icon: Icons.fact_check_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Collection overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    format.money(metrics.collectedMinor),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${format.compactPercent(progress)} collected',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: AppColors.progressTrack,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final action in const <(IconData, String, String)>[
                        (
                          Icons.add_card_outlined,
                          'Record payment',
                          '/contributions/record',
                        ),
                        (
                          Icons.fact_check_outlined,
                          'Review payments',
                          '/contributions',
                        ),
                        (
                          Icons.notifications_active_outlined,
                          'Send reminder',
                          '/reminders/new',
                        ),
                        (Icons.bar_chart_outlined, 'Reports', '/reports'),
                        (Icons.account_balance_outlined, 'My loans', '/loans'),
                        (
                          Icons.assignment_outlined,
                          'Loan reviews',
                          '/loans/applications',
                        ),
                      ])
                        SizedBox(
                          width: 140,
                          child: OutlinedButton(
                            onPressed: () => context.push(action.$3),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Icon(action.$1),
                                  const SizedBox(height: 8),
                                  Text(action.$2, textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent transactions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/contributions'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  if (payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No payments recorded yet.'),
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
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => context.push('/contributions'),
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
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.primary = false,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary ? AppColors.onPrimary : AppColors.onSurface;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label, style: TextStyle(color: color)),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
