import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class RecordPaymentScreen extends StatelessWidget {
  const RecordPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final member = sofiaMembers[1];

    return VikoplusScreen(
      title: 'Record Payment',
      backRoute: '/contributions/record/select-member',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepIndicator(),
          const SizedBox(height: AppSpacing.md),
          _SelectedMemberCard(member: member),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Contribution Type',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Row(
            children: [
              Expanded(
                child: _ContributionTypeChip(
                  label: 'Monthly Contribution',
                  selected: true,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _ContributionTypeChip(label: 'Joining Fee')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'TZS ',
            ),
            initialValue: '50000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Payment Date',
              hintText: '2026-09-02',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Payment Method',
              hintText: 'Mobile Money',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Transaction Reference',
              hintText: 'e.g. MPESA-7A8B9C',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: AppSpacing.md),
          _AllocationReview(formatters: formatters),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/contributions/record'),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => context.go('/contributions/receipt/latest'),
                  child: const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _StepBadge(number: '1', label: 'Select Member'),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: AppColors.primary,
          ),
        ),
        const _StepBadge(number: '2', label: 'Payment Details', active: true),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.primary,
          child: Text(
            number,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SelectedMemberCard extends StatelessWidget {
  const _SelectedMemberCard({required this.member});

  final SofiaMember member;

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
      child: Row(
        children: [
          InitialsAvatar(initials: member.initials),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'ID: ${member.number} | Regular Member',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/contributions/record/select-member'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Change member',
          ),
        ],
      ),
    );
  }
}

class _ContributionTypeChip extends StatelessWidget {
  const _ContributionTypeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.secondaryContainer.withValues(alpha: 0.7)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: selected
              ? AppColors.onSecondaryContainer
              : AppColors.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _AllocationReview extends StatelessWidget {
  const _AllocationReview({required this.formatters});

  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const SectionHeader(title: 'Allocation Preview'),
          const SizedBox(height: AppSpacing.sm),
          _AllocationRow(
            label: 'Monthly contribution',
            amount: formatters.money(50000),
          ),
          _AllocationRow(label: 'Transaction fee', amount: formatters.money(0)),
          const Divider(height: AppSpacing.md, color: AppColors.outlineVariant),
          _AllocationRow(
            label: 'Total payment',
            amount: formatters.money(50000),
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    required this.label,
    required this.amount,
    this.isStrong = false,
  });

  final String label;
  final String amount;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontWeight: isStrong ? FontWeight.w800 : FontWeight.w500);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(amount, style: style),
        ],
      ),
    );
  }
}
