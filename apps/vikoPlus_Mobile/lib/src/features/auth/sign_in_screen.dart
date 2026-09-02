import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/roles/vikoplus_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  VikoplusRole _selectedRole = VikoplusRole.newUser;

  void _submit() {
    final next = Uri.encodeQueryComponent(_selectedRole.verifyDestination);
    final back = Uri.encodeQueryComponent('/sign-in');
    context.push('/verify-account?next=$next&back=$back');
  }

  void _startGroupSetup() {
    final next = Uri.encodeQueryComponent('/create-or-join-group');
    final back = Uri.encodeQueryComponent('/sign-in');
    context.push('/verify-account?next=$next&back=$back');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vikoplus',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in to your account',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthField(
                  label: 'Phone number or email',
                  hint: 'Enter your detail',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthField(
                  label: 'Password',
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RoleDropdown(
                  value: _selectedRole,
                  onChanged: (role) {
                    if (role == null) return;
                    setState(() => _selectedRole = role);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Remember me',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(onPressed: _submit, child: const Text('Sign in')),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _startGroupSetup,
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('Create or join a group'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthTextLink(
            text: "Don't have an account? ",
            action: 'Create one',
            onPressed: () => context.push('/create-account'),
          ),
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.value, required this.onChanged});

  final VikoplusRole value;
  final ValueChanged<VikoplusRole?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Continue as',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
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
          items: VikoplusRole.values.map((role) {
            return DropdownMenuItem(value: role, child: Text(role.label));
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${value.description} Use this as a static role preview for existing accounts.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
