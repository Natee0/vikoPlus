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

class MemberAnalysisScreen extends ConsumerStatefulWidget {
  const MemberAnalysisScreen({super.key});

  @override
  ConsumerState<MemberAnalysisScreen> createState() =>
      _MemberAnalysisScreenState();
}

class _MemberAnalysisScreenState extends ConsumerState<MemberAnalysisScreen> {
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
      title: 'Member analysis',
      backRoute: '/reports',
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Contribution breakdown'),
          const SizedBox(height: 12),
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
                    message: 'Could not load member analysis.',
                  );
                }

                final report = snapshot.data!;
                final rankedMembers = [
                  ..._filterMembers(report.memberAnalysis, filters.memberStatus),
                ]
                  ..sort(
                    (left, right) =>
                        right.totalPaidMinor.compareTo(left.totalPaidMinor),
                  );

                if (rankedMembers.isEmpty) {
                  return const _EmptyAnalysisNotice(
                    message: 'No contribution obligations are available yet.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final member in rankedMembers) ...[
                      _MemberAnalysisCard(
                        member: member,
                        groupTotalMinor: report.totalPaidMinor,
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

class _MemberAnalysisCard extends StatelessWidget {
  const _MemberAnalysisCard({
    required this.member,
    required this.groupTotalMinor,
    required this.formatters,
  });

  final MemberContributionAnalysis member;
  final int groupTotalMinor;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final totalDueMinor = member.totalPaidMinor + member.outstandingMinor;
    final paidProgress =
        totalDueMinor == 0 ? 0.0 : member.totalPaidMinor / totalDueMinor;
    final joiningProgress = member.joiningFeePaidMinor == 0 ? 0.0 : 1.0;
    final recurringProgress =
        totalDueMinor == 0 ? 0.0 : member.recurringPaidMinor / totalDueMinor;
    final share = groupTotalMinor == 0
        ? 0.0
        : member.totalPaidMinor / groupTotalMinor;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => context.go('/members/${member.memberId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InitialsAvatar(initials: _initials(member.memberName)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          member.memberNumber ?? member.memberId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: formatters.compactPercent(share),
                    color: member.outstandingMinor == 0
                        ? AppColors.primaryGreen
                        : AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AmountBar(
                label: 'Joining',
                amount: formatters.money(member.joiningFeePaidMinor),
                progress: joiningProgress,
              ),
              const SizedBox(height: 8),
              _AmountBar(
                label: 'Recurring',
                amount: formatters.money(member.recurringPaidMinor),
                progress: recurringProgress,
              ),
              const SizedBox(height: 8),
              _AmountBar(
                label: 'Overall paid',
                amount: formatters.money(member.totalPaidMinor),
                progress: paidProgress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountBar extends StatelessWidget {
  const _AmountBar({
    required this.label,
    required this.amount,
    required this.progress,
  });

  final String label;
  final String amount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              amount,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0, 1).toDouble(),
            backgroundColor: AppColors.lightGreen,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}

class _EmptyAnalysisNotice extends StatelessWidget {
  const _EmptyAnalysisNotice({required this.message});

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
