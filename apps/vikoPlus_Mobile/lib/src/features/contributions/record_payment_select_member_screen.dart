import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class RecordPaymentSelectMemberScreen extends StatelessWidget {
  const RecordPaymentSelectMemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final recentMembers = sofiaMembers.take(2).toList();
    final allMembers = sofiaMembers.skip(2).take(5).toList();

    return VikoplusScreen(
      title: 'Record Payment',
      backRoute: '/contributions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Recent'),
          const SizedBox(height: AppSpacing.sm),
          _MemberSelectionList(members: recentMembers, formatter: formatter),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'All Members'),
          const SizedBox(height: AppSpacing.sm),
          _MemberSelectionList(members: allMembers, formatter: formatter),
        ],
      ),
    );
  }
}

class _MemberSelectionList extends StatelessWidget {
  const _MemberSelectionList({required this.members, required this.formatter});

  final List<SofiaMember> members;
  final AppFormatters formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < members.length; index++) ...[
            _SelectableMemberRow(member: members[index], formatter: formatter),
            if (index != members.length - 1)
              const Divider(height: 1, color: AppColors.surfaceVariant),
          ],
        ],
      ),
    );
  }
}

class _SelectableMemberRow extends StatelessWidget {
  const _SelectableMemberRow({required this.member, required this.formatter});

  final SofiaMember member;
  final AppFormatters formatter;

  @override
  Widget build(BuildContext context) {
    final outstanding = member.outstanding > 0;

    return Material(
      color: AppColors.surfaceContainerLowest,
      child: InkWell(
        onTap: () => context.go('/contributions/record/details'),
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                InitialsAvatar(
                  initials: member.initials,
                  color: outstanding ? AppColors.primary : AppColors.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'ID: ${member.number} | Regular Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.money(member.outstanding.clamp(0, 9999999)),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: outstanding
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      outstanding ? 'Outstanding' : 'Cleared',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: outstanding
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
