import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/roles/vikoplus_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_design_widgets.dart';

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  VikoplusRole _defaultRole = VikoplusRole.member;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/members');
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
                        _AssignedRoleCard(
                          value: _defaultRole,
                          onChanged: (role) {
                            if (role == null) return;
                            setState(() => _defaultRole = role);
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _InviteCodeCard(),
                        const SizedBox(height: AppSpacing.sm),
                        const _InviteLinkCard(),
                        const SizedBox(height: AppSpacing.sm),
                        const _QrCodeCard(),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('Invite via WhatsApp'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.sms_outlined, size: 18),
                          label: const Text('Invite via SMS'),
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
  const _InviteCodeCard();

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
                  'SW-9982',
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
            onPressed: () {},
            icon: const Icon(Icons.content_copy),
          ),
        ],
      ),
    );
  }
}

class _InviteLinkCard extends StatelessWidget {
  const _InviteLinkCard();

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
              'https://vikoplus.app/join/sw-9982',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(onPressed: () {}, child: const Text('Copy')),
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
