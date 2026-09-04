import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
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

    return VikoplusScreen(
      title: 'Digital Receipt',
      backRoute: backRoute ?? '/member/payments/success',
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
        ),
      ],
      child: id == null || id == 'latest' || activeGroup == null
          ? _StaticReceiptContent(formatters: formatters)
          : FutureBuilder<ReceiptSummary>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .receipt(activeGroup.id, id),
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
                      const AuthErrorMessage(
                        message: 'Could not load this receipt. Please try again.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => context.go(backRoute ?? '/dashboard'),
                        child: const Text('Go Back'),
                      ),
                    ],
                  );
                }

                return _ReceiptContent(
                  receipt: snapshot.data!,
                  groupName: activeGroup.name,
                  formatters: formatters,
                );
              },
            ),
    );
  }
}

class _StaticReceiptContent extends StatelessWidget {
  const _StaticReceiptContent({required this.formatters});

  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final member = sofiaMembers[4];
    final amount = formatters.money(10000);
    return _ReceiptLayout(
      amount: amount,
      lines: [
        const ('Reference No', 'TRX-89234-77'),
        const ('Date & Time', 'Sep 2, 2026\n10:30 AM'),
        const ('Payment Method', 'M-Pesa'),
        const ('Group Name', 'Sofia Wajukuu Group'),
        const ('Contribution Type', 'Monthly Contribution'),
        ('Member Name', member.name),
        ('Amount', amount),
        const ('Transaction Fee', 'TZS 0'),
      ],
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({
    required this.receipt,
    required this.groupName,
    required this.formatters,
  });

  final ReceiptSummary receipt;
  final String groupName;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final payment = receipt.payment;
    final amount = formatters.money(
      payment?.amountMinor ?? 0,
      currency: payment?.currency ?? 'TZS',
    );

    return _ReceiptLayout(
      amount: amount,
      lines: [
        ('Reference No', receipt.receiptNumber),
        ('Date & Time', formatters.date(receipt.issuedAt)),
        ('Payment Method', _methodLabel(payment?.method ?? 'OTHER')),
        ('Group Name', groupName),
        const ('Contribution Type', 'Monthly Contribution'),
        ('Member Name', payment?.memberName ?? 'Member'),
        ('Amount', amount),
        const ('Transaction Fee', 'TZS 0'),
      ],
    );
  }
}

class _ReceiptLayout extends StatelessWidget {
  const _ReceiptLayout({required this.amount, required this.lines});

  final String amount;
  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReceiptSuccessHeader(amount: amount),
        const SizedBox(height: AppSpacing.md),
        _ReceiptCard(lines: lines, total: amount),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share Receipt'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download PDF'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go('/dashboard'),
          child: const Text('Return to Dashboard'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'This is an automated receipt for your records.\nPlease contact your group admin for any queries.',
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
          'Payment Confirmed',
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
            _ReceiptLine(label: lines[index].$1, value: lines[index].$2),
            if (index == 2 || index == 5)
              const Divider(
                height: AppSpacing.md,
                color: AppColors.outlineVariant,
              ),
          ],
          const Divider(height: AppSpacing.md, color: AppColors.outlineVariant),
          _ReceiptLine(label: 'Total', value: total, strong: true),
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
