import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class HistoricalRecordsScreen extends ConsumerStatefulWidget {
  const HistoricalRecordsScreen({this.groupId, this.returnTo, super.key});

  final String? groupId;
  final String? returnTo;

  @override
  ConsumerState<HistoricalRecordsScreen> createState() =>
      _HistoricalRecordsScreenState();
}

class _HistoricalRecordsScreenState extends ConsumerState<HistoricalRecordsScreen> {
  final _amountController = TextEditingController(text: '5000');
  final _referenceController = TextEditingController();
  late Future<GroupMembersResult>? _membersFuture;
  bool _bulkMode = false;
  String _method = 'Cash';
  String? _selectedMemberId;
  DateTime _paidAt = DateUtils.dateOnly(DateTime.now());
  String _errorMessage = '';
  bool _isSubmitting = false;

  static const _methods = ['Cash', 'Mobile money', 'Bank transfer', 'Other'];

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

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

  Future<GroupMembersResult>? _loadMembers() {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return null;
    return ref.read(groupsRepositoryProvider).listMembers(groupId);
  }

  String? get _groupId {
    final widgetGroupId = widget.groupId;
    if (widgetGroupId != null && widgetGroupId.isNotEmpty) {
      return widgetGroupId;
    }
    final draftGroupId = ref.read(groupSetupDraftProvider).createdGroupId;
    if (draftGroupId != null && draftGroupId.isNotEmpty) {
      return draftGroupId;
    }
    return ref.read(activeGroupProvider)?.id;
  }

  String _routeWithReturnTo(String route) {
    final returnTo = widget.returnTo;
    if (returnTo == null || returnTo.isEmpty) return route;
    final separator = route.contains('?') ? '&' : '?';
    return '$route${separator}returnTo=${Uri.encodeComponent(returnTo)}';
  }

  String get _backRoute {
    final returnTo = widget.returnTo;
    if (returnTo != null && returnTo.isNotEmpty) return returnTo;
    if (widget.groupId == null && ref.read(activeGroupProvider) != null) {
      return '/dashboard';
    }

    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return '/groups/contributions';
    return '/groups/contributions?groupId=${Uri.encodeComponent(groupId)}';
  }

  String _remindersRoute(String? groupId) {
    final route = groupId == null || groupId.isEmpty
        ? '/groups/reminders'
        : '/groups/reminders?groupId=${Uri.encodeComponent(groupId)}';
    return _routeWithReturnTo(route);
  }

  Future<void> _refresh() async {
    final future = _loadMembers();
    setState(() => _membersFuture = future);
    await future;
  }

  int? _amountMinor() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String _apiMethod() {
    return switch (_method) {
      'Mobile money' => 'MOBILE_MONEY',
      'Bank transfer' => 'BANK_TRANSFER',
      'Other' => 'OTHER',
      _ => 'CASH',
    };
  }

  Future<void> _saveSinglePayment() async {
    final groupId = _groupId;
    if (_isSubmitting) return;
    if (groupId == null || groupId.isEmpty) {
      setState(() => _errorMessage = 'Create a group before importing records.');
      return;
    }
    final memberId = _selectedMemberId;
    final amount = _amountMinor();
    if (memberId == null || memberId.isEmpty) {
      setState(() => _errorMessage = 'Select a member for this payment.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid payment amount.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref.read(groupsRepositoryProvider).importHistoricalPayment(
            groupId,
            HistoricalPaymentInput(
              memberId: memberId,
              amountMinor: amount,
              method: _apiMethod(),
              paidAt: _paidAt,
              reference: _referenceController.text,
            ),
          );
      if (!mounted) return;
      context.go(_remindersRoute(groupId));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _continueToReminders() {
    context.go(_remindersRoute(_groupId));
  }

  Future<void> _pickPaidAt() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(1970),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() => _paidAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Historical Records',
      backRoute: _backRoute,
      preferBackRoute: true,
      onRefresh: _membersFuture == null ? null : _refresh,
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
            _MembersLoader(
              membersFuture: _membersFuture,
              selectedMemberId: _selectedMemberId,
              method: _method,
              methods: _methods,
              paidAtLabel: _dateLabel,
              amountController: _amountController,
              referenceController: _referenceController,
              onMemberChanged: (value) {
                setState(() {
                  _selectedMemberId = value;
                  _errorMessage = '';
                });
              },
              onMethodChanged: (value) {
                if (value == null) return;
                setState(() => _method = value);
              },
              onPickPaidAt: _pickPaidAt,
              onError: (message) => AuthErrorMessage(message: message),
            ),
          const SizedBox(height: AppSpacing.md),
          const _ImportRulesCard(),
          const SizedBox(height: AppSpacing.md),
          AuthErrorMessage(message: _errorMessage),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : _bulkMode
                ? () {
                    setState(() {
                      _errorMessage =
                          'Bulk upload will be wired after file selection is enabled.';
                    });
                  }
                : _saveSinglePayment,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_bulkMode ? Icons.cloud_upload_outlined : Icons.save),
            label: Text(
              _isSubmitting
                  ? 'Saving'
                  : _bulkMode
                  ? 'Import Records'
                  : 'Save Historical Payment',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _isSubmitting ? null : _continueToReminders,
            child: const Text('Skip Historical Records'),
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

class _MembersLoader extends StatelessWidget {
  const _MembersLoader({
    required this.membersFuture,
    required this.selectedMemberId,
    required this.method,
    required this.methods,
    required this.paidAtLabel,
    required this.amountController,
    required this.referenceController,
    required this.onMemberChanged,
    required this.onMethodChanged,
    required this.onPickPaidAt,
    required this.onError,
  });

  final Future<GroupMembersResult>? membersFuture;
  final String? selectedMemberId;
  final String method;
  final List<String> methods;
  final String paidAtLabel;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final ValueChanged<String?> onMemberChanged;
  final ValueChanged<String?> onMethodChanged;
  final VoidCallback onPickPaidAt;
  final Widget Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    final future = membersFuture;
    if (future == null) {
      return onError('Create a group before importing historical records.');
    }

    return FutureBuilder<GroupMembersResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return onError(AuthFailure.from(snapshot.error!).message);
        }

        final members = snapshot.data?.members ?? const [];
        if (members.isEmpty) {
          return onError('Add at least one group member before importing records.');
        }

        final activeSelectedMemberId =
            members.any((member) => member.id == selectedMemberId)
            ? selectedMemberId
            : members.first.id;
        if (activeSelectedMemberId != selectedMemberId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onMemberChanged(activeSelectedMemberId);
          });
        }

        return _SinglePaymentCard(
          selectedMemberId: activeSelectedMemberId,
          members: members,
          method: method,
          methods: methods,
          paidAtLabel: paidAtLabel,
          amountController: amountController,
          referenceController: referenceController,
          onMemberChanged: onMemberChanged,
          onMethodChanged: onMethodChanged,
          onPickPaidAt: onPickPaidAt,
        );
      },
    );
  }
}

class _SinglePaymentCard extends StatelessWidget {
  const _SinglePaymentCard({
    required this.selectedMemberId,
    required this.members,
    required this.method,
    required this.methods,
    required this.paidAtLabel,
    required this.amountController,
    required this.referenceController,
    required this.onMemberChanged,
    required this.onMethodChanged,
    required this.onPickPaidAt,
  });

  final String? selectedMemberId;
  final List<GroupMemberSummary> members;
  final String method;
  final List<String> methods;
  final String paidAtLabel;
  final TextEditingController amountController;
  final TextEditingController referenceController;
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
            initialValue: selectedMemberId,
            decoration: const InputDecoration(
              labelText: 'Member',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: members
                .map(
                  (member) => DropdownMenuItem(
                    value: member.id,
                    child: Text(member.fullName),
                  ),
                )
                .toList(),
            onChanged: onMemberChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
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
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(
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
