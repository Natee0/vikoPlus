import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_design_widgets.dart';

class JoinGroupInvitationScreen extends ConsumerStatefulWidget {
  const JoinGroupInvitationScreen({super.key});

  @override
  ConsumerState<JoinGroupInvitationScreen> createState() =>
      _JoinGroupInvitationScreenState();
}

class _JoinGroupInvitationScreenState
    extends ConsumerState<JoinGroupInvitationScreen> {
  final _codeController = TextEditingController();
  JoinGroupPreview? _preview;
  String _errorMessage = '';
  bool _isPreviewing = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/create-or-join-group');
  }

  void _clearError() {
    if (_errorMessage.isEmpty) return;
    setState(() => _errorMessage = '');
  }

  Future<void> _previewCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.length < 4) {
      setState(() => _errorMessage = 'Enter a valid invitation code.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isPreviewing = true;
      });
      final preview =
          await ref.read(groupsRepositoryProvider).previewJoinCode(trimmed);
      if (!mounted) return;
      _codeController.text = trimmed;
      setState(() => _preview = preview);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isPreviewing = false);
      }
    }
  }

  Future<void> _joinGroup() async {
    if (_isJoining || _isPreviewing) return;

    final code = (_preview?.invitationCode ?? _codeController.text).trim();
    if (code.length < 4) {
      _showCodeSheet(context);
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isJoining = true;
      });
      await ref.read(groupsRepositoryProvider).joinGroup(code);
      if (!mounted) return;
      context.go('/groups');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _showCodeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.md,
            AppSpacing.screenEdge,
            AppSpacing.md + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enter Group Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use the invitation code shared by your group administrator.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => _clearError(),
                onSubmitted: (value) {
                  Navigator.of(sheetContext).pop();
                  _previewCode(value);
                },
                decoration: const InputDecoration(
                  hintText: 'Invitation code',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _previewCode(_codeController.text);
                },
                child: const Text('Verify group details'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final isBusy = _isPreviewing || _isJoining;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/create-or-join-group');
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.surface,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                VikoplusTopBar(
                  title: 'Vikoplus',
                  onBack: () => _goBack(context),
                  trailing: const _ProfileButton(),
                ),
                Expanded(
                  child: VikoplusConstrainedContent(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenEdge,
                        AppSpacing.xl,
                        AppSpacing.screenEdge,
                        AppSpacing.lg,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipOval(
                                child: Container(
                                  color: AppColors.surfaceContainerLowest,
                                  child: Image.asset(
                                    'assets/images/join_group_growth.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          preview?.group.name ?? 'Join an existing group',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: _MemberCountChip(
                            label: preview == null
                                ? 'Invitation required'
                                : '${preview.group.membersCount} Members',
                          ),
                        ),
                        if (preview != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'You will join as ${_roleLabel(preview.roleOnJoin)}.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: FilledButton(
                            onPressed: isBusy ? null : _joinGroup,
                            child: _isJoining
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    preview == null
                                        ? 'Enter Code to Join'
                                        : 'Join Group',
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => _showCodeSheet(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                AppSizes.buttonHeight,
                              ),
                              side: const BorderSide(
                                color: AppColors.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _isPreviewing
                                  ? 'Checking code'
                                  : 'Enter Group Code',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthErrorMessage(message: _errorMessage),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_outline,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }
}

class _MemberCountChip extends StatelessWidget {
  const _MemberCountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_2,
            size: 24,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
