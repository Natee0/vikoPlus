import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class ReportFiltersScreen extends StatelessWidget {
  const ReportFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Report Filters',
      backRoute: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'Financial year',
              hintText: 'July 2026 - June 2027',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Member status',
              hintText: 'All members',
              prefixIcon: Icon(Icons.groups_2_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Export format',
              hintText: 'PDF',
              prefixIcon: Icon(Icons.file_download_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/reports'),
            icon: const Icon(Icons.filter_alt_outlined, size: 18),
            label: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
