import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MemberListScreen extends StatelessWidget {
  const MemberListScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final outstandingCount = sofiaMembers
        .where((member) => member.outstanding > 0)
        .length;

    return VikoplusScreen(
      title: 'Members',
      bottomNavigationIndex: 1,
      showBottomNavigation: showBottomNavigation,
      actions: [
        IconButton(
          tooltip: 'Invite members',
          onPressed: () => context.push('/members/invite'),
          icon: const Icon(Icons.person_add_alt_outlined),
        ),
        IconButton(
          tooltip: 'Add member manually',
          onPressed: () => context.push('/members/add'),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ActionTile(
            title: 'Invite members',
            subtitle:
                'Share a role-based invitation code, link, SMS or WhatsApp',
            icon: Icons.person_add_alt_outlined,
            route: '/members/invite',
          ),
          const SizedBox(height: 12),
          const ActionTile(
            title: 'Add member manually',
            subtitle: 'Create a member record and assign their group role',
            icon: Icons.add_circle_outline,
            route: '/members/add',
            color: AppColors.secondaryGreen,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: 'Total members',
                  value: '${sofiaMembers.length}',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoCard(
                  title: 'Outstanding',
                  value: '$outstandingCount',
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _FilterChip(label: 'All', selected: true),
                _FilterChip(label: 'Active'),
                _FilterChip(label: 'Outstanding'),
                _FilterChip(label: 'Fully paid'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final member in sofiaMembers) ...[
            _MemberRow(member: member, formatters: formatters),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

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

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.formatters});

  final SofiaMember member;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final statusColor = member.fullyPaid
        ? AppColors.primaryGreen
        : member.totalPaid == 0
        ? AppColors.error
        : AppColors.warning;
    final status = member.fullyPaid
        ? 'Paid'
        : member.totalPaid == 0
        ? 'No payment'
        : 'Outstanding';

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
                      '${member.number}  |  ${member.paidMonths}/12 months paid',
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
                    formatters.money(member.totalPaid),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  StatusPill(label: status, color: statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
