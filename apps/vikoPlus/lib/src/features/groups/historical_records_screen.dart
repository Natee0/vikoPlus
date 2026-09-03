import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class HistoricalRecordsScreen extends StatefulWidget {
  const HistoricalRecordsScreen({super.key});

  @override
  State<HistoricalRecordsScreen> createState() =>
      _HistoricalRecordsScreenState();
}

class _HistoricalRecordsScreenState extends State<HistoricalRecordsScreen> {
  bool _bulkMode = false;
  String _method = 'Cash';
  String _selectedMember = 'Amina Mwangi';
  DateTime _paidAt = DateTime(2020, 7, 5);

  static const _members = [
    'Amina Mwangi',
    'John Ochieng',
    'Sarah Koech',
    'Emmanuel Malekela',
  ];

  static const _methods = ['Cash', 'Mobile money', 'Bank transfer', 'Other'];

  String get _dateLabel {
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
    return '${_paidAt.day} ${months[_paidAt.month - 1]} ${_paidAt.year}';
  }

  Future<void> _pickPaidAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _paidAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Historical Records',
      backRoute: '/groups/contributions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HistoryHero(),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.edit_note_outlined),
                label: Text('One by one'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.upload_file_outlined),
                label: Text('Bulk'),
              ),
            ],
            selected: {_bulkMode},
            onSelectionChanged: (value) {
              setState(() => _bulkMode = value.first);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_bulkMode)
            const _BulkImportCard()
          else
            _SinglePaymentCard(
              selectedMember: _selectedMember,
              members: _members,
              method: _method,
              methods: _methods,
              paidAtLabel: _dateLabel,
              onMemberChanged: (value) {
                if (value == null) return;
                setState(() => _selectedMember = value);
              },
              onMethodChanged: (value) {
                if (value == null) return;
                setState(() => _method = value);
              },
              onPickPaidAt: _pickPaidAt,
            ),
          const SizedBox(height: AppSpacing.md),
          const _ImportRulesCard(),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/groups/reminders'),
            icon: Icon(_bulkMode ? Icons.cloud_upload_outlined : Icons.save),
            label: Text(
              _bulkMode ? 'Import Records' : 'Save Historical Payment',
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level2(),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(
              Icons.history_edu_outlined,
              color: AppColors.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bring old group records into vikoPlus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'For groups that started before using the app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinglePaymentCard extends StatelessWidget {
  const _SinglePaymentCard({
    required this.selectedMember,
    required this.members,
    required this.method,
    required this.methods,
    required this.paidAtLabel,
    required this.onMemberChanged,
    required this.onMethodChanged,
    required this.onPickPaidAt,
  });

  final String selectedMember;
  final List<String> members;
  final String method;
  final List<String> methods;
  final String paidAtLabel;
  final ValueChanged<String?> onMemberChanged;
  final ValueChanged<String?> onMethodChanged;
  final VoidCallback onPickPaidAt;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Single Payment'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: selectedMember,
            decoration: const InputDecoration(
              labelText: 'Member',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: members
                .map(
                  (member) =>
                      DropdownMenuItem(value: member, child: Text(member)),
                )
                .toList(),
            onChanged: onMemberChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount Paid',
              hintText: '5000',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: methods
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: paidAtLabel),
            onTap: onPickPaidAt,
            decoration: const InputDecoration(
              labelText: 'Paid Date',
              prefixIcon: Icon(Icons.event_outlined),
              suffixIcon: Icon(Icons.expand_more),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Reference',
              hintText: 'Receipt, book page, or old ledger note',
              prefixIcon: Icon(Icons.tag_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkImportCard extends StatelessWidget {
  const _BulkImportCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Bulk Import'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload a spreadsheet or CSV prepared from the old ledger. Each row should include member, amount, method, paid date, and reference.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_outlined, size: 18),
            label: const Text('Choose file'),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _FilePreviewTile(
            title: 'historical_payments_2015_2026.csv',
            subtitle: '248 rows ready to validate',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ImportColumnMap(),
        ],
      ),
    );
  }
}

class _FilePreviewTile extends StatelessWidget {
  const _FilePreviewTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const StatusPill(label: 'CSV'),
        ],
      ),
    );
  }
}

class _ImportColumnMap extends StatelessWidget {
  const _ImportColumnMap();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: const [
        _ColumnChip(label: 'Member'),
        _ColumnChip(label: 'Amount'),
        _ColumnChip(label: 'Method'),
        _ColumnChip(label: 'Paid date'),
        _ColumnChip(label: 'Reference'),
      ],
    );
  }
}

class _ColumnChip extends StatelessWidget {
  const _ColumnChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.check_circle, size: 16),
      label: Text(label),
      backgroundColor: AppColors.surfaceContainerLow,
      side: BorderSide.none,
    );
  }
}

class _ImportRulesCard extends StatelessWidget {
  const _ImportRulesCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import rules',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _RuleLine(text: 'Only group admin and secretary can import.'),
          const _RuleLine(
            text: 'Imported records are approved manual payments.',
          ),
          const _RuleLine(text: 'Payment dates must be inside group history.'),
          const _RuleLine(text: 'Receipts and audit logs are created.'),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: child,
    );
  }
}
