import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({this.showBottomNavigation = true, super.key});

  final bool showBottomNavigation;

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  String? _loadedMembersGroupId;
  Future<GroupMembersResult>? _membersFuture;

  @override
  void initState() {
    super.initState();
    final group = ref.read(activeGroupProvider);
    if (group != null) {
      _setMembersFuture(group.id);
    }
  }

  Future<GroupMembersResult> _loadMembers(String groupId) {
    return ref.read(groupsRepositoryProvider).listMembers(groupId);
  }

  void _setMembersFuture(String groupId, [Future<GroupMembersResult>? future]) {
    _loadedMembersGroupId = groupId;
    _membersFuture = future ?? _loadMembers(groupId);
  }

  void _ensureMembersFuture(String? groupId) {
    if (groupId == null || groupId.isEmpty) {
      _loadedMembersGroupId = null;
      _membersFuture = null;
      return;
    }
    if (_loadedMembersGroupId != groupId || _membersFuture == null) {
      _setMembersFuture(groupId);
    }
  }

  void _reload() {
    final group = ref.read(activeGroupProvider);
    setState(() {
      if (group == null) {
        _loadedMembersGroupId = null;
        _membersFuture = null;
        return;
      }
      _setMembersFuture(group.id);
    });
  }

  Future<void> _refresh() async {
    final group = ref.read(activeGroupProvider);
    if (group == null) return;

    final future = _loadMembers(group.id);
    setState(() => _setMembersFuture(group.id, future));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    _ensureMembersFuture(activeGroup?.id);

    return VikoplusScreen(
      title: 'Members',
      bottomNavigationIndex: 1,
      showBottomNavigation: widget.showBottomNavigation,
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
      onRefresh: activeGroup == null ? null : _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeGroup == null) ...[
            const AuthErrorMessage(
              message: 'Open a group before managing members.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/groups'),
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('Choose Group'),
            ),
            const SizedBox(height: 16),
          ],
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
          _MemberStatsRow(
            membersFuture: _membersFuture,
            fallbackMembersCount: activeGroup?.membersCount ?? 0,
            role: activeGroup?.role ?? 'NONE',
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
          _MemberListBody(membersFuture: _membersFuture, onReload: _reload),
        ],
      ),
    );
  }
}

class _MemberStatsRow extends StatelessWidget {
  const _MemberStatsRow({
    required this.membersFuture,
    required this.fallbackMembersCount,
    required this.role,
  });

  final Future<GroupMembersResult>? membersFuture;
  final int fallbackMembersCount;
  final String role;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GroupMembersResult>(
      future: membersFuture,
      builder: (context, snapshot) {
        final membersCount =
            snapshot.data?.members.length ?? fallbackMembersCount;
        return Row(
          children: [
            Expanded(
              child: InfoCard(
                title: 'Total members',
                value: '$membersCount',
                icon: Icons.groups_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoCard(
                title: 'Current role',
                value: _roleLabel(role),
                icon: Icons.admin_panel_settings_outlined,
                accentColor: AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemberListBody extends StatelessWidget {
  const _MemberListBody({required this.membersFuture, required this.onReload});

  final Future<GroupMembersResult>? membersFuture;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final future = membersFuture;
    if (future == null) return const SizedBox.shrink();

    return FutureBuilder<GroupMembersResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthErrorMessage(
                message: AuthFailure.from(snapshot.error!).message,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          );
        }

        final members = snapshot.data?.members ?? const [];
        if (members.isEmpty) {
          return const _EmptyMembersCard();
        }

        return Column(
          children: [
            for (final member in members) ...[
              _MemberRow(member: member),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyMembersCard extends StatelessWidget {
  const _EmptyMembersCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.surfaceContainer,
              child: Icon(Icons.person_add_alt_outlined),
            ),
            const SizedBox(height: 8),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add the first member or invite members to join this group.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ],
        ),
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
  const _MemberRow({required this.member});

  final GroupMemberSummary member;

  @override
  Widget build(BuildContext context) {
    final initials = member.fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final memberNumber = member.memberNumber?.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/members/${member.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              InitialsAvatar(initials: initials.isEmpty ? 'M' : initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${memberNumber == null || memberNumber.isEmpty ? 'No member number' : memberNumber}  |  ${_roleLabel(member.role)}',
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
                  Text(_roleLabel(member.role)),
                  const SizedBox(height: 4),
                  StatusPill(
                    label: _roleLabel(member.status),
                    color: member.status == 'ACTIVE'
                        ? AppColors.primaryGreen
                        : AppColors.warning,
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

String _roleLabel(String value) {
  return value
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
