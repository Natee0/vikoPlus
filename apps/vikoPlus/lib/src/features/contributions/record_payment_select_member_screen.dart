import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class RecordPaymentSelectMemberScreen extends ConsumerWidget {
  const RecordPaymentSelectMemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: 'Record Payment',
      backRoute: '/contributions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeGroup == null) ...[
            const AuthErrorMessage(
              message: 'Select a group before recording a payment.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/groups/my'),
              child: const Text('Choose Group'),
            ),
          ] else ...[
            TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: activeGroup.name,
                prefixIcon: const Icon(Icons.groups_2_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'All Members'),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<GroupMembersResult>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .listMembers(activeGroup.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const AuthErrorMessage(
                    message: 'Could not load group members. Please try again.',
                  );
                }

                final members = snapshot.data?.members ?? const [];
                if (members.isEmpty) {
                  return const AuthErrorMessage(
                    message: 'Add members before recording contributions.',
                  );
                }

                return _MemberSelectionList(
                  members: members,
                  formatter: formatter,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberSelectionList extends StatelessWidget {
  const _MemberSelectionList({required this.members, required this.formatter});

  final List<GroupMemberSummary> members;
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

  final GroupMemberSummary member;
  final AppFormatters formatter;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      child: InkWell(
        onTap: () => context.go(
          '/contributions/record/details?memberId=${Uri.encodeComponent(member.id)}',
        ),
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                InitialsAvatar(initials: _initials(member.fullName)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          if (member.memberNumber != null)
                            'ID: ${member.memberNumber}',
                          _roleLabel(member.role),
                        ].join(' | '),
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
                      formatter.money(0),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      member.status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
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

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'M';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

String _roleLabel(String role) {
  return role
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}
