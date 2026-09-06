import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/groups/contribution_report_details.dart';
import '../../core/groups/contribution_report_filters.dart';
import '../../core/groups/groups_repository.dart';

Future<Uint8List> buildContributionReportPdf({
  required ContributionReportResult report,
  required String groupName,
  required String year,
  required ContributionReportMemberStatus memberStatus,
  String locale = 'en',
}) async {
  String tr(String en, String sw) => locale == 'sw' ? sw : en;
  final title = tr(
    'Member contribution report',
    'Ripoti ya michango ya wanachama',
  );
  final document = pw.Document(title: '$groupName - $title');
  final number = NumberFormat('#,##0.##', 'en');
  final members =
      report.memberAnalysis
          .where(
            (m) => switch (memberStatus) {
              ContributionReportMemberStatus.all => true,
              ContributionReportMemberStatus.outstanding =>
                m.outstandingMinor > 0,
              ContributionReportMemberStatus.cleared => m.outstandingMinor <= 0,
            },
          )
          .toList()
        ..sort((a, b) => a.memberName.compareTo(b.memberName));
  final memberIds = members.map((m) => m.memberId).toSet();
  final cells = report.register
      .where((c) => memberIds.contains(c.memberId))
      .toList();
  final periodMap = <String, ContributionRegisterCell>{};
  final payments = <String, Map<String, int>>{};
  final periodPaid = <String, int>{};
  final contributors = <String, Set<String>>{};
  for (final cell in cells) {
    periodMap[cell.periodKey] = cell;
    (payments[cell.memberId] ??= {})[cell.periodKey] = cell.paidMinor;
    periodPaid.update(
      cell.periodKey,
      (n) => n + cell.paidMinor,
      ifAbsent: () => cell.paidMinor,
    );
    if (cell.paidMinor > 0) {
      (contributors[cell.periodKey] ??= {}).add(cell.memberId);
    }
  }
  final periods = periodMap.values.toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.periodKey.compareTo(b.periodKey) : order;
    });
  int sum(int Function(MemberContributionAnalysis) value) =>
      members.fold(0, (n, m) => n + value(m));
  final total = sum((m) => m.totalPaidMinor);
  final joining = sum((m) => m.joiningFeePaidMinor);
  final recurring = sum((m) => m.recurringPaidMinor);
  String percent(int paid) =>
      '${(total == 0 ? 0 : paid / total * 100).toStringAsFixed(1)}%';
  const green = PdfColor.fromInt(0xff005843);
  final nameLabel = tr('Full name', 'Jina');
  final joiningLabel = tr('Joining fee', 'Kiingilio');
  final totalLabel = tr('Total', 'Jumla');
  pw.Widget heading(String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 12),
    child: pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: 13,
        color: green,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
  pw.Widget table(
    List<String> headers,
    List<List<String>> rows, {
    bool compact = false,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerDecoration: const pw.BoxDecoration(color: green),
    headerStyle: pw.TextStyle(
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
      fontSize: compact ? 7 : 9,
    ),
    cellStyle: pw.TextStyle(fontSize: compact ? 7 : 9),
    cellPadding: pw.EdgeInsets.all(compact ? 4 : 7),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
  );
  final scope = switch (memberStatus) {
    ContributionReportMemberStatus.all => tr(
      'All accessible members',
      'Wanachama wote wanaoruhusiwa',
    ),
    ContributionReportMemberStatus.outstanding => tr(
      'Outstanding members only',
      'Wanachama wenye madeni pekee',
    ),
    ContributionReportMemberStatus.cleared => tr(
      'Cleared members only',
      'Wanachama wasio na madeni pekee',
    ),
  };
  void section(List<pw.Widget> widgets) => document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      maxPages: 1000,
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            groupName,
            style: pw.TextStyle(
              fontSize: 20,
              color: green,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('$title | $year', style: const pw.TextStyle(fontSize: 11)),
          pw.Text(scope, style: const pw.TextStyle(fontSize: 8)),
          pw.Divider(color: green),
        ],
      ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'vikoPlus | ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            '${tr('Page', 'Ukurasa')} ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
      build: (_) => widgets,
    ),
  );

  final maxPaid = periodPaid.values.fold<int>(0, math.max);
  section([
    heading(tr('Contribution summary', 'Muhtasari wa michango')),
    table(
      [
        tr('Members', 'Wanachama'),
        totalLabel,
        joiningLabel,
        tr('Recurring fees', 'Ada za vipindi'),
        tr('Outstanding', 'Deni'),
      ],
      [
        [
          '${members.length}',
          number.format(total),
          number.format(joining),
          number.format(recurring),
          number.format(sum((m) => m.outstandingMinor)),
        ],
      ],
    ),
    heading(
      tr('Configured contribution rates', 'Viwango vya michango vilivyowekwa'),
    ),
    if (report.rates.isEmpty)
      pw.Text(
        tr('No configured rates available.', 'Hakuna viwango vilivyowekwa.'),
      ),
    if (report.rates.isNotEmpty)
      table(
        [
          tr('Contribution type', 'Aina ya mchango'),
          tr('Cycle', 'Mzunguko'),
          tr('Currency', 'Sarafu'),
          tr('Configured amount', 'Kiasi kilichowekwa'),
        ],
        report.rates
            .map(
              (r) => [
                r.name,
                r.frequency.replaceAll('_', ' '),
                r.currency,
                number.format(r.amountMinor),
              ],
            )
            .toList(),
      ),
    pw.SizedBox(height: 6),
    pw.Text(
      tr(
        'Rates show current configuration; paid amounts reflect the selected financial year.',
        'Viwango ni vya usanidi wa sasa; malipo ni ya mwaka wa fedha uliochaguliwa.',
      ),
      style: const pw.TextStyle(fontSize: 8),
    ),
    heading(tr('Recurring contribution trend', 'Mwenendo wa ada za vipindi')),
    if (periods.isEmpty)
      pw.Text(tr('No period data available.', 'Hakuna taarifa za vipindi.')),
    for (final p in periods)
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 175,
              child: pw.Text(p.label, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.SizedBox(
              width: 420,
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(
                  width: maxPaid == 0
                      ? 0
                      : 420 * (periodPaid[p.periodKey] ?? 0) / maxPaid,
                  height: 10,
                  color: green,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              number.format(periodPaid[p.periodKey] ?? 0),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
  ]);

  // Split wide daily/weekly registers without shrinking text beyond readability.
  final chunks = <List<ContributionRegisterCell>>[];
  for (var start = 0; start < periods.length; start += 12) {
    chunks.add(periods.sublist(start, math.min(start + 12, periods.length)));
  }
  if (chunks.isEmpty) {
    chunks.add([]);
  }
  for (var i = 0; i < chunks.length; i++) {
    final chunk = chunks[i];
    section([
      heading(
        '${tr('Member contribution register', 'Rejesta ya michango ya wanachama')}${chunks.length > 1 ? ' (${i + 1}/${chunks.length})' : ''}',
      ),
      pw.Text(
        tr(
          'A dash means no obligation for that period; 0 means no payment. Total includes every period.',
          'Alama - inamaanisha hakuna wajibu wa kipindi; 0 ni hakuna malipo. Jumla inajumuisha vipindi vyote.',
        ),
        style: const pw.TextStyle(fontSize: 8),
      ),
      pw.SizedBox(height: 8),
      if (members.isEmpty)
        pw.Text(
          tr(
            'No members match this filter.',
            'Hakuna wanachama wanaolingana na kichujio.',
          ),
        ),
      if (members.isNotEmpty)
        table(
          [
            tr('Member no.', 'Namba'),
            nameLabel,
            joiningLabel,
            ...chunk.map((p) => p.label),
            totalLabel,
          ],
          [
            for (final m in members)
              [
                m.memberNumber ?? '-',
                m.memberName,
                number.format(m.joiningFeePaidMinor),
                ...chunk.map(
                  (p) => payments[m.memberId]?.containsKey(p.periodKey) == true
                      ? number.format(payments[m.memberId]![p.periodKey])
                      : '-',
                ),
                number.format(m.totalPaidMinor),
              ],
            [
              '',
              totalLabel,
              number.format(joining),
              ...chunk.map((p) => number.format(periodPaid[p.periodKey] ?? 0)),
              number.format(total),
            ],
          ],
          compact: true,
        ),
    ]);
  }
  final ranked = [...members]
    ..sort((a, b) {
      final order = b.totalPaidMinor.compareTo(a.totalPaidMinor);
      return order == 0 ? a.memberName.compareTo(b.memberName) : order;
    });
  section([
    heading(tr('Contribution analysis', 'Uchambuzi wa michango')),
    if (members.isEmpty)
      pw.Text(
        tr(
          'No members match this filter.',
          'Hakuna wanachama wanaolingana na kichujio.',
        ),
      ),
    if (members.isNotEmpty)
      table(
        [
          tr('Rank', 'Na.'),
          nameLabel,
          joiningLabel,
          tr('Recurring fees', 'Ada za vipindi'),
          totalLabel,
          tr('Paid periods', 'Vipindi vilivyolipwa'),
          tr('% of total', '% ya jumla'),
          tr('Outstanding', 'Deni'),
        ],
        [
          for (var i = 0; i < ranked.length; i++)
            [
              '${i + 1}',
              ranked[i].memberName,
              number.format(ranked[i].joiningFeePaidMinor),
              number.format(ranked[i].recurringPaidMinor),
              number.format(ranked[i].totalPaidMinor),
              '${ranked[i].paidRecurringPeriods}',
              percent(ranked[i].totalPaidMinor),
              number.format(ranked[i].outstandingMinor),
            ],
        ],
      ),
  ]);
  section([
    heading(
      tr('Recurring contribution summary', 'Muhtasari wa ada za vipindi'),
    ),
    if (periods.isEmpty)
      pw.Text(tr('No period data available.', 'Hakuna taarifa za vipindi.')),
    if (periods.isNotEmpty)
      table(
        [
          tr('Period', 'Kipindi'),
          tr('Contributors', 'Waliochangia'),
          tr('Amount', 'Kiasi'),
          tr('% of total contributions', 'Asilimia ya jumla'),
        ],
        [
          for (final p in periods)
            [
              p.label,
              '${contributors[p.periodKey]?.length ?? 0}',
              number.format(periodPaid[p.periodKey] ?? 0),
              percent(periodPaid[p.periodKey] ?? 0),
            ],
          [totalLabel, '', number.format(recurring), percent(recurring)],
        ],
      ),
  ]);
  return document.save();
}
