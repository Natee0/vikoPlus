import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/contribution_report_filters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class ReportFiltersScreen extends ConsumerStatefulWidget {
  const ReportFiltersScreen({super.key});

  @override
  ConsumerState<ReportFiltersScreen> createState() =>
      _ReportFiltersScreenState();
}

class _ReportFiltersScreenState extends ConsumerState<ReportFiltersScreen> {
  String? _financialYearId;
  String? _loadedGroupId;
  Future<GroupFinancialYearsResult>? _financialYearsFuture;
  late ContributionReportMemberStatus _memberStatus;
  late ContributionReportExportFormat _exportFormat;
  String _errorMessage = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(contributionReportFiltersProvider);
    _financialYearId = filters.financialYearId;
    _memberStatus = filters.memberStatus;
    _exportFormat = filters.exportFormat;
  }

  void _apply(GroupFinancialYearSummary selectedYear) {
    ref.read(contributionReportFiltersProvider.notifier).update(
          ContributionReportFilters(
            financialYearId: selectedYear.id,
            financialYearLabel: _yearLabel(selectedYear),
            memberStatus: _memberStatus,
            exportFormat: _exportFormat,
          ),
        );
    context.go('/reports');
  }

  void _reset() {
    ref.read(contributionReportFiltersProvider.notifier).reset();
    context.go('/reports');
  }

  Future<void> _copyExport(
    String groupId,
    GroupFinancialYearSummary selectedYear,
  ) async {
    if (_isExporting) return;

    try {
      setState(() {
        _errorMessage = '';
        _isExporting = true;
      });
      final export = await ref
          .read(groupsRepositoryProvider)
          .exportContributionReport(
            groupId,
            financialYearId: selectedYear.id,
            memberStatus: _memberStatus.name,
            format: _exportFormat.apiValue,
          );
      await Clipboard.setData(ClipboardData(text: export.content));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${export.fileName} copied to clipboard.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<GroupFinancialYearsResult> _financialYearsFor(String groupId) {
    if (_loadedGroupId != groupId || _financialYearsFuture == null) {
      _loadedGroupId = groupId;
      _financialYearsFuture =
          ref.read(groupsRepositoryProvider).financialYears(groupId);
    }
    return _financialYearsFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: 'Report Filters',
      backRoute: '/reports',
      child: activeGroup == null
          ? _MissingGroupState(onChooseGroup: () => context.go('/groups'))
          : FutureBuilder<GroupFinancialYearsResult>(
              future: _financialYearsFor(activeGroup.id),
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
                    message: 'Could not load financial years.',
                  );
                }

                final years = snapshot.data!.financialYears;
                if (years.isEmpty) {
                  return _MissingFinancialYearState(
                    onConfigure: () => context.go('/groups/financial-year'),
                  );
                }

                final selectedYear = _selectedYear(years);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedYear.id),
                      initialValue: selectedYear.id,
                      decoration: const InputDecoration(
                        labelText: 'Financial year',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      items: [
                        for (final year in years)
                          DropdownMenuItem(
                            value: year.id,
                            child: Text(_yearLabel(year)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        final year = years.firstWhere(
                          (item) => item.id == value,
                          orElse: () => selectedYear,
                        );
                        setState(() {
                          _financialYearId = year.id;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<ContributionReportMemberStatus>(
                      initialValue: _memberStatus,
                      decoration: const InputDecoration(
                        labelText: 'Member status',
                        prefixIcon: Icon(Icons.groups_2_outlined),
                      ),
                      items: [
                        for (final status
                            in ContributionReportMemberStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _memberStatus = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<ContributionReportExportFormat>(
                      initialValue: _exportFormat,
                      decoration: const InputDecoration(
                        labelText: 'Export format',
                        prefixIcon: Icon(Icons.file_download_outlined),
                      ),
                      items: [
                        for (final format
                            in ContributionReportExportFormat.values)
                          DropdownMenuItem(
                            value: format,
                            child: Text(format.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _exportFormat = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorMessage(message: _errorMessage),
                    if (_errorMessage.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => _apply(selectedYear),
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('Apply Filters'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _copyExport(activeGroup.id, selectedYear),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.copy_outlined, size: 18),
                      label: Text(_isExporting ? 'Preparing' : 'Copy Export'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_outlined, size: 18),
                      label: const Text('Reset Filters'),
                    ),
                  ],
                );
              },
            ),
    );
  }

  GroupFinancialYearSummary _selectedYear(
    List<GroupFinancialYearSummary> years,
  ) {
    for (final year in years) {
      if (year.id == _financialYearId) return year;
    }
    for (final year in years) {
      if (year.isActive) return year;
    }
    return years.first;
  }

  String _yearLabel(GroupFinancialYearSummary year) {
    return year.isActive ? '${year.name} (Active)' : year.name;
  }
}

class _MissingGroupState extends StatelessWidget {
  const _MissingGroupState({required this.onChooseGroup});

  final VoidCallback onChooseGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthErrorMessage(message: 'Select a group to filter reports.'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onChooseGroup,
          child: const Text('Choose Group'),
        ),
      ],
    );
  }
}

class _MissingFinancialYearState extends StatelessWidget {
  const _MissingFinancialYearState({required this.onConfigure});

  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthErrorMessage(
          message: 'Set up a financial year before filtering reports.',
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onConfigure,
          child: const Text('Configure Financial Year'),
        ),
      ],
    );
  }
}
