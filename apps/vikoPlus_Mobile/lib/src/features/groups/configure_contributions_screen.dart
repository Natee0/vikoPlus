import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/info_card.dart';
import '../common/vikoplus_screen.dart';

class ConfigureContributionsScreen extends StatelessWidget {
  const ConfigureContributionsScreen({super.key});

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
            trailing: Switch(value: true, onChanged: (_) {}),
            children: const [
              _MoneyField(label: 'Joining Fee Amount', hint: '10000'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ContributionSection(
            title: 'Membership Fee',
            subtitle:
                'Set the monthly membership contribution for every member.',
            children: [
              _MoneyField(label: 'Monthly Membership Amount', hint: '5000'),
              SizedBox(height: AppSpacing.sm),
              _SelectField(label: 'Contribution Frequency', value: 'Monthly'),
              SizedBox(height: AppSpacing.sm),
              _SelectField(label: 'Due Day', value: '5th of the month'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ContributionSection(
            title: 'Payment Rules',
            subtitle: 'Configure how members can pay their contributions.',
            children: [
              _RuleRow(
                title: 'Allow Partial Payments',
                subtitle: 'Members can pay their contribution in installments.',
                enabled: true,
              ),
              Divider(color: AppColors.outlineVariant),
              _RuleRow(
                title: 'Auto Allocate Payments',
                subtitle: 'Apply payments to oldest unpaid periods first.',
                enabled: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: 'Joining fee',
                  value: 'TZS 10,000',
                  icon: Icons.person_add_alt_1_outlined,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InfoCard(
                  title: 'Monthly',
                  value: 'TZS 5,000',
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
  const _SelectField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      icon: const Icon(Icons.expand_more),
      decoration: InputDecoration(labelText: label),
      items: [value]
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (_) {},
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: enabled,
        contentPadding: EdgeInsets.zero,
        onChanged: (_) {},
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
