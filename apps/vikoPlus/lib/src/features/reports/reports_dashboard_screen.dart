import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/contribution_report_filters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class ReportsDashboardScreen extends ConsumerStatefulWidget {
  const ReportsDashboardScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  ConsumerState<ReportsDashboardScreen> createState() =>
      _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends ConsumerState<ReportsDashboardScreen> {
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
      title: 'Reports',
      bottomNavigationIndex: 3,
      showBottomNavigation: widget.showBottomNavigation,
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportSummaryBlock(
            groupId: activeGroup?.id,
            reportFuture: _reportFuture,
            formatters: formatters,
            exportFormatLabel: filters.exportFormat.label,
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Available reports'),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Outstanding contributions',
            subtitle: 'Members and periods still due',
            icon: Icons.pending_actions_outlined,
            route: '/reports/outstanding',
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Member contribution analysis',
            subtitle: 'Joining fee, monthly dues, total and percentage',
            icon: Icons.analytics_outlined,
            route: '/reports/member-analysis',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Export files',
            subtitle: 'Selected format is managed in report filters',
            icon: Icons.file_download_outlined,
            route: '/reports/filters',
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryBlock extends ConsumerWidget {
  const _ReportSummaryBlock({
    required this.groupId,
    required this.reportFuture,
    required this.formatters,
    required this.exportFormatLabel,
  });

  final String? groupId;
  final Future<ContributionReportResult>? reportFuture;
  final AppFormatters formatters;
  final String exportFormatLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = groupId;
    if (id == null || id.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthErrorMessage(message: 'Select a group to load reports.'),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.go('/groups'),
            child: const Text('Choose Group'),
          ),
        ],
      );
    }

    return FutureBuilder<ContributionReportResult>(
      future: reportFuture,
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
            message: 'Could not load contribution report.',
          );
        }

        final report = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoCard(
              title: 'Total contributions',
              value: formatters.money(report.totalPaidMinor),
              icon: Icons.savings_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Joining',
                    value: formatters.money(report.joiningFeesPaidMinor),
                    icon: Icons.person_add_alt_1_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoCard(
                    title: 'Recurring',
                    value: formatters.money(report.recurringPaidMinor),
                    icon: Icons.event_repeat_outlined,
                    accentColor: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: 'Outstanding obligations',
              value: formatters.money(report.totalOutstandingMinor),
              icon: Icons.warning_amber_outlined,
              accentColor: AppColors.warning,
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: 'Export format',
              value: exportFormatLabel,
              icon: Icons.file_download_outlined,
            ),
          ],
        );
      },
    );
  }
}
