import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/main.dart';
import 'package:integration_test/integration_test.dart';

Finder verticalScrollable() => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can discover a lot and open its details', (tester) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Live service unavailable — availability may be out of date'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(SearchBar), 'Union Square');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Union Square Garage'),
      250,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Union Square Garage'), findsOneWidget);

    await tester.tap(find.text('Union Square Garage'));
    await tester.pumpAndSettle();

    expect(find.text('Parking details'), findsOneWidget);
    expect(find.text('Union Square Garage'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Get directions'),
      300,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Get directions'), findsOneWidget);
  });
}
