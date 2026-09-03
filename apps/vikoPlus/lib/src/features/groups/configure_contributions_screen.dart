import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/info_card.dart';
import '../common/vikoplus_screen.dart';

class ConfigureContributionsScreen extends StatefulWidget {
  const ConfigureContributionsScreen({super.key});

  @override
  State<ConfigureContributionsScreen> createState() =>
      _ConfigureContributionsScreenState();
}

class _ConfigureContributionsScreenState
    extends State<ConfigureContributionsScreen> {
  String _frequency = 'Monthly';
  int _weeklyDay = 6;
  int _monthlyDay = 5;
  bool _joiningFeeEnabled = true;
  bool _allowPartialPayments = true;
  bool _autoAllocatePayments = true;

  String get _dueLabel {
    if (_frequency == 'Daily') return 'Every day';
    if (_frequency == 'Weekly') return _weekDays[_weeklyDay - 1];
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

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Configure Contributions',
      backRoute: '/groups/financial-year',
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
              },
            ),
            children: const [
              _MoneyField(label: 'Joining Fee Amount', hint: '10000'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContributionSection(
            title: 'Membership Fee',
            subtitle: 'Set the recurring contribution cycle for every member.',
            children: [
              const _MoneyField(label: 'Membership Amount', hint: '5000'),
              const SizedBox(height: AppSpacing.sm),
              _SelectField(
                label: 'Contribution Frequency',
                value: _frequency,
                values: const ['Daily', 'Weekly', 'Monthly'],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _frequency = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_frequency == 'Weekly')
                _SelectField(
                  label: 'Weekly Due Day',
                  value: _weekDays[_weeklyDay - 1],
                  values: _weekDays,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _weeklyDay = _weekDays.indexOf(value) + 1);
                  },
                )
              else if (_frequency == 'Monthly')
                _SelectField(
                  label: 'Monthly Due Day',
                  value: 'Day $_monthlyDay',
                  values: List.generate(31, (index) => 'Day ${index + 1}'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _monthlyDay = int.parse(value.replaceFirst('Day ', ''));
                    });
                  },
                )
              else
                const _LockedCycleField(
                  label: 'Due Schedule',
                  value: 'Every day',
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
                },
              ),
              const Divider(color: AppColors.outlineVariant),
              _RuleRow(
                title: 'Auto Allocate Payments',
                subtitle: 'Apply payments to oldest unpaid periods first.',
                enabled: _autoAllocatePayments,
                onChanged: (value) {
                  setState(() => _autoAllocatePayments = value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _HistoricalDataCard(onImport: () => context.go('/groups/history')),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(
                child: InfoCard(
                  title: 'Joining fee',
                  value: 'TZS 10,000',
                  icon: Icons.person_add_alt_1_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InfoCard(
                  title: _frequency,
                  value: _dueLabel,
                  icon: Icons.event_repeat_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.go('/groups/reminders'),
            child: const Text('Continue'),
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
  const _MoneyField({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
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
