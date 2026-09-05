import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/billing/billing_repository.dart';
import '../../core/config/app_config.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState
    extends ConsumerState<SubscriptionPlanScreen> {
  String? _selectedPlanCode;
  String? _loadedGroupId;
  Future<AccessPlansResult>? _plansFuture;
  String _checkoutUrl = '';
  String _errorMessage = '';
  bool _isStartingCheckout = false;

  Uri _billingReturnUri(String path) {
    final apiBaseUri = Uri.parse(AppConfig.VIKOPLUS_API_BASE_URL);
    return apiBaseUri.replace(path: path, query: '');
  }

  Future<AccessPlansResult>? _plansFor(String? groupId) {
    if (groupId == null || groupId.isEmpty) return null;
    if (_loadedGroupId != groupId || _plansFuture == null) {
      _setPlansFuture(groupId);
    }
    return _plansFuture;
  }

  void _setPlansFuture(String groupId, [Future<AccessPlansResult>? future]) {
    _loadedGroupId = groupId;
    _plansFuture =
        future ?? ref.read(billingRepositoryProvider).accessPlans(groupId);
  }

  Future<void> _refresh() async {
    final activeGroup = ref.read(activeGroupProvider);
    if (activeGroup == null) return;
    final future = ref
        .read(billingRepositoryProvider)
        .accessPlans(activeGroup.id);
    setState(() => _setPlansFuture(activeGroup.id, future));
    await future;
  }

  AccessPlanSummary? _selectedPlan(List<AccessPlanSummary> plans) {
    for (final plan in plans) {
      if (plan.code == _selectedPlanCode) return plan;
    }
    if (plans.isEmpty) return null;
    return plans.first;
  }

  Future<void> _startCheckout(
    String groupId,
    AccessPlanSummary plan,
  ) async {
    if (_isStartingCheckout) return;

    try {
      setState(() {
        _checkoutUrl = '';
        _errorMessage = '';
        _isStartingCheckout = true;
      });
      final checkout = await ref
          .read(billingRepositoryProvider)
          .createAccessCheckout(
            groupId,
            AccessCheckoutInput(
              planCode: plan.code,
              successUrl: _billingReturnUri('/billing/success').toString(),
              cancelUrl: _billingReturnUri('/billing/cancelled').toString(),
            ),
          );
      await Clipboard.setData(ClipboardData(text: checkout.checkoutUrl));
      if (!mounted) return;
      setState(() => _checkoutUrl = checkout.checkoutUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout link copied to clipboard.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isStartingCheckout = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return VikoplusScreen(
      title: 'Group Access',
      backRoute: '/groups/onboarding-success',
      onRefresh: activeGroup == null ? null : _refresh,
      child: activeGroup == null
          ? _MissingGroupState(onChooseGroup: () => context.go('/groups'))
          : FutureBuilder<AccessPlansResult>(
              future: _plansFor(activeGroup.id),
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
                  return const AuthErrorMessage(
                    message: 'Could not load access plans.',
                  );
                }

                final plans = snapshot.data!.plans;
                final selected = _selectedPlan(plans);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Activate ${activeGroup.name}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'The group administrator pays platform access for this group. Member contributions remain separate manual records.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (plans.isEmpty)
                      const _NoPlansCard()
                    else ...[
                      for (final plan in plans) ...[
                        _AccessPlanCard(
                          plan: plan,
                          price: formatters.money(
                            plan.priceMinor,
                            currency: plan.currency,
                          ),
                          selected:
                              plan.code == (_selectedPlanCode ?? selected?.code),
                          onTap: () {
                            setState(() => _selectedPlanCode = plan.code);
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    if (_checkoutUrl.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CheckoutLinkCard(
                        url: _checkoutUrl,
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _checkoutUrl),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checkout link copied.'),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AuthErrorMessage(message: _errorMessage),
                    if (_errorMessage.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: selected == null || _isStartingCheckout
                          ? null
                          : () => _startCheckout(activeGroup.id, selected),
                      icon: _isStartingCheckout
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline, size: 18),
                      label: Text(
                        _isStartingCheckout
                            ? 'Creating checkout'
                            : 'Create checkout link',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Open admin dashboard'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _MissingGroupState extends StatelessWidget {
  const _MissingGroupState({required this.onChooseGroup});

  final VoidCallback onChooseGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthErrorMessage(message: 'Select a group to manage billing.'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onChooseGroup,
          child: const Text('Choose Group'),
        ),
      ],
    );
  }
}

class _NoPlansCard extends StatelessWidget {
  const _NoPlansCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Access plans are not available yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPlanCard extends StatelessWidget {
  const _AccessPlanCard({
    required this.plan,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final AccessPlanSummary plan;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.08)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: AppInsets.card,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant,
            ),
            boxShadow: AppShadows.level1(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          _billingCadence(plan),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? AppColors.primary : AppColors.outline,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                price,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (plan.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
              if (plan.trialDays > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _IncludedFeature(label: '${plan.trialDays} days free trial'),
              ],
              const _IncludedFeature(label: 'Admin dashboard and member register'),
              const _IncludedFeature(label: 'Contribution tracking and reports'),
              const _IncludedFeature(
                label: 'Manual member payments stay separate from app access',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _billingCadence(AccessPlanSummary plan) {
    final interval = plan.interval == 'YEAR' ? 'year' : 'month';
    if (plan.intervalCount == 1) return 'Per group, billed every $interval';
    return 'Per group, billed every ${plan.intervalCount} ${interval}s';
  }
}

class _IncludedFeature extends StatelessWidget {
  const _IncludedFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLinkCard extends StatelessWidget {
  const _CheckoutLinkCard({required this.url, required this.onCopy});

  final String url;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout link ready',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy checkout link',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
    );
  }
}
