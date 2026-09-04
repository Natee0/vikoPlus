import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';

class VikoplusConstrainedContent extends StatelessWidget {
  const VikoplusConstrainedContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: child,
      ),
    );
  }
}

class VikoplusTopBar extends StatelessWidget {
  const VikoplusTopBar({
    required this.title,
    this.onBack,
    this.trailing,
    this.showBorder = true,
    this.trailingWidth = AppSizes.iconButton,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBorder;
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.topBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: showBorder
            ? const Border(bottom: BorderSide(color: AppColors.outlineVariant))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.iconButton,
            height: AppSizes.iconButton,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: trailingWidth,
            height: AppSizes.iconButton,
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

class VikoplusBottomActionBar extends StatelessWidget {
  const VikoplusBottomActionBar({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.sm,
        AppSpacing.screenEdge,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: VikoplusConstrainedContent(
        child: icon == null
            ? FilledButton(
                onPressed: isLoading ? null : onPressed,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(label),
              )
            : FilledButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : icon!,
                iconAlignment: IconAlignment.end,
                label: Text(label),
              ),
      ),
    );
  }
}
