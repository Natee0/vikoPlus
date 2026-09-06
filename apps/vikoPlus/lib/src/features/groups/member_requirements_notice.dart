import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/groups/groups_repository.dart';
import '../../theme/app_design_tokens.dart';

final memberRequirementsProvider = FutureProvider.autoDispose
    .family<(ContributionRegisterResult, Map<String, dynamic>), String>((
      ref,
      groupId,
    ) async {
      final repository = ref.watch(groupsRepositoryProvider);
      final register = await repository.contributionRegister(groupId);
      final rules = await repository.paymentRules(groupId);
      return (register, rules);
    });

/// Uses the member-scoped register: pending requests do not count as paid.
class MemberRequirementsNotice extends ConsumerWidget {
  const MemberRequirementsNotice({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Localizations.localeOf(context).languageCode == 'sw';
    final data = ref.watch(memberRequirementsProvider(groupId));
    return data.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => TextButton.icon(
        onPressed: () => ref.invalidate(memberRequirementsProvider(groupId)),
        icon: const Icon(Icons.refresh),
        label: Text(
          sw
              ? 'Masharti hayajapakiwa. Jaribu tena.'
              : 'Could not load requirements. Retry.',
        ),
      ),
      data: (result) {
        final joining = result.$1.obligations.where(
          (item) => item.planType == 'JOINING_FEE' && item.outstandingMinor > 0,
        );
        final rules = result.$2;
        final formatter = AppFormatters(
          Localizations.localeOf(context).toLanguageTag(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sw ? 'Masharti ya malipo' : 'Payment requirements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final fee in joining)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  '${sw ? 'Ada ya kujiunga inayodaiwa' : 'Joining fee outstanding'}: ${formatter.money(fee.outstandingMinor, currency: fee.currency)}',
                ),
              ),
            Text(
              sw
                  ? 'Lipa kwa kiongozi wa kikundi, kisha wasilisha taarifa ya malipo. Salio litabadilika baada ya mweka hazina kuthibitisha kupokea pesa.'
                  : 'Pay your group leader, then submit your payment details. Your balance changes only after the treasurer confirms receipt.',
            ),
            Text(
              rules['allowsPartial'] == false
                  ? (sw
                        ? 'Malipo ya sehemu hayaruhusiwi; lipa kiasi kamili kinachodaiwa.'
                        : 'Partial payments are not allowed; pay the full amount due.')
                  : (sw
                        ? 'Malipo ya sehemu yanaruhusiwa.'
                        : 'Partial payments are allowed.'),
            ),
            if (rules['penaltiesEnabled'] == true)
              Text(
                sw
                    ? 'Faini za kuchelewa zinatumika baada ya siku ${rules['graceDays']} za nyongeza.'
                    : 'Late-payment penalties apply after ${rules['graceDays']} grace days.',
              ),
            TextButton.icon(
              onPressed: () => context.go('/member/payments/select'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(
                sw
                    ? 'Angalia ada na michango / Wasilisha malipo'
                    : 'View fees and contributions / Submit payment',
              ),
            ),
          ],
        );
      },
    );
  }
}
