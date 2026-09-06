import 'package:dio/dio.dart';
import 'package:vikoplus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vikoplus/src/core/groups/groups_repository.dart';
import 'package:vikoplus/src/features/reports/report_filters_screen.dart';

class _Repository extends GroupsRepository {
  _Repository() : super(Dio());

  @override
  Future<GroupFinancialYearsResult> financialYears(String groupId) async =>
      GroupFinancialYearsResult(
        groupId: groupId,
        financialYears: [
          GroupFinancialYearSummary(
            id: 'year',
            name: 'September 2026 - September 2027 Financial Year',
            startsAt: DateTime(2026, 9, 2),
            endsAt: DateTime(2027, 9, 2),
            isActive: true,
          ),
        ],
      );
}

void main() {
  for (final width in [320.0, 360.0, 420.0]) {
    testWidgets('report filters fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [groupsRepositoryProvider.overrideWithValue(_Repository())],
      );
      addTearDown(container.dispose);
      container
          .read(activeGroupProvider.notifier)
          .setGroup(
            const GroupAccessSummary(
              id: 'group',
              name: 'Group',
              role: 'TREASURER',
              status: 'ACTIVE',
              membersCount: 2,
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('sw'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const ReportFiltersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
