import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../routing/portal_route_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class VerifyGroupDetailsScreen extends ConsumerStatefulWidget {
  const VerifyGroupDetailsScreen({this.invitationCode, super.key});

  final String? invitationCode;

  @override
  ConsumerState<VerifyGroupDetailsScreen> createState() =>
      _VerifyGroupDetailsScreenState();
}

class _VerifyGroupDetailsScreenState
    extends ConsumerState<VerifyGroupDetailsScreen> {
  late Future<JoinGroupPreview>? _previewFuture;
  bool _isJoining = false;
  String _errorMessage = '';

  String get _code => widget.invitationCode?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _previewFuture = _loadPreview();
  }

  Future<JoinGroupPreview>? _loadPreview() {
    if (_code.isEmpty) return null;
    return ref.read(groupsRepositoryProvider).previewJoinCode(_code);
  }

  Future<void> _refresh() async {
    final future = _loadPreview();
    setState(() => _previewFuture = future);
    await future;
  }

  Future<void> _join(JoinGroupPreview preview) async {
    if (_isJoining) return;

    try {
      setState(() {
        _errorMessage = '';
        _isJoining = true;
      });
      final result = await ref
          .read(groupsRepositoryProvider)
          .joinGroup(preview.invitationCode);
      if (!mounted) return;
      ref.read(activeGroupProvider.notifier).setGroup(
            GroupAccessSummary(
              id: result.groupId,
              name: preview.group.name,
              role: result.role,
              status: result.status,
              membersCount: preview.group.membersCount,
            ),
      );
      if (!mounted) return;
      context.go(routeForGroupRole(result.role));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewFuture = _previewFuture;

    return VikoplusScreen(
      title: 'Verify Group',
      backRoute: '/groups/join',
      onRefresh: _previewFuture == null ? null : _refresh,
      child: previewFuture == null
          ? EmptyStateCard(
              icon: Icons.key_off_outlined,
              title: 'Invitation code required',
              message: 'Enter an invitation code to verify a group.',
              actionLabel: 'Enter Code',
              onAction: () => context.go('/groups/join'),
            )
          : FutureBuilder<JoinGroupPreview>(
              future: previewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthErrorMessage(
                        message: AuthFailure.from(
                          snapshot.error ?? 'Could not verify group.',
                        ).message,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => context.go('/groups/join'),
                        child: const Text('Try Another Code'),
                      ),
                    ],
                  );
                }

                final preview = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: AppInsets.card,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        boxShadow: AppShadows.level1(),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surfaceContainer,
                            child: Icon(
                              Icons.groups_2_outlined,
                              color: AppColors.primary,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            preview.group.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatusPill(
                            label:
                                '${preview.group.membersCount} ${preview.group.membersCount == 1 ? 'Member' : 'Members'}',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          StatusPill(label: 'Role: ${_roleLabel(preview.roleOnJoin)}'),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Your invitation is valid. Join this group to access your member workspace.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorMessage(message: _errorMessage),
                    if (_errorMessage.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: _isJoining ? null : () => _join(preview),
                      child: _isJoining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Join Group'),
                    ),
                  ],
                );
              },
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
