import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MyGroupsScreen extends ConsumerStatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  ConsumerState<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends ConsumerState<MyGroupsScreen> {
  late Future<MyGroupsResult> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = ref.read(groupsRepositoryProvider).myGroups();
  }

  void _reload() {
    setState(() {
      _groupsFuture = ref.read(groupsRepositoryProvider).myGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'My Groups',
      backRoute: '/dashboard',
      actions: [
        const AuthLogoutIconButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a group to open, create a new group, or join one using an invitation.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _GroupActionButton(
                  label: 'Create group',
                  route: '/groups/create',
                  icon: Icons.add_circle_outline,
                  filled: true,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GroupActionButton(
                  label: 'Join group',
                  route: '/groups/join',
                  icon: Icons.group_add_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Groups you can access'),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<MyGroupsResult>(
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthErrorMessage(
                      message: AuthFailure.from(snapshot.error!).message,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                );
              }

              final groups = snapshot.data?.groups ?? const [];
              if (groups.isEmpty) {
                return const _EmptyGroupsCard();
              }

              return Column(
                children: [
                  for (final group in groups) ...[
                    _GroupAccessCard(
                      group: group,
                      onOpen: () {
                        ref.read(activeGroupProvider.notifier).setGroup(group);
                        context.go(_routeForRole(group.role));
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  const _GroupActionButton({
    required this.label,
    required this.route,
    required this.icon,
    this.filled = false,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => context.go(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
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
            'No groups yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a group or join one with an invitation code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
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
    final accent = highlighted ? AppColors.primaryContainer : AppColors.primary;
    final role = _roleLabel(group.role);

    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: highlighted
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
                child: Icon(icon, color: accent),
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
                          label: _statusLabel(group.status),
                          color: group.status == 'INVITED'
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
                          label: '${group.membersCount} members',
                          icon: Icons.groups_2_outlined,
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
    return role
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
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

String _routeForRole(String role) {
  if (role == 'MEMBER') return '/member/dashboard';
  return '/dashboard';
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
