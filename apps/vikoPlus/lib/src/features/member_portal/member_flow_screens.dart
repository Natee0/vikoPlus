import 'package:flutter/material.dart';

import '../../core/auth/profile_provider.dart';
import '../common/profile_avatar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../routing/portal_route_guard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

List<ContributionObligationSummary> _myObligations(
  List<ContributionObligationSummary> obligations,
  GroupAccessSummary activeGroup,
) {
  final membershipId = activeGroup.membershipId;
  if (membershipId == null || membershipId.isEmpty) {
    return obligations;
  }
  return obligations
      .where((obligation) => obligation.memberId == membershipId)
      .toList();
}

class MemberDashboardNewUserScreen extends ConsumerWidget {
  const MemberDashboardNewUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupName =
        ref.watch(activeGroupProvider)?.name ?? context.vt('your group');

    return VikoplusScreen(
      title: context.vt('Member Portal'),
      actions: [const AuthLogoutIconButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CenteredHero(
            icon: Icons.group_add_outlined,
            title: context.vt('Welcome to your group'),
            subtitle: context.vt(
              'Your membership is active. Start with your first contribution.',
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            groupName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/member/payments/select'),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: Text(context.vt('Make first contribution')),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.go('/member/profile'),
            icon: const Icon(Icons.person_outline, size: 18),
            label: Text(context.vt('Review profile')),
          ),
        ],
      ),
    );
  }
}

class MyContributionsScreen extends ConsumerWidget {
  const MyContributionsScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: context.vt('My Contributions'),
      backRoute: '/member/dashboard',
      showBackButton: showBackButton,
      child: activeGroup == null
          ? AuthErrorMessage(
              message: context.vt('Select a group to view your contributions.'),
            )
          : FutureBuilder<ContributionRegisterResult>(
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
                if (snapshot.hasError || snapshot.data == null) {
                  return AuthErrorMessage(
                    message: context.vt(
                      'Could not load contributions. Please try again.',
                    ),
                  );
                }

                final obligations = _myObligations(
                  snapshot.data!.obligations,
                  activeGroup,
                );
                final totalPaid = obligations.fold<int>(
                  0,
                  (total, item) => total + item.amountPaidMinor,
                );
                final outstanding = obligations
                    .where((item) => item.isPayable)
                    .fold<int>(
                  0,
                  (total, item) => total + item.outstandingMinor,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MetricPanel(
                      label: context.vt('Total paid'),
                      value: formatter.compactMoney(totalPaid),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MetricPanel(
                      label: context.vt('Outstanding'),
                      value: formatter.compactMoney(outstanding),
                      icon: Icons.pending_actions_outlined,
                      color: AppColors.error,
                      backgroundColor: AppColors.errorContainer.withValues(
                        alpha: 0.42,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionHeader(title: context.vt('Contribution History')),
                    const SizedBox(height: AppSpacing.sm),
                    if (obligations.isEmpty)
                      AuthErrorMessage(
                        message: context.vt(
                          'No contribution obligations are due.',
                        ),
                      )
                    else
                      for (final obligation in obligations) ...[
                        _MemberContributionTile(
                          title: obligation.planName,
                          subtitle: _obligationSubtitle(
                            context,
                            formatter,
                            obligation,
                          ),
                          amount: formatter.money(
                            obligation.outstandingMinor,
                            currency: obligation.currency,
                          ),
                          paid: obligation.outstandingMinor <= 0,
                          upcoming: obligation.isUpcoming,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                  ],
                );
              },
            ),
    );
  }
}

class DuesArrearsScreen extends ConsumerWidget {
  const DuesArrearsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: context.vt('Member Portal'),
      backRoute: '/member/dashboard',
      actions: [
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: context.vt('Notifications'),
        ),
      ],
      child: activeGroup == null
          ? AuthErrorMessage(
              message: context.vt('Select a group to view dues and arrears.'),
            )
          : FutureBuilder<ContributionRegisterResult>(
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
                if (snapshot.hasError || snapshot.data == null) {
                  return AuthErrorMessage(
                    message: context.vt('Could not load outstanding dues.'),
                  );
                }

                final obligations = _myObligations(
                  snapshot.data!.obligations,
                  activeGroup,
                );
                final outstanding = obligations
                    .where((item) => item.isPayable)
                    .toList();
                final totalOutstanding = outstanding.fold<int>(
                  0,
                  (total, item) => total + item.outstandingMinor,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.vt('Dues & Arrears'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.vt('Manage your outstanding group fees.'),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AmountDueCard(amount: formatter.money(totalOutstanding)),
                    const SizedBox(height: AppSpacing.md),
                    SectionHeader(
                      title: context.vt('Outstanding Contributions'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (outstanding.isEmpty)
                      AuthErrorMessage(
                        message: context.vt(
                          'You do not have outstanding dues.',
                        ),
                      )
                    else
                      for (final item in outstanding) ...[
                        _ArrearsMonthTile(
                          month: item.periodLabel,
                          amount: formatter.money(
                            item.outstandingMinor,
                            currency: item.currency,
                          ),
                          primaryAction: item == outstanding.first,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    const SizedBox(height: AppSpacing.md),
                    _InfoNotice(
                      title: context.vt('Already paid?'),
                      message: context.vt(
                        'Notify the treasurer for a payment you have already sent. The treasurer will verify and update your record.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => context.go('/member/payments/select'),
                      child: Text(context.vt('Pay selected dues')),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).user;
    final activeGroup = ref.watch(activeGroupProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final displayName =
        (profile?['displayName'] as String? ?? user?.displayName)?.trim();
    final memberName = displayName == null || displayName.isEmpty
        ? context.vt('Member')
        : displayName;

    return VikoplusScreen(
      title: context.vt('My Profile'),
      backRoute: '/member/dashboard',
      showBackButton: showBackButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ProfileAvatar(
              name: memberName,
              url: profile?['profilePictureUrl'] as String?,
              radius: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            memberName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            _roleLabel(activeGroup?.role ?? 'MEMBER'),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: () => context.push('/profile/complete'),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.vt('Manage profile')),
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileField(
            label: context.vt('User ID'),
            value: user?.id ?? context.vt('Not signed in'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileField(
            label: context.vt('Preferred Language'),
            value: user?.preferredLocale.toUpperCase() ?? 'EN',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileField(
            label: context.vt('Group'),
            value: activeGroup?.name ?? context.vt('None'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileField(
            label: context.vt('Status'),
            value: activeGroup?.status ?? context.vt('New user'),
          ),
          if (activeGroup != null && user != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MembershipDetails(groupId: activeGroup.id, userId: user.id),
          ],
        ],
      ),
    );
  }
}

class _MembershipDetails extends ConsumerWidget {
  const _MembershipDetails({required this.groupId, required this.userId});

  final String groupId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<GroupMembersResult>(
      future: ref.read(groupsRepositoryProvider).listMembers(groupId),
      builder: (context, snapshot) {
        final members = snapshot.data?.members ?? const [];
        final matches = members.where((member) => member.userId == userId);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }
        final member = matches.first;
        return Column(
          children: [
            _ProfileField(
              label: context.vt('Member number'),
              value: member.memberNumber ?? context.vt('Not provided'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              label: context.vt('Phone number'),
              value: member.phone ?? context.vt('Not provided'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              label: context.vt('Email address'),
              value: member.email ?? context.vt('Not provided'),
            ),
          ],
        );
      },
    );
  }
}

class SelectContributionScreen extends ConsumerStatefulWidget {
  const SelectContributionScreen({
    this.showBackButton = true,
    this.bottomNavigationIndex,
    this.usePortalPaymentTabIndex = false,
    super.key,
  });

  final bool showBackButton;
  final int? bottomNavigationIndex;
  final bool usePortalPaymentTabIndex;

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
          .where((obligation) => obligation.isPayable)
          .take(2)
          .map((obligation) => obligation.id),
    );
  }

  void _continue(List<ContributionObligationSummary> obligations) {
    final selected = obligations
        .where((obligation) => _selectedIds.contains(obligation.id))
        .toList();
    if (selected.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Select at least one contribution.'),
      );
      return;
    }
    ref
        .read(selectedContributionPaymentProvider.notifier)
        .set(SelectedContributionPayment(obligations: selected));
    context.go('/member/payments/method');
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: context.vt('Select Contribution'),
      backRoute: portalHomeRoute(activeGroup),
      showBackButton: widget.showBackButton,
      bottomNavigationIndex: widget.bottomNavigationIndex ??
          (widget.usePortalPaymentTabIndex
              ? portalPaymentsTabIndex(activeGroup)
              : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.vt('Choose what you want to pay.'),
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (activeGroup == null) ...[
            AuthErrorMessage(
              message: context.vt(
                'Select a group before making a contribution.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/groups'),
              child: Text(context.vt('Choose Group')),
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
                  return AuthErrorMessage(
                    message: context.vt('Could not load your contributions.'),
                  );
                }

                final allObligations = _myObligations(
                  snapshot.data?.obligations ?? const [],
                  activeGroup,
                );
                final obligations = allObligations
                    .where((obligation) => obligation.isPayable)
                    .toList();
                _initializeSelection(obligations);
                if (obligations.isEmpty) {
                  final hasUpcoming = allObligations.any(
                    (obligation) => obligation.isUpcoming,
                  );
                  return _InfoNotice(
                    title: context.vt('Nothing Due'),
                    message: context.vt(
                      hasUpcoming
                          ? 'No contributions are due yet. Upcoming items will activate on their collection date.'
                          : 'Your current contribution obligations are fully paid.',
                    ),
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
                        (context.vt('Selected items'), '${selected.length}'),
                        (
                          context.vt('Payment purpose'),
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
                      label: Text(context.vt('Continue')),
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
    final activeGroup = ref.watch(activeGroupProvider);

    return VikoplusScreen(
      title: context.vt('Payment Method'),
      backRoute: portalPaymentsRoute(activeGroup),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaymentMethodTile(
            title: context.vt('Mobile money'),
            subtitle: context.vt('M-Pesa, Tigo Pesa, Airtel Money'),
            icon: Icons.phone_android_outlined,
            selected: _method == 'Mobile money',
            onTap: () => setState(() => _method = 'Mobile money'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodTile(
            title: context.vt('Bank transfer'),
            subtitle: context.vt('Pay from a bank account'),
            icon: Icons.account_balance_outlined,
            selected: _method == 'Bank transfer',
            onTap: () => setState(() => _method = 'Bank transfer'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodTile(
            title: context.vt('Cash to treasurer'),
            subtitle: context.vt('Treasurer records and verifies manually'),
            icon: Icons.payments_outlined,
            selected: _method == 'Cash to treasurer',
            onTap: () => setState(() => _method = 'Cash to treasurer'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: payment == null
                ? () => context.go(portalPaymentsRoute(activeGroup))
                : () {
                    ref
                        .read(selectedContributionPaymentProvider.notifier)
                        .set(payment.copyWith(method: _method));
                    final route = _method.toLowerCase().contains('cash')
                        ? '/member/payments/review/cash'
                        : '/member/payments/review/mobile-money';
                    context.go(route);
                  },
            child: Text(context.vt('Review Payment')),
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
      setState(
        () => _errorMessage = context.vt(
          'Select a group before submitting payment.',
        ),
      );
      return;
    }
    final selectedPayment = ref.read(selectedContributionPaymentProvider);
    if (selectedPayment == null || selectedPayment.amountMinor <= 0) {
      setState(
        () => _errorMessage = context.vt(
          'Select contribution items before submitting.',
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final payment = await ref
          .read(groupsRepositoryProvider)
          .submitPaymentRequest(
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
      context.go('$successRoute?paymentId=${Uri.encodeComponent(payment.id)}');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = context.vt(
          'Payment request was not submitted. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
      title: context.vt('Review Payment'),
      backRoute: '/member/payments/method',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CenteredHero(
            icon: isCash
                ? Icons.payments_outlined
                : Icons.phone_android_outlined,
            title: isCash ? context.vt('Cash payment') : context.vt(method),
            subtitle: context.vt(
              'Submit this contribution for secretary or treasurer verification.',
            ),
            compact: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: [
              (
                context.vt('Member'),
                obligations.isEmpty
                    ? context.vt('Member')
                    : obligations.first.memberName,
              ),
              (
                context.vt('Group'),
                activeGroup?.name ?? context.vt('Selected group'),
              ),
              (context.vt('Payment method'), context.vt(method)),
              (context.vt('Status'), context.vt('Pending treasurer review')),
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
              _isSubmitting
                  ? context.vt('Submitting')
                  : context.vt('Submit for verification'),
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
    final activeGroup = ref.watch(activeGroupProvider);
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
            context.vt('Payment Submitted'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.vt(
              'Your contribution request is waiting for secretary or treasurer verification. A receipt will be created after approval.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: [
              (
                context.vt('Member'),
                selectedObligations.isEmpty
                    ? context.vt('Member')
                    : selectedObligations.first.memberName,
              ),
              (context.vt('Request ID'), paymentId ?? context.vt('Pending')),
              (context.vt('Status'), context.vt('Pending verification')),
              (context.vt('Payment Method'), context.vt(paymentMethod)),
            ],
            total: formatters.money(amountMinor),
            label: context.vt('Total Amount'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go(portalContributionsRoute(activeGroup)),
            icon: const Icon(Icons.savings_outlined),
            label: Text(context.vt('View Contributions')),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  label: Text(context.vt('Share')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(portalPaymentsRoute(activeGroup)),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(context.vt('Record New')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.go(portalHomeRoute(activeGroup)),
            icon: const Icon(Icons.arrow_back),
            label: Text(context.vt('Return to Dashboard')),
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
                      context.vt('Monthly Club Dues'),
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
                      label: Text(context.vt('Send Reminder')),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => context.go('/reminders/new'),
                      icon: const Icon(Icons.campaign_outlined, size: 18),
                      label: Text(context.vt('Send Reminder')),
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
    this.upcoming = false,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool paid;
  final bool upcoming;

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
            label: paid
                ? context.vt('Paid')
                : upcoming
                ? context.vt('Upcoming')
                : context.vt('Due'),
            color: paid
                ? AppColors.primary
                : upcoming
                ? AppColors.onSurfaceVariant
                : AppColors.error,
          ),
        ],
      ),
    );
  }
}

String _obligationSubtitle(
  BuildContext context,
  AppFormatters formatter,
  ContributionObligationSummary obligation,
) {
  final dateLabel = obligation.isUpcoming
      ? context.vt('Collection date')
      : context.vt('Due');
  return '${obligation.periodLabel} • '
      '$dateLabel ${formatter.date(obligation.dueAt)}';
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

String _roleLabel(String value) {
  return value
      .toLowerCase()
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
