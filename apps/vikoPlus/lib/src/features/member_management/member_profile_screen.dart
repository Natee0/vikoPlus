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

  String _initials(String fullName) {
    final initials = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? 'M' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Member Profile',
      backRoute: '/members',
      actions: [
        if (ref.watch(activeGroupProvider)?.role == 'GROUP_ADMIN')
          IconButton(
            onPressed: _isAssigningRole ? null : () {},
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit member',
          ),
      ],
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
                  children: [
                    InitialsAvatar(initials: _initials(member.fullName)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      member.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusPill(label: _roleLabel(member.role)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (member.phone != null)
                          _InlineInfo(
                            icon: Icons.phone_outlined,
                            label: member.phone!,
                          ),
                        if (member.email != null)
                          _InlineInfo(
                            icon: Icons.mail_outline,
                            label: member.email!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthErrorMessage(message: _errorMessage),
              if (_errorMessage.isNotEmpty)
                const SizedBox(height: AppSpacing.sm),
              if (ref.watch(activeGroupProvider)?.role == 'GROUP_ADMIN')
                OutlinedButton.icon(
                  onPressed: _isAssigningRole
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
              FilledButton.icon(
                onPressed: () => context.go(
                  '/reminders/new?memberId=${Uri.encodeComponent(member.id)}',
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Reminder'),
              ),
              const SizedBox(height: AppSpacing.sm),
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

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.outline),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
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
