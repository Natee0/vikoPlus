import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/info_card.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class ContributionRegisterScreen extends ConsumerStatefulWidget {
  const ContributionRegisterScreen({
    this.showBottomNavigation = true,
    super.key,
  });

  final bool showBottomNavigation;

  @override
  ConsumerState<ContributionRegisterScreen> createState() =>
      _ContributionRegisterScreenState();
}

class _ContributionRegisterScreenState
    extends ConsumerState<ContributionRegisterScreen> {
  bool _isReviewing = false;
  String _errorMessage = '';

  Future<void> _reviewPayment(
    GroupAccessSummary group,
    ContributionPaymentSummary payment,
    bool approve,
  ) async {
    setState(() {
      _isReviewing = true;
      _errorMessage = '';
    });
    try {
      await (approve
          ? ref.read(groupsRepositoryProvider).approvePayment(group.id, payment.id)
          : ref
              .read(groupsRepositoryProvider)
              .rejectPayment(group.id, payment.id, reason: 'Rejected by treasurer'));
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = approve
            ? 'Payment was not approved. Please try again.'
            : 'Payment was not rejected. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isReviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);
    final canReviewPayments = activeGroup?.role == 'TREASURER';

    return VikoplusScreen(
      title: 'Contribution Register',
      bottomNavigationIndex: 2,
      showBottomNavigation: widget.showBottomNavigation,
      actions: [
        if (canReviewPayments)
          IconButton(
            tooltip: 'Record payment',
            onPressed: () => context.go('/contributions/record'),
            icon: const Icon(Icons.add_card_outlined),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusPill(label: activeGroup?.name ?? sofiaFinancialYear),
          const SizedBox(height: 16),
          const ActionTile(
            title: 'Loan applications',
            subtitle: 'Review guarantors, approve loans, and disburse funds',
            icon: Icons.fact_check_outlined,
            route: '/loans/applications',
          ),
          const SizedBox(height: 16),
          if (activeGroup == null) ...[
            const AuthErrorMessage(
              message: 'Select a group to view contribution payments.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/groups/my'),
              child: const Text('Choose Group'),
            ),
          ] else ...[
            FutureBuilder<ContributionPaymentsResult>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .contributionPayments(activeGroup.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const AuthErrorMessage(
                    message: 'Could not load contribution payments.',
                  );
                }

                final payments = snapshot.data?.payments ?? const [];
                final pending = payments
                    .where((payment) => _isPendingReview(payment.status))
                    .toList();
                final approvedTotal = payments
                    .where((payment) => payment.status == 'APPROVED')
                    .fold<int>(
                      0,
                      (total, payment) => total + payment.amountMinor,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InfoCard(
                      title: 'Total approved contributions',
                      value: formatters.money(approvedTotal),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Approved',
                            value:
                                '${payments.where((payment) => payment.status == 'APPROVED').length}',
                            icon: Icons.check_circle_outline,
                            accentColor: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InfoCard(
                            title: 'Pending',
                            value: '${pending.length}',
                            icon: Icons.pending_actions_outlined,
                            accentColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthErrorMessage(message: _errorMessage),
                    if (_errorMessage.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    if (canReviewPayments) ...[
                      const SectionHeader(title: 'Pending Review'),
                      const SizedBox(height: AppSpacing.sm),
                      if (pending.isEmpty)
                        const _EmptyPaymentsNotice(
                          message: 'No member payments are waiting for review.',
                        )
                      else
                        for (final payment in pending) ...[
                          _PaymentReviewCard(
                            payment: payment,
                            formatters: formatters,
                            isBusy: _isReviewing,
                            onApprove: () =>
                                _reviewPayment(activeGroup, payment, true),
                            onReject: () =>
                                _reviewPayment(activeGroup, payment, false),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SectionHeader(title: 'Recent Payments'),
                    const SizedBox(height: AppSpacing.sm),
                    if (payments.isEmpty)
                      const _EmptyPaymentsNotice(
                        message: 'No contribution payments have been recorded yet.',
                      )
                    else
                      for (final payment in payments.take(20)) ...[
                        _ContributionPaymentRow(
                          payment: payment,
                          formatters: formatters,
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentReviewCard extends StatelessWidget {
  const _PaymentReviewCard({
    required this.payment,
    required this.formatters,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final ContributionPaymentSummary payment;
  final AppFormatters formatters;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

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
          _PaymentHeader(payment: payment, formatters: formatters),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: isBusy ? null : onApprove,
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContributionPaymentRow extends StatelessWidget {
  const _ContributionPaymentRow({
    required this.payment,
    required this.formatters,
  });

  final ContributionPaymentSummary payment;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: payment.receipt == null
            ? null
            : () => context.go(
                  '/contributions/receipt/${Uri.encodeComponent(payment.receipt!.id)}',
                ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _PaymentHeader(payment: payment, formatters: formatters),
        ),
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.payment, required this.formatters});

  final ContributionPaymentSummary payment;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(initials: _initials(payment.memberName)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '${_methodLabel(payment.method)} • ${formatters.date(payment.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatters.money(payment.amountMinor, currency: payment.currency),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            StatusPill(
              label: _statusLabel(payment.status),
              color: _statusColor(payment.status),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyPaymentsNotice extends StatelessWidget {
  const _EmptyPaymentsNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

bool _isPendingReview(String status) {
  return status == 'SUBMITTED' ||
      status == 'PENDING_VERIFICATION' ||
      status == 'CORRECTION_REQUESTED';
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

String _methodLabel(String method) {
  return method
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _statusLabel(String status) {
  return status
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

Color _statusColor(String status) {
  if (status == 'APPROVED') return AppColors.primaryGreen;
  if (status == 'REJECTED') return AppColors.error;
  if (status == 'CORRECTION_REQUESTED') return AppColors.warning;
  return AppColors.primary;
}
