import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../core/loans/loans_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class LoanTasksScreen extends ConsumerStatefulWidget {
  const LoanTasksScreen({super.key});
  @override
  ConsumerState<LoanTasksScreen> createState() => _LoanTasksScreenState();
}

class _LoanTasksScreenState extends ConsumerState<LoanTasksScreen> {
  Future<List<LoanTask>>? _future;
  String? _groupId;
  bool _busy = false;
  String _error = '';

  Future<void> _refresh() async {
    final id = _groupId;
    if (id == null) return;
    final future = ref.read(loansRepositoryProvider).tasks(id);
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _decide(LoanTask task, bool approve) async {
    if (_busy || _groupId == null) return;
    final formatters = AppFormatters(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final amount = formatters.money(
      task.amountMinor,
      currency: task.currency,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          task.isGuarantee
              ? context.vt('Confirm guarantee response')
              : context.vt('Verify repayment'),
        ),
        content: Text(
          task.isGuarantee
              ? context.vtf(
                  'Respond to {name}\'s guarantee request for {amount}?',
                  {
                    'name': task.memberName,
                    'amount': amount,
                  },
                )
              : context.vtf('Confirm repayment from {name}.', {
                  'name': task.memberName,
                }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.vt('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.vt('Confirm')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await ref
          .read(loansRepositoryProvider)
          .decideTask(_groupId!, task, approve);
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _error = context.vt(AuthFailure.from(error).message));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    if (group != null && _groupId != group.id) {
      _groupId = group.id;
      _future = ref.read(loansRepositoryProvider).tasks(group.id);
    }
    return VikoplusScreen(
      title: 'Loan Requests',
      backRoute: '/loans',
      onRefresh: _refresh,
      child: FutureBuilder<List<LoanTask>>(
        future: _future,
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorMessage(message: _error),
            if (snapshot.hasError)
              AuthErrorMessage(
                message: context.vt(AuthFailure.from(snapshot.error!).message),
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.data?.isEmpty ?? true)
              Text(context.vt('No requests awaiting your response.')),
            for (final task in snapshot.data ?? <LoanTask>[]) ...[
              Builder(
                builder: (context) {
                  final formatters = AppFormatters(
                    Localizations.localeOf(context).toLanguageTag(),
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(task.memberName),
                    subtitle: Text(
                      '${context.vt(task.isGuarantee ? "Guarantee request" : "Repayment verification")} - ${formatters.money(task.amountMinor, currency: task.currency)}',
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _decide(task, false),
                      child: Text(context.vt('Decline')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _decide(task, true),
                      child: Text(
                        context.vt(task.isGuarantee ? 'Accept' : 'Received'),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
