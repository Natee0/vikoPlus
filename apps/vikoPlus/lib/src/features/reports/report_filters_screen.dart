import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/contribution_report_filters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';
import 'contribution_report_pdf.dart';

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
    ref
        .read(contributionReportFiltersProvider.notifier)
        .update(
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

  Future<void> _exportFile(
    String groupId,
    GroupFinancialYearSummary selectedYear,
  ) async {
    if (_isExporting) return;

    try {
      setState(() {
        _errorMessage = '';
        _isExporting = true;
      });
      final format = _exportFormat;
      final status = _memberStatus;
      final groupName = ref.read(activeGroupProvider)?.name ?? '';
      final locale = Localizations.localeOf(context).languageCode;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      late Uint8List bytes;
      late String fileName;
      late String mimeType;
      if (format == ContributionReportExportFormat.pdf) {
        final report = await ref
            .read(groupsRepositoryProvider)
            .contributionReport(groupId, financialYearId: selectedYear.id);
        bytes = await buildContributionReportPdf(
          report: report,
          groupName: groupName,
          year: selectedYear.name,
          memberStatus: status,
          locale: locale,
        );
        fileName = 'contributions-${selectedYear.id}.pdf';
        mimeType = 'application/pdf';
      } else {
        final export = await ref
            .read(groupsRepositoryProvider)
            .exportContributionReport(
              groupId,
              financialYearId: selectedYear.id,
              memberStatus: status.name,
              format: 'csv',
            );
        bytes = Uint8List.fromList(utf8.encode('\uFEFF${export.content}'));
        fileName = export.fileName;
        mimeType = 'text/csv';
      }
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mimeType)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: origin,
        ),
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
      _setFinancialYearsFuture(groupId);
    }
    return _financialYearsFuture!;
  }

  void _setFinancialYearsFuture(
    String groupId, [
    Future<GroupFinancialYearsResult>? future,
  ]) {
    _loadedGroupId = groupId;
    _financialYearsFuture =
        future ?? ref.read(groupsRepositoryProvider).financialYears(groupId);
  }

  Future<void> _refresh() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;
    final future = ref
        .read(groupsRepositoryProvider)
        .financialYears(activeGroup.id);
    setState(() => _setFinancialYearsFuture(activeGroup.id, future));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: AppLocalizations.of(context).reportFilters,
      backRoute: '/reports',
      onRefresh: activeGroup == null ? null : _refresh,
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
                  return AuthErrorMessage(
                    message: context.vt('Could not load financial years.'),
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
                      isExpanded: true,
                      key: ValueKey(selectedYear.id),
                      initialValue: selectedYear.id,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).financialYear,
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      items: [
                        for (final year in years)
                          DropdownMenuItem(
                            value: year.id,
                            child: Text(
                              _yearLabel(year),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      isExpanded: true,
                      initialValue: _memberStatus,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).memberStatus,
                        prefixIcon: Icon(Icons.groups_2_outlined),
                      ),
                      items: [
                        for (final status
                            in ContributionReportMemberStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(
                              context.vt(status.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _memberStatus = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<ContributionReportExportFormat>(
                      isExpanded: true,
                      initialValue: _exportFormat,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).exportFormat,
                        prefixIcon: Icon(Icons.file_download_outlined),
                      ),
                      items: [
                        for (final format
                            in ContributionReportExportFormat.values)
                          DropdownMenuItem(
                            value: format,
                            child: Text(
                              context.vt(format.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      label: Text(AppLocalizations.of(context).applyFilters),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _exportFile(activeGroup.id, selectedYear),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_outlined, size: 18),
                      label: Text(
                        _isExporting
                            ? AppLocalizations.of(context).preparing
                            : AppLocalizations.of(context).exportReport,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_outlined, size: 18),
                      label: Text(AppLocalizations.of(context).resetFilters),
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
        AuthErrorMessage(message: 'Select a group to filter reports.'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onChooseGroup,
          child: Text(AppLocalizations.of(context).chooseGroup),
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
        AuthErrorMessage(
          message: 'Set up a financial year before filtering reports.',
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onConfigure,
          child: Text(AppLocalizations.of(context).configureFinancialYear),
        ),
      ],
    );
  }
}
