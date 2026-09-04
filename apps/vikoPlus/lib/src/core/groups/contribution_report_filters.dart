import 'package:flutter_riverpod/flutter_riverpod.dart';

final contributionReportFiltersProvider = NotifierProvider<
    ContributionReportFiltersNotifier, ContributionReportFilters>(
  ContributionReportFiltersNotifier.new,
);

enum ContributionReportMemberStatus {
  all('All members'),
  outstanding('Outstanding only'),
  cleared('Cleared only');

  const ContributionReportMemberStatus(this.label);

  final String label;
}

enum ContributionReportExportFormat {
  csv('CSV', 'csv');

  const ContributionReportExportFormat(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

class ContributionReportFilters {
  const ContributionReportFilters({
    this.financialYearId,
    this.financialYearLabel = 'Current financial year',
    this.memberStatus = ContributionReportMemberStatus.all,
    this.exportFormat = ContributionReportExportFormat.csv,
  });

  final String? financialYearId;
  final String financialYearLabel;
  final ContributionReportMemberStatus memberStatus;
  final ContributionReportExportFormat exportFormat;

  ContributionReportFilters copyWith({
    String? financialYearId,
    String? financialYearLabel,
    ContributionReportMemberStatus? memberStatus,
    ContributionReportExportFormat? exportFormat,
  }) {
    return ContributionReportFilters(
      financialYearId: financialYearId ?? this.financialYearId,
      financialYearLabel: financialYearLabel ?? this.financialYearLabel,
      memberStatus: memberStatus ?? this.memberStatus,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }
}

class ContributionReportFiltersNotifier
    extends Notifier<ContributionReportFilters> {
  @override
  ContributionReportFilters build() => const ContributionReportFilters();

  void update(ContributionReportFilters filters) {
    state = filters;
  }

  void reset() {
    state = const ContributionReportFilters();
  }
}
