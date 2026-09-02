import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MemberAnalysisScreen extends StatelessWidget {
  const MemberAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final rankedMembers = [...sofiaMembers]
      ..sort((left, right) => right.totalPaid.compareTo(left.totalPaid));

    return VikoplusScreen(
      title: 'Member analysis',
      backRoute: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Contribution breakdown'),
          const SizedBox(height: 12),
          for (final member in rankedMembers) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        InitialsAvatar(initials: member.initials),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                member.number,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label:
                              '${((member.totalPaid / sofiaTotalContributions) * 100).toStringAsFixed(2)}%',
                          color: member.fullyPaid
                              ? AppColors.primaryGreen
                              : AppColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AmountBar(
                      label: 'Joining',
                      amount: formatters.money(member.joiningPaid),
                      progress: member.joiningPaid / 10000,
                    ),
                    const SizedBox(height: 8),
                    _AmountBar(
                      label: 'Monthly',
                      amount: formatters.money(member.monthlyPaid),
                      progress: member.monthlyPaid / 60000,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AmountBar extends StatelessWidget {
  const _AmountBar({
    required this.label,
    required this.amount,
    required this.progress,
  });

  final String label;
  final String amount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              amount,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0, 1).toDouble(),
            backgroundColor: AppColors.lightGreen,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}
