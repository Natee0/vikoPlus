import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../routing/portal_route_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class DigitalReceiptScreen extends ConsumerWidget {
  const DigitalReceiptScreen({this.receiptId, this.backRoute, super.key});

  final String? receiptId;
  final String? backRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);
    final id = receiptId;
    final fallbackRoute = backRoute ?? portalHomeRoute(activeGroup);

    return VikoplusScreen(
      title: context.vt('Digital Receipt'),
      backRoute: fallbackRoute,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
          tooltip: context.vt('More options'),
        ),
      ],
      child: _body(context, ref, formatters, activeGroup, id, fallbackRoute),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppFormatters formatters,
    GroupAccessSummary? activeGroup,
    String? id,
    String fallbackRoute,
  ) {
    if (id == null || id == 'latest') {
      return _ReceiptUnavailable(backRoute: fallbackRoute);
    }
    if (activeGroup == null) {
      return _ReceiptUnavailable(
        backRoute: fallbackRoute,
        title: context.vt('Select a group'),
        message: context.vt('Open a group before viewing receipts.'),
      );
    }

    return FutureBuilder<ReceiptSummary>(
      future: ref.read(groupsRepositoryProvider).receipt(activeGroup.id, id),
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthErrorMessage(
                message: context.vt(
                  'Could not load this receipt. Please try again.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(fallbackRoute),
                child: Text(context.vt('Go Back')),
              ),
            ],
          );
        }

        return _ReceiptContent(
          receipt: snapshot.data!,
          groupName: activeGroup.name,
          formatters: formatters,
          returnRoute: fallbackRoute,
        );
      },
    );
  }
}

class _ReceiptUnavailable extends StatelessWidget {
  const _ReceiptUnavailable({
    required this.backRoute,
    this.title = 'Receipt not available yet',
    this.message =
        'A receipt will be created after the treasurer approves this payment.',
  });

  final String backRoute;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.receipt_long_outlined,
      title: context.vt(title),
      message: context.vt(message),
      actionLabel: context.vt('Go Back'),
      onAction: () => context.go(backRoute),
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({
    required this.receipt,
    required this.groupName,
    required this.formatters,
    required this.returnRoute,
  });

  final ReceiptSummary receipt;
  final String groupName;
  final AppFormatters formatters;
  final String returnRoute;

  @override
  Widget build(BuildContext context) {
    final payment = receipt.payment;
    final amount = formatters.money(
      payment?.amountMinor ?? 0,
      currency: payment?.currency ?? 'TZS',
    );
    final lines = [
      ('Reference No', receipt.receiptNumber),
      ('Date & Time', formatters.date(receipt.issuedAt)),
      ('Payment Method', context.vt(_methodLabel(payment?.method ?? 'OTHER'))),
      ('Group Name', groupName),
      ('Contribution Type', 'Monthly Contribution'),
      ('Member Name', payment?.memberName ?? context.vt('Member')),
      ('Amount', amount),
      ('Transaction Fee', 'TZS 0'),
    ];

    return _ReceiptLayout(
      amount: amount,
      receiptNumber: receipt.receiptNumber,
      returnRoute: returnRoute,
      lines: lines,
    );
  }
}

class _ReceiptLayout extends StatefulWidget {
  const _ReceiptLayout({
    required this.amount,
    required this.receiptNumber,
    required this.returnRoute,
    required this.lines,
  });

  final String amount;
  final String receiptNumber;
  final String returnRoute;
  final List<(String, String)> lines;

  @override
  State<_ReceiptLayout> createState() => _ReceiptLayoutState();
}

class _ReceiptLayoutState extends State<_ReceiptLayout> {
  bool _isExporting = false;
  String _errorMessage = '';

  Future<({Uint8List bytes, String fileName, String mimeType})>
      _buildReceiptFile() async {
    final note = context.vt(
      'This is an automated receipt for your records.\nPlease contact your group admin for any queries.',
    );
    final localizedLines = widget.lines
        .map((line) => (context.vt(line.$1), line.$2))
        .toList(growable: false);
    final bytes = await _buildReceiptPdf(
      amount: widget.amount,
      lines: localizedLines,
      total: widget.amount,
      totalLabel: context.vt('Total'),
      note: note,
    );
    return (
      bytes: bytes,
      fileName: 'receipt-${_safeFilePart(widget.receiptNumber)}.pdf',
      mimeType: 'application/pdf',
    );
  }

  Future<void> _downloadPdf() async {
    if (_isExporting) return;

    try {
      setState(() {
        _errorMessage = '';
        _isExporting = true;
      });
      final export = await _buildReceiptFile();
      if (!mounted) return;
      await FilePicker.saveFile(
        dialogTitle: context.vt('Download PDF'),
        fileName: export.fileName,
        type: FileType.any,
        bytes: export.bytes,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = context.vt(AuthFailure.from(error).message),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareReceipt() async {
    if (_isExporting) return;

    try {
      setState(() {
        _errorMessage = '';
        _isExporting = true;
      });
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      final export = await _buildReceiptFile();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(export.bytes, mimeType: export.mimeType)],
          fileNameOverrides: [export.fileName],
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = context.vt(AuthFailure.from(error).message),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReceiptSuccessHeader(amount: widget.amount),
        const SizedBox(height: AppSpacing.md),
        _ReceiptCard(lines: widget.lines, total: widget.amount),
        const SizedBox(height: AppSpacing.md),
        AuthErrorMessage(message: _errorMessage),
        if (_errorMessage.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: _isExporting ? null : _shareReceipt,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_outlined),
          label: Text(context.vt('Share Receipt')),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _isExporting ? null : _downloadPdf,
          icon: const Icon(Icons.download_outlined),
          label: Text(context.vt('Download PDF')),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _isExporting ? null : () => context.go(widget.returnRoute),
          child: Text(context.vt('Return to Dashboard')),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.vt(
            'This is an automated receipt for your records.\nPlease contact your group admin for any queries.',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _ReceiptSuccessHeader extends StatelessWidget {
  const _ReceiptSuccessHeader({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.onPrimary, size: 36),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.vt('Payment Confirmed'),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          amount,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

String _methodLabel(String method) {
  return method
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.lines, required this.total});

  final List<(String, String)> lines;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        children: [
          for (var index = 0; index < lines.length; index++) ...[
            _ReceiptLine(
              label: context.vt(lines[index].$1),
              value: lines[index].$2,
            ),
            if (index == 2 || index == 5)
              const Divider(
                height: AppSpacing.md,
                color: AppColors.outlineVariant,
              ),
          ],
          const Divider(height: AppSpacing.md, color: AppColors.outlineVariant),
          _ReceiptLine(label: context.vt('Total'), value: total, strong: true),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Uint8List> _buildReceiptPdf({
  required String amount,
  required List<(String, String)> lines,
  required String total,
  required String totalLabel,
  required String note,
}) async {
  const green = PdfColor.fromInt(0xff005843);
  final document = pw.Document(title: 'vikoPlus receipt');

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(
                  width: 48,
                  height: 48,
                  decoration: const pw.BoxDecoration(
                    color: green,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'OK',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'vikoPlus',
                  style: pw.TextStyle(
                    color: green,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  amount,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              children: [
                for (var index = 0; index < lines.length; index++) ...[
                  _receiptPdfLine(lines[index].$1, lines[index].$2),
                  if (index == 2 || index == 5)
                    pw.Divider(color: PdfColors.grey300, height: 18),
                ],
                pw.Divider(color: PdfColors.grey300, height: 18),
                _receiptPdfLine(totalLabel, total, strong: true),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Text(
            note,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
          ),
        ],
      ),
    ),
  );

  return document.save();
}

pw.Widget _receiptPdfLine(
  String label,
  String value, {
  bool strong = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

String _safeFilePart(String value) {
  final sanitized = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
  return sanitized.isEmpty ? 'vikoplus' : sanitized;
}
