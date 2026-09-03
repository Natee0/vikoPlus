import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_design_widgets.dart';

class LoansOverviewScreen extends StatelessWidget {
  const LoansOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BorrowingPowerCard(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Active Loans',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('History')),
            ],
          ),
          const _ActiveLoanCard(),
          const SizedBox(height: AppSpacing.md),
          const _EligibilityCard(),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/loans/apply'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Apply for New Loan'),
          ),
        ],
      ),
    );
  }
}

class ApplyForLoanScreen extends StatefulWidget {
  const ApplyForLoanScreen({super.key});

  @override
  State<ApplyForLoanScreen> createState() => _ApplyForLoanScreenState();
}

class _ApplyForLoanScreenState extends State<ApplyForLoanScreen> {
  int _term = 6;
  String _purpose = 'School fees';

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurfacePanel(
            padding: AppInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIKOPLUS CREDIT',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Apply for Loan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: AppColors.surfaceContainer,
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const _LoanAmountField(),
                const SizedBox(height: AppSpacing.sm),
                const Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _AmountChip(label: '10k'),
                    _AmountChip(label: '25k'),
                    _AmountChip(label: '50k'),
                    _AmountChip(label: '100k'),
                    _AmountChip(label: '250k'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Loan Purpose',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  shrinkWrap: true,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _PurposeChip(
                      label: 'School fees',
                      icon: Icons.school_outlined,
                      selected: _purpose == 'School fees',
                      onTap: () => setState(() => _purpose = 'School fees'),
                    ),
                    _PurposeChip(
                      label: 'Emergency',
                      icon: Icons.medical_services_outlined,
                      selected: _purpose == 'Emergency',
                      onTap: () => setState(() => _purpose = 'Emergency'),
                    ),
                    _PurposeChip(
                      label: 'Business',
                      icon: Icons.business_center_outlined,
                      selected: _purpose == 'Business',
                      onTap: () => setState(() => _purpose = 'Business'),
                    ),
                    _PurposeChip(
                      label: 'Agriculture',
                      icon: Icons.agriculture_outlined,
                      selected: _purpose == 'Agriculture',
                      onTap: () => setState(() => _purpose = 'Agriculture'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Repayment Term',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _TermButton(
                      months: 3,
                      selected: _term == 3,
                      onTap: () => setState(() => _term = 3),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TermButton(
                      months: 6,
                      selected: _term == 6,
                      onTap: () => setState(() => _term = 6),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TermButton(
                      months: 12,
                      selected: _term == 12,
                      onTap: () => setState(() => _term = 12),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const _LoanEstimateCard(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _GuarantorCard(),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/loans'),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Submit Loan Application'),
          ),
        ],
      ),
    );
  }
}

class LoanRepaymentScreen extends StatefulWidget {
  const LoanRepaymentScreen({super.key});

  @override
  State<LoanRepaymentScreen> createState() => _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends State<LoanRepaymentScreen> {
  String _provider = 'M-Pesa';

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RepaymentHeroCard(),
          const SizedBox(height: AppSpacing.md),
          _SurfacePanel(
            padding: AppInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Make a Repayment',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Repayment Amount',
                    prefixText: 'TZS ',
                    hintText: '125,000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mobile Money Provider',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _ProviderButton(
                      label: 'M-Pesa',
                      icon: Icons.phone_iphone_outlined,
                      selected: _provider == 'M-Pesa',
                      onTap: () => setState(() => _provider = 'M-Pesa'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _ProviderButton(
                      label: 'Airtel',
                      icon: Icons.phone_android_outlined,
                      selected: _provider == 'Airtel',
                      onTap: () => setState(() => _provider = 'Airtel'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _ProviderButton(
                      label: 'Tigo Pesa',
                      icon: Icons.smartphone_outlined,
                      selected: _provider == 'Tigo Pesa',
                      onTap: () => setState(() => _provider = 'Tigo Pesa'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => context.go('/loans'),
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Pay TZS 125,000 Now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _RepaymentHistoryCard(),
        ],
      ),
    );
  }
}

class LoanApplicationsScreen extends StatelessWidget {
  const LoanApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoanReviewFilters(),
          SizedBox(height: AppSpacing.md),
          _LoanApplicationCard(
            initials: 'DK',
            name: 'David Kiprop',
            amount: 'TZS 500,000',
            loanId: 'Loan #VK-4903 | 6 Months',
            purpose: 'Business Growth',
            guarantors: '2/2 Guarantors Confirmed',
            risk: 'Low Risk (41%)',
            riskColor: AppColors.primary,
          ),
          SizedBox(height: AppSpacing.sm),
          _LoanApplicationCard(
            initials: 'GW',
            name: 'Grace Wanjiku',
            amount: 'TZS 250,000',
            loanId: 'Loan #VK-4901 | 2 Months',
            purpose: 'School Fees',
            guarantors: '1/2 Guarantors Confirmed',
            risk: 'Medium Risk (62%)',
            riskColor: AppColors.warning,
          ),
          SizedBox(height: AppSpacing.sm),
          _LoanApplicationCard(
            initials: 'SO',
            name: 'Samuel Otieno',
            amount: 'TZS 1,000,000',
            loanId: 'Loan #VK-4902 | 12 Months',
            purpose: 'Agriculture',
            guarantors: '0/2 Guarantors Confirmed',
            risk: 'High Risk (65%)',
            riskColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class LoanApplicationReviewScreen extends StatelessWidget {
  const LoanApplicationReviewScreen({
    this.applicationId = 'david-kiprop',
    super.key,
  });

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return _LoanScaffold(
      title: 'Loans',
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ApplicantReviewHeader(),
          const SizedBox(height: AppSpacing.md),
          const _LoanReviewDetailsCard(),
          const SizedBox(height: AppSpacing.md),
          const _GuarantorVerificationCard(),
          const SizedBox(height: AppSpacing.md),
          const _AdminReviewCard(),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/loans/applications'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve & Disburse Funds'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.go('/loans/applications'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject Application'),
          ),
        ],
      ),
    );
  }
}

class _LoanScaffold extends StatelessWidget {
  const _LoanScaffold({
    required this.title,
    required this.child,
    required this.selectedIndex,
  });

  final String title;
  final Widget child;
  final int selectedIndex;

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
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMobile,
                    AppSpacing.sm,
                    AppSpacing.screenMobile,
                    AppSpacing.lg,
                  ),
                  children: [child],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanReviewFilters extends StatelessWidget {
  const _LoanReviewFilters();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All (5)'),
            selected: true,
            onSelected: (_) {},
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('Pending Review (3)'),
            selected: false,
            onSelected: (_) {},
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('Guarantor Pending'),
            selected: false,
            onSelected: (_) {},
          ),
        ],
      ),
    );
  }
}

class _LoanApplicationCard extends StatelessWidget {
  const _LoanApplicationCard({
    required this.initials,
    required this.name,
    required this.amount,
    required this.loanId,
    required this.purpose,
    required this.guarantors,
    required this.risk,
    required this.riskColor,
  });

  final String initials;
  final String name;
  final String amount;
  final String loanId;
  final String purpose;
  final String guarantors;
  final String risk;
  final Color riskColor;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(initials: initials),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      loanId,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    purpose,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SoftInfoLine(
                  icon: Icons.verified_user_outlined,
                  label: guarantors,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusPill(label: risk, color: riskColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => context.go('/loans/applications/$initials'),
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Review Application'),
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
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantReviewHeader extends StatelessWidget {
  const _ApplicantReviewHeader();

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const InitialsAvatar(initials: 'DK'),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'David Kiprop',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Member ID: #VK-4832 | 3 years in group',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const StatusPill(label: 'Active'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _ReviewMetricTile(
                  label: 'Total Savings',
                  value: 'TZS 1,850,000',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReviewMetricTile(
                  label: 'Active Defaults',
                  value: '0 Loans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewMetricTile extends StatelessWidget {
  const _ReviewMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: AppInsets.compactCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanReviewDetailsCard extends StatelessWidget {
  const _LoanReviewDetailsCard();

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Loan Details',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              const StatusPill(label: 'Requested'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Padding(
              padding: AppInsets.compactCard,
              child: Column(
                children: [
                  Text(
                    'REQUESTED AMOUNT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'TZS 500,000',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Purpose: Business growth and inventory',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ReviewDetailRow(label: 'Repayment Term', value: '6 Months'),
          const _ReviewDetailRow(
            label: 'Monthly Installment',
            value: 'TZS 92,500',
          ),
          const _ReviewDetailRow(label: 'Interest Rate', value: '1.5% / month'),
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
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _GuarantorVerificationCard extends StatelessWidget {
  const _GuarantorVerificationCard();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guarantor Verification',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: AppSpacing.sm),
          _VerificationTile(
            name: 'Amina Mwangi',
            status: 'Confirmed',
            trustScore: '98%',
          ),
          SizedBox(height: AppSpacing.xs),
          _VerificationTile(
            name: 'John Ochieng',
            status: 'Confirmed',
            trustScore: '95%',
          ),
        ],
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.name,
    required this.status,
    required this.trustScore,
  });

  final String name;
  final String status;
  final String trustScore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: AppInsets.compactCard,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.surfaceContainer,
              child: Icon(Icons.person_outline, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              trustScore,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminReviewCard extends StatelessWidget {
  const _AdminReviewCard();

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Treasurer Review',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add notes or modify terms before approval.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            minLines: 4,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Comments, modified amount, or disbursement notes...',
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowingPowerCard extends StatelessWidget {
  const _BorrowingPowerCard();

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'AVAILABLE BORROWING POWER',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const CircleAvatar(
                backgroundColor: AppColors.surfaceTint,
                child: Icon(
                  Icons.verified_outlined,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\$1,200.00',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Credit Limit: \$5,000',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.onPrimaryContainer),
              ),
              const Spacer(),
              Text(
                'Tier 2 Member',
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
              value: 0.76,
              minHeight: 7,
              color: AppColors.primaryFixed,
              backgroundColor: AppColors.surfaceTint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: AppColors.primaryFixed,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  '+ \$300 limit increase unlocked',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryFixed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View tier perks',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
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

class _ActiveLoanCard extends StatelessWidget {
  const _ActiveLoanCard();

  @override
  Widget build(BuildContext context) {
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
                      'Emergency Micro-Loan',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Due in 14 days | 4.5% APR',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const StatusPill(label: 'On Track'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: Text('Paid: \$350.00')),
              Text(
                'Remaining: \$150.00',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: const LinearProgressIndicator(
              value: 0.7,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next Payment: \$75.00 on Oct 24',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/loans/repayment'),
                child: const Text('Make Payment'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard();

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
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Maintain your borrowing privileges and unlock higher limits by keeping your community shares active.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ChecklistLine('Min. 3 months community membership'),
          const _ChecklistLine('Zero active defaults or overdue fees'),
          const _ChecklistLine('Minimum monthly savings streak of TZS 50,000'),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.primary, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _LoanAmountField extends StatelessWidget {
  const _LoanAmountField();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '50000',
      decoration: const InputDecoration(
        labelText: 'Loan Amount',
        prefixText: 'KES ',
        suffixText: 'KES 50,000',
      ),
      keyboardType: TextInputType.number,
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.surfaceContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PurposeChip extends StatelessWidget {
  const _PurposeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadii.base),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.base),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.onPrimary : AppColors.onSurface,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermButton extends StatelessWidget {
  const _TermButton({
    required this.months,
    required this.selected,
    required this.onTap,
  });

  final int months;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              '$months\nMonths',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanEstimateCard extends StatelessWidget {
  const _LoanEstimateCard();

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimated Monthly\nPayment',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                'KES\n9,250',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: _EstimateMini(
                  label: 'Interest\nRate',
                  value: '1.5% / mo',
                ),
              ),
              Expanded(
                child: _EstimateMini(
                  label: 'Processing\nFee',
                  value: 'KES 1,000',
                ),
              ),
              Expanded(
                child: _EstimateMini(
                  label: 'Total\nPayable',
                  value: 'KES 55,500',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstimateMini extends StatelessWidget {
  const _EstimateMini({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _GuarantorCard extends StatelessWidget {
  const _GuarantorCard();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Guarantors',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Choose at least 2 community members to back your loan',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const StatusPill(label: '0/2\nSelected'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _GuarantorTile(initials: 'AM', name: 'Amina Mwangi'),
          const SizedBox(height: AppSpacing.xs),
          const _GuarantorTile(initials: 'JO', name: 'John Ochieng'),
          const SizedBox(height: AppSpacing.xs),
          const _GuarantorTile(initials: 'SK', name: 'Sarah Koech'),
        ],
      ),
    );
  }
}

class _GuarantorTile extends StatelessWidget {
  const _GuarantorTile({required this.initials, required this.name});

  final String initials;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: initials),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Trust Score: 98% | Active Saver',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Checkbox(value: false, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _RepaymentHeroCard extends StatelessWidget {
  const _RepaymentHeroCard();

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
          Row(
            children: [
              const StatusPill(label: 'ACTIVE LOAN #VK-8849'),
              const Spacer(),
              const CircleAvatar(
                backgroundColor: AppColors.surfaceTint,
                child: Icon(
                  Icons.verified_outlined,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Business Growth Fund',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(color: AppColors.surfaceTint),
          Row(
            children: [
              Expanded(
                child: _HeroAmount(
                  label: 'Remaining Balance',
                  value: '\$500.00',
                ),
              ),
              Expanded(
                child: _HeroAmount(
                  label: 'Next Installment',
                  value: '\$125.00',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Due in 3 days (Oct 24, 2023)',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.primaryFixed),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: const LinearProgressIndicator(
              value: 0.25,
              minHeight: 8,
              color: AppColors.primaryFixed,
              backgroundColor: AppColors.surfaceTint,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAmount extends StatelessWidget {
  const _HeroAmount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.onPrimaryContainer),
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

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.onPrimary : AppColors.onSurface,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RepaymentHistoryCard extends StatelessWidget {
  const _RepaymentHistoryCard();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Repayment History',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _RepaymentTile(title: 'Installment #3', date: 'Sep 24, 2023'),
          _RepaymentTile(title: 'Installment #2', date: 'Aug 24, 2023'),
          _RepaymentTile(title: 'Installment #1', date: 'Jul 24, 2023'),
        ],
      ),
    );
  }
}

class _RepaymentTile extends StatelessWidget {
  const _RepaymentTile({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.secondaryContainer,
            child: Icon(Icons.arrow_downward, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$date | M-Pesa',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+\$125.00', style: TextStyle(fontWeight: FontWeight.w800)),
              StatusPill(label: 'Completed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = AppInsets.compactCard,
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
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}
