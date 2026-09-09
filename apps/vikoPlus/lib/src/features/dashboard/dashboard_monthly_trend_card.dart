import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';

class DashboardMonthlyTrendCard extends StatelessWidget {
  const DashboardMonthlyTrendCard({
    required this.trend,
    required this.formatters,
    this.loading = false,
    super.key,
  });

  final List<GroupMonthlyTrend> trend;
  final AppFormatters formatters;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final total = trend.fold<int>(
      0,
      (sum, month) => sum + month.amountMinor,
    );
    final maxAmount = trend.fold<int>(
      0,
      (max, month) => month.amountMinor > max ? month.amountMinor : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    formatters.money(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              total == 0
                  ? context.vt(
                      'Monthly trend will appear after approved contribution payments are available.',
                    )
                  : context.vt('Approved contribution payments by month.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final month in trend)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                        ),
                        child: _TrendBar(
                          month: month,
                          maxAmount: maxAmount,
                          formatters: formatters,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.month,
    required this.maxAmount,
    required this.formatters,
  });

  final GroupMonthlyTrend month;
  final int maxAmount;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final heightFactor = maxAmount == 0
        ? 0.08
        : (month.amountMinor / maxAmount).clamp(0.08, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Tooltip(
            message:
                '${formatters.money(month.amountMinor)} - ${month.paymentsCount}',
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                widthFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: month.amountMinor == 0
                        ? AppColors.surfaceContainerHigh
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          month.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
