import 'package:accesspulse/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('public flow shows seeded living accessibility states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('AccessPulse'), findsOneWidget);
    expect(find.text('Current accessibility state'), findsOneWidget);
    expect(find.text('Quezon City Hall Main Entrance'), findsOneWidget);
    expect(find.textContaining('Claimed accessible'), findsOneWidget);

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();

    expect(find.text('For you: Mobility Access'), findsOneWidget);
    expect(find.text('Place memory'), findsOneWidget);
    expect(find.text('I visited this place'), findsOneWidget);
    expect(find.text('Add evidence'), findsOneWidget);
  });

  testWidgets('confirm visit visibly updates a place state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I visited this place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update living state'));
    await tester.pumpAndSettle();

    expect(find.text('Your visit updated this place'), findsOneWidget);
    expect(find.text('Claimed accessible'), findsOneWidget);
    expect(find.text('Degraded'), findsOneWidget);
  });

  testWidgets('evidence flow shows AI structure and submits a signal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add evidence'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyze evidence'));
    await tester.pumpAndSettle();

    expect(find.text('AI evidence structure'), findsOneWidget);
    expect(find.text('Missing evidence'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Submit structured signal'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('evidence-flow-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Submit structured signal'));
    await tester.pumpAndSettle();

    expect(
      find.text('Evidence strengthened this place memory'),
      findsOneWidget,
    );
    expect(find.text('Degraded'), findsOneWidget);
  });
}
