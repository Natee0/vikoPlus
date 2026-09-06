import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vikoplus/src/core/auth/auth_session.dart';
import 'package:vikoplus/src/core/groups/groups_repository.dart';
import 'package:vikoplus/src/features/groups/member_requirements_notice.dart';

void main() {
  test('missing locale defaults to Swahili; explicit English is preserved', () {
    expect(AuthUser.fromJson({'id': 'user'}).preferredLocale, 'sw');
    expect(
      AuthUser.fromJson({'id': 'user', 'preferredLocale': 'en'})
          .preferredLocale,
      'en',
    );
  });

  testWidgets('unpaid joining fee and full-payment rule are visible', (
    tester,
  ) async {
    final register = ContributionRegisterResult.fromJson({
      'groupId': 'group',
      'obligations': [
        {
          'id': 'fee',
          'amountDueMinor': 10000,
          'amountPaidMinor': 2000,
          'plan': {'type': 'JOINING_FEE'},
          'currency': 'TZS',
        },
      ],
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberRequirementsProvider('group').overrideWith(
            (ref) async =>
                (register, <String, dynamic>{'allowsPartial': false}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MemberRequirementsNotice(groupId: 'group')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Joining fee outstanding: TZS 8,000'), findsOneWidget);
    expect(
      find.textContaining('Partial payments are not allowed'),
      findsOneWidget,
    );
    expect(find.textContaining('treasurer confirms receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
