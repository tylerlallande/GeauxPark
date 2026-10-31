import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/main.dart';

void main() {
  testWidgets('home screen presents organized parking discovery sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());

    expect(find.text('GeauxPark'), findsOneWidget);
    expect(find.text('Find your parking'), findsOneWidget);
    expect(find.text('Quick filters'), findsOneWidget);
    expect(find.text('Game-day parking'), findsOneWidget);
    expect(find.text('Parking near LSU'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Union Square Garage'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Union Square Garage'), findsOneWidget);
  });

  testWidgets('bottom navigation tabs are labeled and selectable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(find.text('Parking map'), findsOneWidget);
  });

  testWidgets('parking search filters the visible results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());

    await tester.enterText(find.byType(SearchBar), 'Nicholson');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Nicholson Gateway'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Nicholson Gateway'), findsOneWidget);
    expect(find.text('Union Square Garage'), findsNothing);
  });
}
