import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/roles/vikoplus_role.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({this.memberId, super.key});

  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    if (activeGroup != null && memberId != null) {
      return _ApiMemberProfile(groupId: activeGroup.id, memberId: memberId!);
    }

    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final member = sofiaMembers.firstWhere(
      (item) => item.number == memberId,
      orElse: () => sofiaMembers[4],
    );

    return VikoplusScreen(
      title: member.fullyPaid ? 'Member Profile' : 'Member Details',
      backRoute: '/members',
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit member',
        ),
      ],
      child: member.fullyPaid
          ? _FullyPaidProfile(member: member, formatter: formatter)
          : _OutstandingProfile(member: member, formatter: formatter),
    );
  }
}

class _ApiMemberProfile extends ConsumerStatefulWidget {
  const _ApiMemberProfile({required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  ConsumerState<_ApiMemberProfile> createState() => _ApiMemberProfileState();
}

class _ApiMemberProfileState extends ConsumerState<_ApiMemberProfile> {
  late Future<GroupMemberSummary> _memberFuture;
  String _errorMessage = '';
  bool _isAssigningRole = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _memberFuture = ref
        .read(groupsRepositoryProvider)
        .member(widget.groupId, widget.memberId);
  }

  String _apiRole(VikoplusRole role) {
    return switch (role) {
      VikoplusRole.chairperson => 'GROUP_ADMIN',
      VikoplusRole.treasurer => 'TREASURER',
      VikoplusRole.secretary => 'SECRETARY',
      VikoplusRole.member => 'MEMBER',
      VikoplusRole.newUser => 'MEMBER',
    };
  }

  VikoplusRole _roleFromApi(String role) {
    return switch (role) {
      'GROUP_ADMIN' => VikoplusRole.chairperson,
      'TREASURER' => VikoplusRole.treasurer,
      'SECRETARY' => VikoplusRole.secretary,
      _ => VikoplusRole.member,
    };
  }

  Future<void> _assignRole(GroupMemberSummary member) async {
    final selected = await showModalBottomSheet<VikoplusRole>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMobile,
              AppSpacing.sm,
              AppSpacing.screenMobile,
              AppSpacing.md,
            ),
            children: [
              Text(
                'Assign Role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<VikoplusRole>(
                groupValue: _roleFromApi(member.role),
                onChanged: (value) => Navigator.of(context).pop(value),
                child: Column(
                  children: [
                    for (final role in VikoplusRole.values.where(
                      (role) => role != VikoplusRole.newUser,
                    ))
                      RadioListTile<VikoplusRole>(
                        value: role,
                        title: Text(role.label),
                        subtitle: Text(role.description),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || _isAssigningRole) return;

    try {
      setState(() {
        _errorMessage = '';
        _isAssigningRole = true;
      });
      await ref.read(groupsRepositoryProvider).assignRole(
            widget.groupId,
            member.id,
            _apiRole(selected),
          );
      if (!mounted) return;
      setState(_reload);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isAssigningRole = false);
      }
    }
  }

  String _roleLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _initials(String fullName) {
    final initials = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? 'M' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Member Profile',
      backRoute: '/members',
      actions: [
        IconButton(
          onPressed: _isAssigningRole ? null : () {},
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit member',
        ),
      ],
      child: FutureBuilder<GroupMemberSummary>(
        future: _memberFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthErrorMessage(
                  message: AuthFailure.from(snapshot.error!).message,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            );
          }

          final member = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SurfacePanel(
                padding: AppInsets.card,
                child: Column(
                  children: [
                    InitialsAvatar(initials: _initials(member.fullName)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      member.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusPill(label: _roleLabel(member.role)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (member.phone != null)
                          _InlineInfo(
                            icon: Icons.phone_outlined,
                            label: member.phone!,
                          ),
                        if (member.email != null)
                          _InlineInfo(
                            icon: Icons.mail_outline,
                            label: member.email!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthErrorMessage(message: _errorMessage),
              if (_errorMessage.isNotEmpty) const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isAssigningRole ? null : () => _assignRole(member),
                icon: _isAssigningRole
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.admin_panel_settings_outlined),
                label: Text(_isAssigningRole ? 'Updating role' : 'Assign Role'),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => context.go(
                  '/reminders/new?memberId=${Uri.encodeComponent(member.id)}',
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Reminder'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '/contributions/record/details?memberId=${Uri.encodeComponent(member.id)}',
                ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FullyPaidProfile extends StatelessWidget {
  const _FullyPaidProfile({required this.member, required this.formatter});

  final SofiaMember member;
  final AppFormatters formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(
          member: member,
          status: 'Member',
          statusColor: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ProfileMetric(
                label: 'Total Paid',
                value: formatter.money(member.totalPaid),
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: _ProfileMetric(
                label: 'Joining Fee',
                value: 'Paid',
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _AttendanceCard(),
        const SizedBox(height: AppSpacing.md),
        _MonthlyContributionsGrid(paidMonths: member.paidMonths),
        const SizedBox(height: AppSpacing.md),
        const _RecentTransactionsCard(),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'Admin Actions'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/settings/roles'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Assign Role'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/reminders/new'),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Reminder'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: () => context.go('/contributions/record/details'),
          icon: const Icon(Icons.add_card_outlined),
          label: const Text('Record Payment'),
        ),
      ],
    );
  }
}

class _OutstandingProfile extends StatelessWidget {
  const _OutstandingProfile({required this.member, required this.formatter});

  final SofiaMember member;
  final AppFormatters formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(
          member: member,
          status: 'Action Required',
          statusColor: AppColors.error,
        ),
        const SizedBox(height: AppSpacing.md),
        _OutstandingBalanceCard(amount: formatter.money(member.outstanding)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ProfileMetric(
                label: 'Joining Fee',
                value: member.joiningPaid > 0 ? 'Paid' : 'Due',
                icon: member.joiningPaid > 0
                    ? Icons.task_alt
                    : Icons.warning_amber,
                color: member.joiningPaid > 0
                    ? AppColors.primary
                    : AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ProfileMetric(
                label: 'Total Paid',
                value: formatter.money(member.totalPaid),
                icon: Icons.account_balance_wallet,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'Admin Actions'),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.go('/settings/roles'),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Assign Role'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => context.go('/reminders/new'),
                icon: const Icon(Icons.notifications_active),
                label: const Text('Send Reminder'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/contributions/record/details'),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Payment'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.member,
    required this.status,
    required this.statusColor,
  });

  final SofiaMember member;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        children: [
          InitialsAvatar(initials: member.initials, color: statusColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          StatusPill(label: status, color: statusColor),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _InlineInfo(
                icon: Icons.phone_outlined,
                label: '+255 7XX XXX XXX',
              ),
              _InlineInfo(
                icon: Icons.mail_outline,
                label: '${member.initials.toLowerCase()}@example.com',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutstandingBalanceCard extends StatelessWidget {
  const _OutstandingBalanceCard({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      backgroundColor: AppColors.errorContainer.withValues(alpha: 0.32),
      borderColor: AppColors.error.withValues(alpha: 0.2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding Balance',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.error, color: AppColors.error, size: 40),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      backgroundColor: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      backgroundColor: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '100%',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: const LinearProgressIndicator(
              value: 1,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyContributionsGrid extends StatelessWidget {
  const _MonthlyContributionsGrid({required this.paidMonths});

  final int paidMonths;

  static const _months = [
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
  ];

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Monthly Contributions',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const StatusPill(label: 'July - June'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            itemCount: _months.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.42,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
            ),
            itemBuilder: (context, index) {
              final paid = index < paidMonths;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.base),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _months[index],
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    StatusPill(
                      label: paid ? 'Paid' : 'Due',
                      color: paid ? AppColors.primary : AppColors.error,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Recent Transactions'),
          SizedBox(height: AppSpacing.xs),
          _TransactionRow(title: 'Monthly Contribution', date: 'Oct 15, 2026'),
          Divider(color: AppColors.outlineVariant),
          _TransactionRow(title: 'Monthly Contribution', date: 'Sep 12, 2026'),
          Divider(color: AppColors.outlineVariant),
          _TransactionRow(title: 'Monthly Contribution', date: 'Aug 10, 2026'),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.surfaceContainerHigh,
            child: Icon(Icons.payments_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Text(
            'TZS 10,000',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.outline),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = AppInsets.compactCard,
    this.backgroundColor = AppColors.surfaceContainerLowest,
    this.borderColor = AppColors.outlineVariant,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}
