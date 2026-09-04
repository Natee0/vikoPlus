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

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _memberNumberController = TextEditingController();
  VikoplusRole _role = VikoplusRole.member;
  bool _requireJoiningFee = true;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _memberNumberController.dispose();
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

  void _clearError() {
    if (_errorMessage.isEmpty) return;
    setState(() => _errorMessage = '');
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      setState(() => _errorMessage = 'Open a group before adding members.');
      return;
    }

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (fullName.length < 2) {
      setState(() => _errorMessage = 'Enter the member full name.');
      return;
    }
    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final role = _apiRole(_role);
      await ref.read(groupsRepositoryProvider).addMember(
            activeGroup.id,
            AddMemberInput(
              fullName: fullName,
              memberNumber: _memberNumberController.text,
              phone: phone,
              email: email,
              role: role,
            ),
          );
      if (!mounted) return;
      ref.read(activeGroupProvider.notifier).setGroup(
            GroupAccessSummary(
              id: activeGroup.id,
              name: activeGroup.name,
              role: activeGroup.role,
              status: activeGroup.status,
              membersCount: activeGroup.membersCount + 1,
            ),
      );
      context.go('/members');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                VikoplusTopBar(title: 'Add Member', onBack: _goBack),
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
                        const _PhotoUploader(),
                        const SizedBox(height: AppSpacing.md),
                        _FormCard(
                          title: 'Personal Information',
                          children: [
                            _MemberTextField(
                              label: 'Full Name',
                              requiredField: true,
                              hint: 'Enter full name',
                              controller: _fullNameController,
                              onChanged: (_) => _clearError(),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _MemberTextField(
                              label: 'Phone Number',
                              requiredField: true,
                              hint: '+255 7XX XXX XXX',
                              controller: _phoneController,
                              onChanged: (_) => _clearError(),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _MemberTextField(
                              label: 'Email Address',
                              optionalLabel: '(Optional)',
                              hint: 'member@example.com',
                              controller: _emailController,
                              onChanged: (_) => _clearError(),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _FormCard(
                          title: 'Membership Details',
                          children: [
                            Text(
                              'Assign the role this member will use in the group.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _MemberTextField(
                              label: 'Member Number',
                              hint: 'Auto-generated if empty',
                              controller: _memberNumberController,
                              onChanged: (_) => _clearError(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _RoleAssignmentField(
                              value: _role,
                              onChanged: (role) {
                                if (role == null) return;
                                setState(() => _role = role);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _FormCard(
                          title: 'Settings & Invitations',
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: SwitchListTile(
                                value: _requireJoiningFee,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (value) {
                                  setState(() => _requireJoiningFee = value);
                                },
                                title: const Text('Require Joining Fee'),
                                subtitle: const Text(
                                  'Create the joining fee obligation for this member.',
                                ),
                              ),
                            ),
                            const Divider(color: AppColors.outlineVariant),
                            Text(
                              'Use Invite Members when this person needs their own app login and a role-based join code.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AuthErrorMessage(message: _errorMessage),
                      ],
                    ),
                  ),
                ),
                VikoplusBottomActionBar(
                  label: _isSubmitting ? 'Saving' : 'Save Member',
                  icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoUploader extends StatelessWidget {
  const _PhotoUploader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outlineVariant, width: 2),
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            color: AppColors.onSurfaceVariant,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Upload Photo (Optional)',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _MemberTextField extends StatelessWidget {
  const _MemberTextField({
    required this.label,
    required this.hint,
    this.requiredField = false,
    this.optionalLabel,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final bool requiredField;
  final String? optionalLabel;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MemberFieldLabel(
          label: label,
          requiredField: requiredField,
          optionalLabel: optionalLabel,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _MemberFieldLabel extends StatelessWidget {
  const _MemberFieldLabel({
    required this.label,
    this.requiredField = false,
    this.optionalLabel,
  });

  final String label;
  final bool requiredField;
  final String? optionalLabel;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
          if (optionalLabel != null)
            TextSpan(
              text: ' $optionalLabel',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
    );
  }
}

class _RoleAssignmentField extends StatelessWidget {
  const _RoleAssignmentField({required this.value, required this.onChanged});

  final VikoplusRole value;
  final ValueChanged<VikoplusRole?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MemberFieldLabel(label: 'Role', requiredField: true),
        const SizedBox(height: AppSpacing.xs),
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
    );
  }
}
