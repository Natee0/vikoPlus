import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/locale/locale_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final selected =
        ref.watch(localeControllerProvider).value?.languageCode ?? 'sw';

    return VikoplusScreen(
      title: loc.selectLanguage,
      backRoute: '/welcome',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
                boxShadow: AppShadows.level1(),
              ),
              child: const Icon(
                Icons.language_outlined,
                color: AppColors.primary,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose your language',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You can change this later from app settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (value) => _setLocale(context, ref, value),
            child: Column(
              children: [
                _LanguageTile(
                  value: 'sw',
                  title: loc.languageSwahili,
                  subtitle: 'Tumia Vikoplus kwa Kiswahili',
                  selected: selected == 'sw',
                ),
                const SizedBox(height: AppSpacing.sm),
                _LanguageTile(
                  value: 'en',
                  title: loc.languageEnglish,
                  subtitle: 'Use Vikoplus in English',
                  selected: selected == 'en',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
              }
            },
            child: Text(loc.continueAction),
          ),
        ],
      ),
    );
  }

  Future<void> _setLocale(
    BuildContext context,
    WidgetRef ref,
    String? value,
  ) async {
    if (value == null) return;
    await ref.read(localeControllerProvider.notifier).setLocale(Locale(value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).languageSaved)),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String value;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.08)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: AppShadows.level1(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: RadioListTile<String>(
          value: value,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          secondary: CircleAvatar(
            backgroundColor: selected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainer,
            child: Icon(
              Icons.translate_outlined,
              color: selected ? AppColors.onPrimary : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
