import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:convert';
import 'dart:typed_data';

import '../../core/auth/auth_controller.dart';
import '../../core/groups/group_setup_draft.dart';
import '../../core/groups/groups_repository.dart';
import '../../l10n/vikoplus_translations.dart';
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

class _HistoricalRecordsScreenState
    extends ConsumerState<HistoricalRecordsScreen> {
  final _amountController = TextEditingController(text: '5000');
  final _bulkCsvController = TextEditingController();
  final _referenceController = TextEditingController();
  late Future<GroupMembersResult>? _membersFuture;
  bool _bulkMode = false;
  String _contributionType = 'RECURRING';
  String _method = 'Cash';
  String? _selectedMemberId;
  DateTime _paidAt = DateUtils.dateOnly(DateTime.now());
  String _errorMessage = '';
  bool _isSubmitting = false;

  static const _methods = ['Cash', 'Mobile money', 'Bank transfer', 'Other'];
  static const _contributionTypes = [
    'RECURRING',
    'JOINING_FEE',
    'MEMBERSHIP_FEE',
  ];

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bulkCsvController.dispose();
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
    if (ref.read(activeGroupProvider)?.role == 'SECRETARY') {
      return '/secretary/dashboard';
    }
    final route = groupId == null || groupId.isEmpty
        ? '/groups/reminders'
        : '/groups/reminders?groupId=${Uri.encodeComponent(groupId)}';
    return _routeWithReturnTo(route);
  }

  Future<void> _refresh() async {
    final future = _loadMembers();
    setState(() {
      _membersFuture = future;
    });
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
      setState(
        () =>
            _errorMessage = context.vt('Create a group before importing records.'),
      );
      return;
    }
    final memberId = _selectedMemberId;
    final amount = _amountMinor();
    if (memberId == null || memberId.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Select a member for this payment.'),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      setState(
        () => _errorMessage = context.vt('Enter a valid payment amount.'),
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref
          .read(groupsRepositoryProvider)
          .importHistoricalPayment(
            groupId,
            HistoricalPaymentInput(
              memberId: memberId,
              amountMinor: amount,
              method: _apiMethod(),
              paidAt: _paidAt,
              reference: _referenceController.text,
              contributionType: _contributionType,
            ),
          );
      if (!mounted) return;
      context.go(_remindersRoute(groupId));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.vt(AuthFailure.from(error).message));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _continueToReminders() {
    context.go(_remindersRoute(_groupId));
  }

  Future<void> _shareCsvTemplate() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final members = await _loadTemplateMembers();
    final sampleMember = members.isEmpty ? null : members.first;
    final rows = [
      [
        'member_number',
        'full_name',
        'phone',
        'email',
        'contribution_type',
        'amount',
        'method',
        'paid_at',
        'reference',
      ],
      [
        sampleMember?.memberNumber ?? 'MBR-0001',
        sampleMember?.fullName ?? 'Amina Mwangi',
        sampleMember?.phone ?? '255712345678',
        sampleMember?.email ?? 'amina@example.com',
        'RECURRING',
        '5000',
        'CASH',
        DateUtils.dateOnly(DateTime.now()).toIso8601String().split('T').first,
        'OLD-LEDGER-001',
      ],
    ];
    final csv = rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode('\uFEFF$csv')),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: ['vikoplus-historical-payments-template.csv'],
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<List<GroupMemberSummary>> _loadTemplateMembers() async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return const [];
    final result = await ref.read(groupsRepositoryProvider).listMembers(groupId);
    return result.members;
  }

  Future<void> _importBulkPayments() async {
    final groupId = _groupId;
    if (_isSubmitting) return;
    if (groupId == null || groupId.isEmpty) {
      setState(
        () =>
            _errorMessage = context.vt('Create a group before importing records.'),
      );
      return;
    }
    final csv = _bulkCsvController.text.trim();
    if (csv.isEmpty) {
      setState(() => _errorMessage = context.vt('Paste CSV rows before importing.'));
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final members = (await ref
              .read(groupsRepositoryProvider)
              .listMembers(groupId))
          .members;
      final payments = _parseHistoricalCsv(csv, members);
      await ref.read(groupsRepositoryProvider).importHistoricalPayments(
            groupId,
            payments,
          );
      if (!mounted) return;
      context.go(_remindersRoute(groupId));
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is FormatException
          ? error.message
          : context.vt(AuthFailure.from(error).message);
      setState(() => _errorMessage = context.vt(message));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  List<HistoricalPaymentInput> _parseHistoricalCsv(
    String csv,
    List<GroupMemberSummary> members,
  ) {
    final rows = _parseCsvRows(csv);
    if (rows.length < 2) {
      throw const FormatException('CSV must include a header and at least one row.');
    }
    final headers = rows.first.map((item) => item.trim().toLowerCase()).toList();
    final memberNumberIndex = _headerIndex(headers, 'member_number');
    final memberIdIndex = _headerIndex(headers, 'member_id', required: false);
    final phoneIndex = _headerIndex(headers, 'phone', required: false);
    final emailIndex = _headerIndex(headers, 'email', required: false);
    final typeIndex = _headerIndex(headers, 'contribution_type');
    final amountIndex = _headerIndex(headers, 'amount');
    final methodIndex = _headerIndex(headers, 'method');
    final paidAtIndex = _headerIndex(headers, 'paid_at');
    final referenceIndex = _headerIndex(headers, 'reference', required: false);
    final byId = {for (final member in members) member.id: member};
    final byMemberNumber = {
      for (final member in members)
        if ((member.memberNumber ?? '').trim().isNotEmpty)
          member.memberNumber!.trim().toLowerCase(): member,
    };
    final byPhone = {
      for (final member in members)
        if ((member.phone ?? '').trim().isNotEmpty)
          member.phone!.trim().toLowerCase(): member,
    };
    final byEmail = {
      for (final member in members)
        if ((member.email ?? '').trim().isNotEmpty)
          member.email!.trim().toLowerCase(): member,
    };

    final payments = <HistoricalPaymentInput>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }
      final memberId = _cell(row, memberIdIndex, required: false);
      final memberNumber = _cell(row, memberNumberIndex)!;
      final phone = _cell(row, phoneIndex, required: false);
      final email = _cell(row, emailIndex, required: false);
      final member =
          (memberId == null ? null : byId[memberId]) ??
          byMemberNumber[memberNumber.toLowerCase()] ??
          (phone == null ? null : byPhone[phone.toLowerCase()]) ??
          (email == null ? null : byEmail[email.toLowerCase()]);
      if (member == null) {
        throw const FormatException('CSV row member was not found.');
      }
      final amountText = _cell(row, amountIndex)!.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = int.tryParse(amountText);
      if (amount == null || amount <= 0) {
        throw const FormatException('CSV row has an invalid amount.');
      }
      final contributionType = _normalizeContributionType(
        _cell(row, typeIndex)!,
      );
      final paidAt = DateTime.tryParse(_cell(row, paidAtIndex)!);
      if (paidAt == null) {
        throw const FormatException('CSV row has an invalid paid date.');
      }
      payments.add(
        HistoricalPaymentInput(
          memberId: member.id,
          amountMinor: amount,
          method: _normalizePaymentMethod(_cell(row, methodIndex)!),
          paidAt: DateUtils.dateOnly(paidAt),
          reference: _cell(row, referenceIndex, required: false),
          contributionType: contributionType,
        ),
      );
    }
    if (payments.isEmpty) {
      throw const FormatException('CSV has no importable rows.');
    }
    return payments;
  }

  int _headerIndex(
    List<String> headers,
    String name, {
    bool required = true,
  }) {
    final index = headers.indexOf(name);
    if (index < 0 && required) {
      throw const FormatException('CSV is missing a required column.');
    }
    return index;
  }

  String? _cell(List<String> row, int index, {bool required = true}) {
    final value = index < 0 || index >= row.length ? '' : row[index].trim();
    if (value.isEmpty && required) {
      throw const FormatException('CSV has an empty required field.');
    }
    return value.isEmpty ? null : value;
  }

  String _normalizeContributionType(String value) {
    final normalized = value.trim().toUpperCase().replaceAll(' ', '_');
    if (_contributionTypes.contains(normalized)) {
      return normalized;
    }
    throw const FormatException('CSV row has an invalid contribution type.');
  }

  String _normalizePaymentMethod(String value) {
    return switch (value.trim().toUpperCase().replaceAll(' ', '_')) {
      'MOBILE_MONEY' || 'MOBILE' || 'MPESA' || 'M-PESA' => 'MOBILE_MONEY',
      'BANK_TRANSFER' || 'BANK' => 'BANK_TRANSFER',
      'OTHER' => 'OTHER',
      _ => 'CASH',
    };
  }

  List<List<String>> _parseCsvRows(String source) {
    final normalized = source.replaceFirst('\uFEFF', '');
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      if (char == '"') {
        if (inQuotes && i + 1 < normalized.length && normalized[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < normalized.length && normalized[i + 1] == '\n') {
          i++;
        }
        row.add(cell.toString());
        cell.clear();
        rows.add(List<String>.from(row));
        row.clear();
      } else {
        cell.write(char);
      }
    }
    row.add(cell.toString());
    rows.add(row);
    return rows;
  }

  String _csvEscape(String value) {
    if (!value.contains(RegExp(r'[",\n\r]'))) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    return VikoplusScreen(
      title: context.vt('Historical Records'),
      backRoute: _backRoute,
      bottomNavigationIndex: activeGroup?.role == 'SECRETARY' ? 2 : null,
      preferBackRoute: true,
      onRefresh: _membersFuture == null ? null : _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HistoryHero(),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(context.vt('One by one')),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(context.vt('Bulk')),
              ),
            ],
            selected: {_bulkMode},
            onSelectionChanged: (value) {
              setState(() => _bulkMode = value.first);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_bulkMode)
            _BulkImportCard(
              controller: _bulkCsvController,
              onShareTemplate: _shareCsvTemplate,
            )
          else
            _MembersLoader(
              membersFuture: _membersFuture,
              selectedMemberId: _selectedMemberId,
              method: _method,
              methods: _methods,
              contributionType: _contributionType,
              contributionTypes: _contributionTypes,
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
              onContributionTypeChanged: (value) {
                if (value == null) return;
                setState(() => _contributionType = value);
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
                ? _importBulkPayments
                : _saveSinglePayment,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_bulkMode ? Icons.cloud_upload_outlined : Icons.save),
            label: Text(
              context.vt(
                _isSubmitting
                    ? 'Saving'
                    : _bulkMode
                    ? 'Import Records'
                    : 'Save Historical Payment',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _isSubmitting ? null : _continueToReminders,
            child: Text(context.vt('Skip Historical Records')),
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
                  context.vt('Bring old group records into vikoPlus'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.vt('For groups that started before using the app.'),
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
    required this.contributionType,
    required this.contributionTypes,
    required this.paidAtLabel,
    required this.amountController,
    required this.referenceController,
    required this.onMemberChanged,
    required this.onMethodChanged,
    required this.onContributionTypeChanged,
    required this.onPickPaidAt,
    required this.onError,
  });

  final Future<GroupMembersResult>? membersFuture;
  final String? selectedMemberId;
  final String method;
  final List<String> methods;
  final String contributionType;
  final List<String> contributionTypes;
  final String paidAtLabel;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final ValueChanged<String?> onMemberChanged;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String?> onContributionTypeChanged;
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
          return onError(context.vt(AuthFailure.from(snapshot.error!).message));
        }

        final members = snapshot.data?.members ?? const [];
        if (members.isEmpty) {
          return onError(
            'Add at least one group member before importing records.',
          );
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
          contributionType: contributionType,
          contributionTypes: contributionTypes,
          paidAtLabel: paidAtLabel,
          amountController: amountController,
          referenceController: referenceController,
          onMemberChanged: onMemberChanged,
          onMethodChanged: onMethodChanged,
          onContributionTypeChanged: onContributionTypeChanged,
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
    required this.contributionType,
    required this.contributionTypes,
    required this.paidAtLabel,
    required this.amountController,
    required this.referenceController,
    required this.onMemberChanged,
    required this.onMethodChanged,
    required this.onContributionTypeChanged,
    required this.onPickPaidAt,
  });

  final String? selectedMemberId;
  final List<GroupMemberSummary> members;
  final String method;
  final List<String> methods;
  final String contributionType;
  final List<String> contributionTypes;
  final String paidAtLabel;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final ValueChanged<String?> onMemberChanged;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String?> onContributionTypeChanged;
  final VoidCallback onPickPaidAt;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.vt('Single Payment')),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: selectedMemberId,
            decoration: InputDecoration(
              labelText: context.vt('Member'),
              prefixIcon: const Icon(Icons.person_outline),
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
          DropdownButtonFormField<String>(
            initialValue: contributionType,
            decoration: InputDecoration(
              labelText: context.vt('Contribution type'),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: contributionTypes
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(context.vt(item)),
                  ),
                )
                .toList(),
            onChanged: onContributionTypeChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.vt('Amount Paid'),
              hintText: '5000',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: InputDecoration(
              labelText: context.vt('Payment Method'),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            items: methods
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(context.vt(item)),
                  ),
                )
                .toList(),
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: paidAtLabel),
            onTap: onPickPaidAt,
            decoration: InputDecoration(
              labelText: context.vt('Paid date'),
              prefixIcon: const Icon(Icons.event_outlined),
              suffixIcon: const Icon(Icons.expand_more),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: referenceController,
            decoration: InputDecoration(
              labelText: context.vt('Reference'),
              hintText: context.vt('Receipt, book page, or old ledger note'),
              prefixIcon: const Icon(Icons.tag_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkImportCard extends StatelessWidget {
  const _BulkImportCard({
    required this.controller,
    required this.onShareTemplate,
  });

  final TextEditingController controller;
  final VoidCallback onShareTemplate;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.vt('Bulk Import')),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.vt(
              'Paste CSV rows prepared from the old ledger. Each row should include member number, contribution type, amount, method, paid date, and reference.',
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onShareTemplate,
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: Text(context.vt('Share CSV template')),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            minLines: 8,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: context.vt('CSV rows'),
              hintText:
                  'member_number,full_name,phone,email,contribution_type,amount,method,paid_at,reference\nMBR-0001,Amina Mwangi,255712345678,amina@example.com,RECURRING,5000,CASH,2026-09-09,OLD-LEDGER-001',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.content_paste_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ImportColumnMap(),
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
      children: [
        _ColumnChip(label: context.vt('Member number')),
        _ColumnChip(label: context.vt('Contribution type')),
        _ColumnChip(label: context.vt('Amount')),
        _ColumnChip(label: context.vt('Method')),
        _ColumnChip(label: context.vt('Paid date')),
        _ColumnChip(label: context.vt('Reference')),
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
            context.vt('Import rules'),
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
              context.vt(text),
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
