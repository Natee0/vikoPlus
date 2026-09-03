import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_logout_controls.dart';
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

class SelectContributionScreen extends StatelessWidget {
  const SelectContributionScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Select Contribution',
      backRoute: '/member/dashboard',
      showBackButton: showBackButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose what you want to pay.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const _SelectableObligation(
            title: 'Joining fee',
            subtitle: 'One-time membership fee',
            amount: 'TZS 10,000',
            selected: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SelectableObligation(
            title: 'July monthly contribution',
            subtitle: 'Monthly contribution for July 2026',
            amount: 'TZS 5,000',
            selected: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SelectableObligation(
            title: 'August monthly contribution',
            subtitle: 'Optional early payment',
            amount: 'TZS 5,000',
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: const [
              ('Selected items', '2'),
              ('Payment window', 'July 2026'),
            ],
            total: 'TZS 15,000',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/member/payments/method'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Payment Method',
      backRoute: '/member/payments/select',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PaymentMethodTile(
            title: 'Mobile money',
            subtitle: 'M-Pesa, Tigo Pesa, Airtel Money',
            icon: Icons.phone_android_outlined,
            selected: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _PaymentMethodTile(
            title: 'Bank transfer',
            subtitle: 'Pay from a bank account',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _PaymentMethodTile(
            title: 'Cash to treasurer',
            subtitle: 'Treasurer records and verifies manually',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.go('/member/payments/review/mobile-money'),
            child: const Text('Review Payment'),
          ),
        ],
      ),
    );
  }
}

class ReviewPaymentScreen extends StatelessWidget {
  const ReviewPaymentScreen({this.method = 'Mobile money', super.key});

  final String method;

  @override
  Widget build(BuildContext context) {
    final isCash = method.toLowerCase().contains('cash');

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
            title: isCash ? 'Cash payment' : 'Mobile money',
            subtitle: isCash
                ? 'This payment will be pending treasurer verification.'
                : 'Confirm your selected contribution before submitting.',
            compact: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: [
              const ('Member', 'Amina Issa'),
              const ('Group', 'Sofia Wajukuu'),
              ('Payment method', method),
              const ('Reference', 'TRX-89234-77'),
            ],
            total: 'TZS 15,000',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go(
              isCash
                  ? '/member/payments/success/cash'
                  : '/member/payments/success/mobile-money',
            ),
            icon: Icon(isCash ? Icons.fact_check_outlined : Icons.lock_outline),
            label: Text(isCash ? 'Submit for verification' : 'Confirm Payment'),
          ),
        ],
      ),
    );
  }
}

class PaymentSuccessfulScreen extends StatelessWidget {
  const PaymentSuccessfulScreen({this.method = 'Mobile money', super.key});

  final String method;

  @override
  Widget build(BuildContext context) {
    final isCash = method.toLowerCase().contains('cash');

    return VikoplusScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _SuccessMark(pending: isCash),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Payment Successful!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCash
                ? 'Your contribution has been received and is pending verification by the group admin.'
                : 'Your transaction has been processed securely.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReceiptSummary(
            lines: [
              const ('Member', 'Amina Issa'),
              const ('Date', 'Sep 2, 2026, 10:42 AM'),
              const ('Receipt No.', 'SW-2026-042'),
              ('Payment Method', method),
            ],
            total: isCash ? 'TZS 10,000' : 'TZS 15,000',
            label: 'Total Amount',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/member/receipts/latest'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View Receipt'),
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
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _SimpleMemberTile(
      title: title,
      subtitle: subtitle,
      leading: Checkbox(value: selected, onChanged: (_) {}),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _SimpleMemberTile(
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
