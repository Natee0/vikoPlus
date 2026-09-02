import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vikoplus/src/app.dart';

void main() {
  testWidgets('renders Vikoplus localized shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VikoplusApp()));
    await tester.pump();

    expect(find.text('Vikoplus'), findsOneWidget);
    expect(find.text('Group contributions, made clear.'), findsOneWidget);
  });
}
