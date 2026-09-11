import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/profile_provider.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../routing/portal_route_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/profile_avatar.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MyGroupsScreen extends ConsumerStatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  ConsumerState<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends ConsumerState<MyGroupsScreen> {
  late Future<MyGroupsResult> _groupsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showGroupActions = false;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<MyGroupsResult> _loadGroups() {
    return ref.read(groupsRepositoryProvider).myGroups();
  }

  void _reload() {
    setState(() {
      _groupsFuture = _loadGroups();
    });
  }

  Future<void> _refresh() async {
    final future = _loadGroups();
    setState(() {
      _groupsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final displayName = (profile?['displayName'] as String?)?.trim();
    final profileName = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'Member';
    final profilePictureUrl = profile?['profilePictureUrl'] as String?;

    return VikoplusScreen(
      title: context.vt('My Groups'),
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/profile/complete'),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: ProfileAvatar(
            name: profileName,
            url: profilePictureUrl,
            radius: 18,
          ),
        ),
      ),
      leadingWidth: AppSizes.iconButton + AppSpacing.sm,
      backRoute: portalHomeRoute(activeGroup),
      showBackButton: false,
      actions: [
        const AuthLogoutIconButton(),
      ],
      onRefresh: _refresh,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical -
            AppSizes.topBarHeight -
            AppSpacing.xl,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.vt(
                    'Choose a group to open, create a new group, or join one using an invitation.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                _GroupSearchField(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: context.vt('Groups you can access')),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: FutureBuilder<MyGroupsResult>(
                    future: _groupsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            AuthErrorMessage(
                              message: context.vt(
                                AuthFailure.from(snapshot.error!).message,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh),
                              label: Text(context.vt('Try again')),
                            ),
                          ],
                        );
                      }

                      final groups = snapshot.data?.groups ?? const [];
                      if (groups.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [_EmptyGroupsCard()],
                        );
                      }

                      final filteredGroups = _filteredGroups(groups);
                      if (filteredGroups.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _NoMatchingGroupsCard(
                              onClear: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xl + AppSpacing.lg,
                        ),
                        itemCount: filteredGroups.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          return _GroupAccessCard(
                            group: group,
                            onOpen: () => _openGroup(group),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            _GroupActionFab(
              expanded: _showGroupActions,
              onToggle: () {
                setState(() => _showGroupActions = !_showGroupActions);
              },
              onCreate: () {
                setState(() => _showGroupActions = false);
                context.go(
                  '/groups/create?returnTo=${Uri.encodeComponent('/groups')}',
                );
              },
              onJoin: () {
                setState(() => _showGroupActions = false);
                context.go(
                  '/groups/join?returnTo=${Uri.encodeComponent('/groups')}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<GroupAccessSummary> _filteredGroups(List<GroupAccessSummary> groups) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return groups;
    return groups.where((group) {
      return group.name.toLowerCase().contains(query) ||
          _formatRoleLabel(group.role).toLowerCase().contains(query);
    }).toList();
  }

  void _openGroup(GroupAccessSummary group) {
    ref.read(activeGroupProvider.notifier).setGroup(group);
    if (group.hasPaidFeatureAccess == false) {
      if (group.role == 'GROUP_ADMIN') {
        context.go(
          '/billing/plans?groupId=${Uri.encodeComponent(group.id)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.vt(
                'Group access has expired. Ask the group admin to renew the plan.',
              ),
            ),
          ),
        );
      }
      return;
    }
    context.go(routeForGroupRole(group.role));
  }
}

class _GroupSearchField extends StatelessWidget {
  const _GroupSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: context.vt('Clear search'),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close),
              ),
        hintText: context.vt('Search groups...'),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
    );
  }
}

class _EmptyGroupsCard extends StatelessWidget {
  const _EmptyGroupsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(Icons.groups_2_outlined, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.vt('No groups yet'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.vt('Create a group or join one with an invitation code.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _NoMatchingGroupsCard extends StatelessWidget {
  const _NoMatchingGroupsCard({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(Icons.search_off_outlined, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.vt('No matching groups'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.vt('Try another group name or clear the search.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            label: Text(context.vt('Clear search')),
          ),
        ],
      ),
    );
  }
}

class _GroupActionFab extends StatelessWidget {
  const _GroupActionFab({
    required this.expanded,
    required this.onToggle,
    required this.onCreate,
    required this.onJoin,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expanded) ...[
            _FabOption(
              label: context.vt('Create group'),
              icon: Icons.add_circle_outline,
              onPressed: onCreate,
            ),
            const SizedBox(height: AppSpacing.xs),
            _FabOption(
              label: context.vt('Join group'),
              icon: Icons.group_add_outlined,
              onPressed: onJoin,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          FloatingActionButton.extended(
            heroTag: 'my-groups-actions',
            onPressed: onToggle,
            icon: Icon(expanded ? Icons.close : Icons.add),
            label: Text(context.vt('Group actions')),
          ),
        ],
      ),
    );
  }
}

class _FabOption extends StatelessWidget {
  const _FabOption({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupAccessCard extends StatelessWidget {
  const _GroupAccessCard({required this.group, required this.onOpen});

  final GroupAccessSummary group;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final highlighted = group.role == 'GROUP_ADMIN';
    final expired = group.hasPaidFeatureAccess == false;
    final accent = highlighted ? AppColors.primaryContainer : AppColors.primary;
    final role = _roleLabel(group.role);

    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: expired
              ? AppColors.warning
              : highlighted
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant,
          width: highlighted ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onOpen,
        child: Padding(
          padding: AppInsets.compactCard,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: ProfileAvatar(
                  name: group.name,
                  url: group.logoUrl,
                  radius: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StatusPill(
                          label: expired
                              ? context.vt('Access expired')
                              : _statusLabel(group.status),
                          color: expired || group.status == 'INVITED'
                              ? AppColors.warning
                              : AppColors.primaryGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _subtitleForRole(group.role),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MiniChip(label: role, icon: Icons.badge_outlined),
                        _MiniChip(
                          label: context
                              .vt('{count} members')
                              .replaceAll('{count}', '${group.membersCount}'),
                          icon: Icons.groups_2_outlined,
                        ),
                        if (expired)
                          _MiniChip(
                            label: group.role == 'GROUP_ADMIN'
                                ? context.vt('Renew plan')
                                : context.vt('Admin renewal required'),
                            icon: Icons.lock_clock_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get icon {
    switch (group.role) {
      case 'GROUP_ADMIN':
        return Icons.admin_panel_settings_outlined;
      case 'TREASURER':
        return Icons.account_balance_wallet_outlined;
      case 'SECRETARY':
        return Icons.edit_note_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _subtitleForRole(String role) {
    switch (role) {
      case 'GROUP_ADMIN':
        return 'Owner and chairperson controls';
      case 'TREASURER':
        return 'Contribution and payment controls';
      case 'SECRETARY':
        return 'Member records and reports';
      default:
        return 'Member contribution portal';
    }
  }

  String _roleLabel(String role) {
    return _formatRoleLabel(role);
  }

  String _statusLabel(String status) {
    return status
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

String _formatRoleLabel(String role) {
  return role
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
