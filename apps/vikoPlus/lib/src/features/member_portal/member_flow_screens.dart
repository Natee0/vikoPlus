import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class MemberDashboardNewUserScreen extends StatelessWidget {
  const MemberDashboardNewUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Member Portal',
      actions: [
        const AuthLogoutIconButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CenteredHero(
            icon: Icons.group_add_outlined,
            title: 'Welcome to Sofia Wajukuu',
            subtitle: 'Your membership is active. Start with your first contribution.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/member/payments/select'),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Make first contribution'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.go('/member/profile'),
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('Review profile'),
          ),
        ],
      ),
    );
  }
}

class MyContributionsScreen extends StatelessWidget {
  const MyContributionsScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final member = sofiaMembers[1];

    return VikoplusScreen(
      title: 'My Contributions',
      backRoute: '/member/dashboard',
      showBackButton: showBackButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricPanel(
            label: 'Total paid',
            value: formatter.money(member.totalPaid),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricPanel(
            label: 'Outstanding',
            value: formatter.money(member.outstanding),
            icon: Icons.pending_actions_outlined,
            color: AppColors.error,
            backgroundColor: AppColors.errorContainer.withValues(alpha: 0.42),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Contribution History'),
          const SizedBox(height: AppSpacing.sm),
          const _MemberContributionTile(
            title: 'Joining fee',
            subtitle: 'Required before full activation',
            amount: 'TZS 10,000',
            paid: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _MemberContributionTile(
            title: 'July monthly contribution',
            subtitle: 'Due on July 5, 2026',
            amount: 'TZS 5,000',
            paid: false,
          ),
        ],
      ),
    );
  }
}

class DuesArrearsScreen extends StatelessWidget {
  const DuesArrearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: 'Member Portal',
      backRoute: '/member/dashboard',
      actions: [
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dues & Arrears',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manage your outstanding club fees.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          _AmountDueCard(amount: formatter.money(120000)),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Outstanding Months'),
          const SizedBox(height: AppSpacing.sm),
          const _ArrearsMonthTile(month: 'October 2026', amount: 'TZS 40,000'),
          const SizedBox(height: AppSpacing.sm),
          const _ArrearsMonthTile(month: 'November 2026', amount: 'TZS 40,000'),
          const SizedBox(height: AppSpacing.sm),
          const _ArrearsMonthTile(
            month: 'December 2026',
            amount: 'TZS 40,000',
            primaryAction: true,
          ),
          const SizedBox(height: AppSpacing.md),
          const _InfoNotice(
            title: 'Already paid?',
            message: 'Notify the treasurer for a month you have already paid. The group admin or treasurer will verify and update your record.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.go('/member/payments/select'),
            child: const Text('Pay selected dues'),
          ),
        ],
      ),
    );
  }
}

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'My Profile',
      backRoute: '/member/dashboard',
      showBackButton: showBackButton,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CenteredHero(
            icon: Icons.person_outline,
            title: 'Amina Issa',
            subtitle: 'Member | Sofia Wajukuu',
          ),
          SizedBox(height: AppSpacing.md),
          _ProfileField(label: 'Member Number', value: 'SW-002'),
          SizedBox(height: AppSpacing.sm),
          _ProfileField(label: 'Phone Number', value: '+255 712 019 284'),
          SizedBox(height: AppSpacing.sm),
          _ProfileField(label: 'Group', value: 'Sofia Wajukuu'),
          SizedBox(height: AppSpacing.sm),
          _ProfileField(label: 'Status', value: 'Active member'),
        ],
      ),
    );
  }
}

class SelectContributionScreen extends ConsumerStatefulWidget {
  const SelectContributionScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  ConsumerState<SelectContributionScreen> createState() =>
      _SelectContributionScreenState();
}

class _SelectContributionScreenState
    extends ConsumerState<SelectContributionScreen> {
  final Set<String> _selectedIds = {};
  bool _initializedSelection = false;
  String _errorMessage = '';

  void _initializeSelection(List<ContributionObligationSummary> obligations) {
    if (_initializedSelection) return;
    _initializedSelection = true;
    _selectedIds.addAll(
      obligations
          .where((obligation) => obligation.outstandingMinor > 0)
          .take(2)
          .map((obligation) => obligation.id),
    );
  }

  void _continue(List<ContributionObligationSummary> obligations) {
    final selected = obligations
        .where((obligation) => _selectedIds.contains(obligation.id))
        .toList();
    if (selected.isEmpty) {
      setState(() => _errorMessage = 'Select at least one contribution.');
      return;
    }
    ref.read(selectedContributionPaymentProvider.notifier).set(
          SelectedContributionPayment(obligations: selected),
        );
    context.go('/member/payments/method');
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: 'Select Contribution',
      backRoute: '/member/dashboard',
      showBackButton: widget.showBackButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose what you want to pay.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (activeGroup == null) ...[
            const AuthErrorMessage(
              message: 'Select a group before making a contribution.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/groups/my'),
              child: const Text('Choose Group'),
            ),
          ] else
            FutureBuilder<ContributionRegisterResult>(
              future: ref
                  .read(groupsRepositoryProvider)
                  .contributionRegister(activeGroup.id),
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
                    message: 'Could not load your contributions.',
                  );
                }

                final obligations = (snapshot.data?.obligations ?? const [])
                    .where((obligation) => obligation.outstandingMinor > 0)
                    .toList();
                _initializeSelection(obligations);
                if (obligations.isEmpty) {
                  return const _InfoNotice(
                    title: 'Nothing Due',
                    message:
                        'Your current contribution obligations are fully paid.',
                  );
                }

                final selected = obligations
                    .where((obligation) => _selectedIds.contains(obligation.id))
                    .toList();
                final amountMinor = selected.fold<int>(
                  0,
                  (total, obligation) => total + obligation.outstandingMinor,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final obligation in obligations) ...[
                      _SelectableObligation(
                        title: obligation.planName,
                        subtitle: obligation.periodLabel,
                        amount: formatters.money(
                          obligation.outstandingMinor,
                          currency: obligation.currency,
                        ),
                        selected: _selectedIds.contains(obligation.id),
                        onChanged: (selected) {
                          setState(() {
                            _errorMessage = '';
                            if (selected) {
                              _selectedIds.add(obligation.id);
                            } else {
                              _selectedIds.remove(obligation.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    _ReceiptSummary(
                      lines: [
                        ('Selected items', '${selected.length}'),
                        (
                          'Payment purpose',
                          selected
                              .map((obligation) => obligation.planName)
                              .toSet()
                              .join(', '),
                        ),
                      ],
                      total: formatters.money(amountMinor),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorMessage(message: _errorMessage),
                    if (_errorMessage.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => _continue(obligations),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Continue'),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  String _method = 'Mobile money';

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(selectedContributionPaymentProvider);

    return VikoplusScreen(
      title: 'Payment Method',
      backRoute: '/member/payments/select',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaymentMethodTile(
            title: 'Mobile money',
            subtitle: 'M-Pesa, Tigo Pesa, Airtel Money',
            icon: Icons.phone_android_outlined,
            selected: _method == 'Mobile money',
            onTap: () => setState(() => _method = 'Mobile money'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodTile(
            title: 'Bank transfer',
            subtitle: 'Pay from a bank account',
            icon: Icons.account_balance_outlined,
            selected: _method == 'Bank transfer',
            onTap: () => setState(() => _method = 'Bank transfer'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodTile(
            title: 'Cash to treasurer',
            subtitle: 'Treasurer records and verifies manually',
            icon: Icons.payments_outlined,
            selected: _method == 'Cash to treasurer',
            onTap: () => setState(() => _method = 'Cash to treasurer'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: payment == null
                ? () => context.go('/member/payments/select')
                : () {
                    ref
                        .read(selectedContributionPaymentProvider.notifier)
                        .set(payment.copyWith(method: _method));
                    final route = _method.toLowerCase().contains('cash')
                        ? '/member/payments/review/cash'
                        : '/member/payments/review/mobile-money';
                    context.go(route);
                  },
            child: const Text('Review Payment'),
          ),
        ],
      ),
    );
  }
}

class ReviewPaymentScreen extends ConsumerStatefulWidget {
  const ReviewPaymentScreen({this.method = 'Mobile money', super.key});

  final String method;

  @override
  ConsumerState<ReviewPaymentScreen> createState() =>
      _ReviewPaymentScreenState();
}

class _ReviewPaymentScreenState extends ConsumerState<ReviewPaymentScreen> {
  String _errorMessage = '';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) {
      setState(() => _errorMessage = 'Select a group before submitting payment.');
      return;
    }
    final selectedPayment = ref.read(selectedContributionPaymentProvider);
    if (selectedPayment == null || selectedPayment.amountMinor <= 0) {
      setState(
        () => _errorMessage = 'Select contribution items before submitting.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final payment = await ref.read(groupsRepositoryProvider).submitPaymentRequest(
            activeGroup.id,
            SubmitPaymentRequestInput(
              amountMinor: selectedPayment.amountMinor,
              method: _apiMethod(selectedPayment.method),
              obligationIds: selectedPayment.obligationIds,
              reference: 'Member submitted',
              paidAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      final successRoute = selectedPayment.method.toLowerCase().contains('cash')
          ? '/member/payments/success/cash'
          : '/member/payments/success/mobile-money';
      context.go(
        '$successRoute?paymentId=${Uri.encodeComponent(payment.id)}',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Payment request was not submitted. Please try again.',
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
    final selectedPayment = ref.watch(selectedContributionPaymentProvider);
    final method = selectedPayment?.method ?? widget.method;
    final isCash = method.toLowerCase().contains('cash');
    final amountMinor = selectedPayment?.amountMinor ?? 0;
    final obligations = selectedPayment?.obligations ?? const [];

    return VikoplusScreen(
      title: 'Review Payment',
      backRoute: '/member/payments/method',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CenteredHero(
            icon: isCash
                ? Icons.payments_outlined
                : Icons.phone_android_outlined,
            title: isCash ? 'Cash payment' : method,
            subtitle:
                'Submit this contribution for treasurer verification.',
            compact: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: [
              (
                'Member',
                obligations.isEmpty ? 'Member' : obligations.first.memberName,
              ),
              ('Group', activeGroup?.name ?? 'Selected group'),
              ('Payment method', method),
              const ('Status', 'Pending treasurer review'),
            ],
            total: formatters.money(amountMinor),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          if (_errorMessage.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(
              _isSubmitting ? 'Submitting' : 'Submit for verification',
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentSuccessfulScreen extends ConsumerWidget {
  const PaymentSuccessfulScreen({
    this.method = 'Mobile money',
    this.paymentId,
    super.key,
  });

  final String method;
  final String? paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final selectedPayment = ref.watch(selectedContributionPaymentProvider);
    final selectedObligations = selectedPayment?.obligations ?? const [];
    final paymentMethod = selectedPayment?.method ?? method;
    final amountMinor = selectedPayment?.amountMinor ?? 0;

    return VikoplusScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const _SuccessMark(pending: true),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Payment Submitted',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your contribution request is waiting for treasurer verification. A receipt will be created after approval.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: [
              (
                'Member',
                selectedObligations.isEmpty
                    ? 'Member'
                    : selectedObligations.first.memberName,
              ),
              ('Request ID', paymentId ?? 'Pending'),
              const ('Status', 'Pending verification'),
              ('Payment Method', paymentMethod),
            ],
            total: formatters.money(amountMinor),
            label: 'Total Amount',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/member/contributions'),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('View Contributions'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/member/payments/select'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Record New'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.go('/member/dashboard'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }
}

String _apiMethod(String method) {
  final normalized = method.toLowerCase();
  if (normalized.contains('cash')) return 'CASH';
  if (normalized.contains('bank')) return 'BANK_TRANSFER';
  if (normalized.contains('mobile') || normalized.contains('money')) {
    return 'MOBILE_MONEY';
  }
  return 'OTHER';
}

class _AmountDueCard extends StatelessWidget {
  const _AmountDueCard({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.onError,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.error, color: AppColors.error),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount Due',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Please settle these accounts as soon as possible.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onErrorContainer.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onErrorContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrearsMonthTile extends StatelessWidget {
  const _ArrearsMonthTile({
    required this.month,
    required this.amount,
    this.primaryAction = false,
  });

  final String month;
  final String amount;
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month, color: AppColors.error),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Monthly Club Dues',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              primaryAction
                  ? FilledButton.icon(
                      onPressed: () => context.go('/reminders/new'),
                      icon: const Icon(Icons.campaign_outlined, size: 18),
                      label: const Text('Send Reminder'),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => context.go('/reminders/new'),
                      icon: const Icon(Icons.campaign_outlined, size: 18),
                      label: const Text('Send Reminder'),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredHero extends StatelessWidget {
  const _CenteredHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        children: [
          CircleAvatar(
            radius: compact ? 34 : 48,
            backgroundColor: AppColors.surfaceContainer,
            child: Icon(
              icon,
              color: AppColors.primary,
              size: compact ? 36 : 52,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MemberContributionTile extends StatelessWidget {
  const _MemberContributionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.paid,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    return _SimpleMemberTile(
      title: title,
      subtitle: subtitle,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xxs),
          StatusPill(
            label: paid ? 'Paid' : 'Due',
            color: paid ? AppColors.primary : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _SelectableObligation extends StatelessWidget {
  const _SelectableObligation({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.selected = false,
    this.onChanged,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _SimpleMemberTile(
      title: title,
      subtitle: subtitle,
      leading: Checkbox(
        value: selected,
        onChanged: (value) => onChanged?.call(value ?? false),
      ),
      trailing: Text(
        amount,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      highlighted: selected,
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap,
      child: _SimpleMemberTile(
        title: title,
        subtitle: subtitle,
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceContainer,
          child: Icon(icon, color: AppColors.primary),
        ),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.primary : AppColors.outline,
        ),
        highlighted: selected,
      ),
    );
  }
}

class _SimpleMemberTile extends StatelessWidget {
  const _SimpleMemberTile({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      borderColor: highlighted
          ? AppColors.primary.withValues(alpha: 0.55)
          : AppColors.outlineVariant,
      backgroundColor: highlighted
          ? AppColors.secondaryContainer.withValues(alpha: 0.42)
          : AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SimpleMemberTile(
      title: label,
      subtitle: value,
      leading: const Icon(Icons.info_outline, color: AppColors.primary),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.surfaceContainerLowest,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      backgroundColor: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({
    required this.lines,
    required this.total,
    this.label = 'Total',
  });

  final List<(String, String)> lines;
  final String total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            total,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.outlineVariant),
          for (final line in lines)
            _ReceiptLine(label: line.$1, value: line.$2),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: pending ? AppColors.surfaceContainer : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: AppShadows.level2(),
        ),
        child: Icon(
          pending ? Icons.fact_check : Icons.check_circle,
          color: pending ? AppColors.primary : AppColors.onPrimary,
          size: 54,
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = AppInsets.compactCard,
    this.backgroundColor = AppColors.surfaceContainerLowest,
    this.borderColor = AppColors.outlineVariant,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}
