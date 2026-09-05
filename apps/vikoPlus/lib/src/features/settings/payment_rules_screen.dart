import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/groups/groups_repository.dart';
import '../auth/auth_widgets.dart';
import '../common/vikoplus_screen.dart';

class ContributionPenaltiesScreen extends ConsumerStatefulWidget {
  const ContributionPenaltiesScreen({super.key});
  @override
  ConsumerState<ContributionPenaltiesScreen> createState() => _PaymentRulesState();
}

class _PaymentRulesState extends ConsumerState<ContributionPenaltiesScreen> {
  final _amount = TextEditingController();
  final _days = TextEditingController();
  bool _partial = true;
  bool _enabled = false;
  bool _busy = true;
  bool _loaded = false;
  String _error = '';

  @override
  void initState() { super.initState(); Future.microtask(_load); }
  @override
  void dispose() { _amount.dispose(); _days.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final id = ref.read(activeGroupProvider)?.id;
      if (id == null) return;
      final data = await ref.read(groupsRepositoryProvider).paymentRules(id);
      if (!mounted) return;
      setState(() {
        _partial = data['allowsPartial'] == true;
        _enabled = data['penaltiesEnabled'] == true;
        _amount.text = '${data['penaltyAmountMinor'] ?? 0}';
        _days.text = '${data['graceDays'] ?? 0}';
        _loaded = true;
      });
    } catch (error) { if (mounted) setState(() => _error = AuthFailure.from(error).message); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _save() async {
    final group = ref.read(activeGroupProvider);
    if (_busy || !_loaded || group?.role != 'GROUP_ADMIN') return;
    final amount = int.tryParse(_amount.text);
    final days = int.tryParse(_days.text);
    if (amount == null || amount < 0 || (_enabled && amount == 0) || days == null || days < 0 || days > 365) {
      setState(() => _error = 'Enter a valid amount and grace period (0–365 days).');
      return;
    }
    setState(() { _busy = true; _error = ''; });
    try {
      await ref.read(groupsRepositoryProvider).savePaymentRules(group!.id, allowsPartial: _partial, penaltiesEnabled: _enabled, penaltyAmountMinor: amount, graceDays: days);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment rules saved.')));
    } catch (error) { if (mounted) setState(() => _error = AuthFailure.from(error).message); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(activeGroupProvider)?.role == 'GROUP_ADMIN' && !_busy;
    return VikoplusScreen(title: 'Payment Rules', backRoute: '/settings/admin', onRefresh: _load, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Allow partial payments'), value: _partial, onChanged: canEdit ? (value) => setState(() => _partial = value) : null),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Enable late penalties'), subtitle: const Text('One charge per overdue contribution, after the grace period. Applies to future dues.'), value: _enabled, onChanged: canEdit ? (value) => setState(() => _enabled = value) : null),
      TextField(controller: _amount, enabled: canEdit, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Penalty amount', prefixIcon: Icon(Icons.payments_outlined))),
      const SizedBox(height: 16),
      TextField(controller: _days, enabled: canEdit, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Grace period (days)', prefixIcon: Icon(Icons.event_available))),
      const SizedBox(height: 16),
      AuthErrorMessage(message: _error),
      FilledButton(onPressed: canEdit && _loaded ? _save : null, child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Rules')),
    ]));
  }
}
