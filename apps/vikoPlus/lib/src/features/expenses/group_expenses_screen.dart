import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class GroupExpensesScreen extends ConsumerStatefulWidget {
  const GroupExpensesScreen({super.key});

  @override
  ConsumerState<GroupExpensesScreen> createState() => _GroupExpensesScreenState();
}

class _GroupExpensesScreenState extends ConsumerState<GroupExpensesScreen> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _beneficiaryController = TextEditingController();
  final _purposeController = TextEditingController();
  final _referenceController = TextEditingController();
  String _rail = 'M-Pesa B2C Payout';
  String? _errorMessage;
  bool _submitting = false;
  Future<GroupExpensesResult>? _future;
  String? _groupId;

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _beneficiaryController.dispose();
    _purposeController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<GroupExpensesResult> _load(String groupId) {
    return ref.read(groupsRepositoryProvider).expenses(groupId);
  }

  Future<void> _refresh() async {
    final groupId = ref.read(activeGroupProvider)?.id;
    if (groupId == null) {
      return;
    }
    final future = _load(groupId);
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _submit() async {
    final groupId = ref.read(activeGroupProvider)?.id;
    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    if (groupId == null || amount == null || amount <= 0) {
      setState(() {
        _errorMessage = context.vt('Enter a valid expense amount.');
      });
      return;
    }
    if (_categoryController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = context.vt('Enter the expense category.');
      });
      return;
    }
    if (_purposeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = context.vt('Enter the expense purpose.');
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _submitting = true;
    });
    try {
      await ref.read(groupsRepositoryProvider).createExpense(
            groupId,
            GroupExpenseInput(
              category: _categoryController.text,
              purpose: _purposeController.text,
              amountMinor: amount,
              beneficiary: _beneficiaryController.text,
              paymentRail: _rail,
              reference: _referenceController.text,
            ),
          );
      _amountController.clear();
      _categoryController.clear();
      _beneficiaryController.clear();
      _purposeController.clear();
      _referenceController.clear();
      await _refresh();
    } catch (error) {
      setState(() {
        _errorMessage = context.vt(AuthFailure.from(error).message);
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _review(GroupExpenseSummary expense, bool approve) async {
    final groupId = ref.read(activeGroupProvider)?.id;
    if (groupId == null) {
      return;
    }
    try {
      await ref.read(groupsRepositoryProvider).reviewExpense(
            groupId,
            expense.id,
            approve: approve,
          );
      await _refresh();
    } catch (error) {
      setState(() {
        _errorMessage = context.vt(AuthFailure.from(error).message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (_groupId != group?.id) {
      _groupId = group?.id;
      _future = group == null ? null : _load(group.id);
    }
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: context.vt('Group expenses'),
      backRoute: '/more',
      onRefresh: _refresh,
      child: group == null
          ? AuthErrorMessage(
              message: context.vt('Open a group before recording expenses.'),
            )
          : FutureBuilder<GroupExpensesResult>(
              future: _future,
              builder: (context, snapshot) {
                final result = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      AuthErrorMessage(message: _errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _SummaryCard(result: result, formatters: formatters),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(title: context.vt('Record expense')),
                    const SizedBox(height: AppSpacing.sm),
                    _ExpenseForm(
                      amountController: _amountController,
                      categoryController: _categoryController,
                      beneficiaryController: _beneficiaryController,
                      purposeController: _purposeController,
                      referenceController: _referenceController,
                      rail: _rail,
                      onRailChanged: (value) {
                        setState(() {
                          _rail = value;
                        });
                      },
                      submitting: _submitting,
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(title: context.vt('Expense history')),
                    const SizedBox(height: AppSpacing.sm),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      AuthErrorMessage(
                        message: context.vt('Could not load expenses.'),
                      )
                    else if (result == null || result.expenses.isEmpty)
                      _EmptyExpensesCard()
                    else
                      ...result.expenses.map(
                        (expense) => _ExpenseTile(
                          expense: expense,
                          canReview: result.canReview,
                          formatters: formatters,
                          onApprove: () => _review(expense, true),
                          onReject: () => _review(expense, false),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.formatters});

  final GroupExpensesResult? result;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final summary = result?.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.vt('Group money position')),
        const SizedBox(height: AppSpacing.sm),
        InfoCard(
          title: context.vt('Approved expenses'),
          value: formatters.money(summary?.approvedExpenseMinor ?? 0),
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: InfoCard(
                title: context.vt('Pending expenses'),
                value: formatters.money(summary?.pendingExpenseMinor ?? 0),
                icon: Icons.pending_actions_outlined,
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: InfoCard(
                title: context.vt('Loans out'),
                value: formatters.money(summary?.loanPrincipalOutMinor ?? 0),
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm({
    required this.amountController,
    required this.categoryController,
    required this.beneficiaryController,
    required this.purposeController,
    required this.referenceController,
    required this.rail,
    required this.onRailChanged,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController amountController;
  final TextEditingController categoryController;
  final TextEditingController beneficiaryController;
  final TextEditingController purposeController;
  final TextEditingController referenceController;
  final String rail;
  final ValueChanged<String> onRailChanged;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const rails = ['M-Pesa B2C Payout', 'Cash', 'Bank Transfer', 'Other'];

    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: categoryController,
            decoration: InputDecoration(
              labelText: context.vt('Expense category'),
              hintText: context.vt('Example: Condolences, bank charges'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.vt('Disbursement amount'),
              prefixText: 'TZS ',
              hintText: '35000',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: beneficiaryController,
            decoration: InputDecoration(
              labelText: context.vt('Beneficiary or recipient'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: rail,
            decoration: InputDecoration(labelText: context.vt('Payment rail')),
            items: [
              for (final item in rails)
                DropdownMenuItem(value: item, child: Text(context.vt(item))),
            ],
            onChanged: (value) {
              if (value != null) {
                onRailChanged(value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: referenceController,
            decoration: InputDecoration(labelText: context.vt('Reference')),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: purposeController,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.vt('Purpose')),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
            ),
            icon: const Icon(Icons.send_outlined),
            label: Text(
              submitting
                  ? context.vt('Submitting')
                  : context.vt('Submit expense'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.canReview,
    required this.formatters,
    required this.onApprove,
    required this.onReject,
  });

  final GroupExpenseSummary expense;
  final bool canReview;
  final AppFormatters formatters;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = expense.status == 'SUBMITTED';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: AppInsets.card,
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
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.vt(expense.category),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _StatusChip(status: expense.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatters.money(expense.amountMinor, currency: expense.currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if ((expense.beneficiary ?? '').isNotEmpty)
              Text('${context.vt('Beneficiary')}: ${expense.beneficiary}'),
            Text(expense.purpose),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${expense.paymentRail ?? context.vt('Payment rail')} - ${formatters.date(expense.spentAt ?? expense.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (canReview && isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.compactInputHeight,
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: Text(context.vt('Reject')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.compactInputHeight,
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(context.vt('Approve')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'APPROVED' => AppColors.primary.withValues(alpha: 0.1),
      'REJECTED' => AppColors.errorContainer,
      _ => AppColors.tertiaryFixed,
    };
    final foreground = switch (status) {
      'APPROVED' => AppColors.primary,
      'REJECTED' => AppColors.error,
      _ => AppColors.tertiary,
    };
    return Chip(
      label: Text(
        context.vt(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyExpensesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.receipt_long_outlined,
      title: 'No group expenses recorded yet.',
      message: 'Record group spending for approval',
    );
  }
}
