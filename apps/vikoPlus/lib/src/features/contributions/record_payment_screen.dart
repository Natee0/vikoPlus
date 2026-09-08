import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({this.memberId, super.key});

  final String? memberId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _referenceController = TextEditingController();
  final Set<String> _selectedObligationIds = {};
  String _method = 'MOBILE_MONEY';
  String _errorMessage = '';
  bool _isSubmitting = false;
  bool _initializedObligations = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  void _initializeObligations(List<ContributionObligationSummary> obligations) {
    if (_initializedObligations) return;
    _initializedObligations = true;
    _selectedObligationIds.addAll(
      obligations
          .where((obligation) => obligation.isPayable)
          .take(2)
          .map((obligation) => obligation.id),
    );
  }

  Future<void> _record(GroupAccessSummary activeGroup) async {
    final memberId = widget.memberId;
    if (memberId == null || memberId.isEmpty) {
      setState(
        () => _errorMessage = context.vt(
          'Select a member before recording payment.',
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final register =
          await ref.read(groupsRepositoryProvider).contributionRegister(
                activeGroup.id,
              );
      final selectedObligations = register.obligations
          .where(
            (obligation) =>
                obligation.memberId == memberId &&
                _selectedObligationIds.contains(obligation.id) &&
                obligation.isPayable,
          )
          .toList();
      final amountMinor = selectedObligations.fold<int>(
        0,
        (total, obligation) => total + obligation.outstandingMinor,
      );
      if (amountMinor <= 0) {
        throw const FormatException('Select at least one payable contribution.');
      }
      final payment = await ref.read(groupsRepositoryProvider).recordPayment(
            activeGroup.id,
            RecordPaymentInput(
              memberId: memberId,
              amountMinor: amountMinor,
              method: _method,
              obligationIds: selectedObligations
                  .map((obligation) => obligation.id)
                  .toList(),
              reference: _referenceController.text,
              paidAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      final receiptId = payment.receipt?.id;
      context.go(
        receiptId == null
            ? '/contributions'
            : '/contributions/receipt/${Uri.encodeComponent(receiptId)}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = context.vt(
          error is FormatException
              ? error.message
              : 'Payment was not recorded. Confirm your staff role and try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: context.vt('Record Payment'),
      backRoute: '/contributions/record/select-member',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepIndicator(),
          const SizedBox(height: AppSpacing.md),
          if (activeGroup == null)
            AuthErrorMessage(
              message: context.vt('Select a group before recording payment.'),
            )
          else if (widget.memberId == null || widget.memberId!.isEmpty)
            AuthErrorMessage(
              message: context.vt('Select a member before recording payment.'),
            )
          else
            FutureBuilder<GroupMemberSummary>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .member(activeGroup.id, widget.memberId!),
              builder: (context, snapshot) {
                final member = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || member == null) {
                  return AuthErrorMessage(
                    message: context.vt(
                      'Could not load this member. Please select again.',
                    ),
                  );
                }
                return _SelectedMemberCard(member: member);
              },
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.vt('Contribution Purpose'),
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (activeGroup != null &&
              widget.memberId != null &&
              widget.memberId!.isNotEmpty)
            FutureBuilder<ContributionRegisterResult>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .contributionRegister(activeGroup.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return AuthErrorMessage(
                    message: context.vt(
                      'Could not load this member contributions.',
                    ),
                  );
                }
                final allMemberObligations =
                    (snapshot.data?.obligations ?? const [])
                        .where(
                          (obligation) =>
                              obligation.memberId == widget.memberId,
                        )
                        .toList();
                final obligations = allMemberObligations
                    .where(
                      (obligation) => obligation.isPayable,
                    )
                    .toList();
                final upcoming = allMemberObligations
                    .where((obligation) => obligation.isUpcoming)
                    .toList();
                _initializeObligations(obligations);
                if (obligations.isEmpty) {
                  return AuthErrorMessage(
                    message: context.vt(
                      upcoming.isNotEmpty
                          ? 'No contributions are due yet. Upcoming items will activate on their collection date.'
                          : 'This member has no outstanding contributions.',
                    ),
                  );
                }
                final selected = obligations
                    .where(
                      (obligation) =>
                          _selectedObligationIds.contains(obligation.id),
                    )
                    .toList();
                final amountMinor = selected.fold<int>(
                  0,
                  (total, obligation) => total + obligation.outstandingMinor,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final obligation in obligations)
                          _ContributionTypeChip(
                            label:
                                '${obligation.planName}\n${obligation.periodLabel}',
                            status: context.vt('Due'),
                            selected:
                                _selectedObligationIds.contains(obligation.id),
                            onTap: () {
                              setState(() {
                                _errorMessage = '';
                                if (_selectedObligationIds
                                    .contains(obligation.id)) {
                                  _selectedObligationIds.remove(obligation.id);
                                } else {
                                  _selectedObligationIds.add(obligation.id);
                                }
                              });
                            },
                          ),
                        for (final obligation in upcoming)
                          _ContributionTypeChip(
                            label:
                                '${obligation.planName}\n${obligation.periodLabel}',
                            status: context.vt('Upcoming'),
                            disabled: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: ValueKey(amountMinor),
                      readOnly: true,
                      initialValue: formatters.money(amountMinor),
                      decoration: InputDecoration(
                        labelText: context.vt('Amount from selected purpose'),
                        prefixIcon: const Icon(Icons.savings_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AllocationReview(
                      formatters: formatters,
                      amountMinor: amountMinor,
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            decoration: InputDecoration(
              labelText: context.vt('Payment Date'),
              hintText: '2026-09-02',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: InputDecoration(
              labelText: context.vt('Payment Method'),
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'MOBILE_MONEY',
                child: Text('Mobile Money'),
              ),
              DropdownMenuItem(value: 'CASH', child: Text('Cash')),
              DropdownMenuItem(
                value: 'BANK_TRANSFER',
                child: Text('Bank Transfer'),
              ),
              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _method = value ?? _method),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: context.vt('Transaction Reference'),
              hintText: 'e.g. MPESA-7A8B9C',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/contributions/record'),
                  child: Text(context.vt('Cancel')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: activeGroup == null || _isSubmitting
                      ? null
                      : () => _record(activeGroup),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.vt('Record Payment')),
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

  final GroupMemberSummary member;

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
          InitialsAvatar(initials: _initials(member.fullName)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    if (member.memberNumber != null)
                      'ID: ${member.memberNumber}',
                    _roleLabel(member.role),
                  ].join(' | '),
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
  const _ContributionTypeChip({
    required this.label,
    this.status,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  final String label;
  final String? status;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: disabled ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56, minWidth: 142),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surfaceContainerLow
              : selected
              ? AppColors.secondaryContainer.withValues(alpha: 0.7)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected && !disabled
                ? AppColors.primary
                : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: disabled
                    ? AppColors.onSurfaceVariant
                    : selected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                status!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: disabled ? AppColors.onSurfaceVariant : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllocationReview extends StatelessWidget {
  const _AllocationReview({
    required this.formatters,
    required this.amountMinor,
  });

  final AppFormatters formatters;
  final int amountMinor;

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
            amount: formatters.money(amountMinor),
          ),
          _AllocationRow(label: 'Transaction fee', amount: formatters.money(0)),
          const Divider(height: AppSpacing.md, color: AppColors.outlineVariant),
          _AllocationRow(
            label: 'Total payment',
            amount: formatters.money(amountMinor),
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'M';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

String _roleLabel(String role) {
  return role
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
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
