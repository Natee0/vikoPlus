import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: 'Reports',
      bottomNavigationIndex: 3,
      showBottomNavigation: showBottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoCard(
            title: 'Total contributions',
            value: formatters.money(sofiaTotalContributions),
            icon: Icons.savings_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: 'Joining',
                  value: formatters.money(sofiaJoiningFees),
                  icon: Icons.person_add_alt_1_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoCard(
                  title: 'Monthly',
                  value: formatters.money(sofiaMonthlyFees),
                  icon: Icons.event_repeat_outlined,
                  accentColor: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Outstanding obligations',
            value: formatters.money(sofiaOutstanding),
            icon: Icons.warning_amber_outlined,
            accentColor: AppColors.warning,
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Available reports'),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Outstanding contributions',
            subtitle: 'Members and periods still due',
            icon: Icons.pending_actions_outlined,
            route: '/reports/outstanding',
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Member contribution analysis',
            subtitle: 'Joining fee, monthly dues, total and percentage',
            icon: Icons.analytics_outlined,
            route: '/reports/member-analysis',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Export files',
            subtitle: 'PDF, Excel and CSV exports will use backend reports',
            icon: Icons.file_download_outlined,
            route: '/reports/filters',
          ),
        ],
      ),
    );
  }
}
