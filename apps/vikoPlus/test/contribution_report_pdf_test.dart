import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vikoplus/src/core/groups/contribution_report_filters.dart';
import 'package:vikoplus/src/core/groups/groups_repository.dart';
import 'package:vikoplus/src/features/reports/contribution_report_pdf.dart';

void main() {
  test('exports a multi-page PDF with filtered member data', () async {
    final report = ContributionReportResult.fromJson({
      'membersCount': 100,
      'totalPaidMinor': 100000,
      'recurringPaidMinor': 100000,
      'rates': [
        {
          'name': 'Joining fee',
          'frequency': 'YEARLY',
          'amountMinor': 10000,
          'currency': 'TZS',
        },
        {
          'name': 'Member contribution',
          'frequency': 'MONTHLY',
          'amountMinor': 5000,
          'currency': 'TZS',
        },
      ],
      'register': [
        for (var i = 0; i < 100; i++)
          for (var p = 0; p < 13; p++)
            {
              'memberId': '$i',
              'periodKey': 'p$p',
              'label': 'Period ${p + 1}',
              'sortOrder': p,
              'paidMinor': p == 0 ? 1000 : 0,
            },
      ],
      'periodTotals': [
        {'label': 'September 2026', 'paidMinor': 100000},
      ],
      'memberAnalysis': List.generate(
        100,
        (i) => {
          'memberId': '$i',
          'memberName': 'Test Member $i',
          'memberNumber': 'MBR-${i.toString().padLeft(6, '0')}',
          'totalPaidMinor': 1000,
          'recurringPaidMinor': 1000,
          'paidRecurringPeriods': 1,
          'outstandingMinor': 500,
        },
      ),
    });
    final bytes = await buildContributionReportPdf(
      report: report,
      groupName: 'Test Group',
      year: '2026 - 2027',
      memberStatus: ContributionReportMemberStatus.outstanding,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
    final directory = Directory('build/report-preview')
      ..createSync(recursive: true);
    File('${directory.path}/report.pdf').writeAsBytesSync(bytes);
  });
  test('exports empty reports without a layout failure', () async {
    final bytes = await buildContributionReportPdf(
      report: ContributionReportResult.fromJson({}),
      groupName: 'Empty Group',
      year: '2026 - 2027',
      memberStatus: ContributionReportMemberStatus.cleared,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
