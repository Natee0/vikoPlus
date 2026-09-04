import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_design_tokens.dart';
import '../../common/vikoplus_design_widgets.dart';

class PasswordResetScaffold extends StatelessWidget {
  const PasswordResetScaffold({
    required this.title,
    required this.child,
    required this.onBack,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: VikoplusConstrainedContent(
            child: Column(
              children: [
                VikoplusTopBar(
                  title: title,
                  onBack: onBack,
                  trailing: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.onPrimary,
                      size: 18,
                    ),
                  ),
                  showBorder: false,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenMobile,
                      AppSpacing.sm,
                      AppSpacing.screenMobile,
                      AppSpacing.md,
                    ),
                    children: [child],
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

class ResetHeroIcon extends StatelessWidget {
  const ResetHeroIcon({
    required this.icon,
    required this.badgeIcon,
    this.size = 72,
    super.key,
  });

  final IconData icon;
  final IconData badgeIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed.withValues(alpha: 0.65),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: size * 0.44),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Icon(
                badgeIcon,
                color: AppColors.primary,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrustNote extends StatelessWidget {
  const TrustNote({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.base),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondaryFixed,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RequirementRow extends StatelessWidget {
  const RequirementRow({required this.passed, required this.text, super.key});

  final bool passed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? AppColors.primary : AppColors.outline,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        passed ? AppColors.primaryText : AppColors.secondaryText,
                    fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
