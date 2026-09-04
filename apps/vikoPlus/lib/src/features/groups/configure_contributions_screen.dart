import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_screen.dart';

class ConfigureContributionsScreen extends ConsumerStatefulWidget {
  const ConfigureContributionsScreen({this.groupId, super.key});

  final String? groupId;

  @override
  ConsumerState<ConfigureContributionsScreen> createState() =>
      _ConfigureContributionsScreenState();
}

class _ConfigureContributionsScreenState
    extends ConsumerState<ConfigureContributionsScreen> {
  final _joiningFeeController = TextEditingController(text: '10000');
  final _membershipFeeController = TextEditingController(text: '5000');
  final _memberContributionController = TextEditingController(text: '20000');
  String _membershipFeeFrequency = 'Yearly';
  String _memberContributionFrequency = 'Monthly';
  int _membershipDueDay = 1;
  int _weeklyDay = 6;
  int _monthlyDay = 5;
  bool _joiningFeeEnabled = true;
  bool _allowPartialPayments = true;
  bool _autoAllocatePayments = true;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(groupSetupDraftProvider).contributions;
    _joiningFeeController.text = draft.joiningFee;
    _membershipFeeController.text = draft.membershipFee;
    _memberContributionController.text = draft.memberContribution;
    _membershipFeeFrequency = draft.membershipFeeFrequency;
    _memberContributionFrequency = draft.memberContributionFrequency;
    _membershipDueDay = draft.membershipDueDay;
    _weeklyDay = draft.weeklyDay;
    _monthlyDay = draft.monthlyDay;
    _joiningFeeEnabled = draft.joiningFeeEnabled;
    _allowPartialPayments = draft.allowPartialPayments;
    _autoAllocatePayments = draft.autoAllocatePayments;
  }

  @override
  void dispose() {
    _joiningFeeController.dispose();
    _membershipFeeController.dispose();
    _memberContributionController.dispose();
    super.dispose();
  }

  String get _dueLabel {
    if (_memberContributionFrequency == 'Daily') return 'Every day';
    if (_memberContributionFrequency == 'Weekly') {
      return _weekDays[_weeklyDay - 1];
    }
    return '${_ordinal(_monthlyDay)} of each cycle';
  }

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _ordinal(int value) {
    if (value >= 11 && value <= 13) return '${value}th';
    return switch (value % 10) {
      1 => '${value}st',
      2 => '${value}nd',
      3 => '${value}rd',
      _ => '${value}th',
    };
  }

  int? _amountFrom(TextEditingController controller) {
    final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String _apiFrequency(String frequency) {
    if (frequency == 'Yearly') return 'ANNUAL';
    return frequency.toUpperCase();
  }

  String _moneyLabel(TextEditingController controller) {
    final amount = _amountFrom(controller) ?? 0;
    return 'TZS ${amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  String? get _groupId {
    final widgetGroupId = widget.groupId;
    if (widgetGroupId != null && widgetGroupId.isNotEmpty) {
      return widgetGroupId;
    }
    return ref.read(groupSetupDraftProvider).createdGroupId;
  }

  void _persistContributions() {
    ref.read(groupSetupDraftProvider.notifier).updateContributions(
          ContributionSettingsDraft(
            joiningFee: _joiningFeeController.text,
            membershipFee: _membershipFeeController.text,
            memberContribution: _memberContributionController.text,
            membershipFeeFrequency: _membershipFeeFrequency,
            memberContributionFrequency: _memberContributionFrequency,
            membershipDueDay: _membershipDueDay,
            weeklyDay: _weeklyDay,
            monthlyDay: _monthlyDay,
            joiningFeeEnabled: _joiningFeeEnabled,
            allowPartialPayments: _allowPartialPayments,
            autoAllocatePayments: _autoAllocatePayments,
          ),
        );
  }

  Future<void> _submit() async {
    final groupId = _groupId;
    if (_isSubmitting) return;
    if (groupId == null || groupId.isEmpty) {
      setState(
        () => _errorMessage = 'Create a group before setting contributions.',
      );
      return;
    }

    final membershipFee = _amountFrom(_membershipFeeController);
    final memberContribution = _amountFrom(_memberContributionController);
    final joiningFee =
        _joiningFeeEnabled ? _amountFrom(_joiningFeeController) : 0;
    if (joiningFee == null ||
        membershipFee == null ||
        memberContribution == null ||
        membershipFee <= 0 ||
        memberContribution <= 0) {
      setState(() => _errorMessage = 'Enter valid contribution amounts.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      _persistContributions();
      await ref.read(groupsRepositoryProvider).saveContributionSettings(
            groupId,
            ContributionSettingsInput(
              joiningFeeMinor: joiningFee,
              membershipFeeMinor: membershipFee,
              memberContributionMinor: memberContribution,
              membershipFeeFrequency: _apiFrequency(_membershipFeeFrequency),
              memberContributionFrequency:
                  _apiFrequency(_memberContributionFrequency),
              membershipDueDayOfMonth: _membershipDueDay,
              memberContributionDueDayOfWeek:
                  _memberContributionFrequency == 'Weekly' ? _weeklyDay : null,
              memberContributionDueDayOfMonth:
                  _memberContributionFrequency == 'Daily' ||
                      _memberContributionFrequency == 'Weekly'
                  ? null
                  : _monthlyDay,
              cycleAnchorDate: DateTime.now(),
            ),
          );
      if (!mounted) return;
      context.go('/groups/reminders?groupId=${Uri.encodeComponent(groupId)}');
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
    final groupId = _groupId;

    return VikoplusScreen(
      title: 'Configure Contributions',
      backRoute: groupId == null
          ? '/groups/financial-year'
          : '/groups/financial-year?groupId=${Uri.encodeComponent(groupId)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: AppShadows.level1(),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 455 / 244,
              child: Image.asset(
                'assets/images/contribution_foundation.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ContributionSection(
            title: 'Joining Fee',
            subtitle: 'Require members to pay a fee upon joining.',
            trailing: Switch(
              value: _joiningFeeEnabled,
              onChanged: (value) {
                setState(() => _joiningFeeEnabled = value);
                _persistContributions();
              },
            ),
            children: [
              _MoneyField(
                label: 'Joining Fee Amount',
                hint: '10000',
                controller: _joiningFeeController,
                enabled: _joiningFeeEnabled,
                onChanged: (_) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() => _errorMessage = '');
                  }
                  _persistContributions();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContributionSection(
            title: 'Membership Fee',
            subtitle: 'Set the recurring membership fee for every member.',
            children: [
              _MoneyField(
                label: 'Membership Fee Amount',
                hint: '5000',
                controller: _membershipFeeController,
                onChanged: (_) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() => _errorMessage = '');
                  }
                  _persistContributions();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _SelectField(
                label: 'Membership Fee Cycle',
                value: _membershipFeeFrequency,
                values: const ['Monthly', 'Quarterly', 'Yearly'],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _membershipFeeFrequency = value);
                  _persistContributions();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _SelectField(
                label: 'Membership Fee Due Day',
                value: 'Day $_membershipDueDay',
                values: List.generate(31, (index) => 'Day ${index + 1}'),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _membershipDueDay = int.parse(
                      value.replaceFirst('Day ', ''),
                    );
                  });
                  _persistContributions();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContributionSection(
            title: 'Member Contributions',
            subtitle:
                'Set the normal contribution amount and how often members contribute.',
            children: [
              _MoneyField(
                label: 'Contribution Amount',
                hint: '20000',
                controller: _memberContributionController,
                onChanged: (_) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() => _errorMessage = '');
                  }
                  _persistContributions();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _SelectField(
                label: 'Contribution Cycle',
                value: _memberContributionFrequency,
                values: const [
                  'Daily',
                  'Weekly',
                  'Monthly',
                  'Quarterly',
                  'Yearly',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _memberContributionFrequency = value);
                  _persistContributions();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_memberContributionFrequency == 'Weekly')
                _SelectField(
                  label: 'Weekly Due Day',
                  value: _weekDays[_weeklyDay - 1],
                  values: _weekDays,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _weeklyDay = _weekDays.indexOf(value) + 1);
                    _persistContributions();
                  },
                )
              else if (_memberContributionFrequency == 'Daily')
                const _LockedCycleField(
                  label: 'Due Schedule',
                  value: 'Every day',
                )
              else
                _SelectField(
                  label: 'Due Day',
                  value: 'Day $_monthlyDay',
                  values: List.generate(31, (index) => 'Day ${index + 1}'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _monthlyDay = int.parse(value.replaceFirst('Day ', ''));
                    });
                    _persistContributions();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContributionSection(
            title: 'Payment Rules',
            subtitle: 'Group payments stay manual. Members submit requests and the treasurer confirms receipt.',
            children: [
              _RuleRow(
                title: 'Allow Partial Payments',
                subtitle: 'Members can pay their contribution in installments.',
                enabled: _allowPartialPayments,
                onChanged: (value) {
                  setState(() => _allowPartialPayments = value);
                  _persistContributions();
                },
              ),
              const Divider(color: AppColors.outlineVariant),
              _RuleRow(
                title: 'Auto Allocate Payments',
                subtitle: 'Apply payments to oldest unpaid periods first.',
                enabled: _autoAllocatePayments,
                onChanged: (value) {
                  setState(() => _autoAllocatePayments = value);
                  _persistContributions();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _HistoricalDataCard(
            onImport: () {
              context.go(
                groupId == null
                    ? '/groups/history'
                    : '/groups/history?groupId=${Uri.encodeComponent(groupId)}',
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: 'Joining fee',
            value: _joiningFeeEnabled
                ? '${_moneyLabel(_joiningFeeController)} / yearly'
                : 'Disabled',
            icon: Icons.person_add_alt_1_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoCard(
            title: 'Membership fee',
            value:
                '${_moneyLabel(_membershipFeeController)} / $_membershipFeeFrequency\nDue ${_ordinal(_membershipDueDay)} of each cycle',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoCard(
            title: 'Member contribution',
            value:
                '${_moneyLabel(_memberContributionController)} / $_memberContributionFrequency\n$_dueLabel',
            icon: Icons.event_repeat_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _ContributionSection extends StatelessWidget {
  const _ContributionSection({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.hint,
    this.controller,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
          child: Center(child: Text('TZS')),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      icon: const Icon(Icons.expand_more),
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _LockedCycleField extends StatelessWidget {
  const _LockedCycleField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.today_outlined),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: enabled,
        contentPadding: EdgeInsets.zero,
        onChanged: onChanged,
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _HistoricalDataCard extends StatelessWidget {
  const _HistoricalDataCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical group data',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Admins and secretaries can add previous payments one by one or import them in bulk.',
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
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.history_outlined, size: 18),
            label: const Text('Import historical records'),
          ),
        ],
      ),
    );
  }
}
