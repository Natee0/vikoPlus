import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/contribution_report_filters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class OutstandingReportScreen extends ConsumerStatefulWidget {
  const OutstandingReportScreen({super.key});

  @override
  ConsumerState<OutstandingReportScreen> createState() =>
      _OutstandingReportScreenState();
}

class _OutstandingReportScreenState extends ConsumerState<OutstandingReportScreen> {
  Future<ContributionReportResult>? _reportFuture;
  String? _loadedGroupId;
  String? _loadedFinancialYearId;

  Future<ContributionReportResult> _loadReport(
    String groupId,
    ContributionReportFilters filters,
  ) {
    return ref.read(groupsRepositoryProvider).contributionReport(
          groupId,
          financialYearId: filters.financialYearId,
        );
  }

  void _setReportFuture(
    String groupId,
    ContributionReportFilters filters, [
    Future<ContributionReportResult>? future,
  ]) {
    _loadedGroupId = groupId;
    _loadedFinancialYearId = filters.financialYearId;
    _reportFuture = future ?? _loadReport(groupId, filters);
  }

  void _ensureReportFuture(String? groupId, ContributionReportFilters filters) {
    if (groupId == null || groupId.isEmpty) return;
    if (_loadedGroupId != groupId ||
        _loadedFinancialYearId != filters.financialYearId ||
        _reportFuture == null) {
      _setReportFuture(groupId, filters);
    }
  }

  Future<void> _refresh() async {
    final group = ref.read(activeGroupProvider);
    if (group == null) return;

    final filters = ref.read(contributionReportFiltersProvider);
    final future = _loadReport(group.id, filters);
    setState(() => _setReportFuture(group.id, filters, future));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);
    final filters = ref.watch(contributionReportFiltersProvider);
    _ensureReportFuture(activeGroup?.id, filters);

    return VikoplusScreen(
      title: 'Outstanding report',
      backRoute: '/reports',
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeGroup == null) ...[
            const AuthErrorMessage(message: 'Select a group to view reports.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/groups'),
              child: const Text('Choose Group'),
            ),
          ] else
            FutureBuilder<ContributionReportResult>(
              future: _reportFuture,
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
                    message: 'Could not load outstanding report.',
                  );
                }

                final report = snapshot.data!;
                final outstandingMembers =
                    _filterMembers(report.memberAnalysis, filters.memberStatus)
                        .where((member) => member.outstandingMinor > 0)
                        .toList();
                final paid = report.totalPaidMinor;
                final outstanding = report.totalOutstandingMinor;
                final progress =
                    paid + outstanding == 0 ? 0.0 : paid / (paid + outstanding);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProgressBlock(
                      title: 'Outstanding obligations',
                      value: formatters.money(outstanding),
                      caption:
                          '${outstandingMembers.length} members still have dues',
                      progress: progress,
                    ),
                    const SizedBox(height: 16),
                    if (outstandingMembers.isEmpty)
                      const _EmptyReportNotice(
                        message: 'All current contribution obligations are paid.',
                      )
                    else
                      for (final member in outstandingMembers) ...[
                        _OutstandingMemberCard(
                          member: member,
                          formatters: formatters,
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OutstandingMemberCard extends StatelessWidget {
  const _OutstandingMemberCard({
    required this.member,
    required this.formatters,
  });

  final MemberContributionAnalysis member;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => context.go('/members/${member.memberId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              InitialsAvatar(
                initials: _initials(member.memberName),
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${member.paidRecurringPeriods} recurring periods paid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                label: formatters.money(member.outstandingMinor),
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReportNotice extends StatelessWidget {
  const _EmptyReportNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'M';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

List<MemberContributionAnalysis> _filterMembers(
  List<MemberContributionAnalysis> members,
  ContributionReportMemberStatus status,
) {
  return switch (status) {
    ContributionReportMemberStatus.all => members,
    ContributionReportMemberStatus.outstanding =>
      members.where((member) => member.outstandingMinor > 0).toList(),
    ContributionReportMemberStatus.cleared =>
      members.where((member) => member.outstandingMinor == 0).toList(),
  };
}
