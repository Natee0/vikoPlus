import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/roles/vikoplus_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';
import '../common/profile_avatar.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({this.memberId, super.key});

  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final selectedMemberId = memberId;
    if (activeGroup == null || selectedMemberId == null) {
      return const _MissingMemberProfileState();
    }

    return _ApiMemberProfile(
      groupId: activeGroup.id,
      memberId: selectedMemberId,
    );
  }
}

class _MissingMemberProfileState extends StatelessWidget {
  const _MissingMemberProfileState();

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Member Profile',
      backRoute: '/members',
      child: EmptyStateCard(
        icon: Icons.person_search_outlined,
        title: 'Select a member',
        message: 'Open a group member from the members list to view details.',
        actionLabel: 'Back to Members',
        onAction: () => context.go('/members'),
      ),
    );
  }
}

class _ApiMemberProfile extends ConsumerStatefulWidget {
  const _ApiMemberProfile({required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  ConsumerState<_ApiMemberProfile> createState() => _ApiMemberProfileState();
}

class _ApiMemberProfileState extends ConsumerState<_ApiMemberProfile> {
  late Future<GroupMemberSummary> _memberFuture;
  String _errorMessage = '';
  bool _isAssigningRole = false;
  bool _isUpdatingStatus = false;

  Future<void> _changeStatus(GroupMemberSummary member, String status) async {
    if (_isUpdatingStatus || _isAssigningRole) return;
    final action = status == 'ACTIVE'
        ? 'Restore'
        : status == 'SUSPENDED'
        ? 'Suspend'
        : 'Remove';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action ${member.fullName}?'),
        content: Text(
          status == 'ACTIVE'
              ? 'This restores access to this group. Existing history is retained.'
              : 'Access to this group will be blocked. Contributions and history will remain, and other groups will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isUpdatingStatus) return;
    setState(() {
      _isUpdatingStatus = true;
      _errorMessage = '';
    });
    try {
      await ref
          .read(groupsRepositoryProvider)
          .updateMemberStatus(widget.groupId, member.id, status);
      if (!mounted) return;
      await _refresh();
    } on Object catch (error) {
      if (mounted)
        setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _memberFuture = _loadMember();
  }

  Future<GroupMemberSummary> _loadMember() {
    return ref
        .read(groupsRepositoryProvider)
        .member(widget.groupId, widget.memberId);
  }

  void _reload() {
    _memberFuture = _loadMember();
  }

  Future<void> _refresh() async {
    final future = _loadMember();
    setState(() => _memberFuture = future);
    await future;
  }

  String _apiRole(VikoplusRole role) {
    return switch (role) {
      VikoplusRole.chairperson => 'GROUP_ADMIN',
      VikoplusRole.treasurer => 'TREASURER',
      VikoplusRole.secretary => 'SECRETARY',
      VikoplusRole.member => 'MEMBER',
      VikoplusRole.newUser => 'MEMBER',
    };
  }

  VikoplusRole _roleFromApi(String role) {
    return switch (role) {
      'GROUP_ADMIN' => VikoplusRole.chairperson,
      'TREASURER' => VikoplusRole.treasurer,
      'SECRETARY' => VikoplusRole.secretary,
      _ => VikoplusRole.member,
    };
  }

  Future<void> _assignRole(GroupMemberSummary member) async {
    final selected = await showModalBottomSheet<VikoplusRole>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMobile,
              AppSpacing.sm,
              AppSpacing.screenMobile,
              AppSpacing.md,
            ),
            children: [
              Text(
                'Assign Role',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<VikoplusRole>(
                groupValue: _roleFromApi(member.role),
                onChanged: (value) => Navigator.of(context).pop(value),
                child: Column(
                  children: [
                    for (final role in VikoplusRole.values.where(
                      (role) => role != VikoplusRole.newUser,
                    ))
                      RadioListTile<VikoplusRole>(
                        value: role,
                        title: Text(role.label),
                        subtitle: Text(role.description),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || _isAssigningRole) return;

    try {
      setState(() {
        _errorMessage = '';
        _isAssigningRole = true;
      });
      await ref
          .read(groupsRepositoryProvider)
          .assignRole(widget.groupId, member.id, _apiRole(selected));
      if (!mounted) return;
      setState(_reload);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isAssigningRole = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Member Profile',
      backRoute: '/members',
      onRefresh: _refresh,
      child: FutureBuilder<GroupMemberSummary>(
        future: _memberFuture,
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
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            );
          }

          final member = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SurfacePanel(
                padding: AppInsets.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileAvatar(
                          name: member.fullName,
                          url: member.profilePictureUrl,
                          radius: 30,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.fullName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  StatusPill(label: _roleLabel(member.role)),
                                  StatusPill(label: _roleLabel(member.status)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    _ProfileDetail(
                      icon: Icons.badge_outlined,
                      label: 'Member number',
                      value: member.memberNumber,
                    ),
                    _ProfileDetail(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: member.phone,
                    ),
                    _ProfileDetail(
                      icon: Icons.mail_outline,
                      label: 'Email address',
                      value: member.email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthErrorMessage(message: _errorMessage),
              if (_errorMessage.isNotEmpty)
                const SizedBox(height: AppSpacing.sm),
              if (ref.watch(activeGroupProvider)?.role == 'GROUP_ADMIN' &&
                  member.status == 'ACTIVE')
                OutlinedButton.icon(
                  onPressed: _isAssigningRole || _isUpdatingStatus
                      ? null
                      : () => _assignRole(member),
                  icon: _isAssigningRole
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(
                    _isAssigningRole ? 'Updating role' : 'Assign Role',
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (ref.watch(activeGroupProvider)?.role == 'GROUP_ADMIN' &&
                  member.role != 'GROUP_ADMIN') ...[
                for (final status in [
                  'SUSPENDED',
                  'REMOVED',
                  if (member.userId != null &&
                      (member.status == 'SUSPENDED' ||
                          member.status == 'REMOVED' ||
                          member.status == 'DEACTIVATED'))
                    'ACTIVE',
                ])
                  if (member.status != status)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: OutlinedButton.icon(
                        onPressed: _isUpdatingStatus || _isAssigningRole
                            ? null
                            : () => _changeStatus(member, status),
                        icon: Icon(
                          status == 'ACTIVE'
                              ? Icons.person_add_alt
                              : status == 'SUSPENDED'
                              ? Icons.pause_circle_outline
                              : Icons.person_remove_outlined,
                        ),
                        label: Text(
                          status == 'ACTIVE'
                              ? 'Restore access'
                              : status == 'SUSPENDED'
                              ? 'Suspend member'
                              : 'Remove member',
                        ),
                      ),
                    ),
                if (_isUpdatingStatus)
                  const Center(child: CircularProgressIndicator()),
              ],
              if (member.status == 'ACTIVE')
                FilledButton.icon(
                  onPressed: () => context.go(
                    '/reminders/new?memberId=${Uri.encodeComponent(member.id)}',
                  ),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Send Reminder'),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (ref.watch(activeGroupProvider)?.role == 'TREASURER' &&
                  member.status == 'ACTIVE')
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/contributions/record/details?memberId=${Uri.encodeComponent(member.id)}',
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record Payment'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value?.trim().isNotEmpty == true
                      ? value!.trim()
                      : 'Not provided',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = AppInsets.compactCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}
