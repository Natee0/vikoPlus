import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/loans/loans_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_design_widgets.dart';

class LoansOverviewScreen extends ConsumerWidget {
  const LoansOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    if (group == null) return const _MissingGroupLoansState();

    return _LoanFutureScreen<LoanOverviewResult>(
      title: 'Loans',
      future: ref.watch(loansRepositoryProvider).overview(group.id),
      onRefresh: () => ref.read(loansRepositoryProvider).overview(group.id),
      builder: (context, overview) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BorrowingPowerCard(overview: overview),
            const SizedBox(height: AppSpacing.md),
            SectionHeader(
              title: 'Active Loans',
              trailing: TextButton(
                onPressed: () => context.go('/loans/applications'),
                child: const Text('Applications'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (overview.activeLoans.isEmpty)
              const _EmptyLoanCard()
            else
              for (final loan in overview.activeLoans) ...[
                _ActiveLoanCard(loan: loan),
                const SizedBox(height: AppSpacing.sm),
              ],
            const SizedBox(height: AppSpacing.md),
            _EligibilityCard(items: overview.eligibility),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go('/loans/apply'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Apply for New Loan'),
            ),
          ],
        );
      },
    );
  }
}

class ApplyForLoanScreen extends ConsumerStatefulWidget {
  const ApplyForLoanScreen({super.key});

  @override
  ConsumerState<ApplyForLoanScreen> createState() => _ApplyForLoanScreenState();
}

class _ApplyForLoanScreenState extends ConsumerState<ApplyForLoanScreen> {
  final _amountController = TextEditingController(text: '50000');
  final Set<String> _selectedGuarantors = {};
  int _term = 6;
  String _purpose = 'School fees';
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? get _amountMinor {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  int get _processingFeeMinor => ((_amountMinor ?? 0) * 0.02).ceil();
  int get _interestMinor => (((_amountMinor ?? 0) * 150 * _term) / 10000).ceil();
  int get _totalPayableMinor =>
      (_amountMinor ?? 0) + _processingFeeMinor + _interestMinor;

  void _clearError() {
    if (_errorMessage.isNotEmpty) setState(() => _errorMessage = '');
  }

  Future<void> _submit(String groupId) async {
    if (_isSubmitting) return;
    final amount = _amountMinor;
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid loan amount.');
      return;
    }
    if (_selectedGuarantors.length < 2) {
      setState(() => _errorMessage = 'Select at least 2 guarantors.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref.read(loansRepositoryProvider).createApplication(
            groupId,
            CreateLoanApplicationInput(
              amountMinor: amount,
              purpose: _purpose,
              termMonths: _term,
              guarantorMemberIds: _selectedGuarantors.toList(),
            ),
          );
      if (!mounted) return;
      context.go('/loans');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (group == null) return const _MissingGroupLoansState();
    final membersFuture = ref.watch(groupsRepositoryProvider).listMembers(group.id);

    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: FutureBuilder<GroupMembersResult>(
        future: membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data?.members ?? const <GroupMemberSummary>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SurfacePanel(
                padding: AppInsets.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoanPanelHeader(title: 'Apply for Loan'),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        _clearError();
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount',
                        prefixText: 'TZS ',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final amount in [10000, 25000, 50000, 100000, 250000])
                          ActionChip(
                            label: Text(_shortMoney(amount)),
                            onPressed: () {
                              _amountController.text = amount.toString();
                              _clearError();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PurposeSelector(
                      value: _purpose,
                      onChanged: (value) => setState(() => _purpose = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TermSelector(
                      value: _term,
                      onChanged: (value) => setState(() => _term = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LoanEstimateCard(
                      monthlyPaymentMinor:
                          _term == 0 ? 0 : (_totalPayableMinor / _term).ceil(),
                      interestMinor: _interestMinor,
                      processingFeeMinor: _processingFeeMinor,
                      totalPayableMinor: _totalPayableMinor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GuarantorCard(
                members: members,
                selectedIds: _selectedGuarantors,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                onToggle: (memberId) {
                  _clearError();
                  setState(() {
                    if (_selectedGuarantors.contains(memberId)) {
                      _selectedGuarantors.remove(memberId);
                    } else {
                      _selectedGuarantors.add(memberId);
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthErrorMessage(message: _errorMessage),
              if (_errorMessage.isNotEmpty)
                const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _submit(group.id),
                iconAlignment: IconAlignment.end,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  _isSubmitting ? 'Submitting' : 'Submit Loan Application',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoanRepaymentScreen extends ConsumerStatefulWidget {
  const LoanRepaymentScreen({this.loanId, super.key});

  final String? loanId;

  @override
  ConsumerState<LoanRepaymentScreen> createState() =>
      _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends ConsumerState<LoanRepaymentScreen> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _method = 'MOBILE_MONEY';
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  int? get _amountMinor {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _submit(String groupId, String loanId) async {
    if (_isSubmitting) return;
    final amount = _amountMinor;
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid repayment amount.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref.read(loansRepositoryProvider).recordRepayment(
            groupId,
            loanId,
            RecordLoanRepaymentInput(
              amountMinor: amount,
              method: _method,
              reference: _referenceController.text,
              paidAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      context.go('/loans');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (group == null) return const _MissingGroupLoansState();
    final loanId = widget.loanId;

    if (loanId == null || loanId.isEmpty) {
      return _LoanFutureScreen<LoanOverviewResult>(
        title: 'Loans',
        future: ref.watch(loansRepositoryProvider).overview(group.id),
        onRefresh: () => ref.read(loansRepositoryProvider).overview(group.id),
        builder: (context, overview) {
          final firstLoan = overview.activeLoans.isEmpty
              ? null
              : overview.activeLoans.first;
          if (firstLoan == null) {
            return const _EmptyLoanCard();
          }
          return _RepaymentContent(
            loan: firstLoan,
            repayments: const [],
            method: _method,
            amountController: _amountController,
            referenceController: _referenceController,
            errorMessage: _errorMessage,
            isSubmitting: _isSubmitting,
            onMethodChanged: (value) => setState(() => _method = value),
            onSubmit: () => _submit(group.id, firstLoan.id),
          );
        },
      );
    }

    return _LoanFutureScreen<LoanRepaymentResult>(
      title: 'Loans',
      future: ref.watch(loansRepositoryProvider).repayment(group.id, loanId),
      onRefresh: () => ref.read(loansRepositoryProvider).repayment(group.id, loanId),
      builder: (context, result) {
        if (_amountController.text.isEmpty) {
          _amountController.text = result.loan.outstandingMinor.toString();
        }
        return _RepaymentContent(
          loan: result.loan,
          repayments: result.repayments,
          method: _method,
          amountController: _amountController,
          referenceController: _referenceController,
          errorMessage: _errorMessage,
          isSubmitting: _isSubmitting,
          onMethodChanged: (value) => setState(() => _method = value),
          onSubmit: () => _submit(group.id, result.loan.id),
        );
      },
    );
  }
}

class LoanApplicationsScreen extends ConsumerWidget {
  const LoanApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(activeGroupProvider);
    if (group == null) return const _MissingGroupLoansState();

    return _LoanFutureScreen<LoanApplicationsResult>(
      title: 'Loans',
      future: ref.watch(loansRepositoryProvider).applications(group.id),
      onRefresh: () => ref.read(loansRepositoryProvider).applications(group.id),
      builder: (context, result) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LoanReviewFilters(total: result.applications.length),
            const SizedBox(height: AppSpacing.md),
            if (result.applications.isEmpty)
              const _EmptyApplicationsCard()
            else
              for (final application in result.applications) ...[
                _LoanApplicationCard(application: application),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        );
      },
    );
  }
}

class LoanApplicationReviewScreen extends ConsumerStatefulWidget {
  const LoanApplicationReviewScreen({required this.applicationId, super.key});

  final String applicationId;

  @override
  ConsumerState<LoanApplicationReviewScreen> createState() =>
      _LoanApplicationReviewScreenState();
}

class _LoanApplicationReviewScreenState
    extends ConsumerState<LoanApplicationReviewScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _review({
    required String groupId,
    required String applicationId,
    required bool approve,
  }) async {
    if (_isSubmitting) return;
    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final repository = ref.read(loansRepositoryProvider);
      if (approve) {
        await repository.approveApplication(
          groupId,
          applicationId,
          notes: _notesController.text,
        );
      } else {
        await repository.rejectApplication(
          groupId,
          applicationId,
          reason: _notesController.text,
        );
      }
      if (!mounted) return;
      context.go('/loans/applications');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (group == null) return const _MissingGroupLoansState();

    return _LoanFutureScreen<LoanApplicationSummary>(
      title: 'Loans',
      future: ref
          .watch(loansRepositoryProvider)
          .application(group.id, widget.applicationId),
      onRefresh: () => ref
          .read(loansRepositoryProvider)
          .application(group.id, widget.applicationId),
      builder: (context, application) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ApplicantReviewHeader(application: application),
            const SizedBox(height: AppSpacing.md),
            _LoanReviewDetailsCard(application: application),
            const SizedBox(height: AppSpacing.md),
            _GuarantorVerificationCard(application: application),
            const SizedBox(height: AppSpacing.md),
            _AdminReviewCard(controller: _notesController),
            const SizedBox(height: AppSpacing.md),
            AuthErrorMessage(message: _errorMessage),
            if (_errorMessage.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _review(
                        groupId: group.id,
                        applicationId: application.id,
                        approve: true,
                      ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_isSubmitting ? 'Saving' : 'Approve & Disburse Funds'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _review(
                        groupId: group.id,
                        applicationId: application.id,
                        approve: false,
                      ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject Application'),
            ),
          ],
        );
      },
    );
  }
}

class _LoanFutureScreen<T> extends StatefulWidget {
  const _LoanFutureScreen({
    required this.title,
    required this.future,
    required this.builder,
    this.onRefresh,
  });

  final String title;
  final Future<T> future;
  final Future<T> Function()? onRefresh;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<_LoanFutureScreen<T>> createState() => _LoanFutureScreenState<T>();
}

class _LoanFutureScreenState<T> extends State<_LoanFutureScreen<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  Future<void> _refresh() async {
    final loader = widget.onRefresh;
    if (loader == null) return;

    final future = loader();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: widget.title,
      selectedIndex: 2,
      onRefresh: widget.onRefresh == null ? null : _refresh,
      child: FutureBuilder<T>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(message: AuthFailure.from(snapshot.error!).message);
          }
          final data = snapshot.data;
          if (data == null) return const _EmptyLoanCard();
          return widget.builder(context, data);
        },
      ),
    );
  }
}

class _LoanScaffold extends StatelessWidget {
  const _LoanScaffold({
    required this.title,
    required this.child,
    required this.selectedIndex,
    this.onRefresh,
  });

  final String title;
  final Widget child;
  final int selectedIndex;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) return;
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/members');
              break;
            case 2:
              context.go('/loans');
              break;
            case 3:
              context.go('/reports');
              break;
            case 4:
              context.go('/settings/admin');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Loans',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            VikoplusTopBar(
              title: title,
              onBack: () => context.canPop() ? context.pop() : context.go('/dashboard'),
              trailing: IconButton(
                tooltip: 'Account',
                onPressed: () => context.go('/member/profile'),
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: VikoplusConstrainedContent(
                child: onRefresh == null
                    ? _LoanScreenList(child: child)
                    : RefreshIndicator(
                        onRefresh: onRefresh!,
                        child: _LoanScreenList(child: child),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanScreenList extends StatelessWidget {
  const _LoanScreenList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMobile,
        AppSpacing.sm,
        AppSpacing.screenMobile,
        AppSpacing.lg,
      ),
      children: [child],
    );
  }
}

class _MissingGroupLoansState extends StatelessWidget {
  const _MissingGroupLoansState();

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: _SurfacePanel(
        padding: AppInsets.card,
        child: Column(
          children: [
            const Icon(Icons.groups_2_outlined, color: AppColors.primary, size: 42),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a group first',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Loans are managed inside a group.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/groups'),
              child: const Text('Open Groups'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AuthErrorMessage(message: message);
  }
}

class _EmptyLoanCard extends StatelessWidget {
  const _EmptyLoanCard();

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No active loans',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Approved loans will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplicationsCard extends StatelessWidget {
  const _EmptyApplicationsCard();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      padding: AppInsets.card,
      child: Text('No loan applications found.'),
    );
  }
}

class _LoanPanelHeader extends StatelessWidget {
  const _LoanPanelHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VIKOPLUS CREDIT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          backgroundColor: AppColors.surfaceContainer,
          child: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _BorrowingPowerCard extends StatelessWidget {
  const _BorrowingPowerCard({required this.overview});

  final LoanOverviewResult overview;

  @override
  Widget build(BuildContext context) {
    final progress = overview.creditLimitMinor == 0
        ? 0.0
        : overview.borrowingPowerMinor / overview.creditLimitMinor;
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level2(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AVAILABLE BORROWING POWER',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const CircleAvatar(
                backgroundColor: AppColors.surfaceTint,
                child: Icon(Icons.verified_outlined, color: AppColors.onPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _money(overview.borrowingPowerMinor, overview.currency),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Credit Limit: ${_money(overview.creditLimitMinor, overview.currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                ),
              ),
              Text(
                overview.tierLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              color: AppColors.primaryFixed,
              backgroundColor: AppColors.surfaceTint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveLoanCard extends StatelessWidget {
  const _ActiveLoanCard({required this.loan});

  final LoanSummary loan;

  @override
  Widget build(BuildContext context) {
    final progress = loan.totalPayableMinor == 0
        ? 0.0
        : loan.amountPaidMinor / loan.totalPayableMinor;
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.surfaceContainer,
                child: Icon(Icons.bolt, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.purpose,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'Due ${_date(loan.dueAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: _titleCase(loan.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: Text('Paid: ${_money(loan.amountPaidMinor, loan.currency)}')),
              Text(
                'Remaining: ${_money(loan.outstandingMinor, loan.currency)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/loans/repayment?loanId=${loan.id}'),
              child: const Text('Make Payment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.items});

  final List<LoanEligibilityItem> items;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      backgroundColor: AppColors.surfaceContainerLow,
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Eligibility & Requirements',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            _ChecklistLine(text: item.label, achieved: item.achieved),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.text, required this.achieved});

  final String text;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.radio_button_unchecked,
            color: achieved ? AppColors.primary : AppColors.outline,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _PurposeSelector extends StatelessWidget {
  const _PurposeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const purposes = [
      ('School fees', Icons.school_outlined),
      ('Emergency', Icons.medical_services_outlined),
      ('Business', Icons.business_center_outlined),
      ('Agriculture', Icons.agriculture_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Loan Purpose',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final purpose in purposes)
              ChoiceChip(
                avatar: Icon(purpose.$2, size: 16),
                label: Text(purpose.$1),
                selected: value == purpose.$1,
                onSelected: (_) => onChanged(purpose.$1),
              ),
          ],
        ),
      ],
    );
  }
}

class _TermSelector extends StatelessWidget {
  const _TermSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final months in [3, 6, 12]) ...[
          Expanded(
            child: ChoiceChip(
              label: Center(child: Text('$months Months')),
              selected: value == months,
              onSelected: (_) => onChanged(months),
            ),
          ),
          if (months != 12) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _LoanEstimateCard extends StatelessWidget {
  const _LoanEstimateCard({
    required this.monthlyPaymentMinor,
    required this.interestMinor,
    required this.processingFeeMinor,
    required this.totalPayableMinor,
  });

  final int monthlyPaymentMinor;
  final int interestMinor;
  final int processingFeeMinor;
  final int totalPayableMinor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          _ReviewDetailRow(
            label: 'Estimated Monthly Payment',
            value: _money(monthlyPaymentMinor, 'TZS'),
          ),
          _ReviewDetailRow(label: 'Interest Rate', value: '1.5% / month'),
          _ReviewDetailRow(label: 'Processing Fee', value: _money(processingFeeMinor, 'TZS')),
          _ReviewDetailRow(label: 'Total Payable', value: _money(totalPayableMinor, 'TZS')),
        ],
      ),
    );
  }
}

class _GuarantorCard extends StatelessWidget {
  const _GuarantorCard({
    required this.members,
    required this.selectedIds,
    required this.isLoading,
    required this.onToggle,
  });

  final List<GroupMemberSummary> members;
  final Set<String> selectedIds;
  final bool isLoading;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Guarantors',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusPill(label: '${selectedIds.length}/2 Selected'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isLoading)
            const LinearProgressIndicator()
          else if (members.length < 2)
            Text(
              'Add more group members before applying for a loan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            )
          else
            for (final member in members) ...[
              CheckboxListTile(
                value: selectedIds.contains(member.id),
                onChanged: (_) => onToggle(member.id),
                contentPadding: EdgeInsets.zero,
                title: Text(member.fullName),
                subtitle: Text('${_titleCase(member.role)} | ${member.status}'),
              ),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _RepaymentContent extends StatelessWidget {
  const _RepaymentContent({
    required this.loan,
    required this.repayments,
    required this.method,
    required this.amountController,
    required this.referenceController,
    required this.errorMessage,
    required this.isSubmitting,
    required this.onMethodChanged,
    required this.onSubmit,
  });

  final LoanSummary loan;
  final List<LoanRepaymentSummary> repayments;
  final String method;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final String errorMessage;
  final bool isSubmitting;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RepaymentHeroCard(loan: loan),
        const SizedBox(height: AppSpacing.md),
        _SurfacePanel(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Make a Repayment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Repayment Amount',
                  prefixText: 'TZS ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference',
                  hintText: 'Receipt or transaction reference',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'MOBILE_MONEY', child: Text('Mobile money')),
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank transfer')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) onMethodChanged(value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthErrorMessage(message: errorMessage),
              if (errorMessage.isNotEmpty)
                const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: const Icon(Icons.bolt_outlined),
                label: Text(isSubmitting ? 'Submitting' : 'Submit Repayment'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RepaymentHistoryCard(repayments: repayments),
      ],
    );
  }
}

class _RepaymentHeroCard extends StatelessWidget {
  const _RepaymentHeroCard({required this.loan});

  final LoanSummary loan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level2(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusPill(label: 'Active loan', color: AppColors.primaryFixed),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loan.purpose,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const Divider(color: AppColors.surfaceTint),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Remaining Balance',
                  value: _money(loan.outstandingMinor, loan.currency),
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Next Installment',
                  value: _money(
                    loan.termMonths == 0
                        ? loan.outstandingMinor
                        : (loan.totalPayableMinor / loan.termMonths).ceil(),
                    loan.currency,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _RepaymentHistoryCard extends StatelessWidget {
  const _RepaymentHistoryCard({required this.repayments});

  final List<LoanRepaymentSummary> repayments;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Repayment History',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (repayments.isEmpty)
            Text(
              'No repayments recorded yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            )
          else
            for (final repayment in repayments) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Icon(Icons.arrow_downward, color: AppColors.primary),
                ),
                title: Text(_money(repayment.amountMinor, repayment.currency)),
                subtitle: Text('${_titleCase(repayment.method)} | ${_date(repayment.paidAt)}'),
                trailing: StatusPill(label: _titleCase(repayment.status)),
              ),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _LoanReviewFilters extends StatelessWidget {
  const _LoanReviewFilters({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(label: Text('All ($total)'), selected: true, onSelected: (_) {}),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(label: const Text('Pending Review'), selected: false, onSelected: (_) {}),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(label: const Text('Guarantor Pending'), selected: false, onSelected: (_) {}),
        ],
      ),
    );
  }
}

class _LoanApplicationCard extends StatelessWidget {
  const _LoanApplicationCard({required this.application});

  final LoanApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(initials: _initials(application.applicant.fullName)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicant.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${application.termMonths} Months | ${_titleCase(application.status)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(application.amountMinor, application.currency),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    application.purpose,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SoftInfoLine(
            icon: Icons.verified_user_outlined,
            label:
                '${application.guarantorSummary.confirmed}/${application.guarantorSummary.required} Guarantors Confirmed',
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => context.go('/loans/applications/${application.id}'),
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Review Application'),
          ),
        ],
      ),
    );
  }
}

class _ApplicantReviewHeader extends StatelessWidget {
  const _ApplicantReviewHeader({required this.application});

  final LoanApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Row(
        children: [
          InitialsAvatar(initials: _initials(application.applicant.fullName)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.applicant.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  application.applicant.memberNumber ?? application.applicant.status ?? 'Member',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          StatusPill(label: _titleCase(application.status)),
        ],
      ),
    );
  }
}

class _LoanReviewDetailsCard extends StatelessWidget {
  const _LoanReviewDetailsCard({required this.application});

  final LoanApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Loan Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewDetailRow(
            label: 'Requested Amount',
            value: _money(application.amountMinor, application.currency),
          ),
          _ReviewDetailRow(label: 'Purpose', value: application.purpose),
          _ReviewDetailRow(
            label: 'Repayment Term',
            value: '${application.termMonths} Months',
          ),
          _ReviewDetailRow(
            label: 'Estimated Total',
            value: _money(application.estimatedTotalPayableMinor, application.currency),
          ),
          _ReviewDetailRow(label: 'Interest Rate', value: '1.5% / month'),
        ],
      ),
    );
  }
}

class _ReviewDetailRow extends StatelessWidget {
  const _ReviewDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuarantorVerificationCard extends StatelessWidget {
  const _GuarantorVerificationCard({required this.application});

  final LoanApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guarantor Verification',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final guarantor in application.guarantors) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: InitialsAvatar(initials: _initials(guarantor.member.fullName)),
              title: Text(guarantor.member.fullName),
              trailing: StatusPill(label: _titleCase(guarantor.status)),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _AdminReviewCard extends StatelessWidget {
  const _AdminReviewCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Treasurer Review',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Comments, modified amount, or disbursement notes...',
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftInfoLine extends StatelessWidget {
  const _SoftInfoLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    required this.padding,
    this.backgroundColor = AppColors.surfaceContainerLowest,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}

String _money(int amountMinor, String currency) {
  final value = amountMinor.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '$currency $value';
}

String _shortMoney(int amountMinor) {
  if (amountMinor >= 1000) return '${amountMinor ~/ 1000}k';
  return amountMinor.toString();
}

String _date(DateTime? value) {
  if (value == null) return 'not set';
  const months = [
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'M';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _titleCase(String value) {
  return value
      .split('_')
      .map((part) {
        if (part.isEmpty) return part;
        return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
      })
      .join(' ');
}
