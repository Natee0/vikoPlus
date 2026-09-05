import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_design_widgets.dart';

class ConfigureFinancialYearScreen extends ConsumerStatefulWidget {
  const ConfigureFinancialYearScreen({this.groupId, this.returnTo, super.key});

  final String? groupId;
  final String? returnTo;

  @override
  ConsumerState<ConfigureFinancialYearScreen> createState() =>
      _ConfigureFinancialYearScreenState();
}

class _ConfigureFinancialYearScreenState
    extends ConsumerState<ConfigureFinancialYearScreen> {
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late DateTime _startDate;
  bool _automaticRollover = true;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(groupSetupDraftProvider).financialYear;
    _startDate = draft.startDate ?? _defaultStartDate();
    _automaticRollover = draft.automaticRollover;
  }

  static DateTime _defaultStartDate() => DateUtils.dateOnly(DateTime.now());

  DateTime get _startsAt =>
      DateTime(_startDate.year, _startDate.month, _startDate.day);
  DateTime get _endsAt {
    final targetYear = _startDate.year + 1;
    final lastDay = DateUtils.getDaysInMonth(targetYear, _startDate.month);
    final day = _startDate.day > lastDay ? lastDay : _startDate.day;
    return DateTime(targetYear, _startDate.month, day, 23, 59, 59);
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${_shortMonths[date.month - 1]} ${date.year}';
  }

  String get _periodPreview {
    return '${_dateLabel(_startsAt)} - ${_dateLabel(_endsAt)}';
  }

  String? get _groupId {
    final widgetGroupId = widget.groupId;
    if (widgetGroupId != null && widgetGroupId.isNotEmpty) {
      return widgetGroupId;
    }
    final draftGroupId = ref.read(groupSetupDraftProvider).createdGroupId;
    if (draftGroupId != null && draftGroupId.isNotEmpty) {
      return draftGroupId;
    }
    return ref.read(activeGroupProvider)?.id;
  }

  String get _fallbackBackRoute {
    final returnTo = widget.returnTo;
    if (returnTo != null && returnTo.isNotEmpty) return returnTo;
    if (ref.read(activeGroupProvider) != null) return '/dashboard';
    return '/groups/create';
  }

  bool get _preferFallbackBack {
    final returnTo = widget.returnTo;
    return (returnTo != null && returnTo.isNotEmpty) ||
        (widget.groupId == null && ref.read(activeGroupProvider) != null);
  }

  void _goBack() {
    _persistFinancialYear();
    if (_preferFallbackBack) {
      context.go(_fallbackBackRoute);
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(_fallbackBackRoute);
  }

  void _persistFinancialYear() {
    ref.read(groupSetupDraftProvider.notifier).updateFinancialYear(
          FinancialYearDraft(
            startMonth: _startDate.month,
            startDate: _startsAt,
            automaticRollover: _automaticRollover,
          ),
        );
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(1990),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );
    if (selected == null) return;
    setState(() => _startDate = selected);
    _persistFinancialYear();
  }

  Future<void> _submit() async {
    final groupId = _groupId;
    if (_isSubmitting) return;
    if (groupId == null || groupId.isEmpty) {
      setState(
        () => _errorMessage = 'Create a group before setting its financial year.',
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      _persistFinancialYear();
      await ref.read(groupsRepositoryProvider).saveFinancialYear(
            groupId,
            FinancialYearInput(
              name: _periodPreview,
              startsAt: _startsAt,
              endsAt: _endsAt,
              automaticRollover: _automaticRollover,
            ),
          );
      if (!mounted) return;
      final returnTo = widget.returnTo;
      final route = returnTo == null || returnTo.isEmpty
          ? '/groups/contributions?groupId=${Uri.encodeComponent(groupId)}'
          : '/groups/contributions?groupId=${Uri.encodeComponent(groupId)}&returnTo=${Uri.encodeComponent(returnTo)}';
      context.push(route);
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
      canPop: !_preferFallbackBack && context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _persistFinancialYear();
          context.go(_fallbackBackRoute);
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
                VikoplusTopBar(title: 'Financial Year', onBack: _goBack),
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
                        Text(
                          'Configure Cycle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Set the start and end of your group's financial year. This determines reporting and contribution cycles.",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RecommendationCard(period: _periodPreview),
                        const SizedBox(height: AppSpacing.md),
                        _ConfigurationCard(
                          startDate: _startsAt,
                          endDate: _endsAt,
                          periodPreview: _periodPreview,
                          dateLabel: _dateLabel,
                          onStartDatePressed: _pickStartDate,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RolloverTile(
                          value: _automaticRollover,
                          onChanged: (value) {
                            setState(() => _automaticRollover = value);
                            _persistFinancialYear();
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _WhyItMattersCard(),
                        const SizedBox(height: AppSpacing.sm),
                        AuthErrorMessage(message: _errorMessage),
                      ],
                    ),
                  ),
                ),
                VikoplusBottomActionBar(
                  label: _isSubmitting ? 'Saving' : 'Continue',
                  icon: const Icon(Icons.arrow_forward, size: 18),
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended current year',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  period,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
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

class _ConfigurationCard extends StatelessWidget {
  const _ConfigurationCard({
    required this.startDate,
    required this.endDate,
    required this.periodPreview,
    required this.dateLabel,
    required this.onStartDatePressed,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String periodPreview;
  final String Function(DateTime date) dateLabel;
  final VoidCallback onStartDatePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primaryContainer,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Current Financial Year',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DateSelectField(
            label: 'Start Date',
            value: dateLabel(startDate),
            onTap: onStartDatePressed,
          ),
          const SizedBox(height: AppSpacing.sm),
          _LockedDateField(value: dateLabel(endDate)),
          const SizedBox(height: AppSpacing.md),
          _PeriodPreview(periodPreview: periodPreview),
        ],
      ),
    );
  }
}

class _DateSelectField extends StatelessWidget {
  const _DateSelectField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_outlined),
              suffixIcon: Icon(Icons.expand_more),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedDateField extends StatelessWidget {
  const _LockedDateField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'End Date (Calculated)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: AppSizes.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                color: AppColors.outline,
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodPreview extends StatelessWidget {
  const _PeriodPreview({required this.periodPreview});

  final String periodPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.date_range,
              color: AppColors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Period Preview',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  periodPreview,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Calculated as one full year from your selected start date.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
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

class _RolloverTile extends StatelessWidget {
  const _RolloverTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatic Rollover',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Start the next year automatically after the end date.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _WhyItMattersCard extends StatelessWidget {
  const _WhyItMattersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this matters',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "The financial year defines the 12-month period for your group's accounting, contribution tracking, and annual reports.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
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
