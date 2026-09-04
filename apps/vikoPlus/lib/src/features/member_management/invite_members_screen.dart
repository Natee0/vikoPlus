import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/roles/vikoplus_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_design_widgets.dart';

class InviteMembersScreen extends ConsumerStatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  ConsumerState<InviteMembersScreen> createState() =>
      _InviteMembersScreenState();
}

class _InviteMembersScreenState extends ConsumerState<InviteMembersScreen> {
  final _recipientController = TextEditingController();
  VikoplusRole _defaultRole = VikoplusRole.member;
  MemberInvitation? _latestInvitation;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/members');
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

  Future<void> _generateInvite() async {
    if (_isSubmitting) return;

    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      setState(() => _errorMessage = 'Open a group before inviting members.');
      return;
    }

    final recipient = _recipientController.text.trim();
    if (recipient.length < 4) {
      setState(() => _errorMessage = 'Enter a phone number or email.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final result = await ref.read(groupsRepositoryProvider).inviteMembers(
            activeGroup.id,
            InviteMembersInput(recipients: [recipient], role: _apiRole(_defaultRole)),
          );
      if (!mounted) return;
      setState(
        () => _latestInvitation =
            result.invitations.isEmpty ? null : result.invitations.first,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _copyInviteCode() async {
    final code = _latestInvitation?.invitationCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/members');
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
                VikoplusTopBar(title: 'Invite Members', onBack: _goBack),
                Expanded(
                  child: VikoplusConstrainedContent(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenMobile,
                        AppSpacing.md,
                        AppSpacing.screenMobile,
                        AppSpacing.lg,
                      ),
                      children: [
                        const _InviteHero(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Share this code or link with new members. The chairperson/admin chooses the role attached to this invitation.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _recipientController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) {
                            if (_errorMessage.isNotEmpty) {
                              setState(() => _errorMessage = '');
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Phone number or email',
                            hintText: '+255 7XX XXX XXX',
                            prefixIcon: Icon(Icons.alternate_email_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _AssignedRoleCard(
                          value: _defaultRole,
                          onChanged: (role) {
                            if (role == null) return;
                            setState(() => _defaultRole = role);
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InviteCodeCard(
                          code: _latestInvitation?.invitationCode,
                          onCopy: _copyInviteCode,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InviteLinkCard(code: _latestInvitation?.invitationCode),
                        const SizedBox(height: AppSpacing.sm),
                        const _QrCodeCard(),
                        const SizedBox(height: AppSpacing.md),
                        AuthErrorMessage(message: _errorMessage),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _generateInvite,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add_alt_outlined, size: 18),
                          label: Text(
                            _isSubmitting ? 'Generating' : 'Generate Invitation',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _latestInvitation == null
                              ? null
                              : _copyInviteCode,
                          icon: const Icon(Icons.sms_outlined, size: 18),
                          label: const Text('Copy Code'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: () => context.push('/members/add'),
                          icon: const Icon(Icons.person_add_alt_outlined),
                          label: const Text('Add member manually'),
                        ),
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
}

class _InviteHero extends StatelessWidget {
  const _InviteHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 176,
        height: 176,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.group_add_outlined,
          color: AppColors.onPrimaryContainer,
          size: 72,
        ),
      ),
    );
  }
}

class _AssignedRoleCard extends StatelessWidget {
  const _AssignedRoleCard({required this.value, required this.onChanged});

  final VikoplusRole value;
  final ValueChanged<VikoplusRole?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assigned Role',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New members receive this role after they join.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<VikoplusRole>(
            initialValue: value,
            icon: const Icon(Icons.expand_more),
            decoration: InputDecoration(
              prefixIcon: Icon(value.icon, size: 22),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
            ),
            items: VikoplusRole.values
                .where((role) => role != VikoplusRole.newUser)
                .map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.label));
                })
                .toList(),
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.description,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code, required this.onCopy});

  final String? code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Code',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  code ?? 'No code yet',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy code',
            onPressed: code == null ? null : onCopy,
            icon: const Icon(Icons.content_copy),
          ),
        ],
      ),
    );
  }
}

class _InviteLinkCard extends StatelessWidget {
  const _InviteLinkCard({required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              code == null
                  ? 'Generate a code to create an invite link'
                  : 'https://vikoplus.app/join/$code',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: code == null
                ? null
                : () => Clipboard.setData(
                      ClipboardData(text: 'https://vikoplus.app/join/$code'),
                    ),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _QrCodeCard extends StatelessWidget {
  const _QrCodeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Scan to Join',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 152,
            height: 152,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.outlineVariant, width: 2),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 96,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Members can scan this code from their camera.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
