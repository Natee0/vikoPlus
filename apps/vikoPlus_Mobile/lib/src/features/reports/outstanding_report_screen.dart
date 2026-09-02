import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class OutstandingReportScreen extends StatelessWidget {
  const OutstandingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final outstandingMembers = sofiaMembers.where(
      (member) => member.outstanding > 0,
    );

    return VikoplusScreen(
      title: 'Outstanding report',
      backRoute: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgressBlock(
            title: 'Outstanding obligations',
            value: formatters.money(sofiaOutstanding),
            caption: '${outstandingMembers.length} members still have dues',
            progress:
                sofiaTotalContributions /
                (sofiaTotalContributions + sofiaOutstanding),
          ),
          const SizedBox(height: 16),
          for (final member in outstandingMembers) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    InitialsAvatar(
                      initials: member.initials,
                      color: AppColors.warning,
                    ),
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
                          const SizedBox(height: 3),
                          Text(
                            '${member.paidMonths}/12 monthly periods paid',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: formatters.money(member.outstanding),
                      color: AppColors.warning,
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
