import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class DigitalReceiptScreen extends StatelessWidget {
  const DigitalReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final member = sofiaMembers[4];
    final amount = formatters.money(10000);

    return VikoplusScreen(
      title: 'Digital Receipt',
      backRoute: '/member/payments/success',
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReceiptSuccessHeader(amount: 'TZS 10,000'),
          const SizedBox(height: AppSpacing.md),
          _ReceiptCard(
            lines: [
              const ('Reference No', 'TRX-89234-77'),
              const ('Date & Time', 'Sep 2, 2026\n10:30 AM'),
              const ('Payment Method', 'M-Pesa'),
              const ('Group Name', 'Sofia Wajukuu Group'),
              const ('Contribution Type', 'July 2026 Monthly Dues'),
              ('Member Name', member.name),
              ('Amount', amount),
              const ('Transaction Fee', 'TZS 0'),
            ],
            total: amount,
          ),
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
            onPressed: () => context.go('/member/dashboard'),
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
      ),
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
