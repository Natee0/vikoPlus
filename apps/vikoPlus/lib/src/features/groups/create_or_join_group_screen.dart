import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale/locale_controller.dart';
import '../../core/auth/auth_controller.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../common/vikoplus_design_widgets.dart';

class CreateOrJoinGroupScreen extends ConsumerStatefulWidget {
  const CreateOrJoinGroupScreen({super.key});

  @override
  ConsumerState<CreateOrJoinGroupScreen> createState() =>
      _CreateOrJoinGroupState();
}

class _CreateOrJoinGroupState extends ConsumerState<CreateOrJoinGroupScreen> {
  bool _chooseLanguage = false;
  bool _savingLanguage = false;

  @override
  void initState() {
    super.initState();
    _checkLanguage();
  }

  Future<void> _checkLanguage() async {
    try {
      final needed = await ref
          .read(localeControllerProvider.notifier)
          .needsLanguageChoice();
      if (mounted) {
        setState(() {
          _chooseLanguage = needed;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chooseLanguage = true;
        });
      }
    }
  }

  Future<void> _selectLanguage(String code) async {
    if (_savingLanguage) {
      return;
    }
    setState(() {
      _savingLanguage = true;
    });
    try {
      await ref.read(localeControllerProvider.notifier).setLocale(Locale(code));
      if (mounted) {
        setState(() {
          _chooseLanguage = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthFailure.from(error).message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingLanguage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = Localizations.localeOf(context).languageCode == 'sw';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: VikoplusConstrainedContent(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    AppSpacing.unit * 13,
                    AppSpacing.screenEdge,
                    AppSpacing.lg,
                  ),
                  children: [
                    if (_chooseLanguage) ...[
                      const Text(
                        'Chagua lugha / Choose your language',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 320;
                          final buttons = [
                            OutlinedButton(
                              onPressed: _savingLanguage
                                  ? null
                                  : () => _selectLanguage('sw'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(
                                  AppSizes.compactInputHeight,
                                ),
                              ),
                              child: const Text('Kiswahili'),
                            ),
                            OutlinedButton(
                              onPressed: _savingLanguage
                                  ? null
                                  : () => _selectLanguage('en'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(
                                  AppSizes.compactInputHeight,
                                ),
                              ),
                              child: const Text('English'),
                            ),
                          ];
                          if (stacked) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buttons[0],
                                const SizedBox(height: AppSpacing.xs),
                                buttons[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: buttons[0]),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: buttons[1]),
                            ],
                          );
                        },
                      ),
                      if (_savingLanguage) const LinearProgressIndicator(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Text(
                      sw ? 'Karibu Vikoplus' : 'Welcome to Vikoplus',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sw
                          ? 'Chagua jinsi unavyotaka kuanza.'
                          : 'Choose how you want to get started.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GroupChoiceTile(
                      title: sw ? 'Unda kikundi kipya' : 'Create a new group',
                      subtitle: sw
                          ? 'Anzisha kikundi na uwaalike wanachama'
                          : 'Start a new group and invite\nmembers',
                      icon: Icons.add_circle_outline,
                      iconBackground: AppColors.primaryGreen,
                      iconColor: AppColors.onPrimaryContainer,
                      onTap: () => context.push('/groups/create'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GroupChoiceTile(
                      title: sw
                          ? 'Jiunge na kikundi'
                          : 'Join an existing group',
                      subtitle: sw
                          ? 'Weka msimbo wa mwaliko kujiunga na kikundi'
                          : 'Enter an invitation code to join a\ngroup',
                      icon: Icons.group_add_outlined,
                      iconBackground: AppColors.lightGreen,
                      iconColor: AppColors.primary,
                      onTap: () => context.push('/groups/join'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.base),
                      child: AspectRatio(
                        aspectRatio: 1.88,
                        child: Image.asset(
                          'assets/images/group_choice_community.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: const AuthLogoutIconButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupChoiceTile extends StatelessWidget {
  const _GroupChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: AppSizes.choiceIcon,
                height: AppSizes.choiceIcon,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 28,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
