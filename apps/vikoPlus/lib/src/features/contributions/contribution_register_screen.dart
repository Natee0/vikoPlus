import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class ContributionRegisterScreen extends StatelessWidget {
  const ContributionRegisterScreen({
    this.showBottomNavigation = true,
    super.key,
  });

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final julyPaid = sofiaMembers
        .where((member) => member.paidMonths >= 1)
        .length;

    return VikoplusScreen(
      title: 'Contribution Register',
      bottomNavigationIndex: 2,
      showBottomNavigation: showBottomNavigation,
      actions: [
        IconButton(
          tooltip: 'Record payment',
          onPressed: () => context.go('/contributions/record'),
          icon: const Icon(Icons.add_card_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatusPill(label: sofiaFinancialYear),
          const SizedBox(height: 16),
          const ActionTile(
            title: 'Loan applications',
            subtitle: 'Review guarantors, approve loans, and disburse funds',
            icon: Icons.fact_check_outlined,
            route: '/loans/applications',
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _MonthChip(label: 'July', selected: true),
                _MonthChip(label: 'Aug'),
                _MonthChip(label: 'Sept'),
                _MonthChip(label: 'Oct'),
                _MonthChip(label: 'Nov'),
                _MonthChip(label: 'Dec'),
                _MonthChip(label: 'Jan'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoCard(
            title: 'Total collected in July',
            value: formatters.money(65000),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: 'Paid',
                  value: '$julyPaid',
                  icon: Icons.check_circle_outline,
                  accentColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoCard(
                  title: 'Outstanding',
                  value: '${sofiaMembers.length - julyPaid}',
                  icon: Icons.pending_actions_outlined,
                  accentColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          for (final member in sofiaMembers) ...[
            _ContributionMemberRow(member: member, formatters: formatters),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
      ),
    );
  }
}

class _ContributionMemberRow extends StatelessWidget {
  const _ContributionMemberRow({
    required this.member,
    required this.formatters,
  });

  final SofiaMember member;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final paidJuly = member.paidMonths >= 1;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/members/${member.number}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                    const SizedBox(height: 3),
                    Text(
                      paidJuly
                          ? 'July allocation applied'
                          : 'July dues pending',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    paidJuly ? formatters.money(5000) : formatters.money(0),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  StatusPill(
                    label: paidJuly ? 'Paid' : 'Due',
                    color: paidJuly ? AppColors.primaryGreen : AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
