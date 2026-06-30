import 'package:accesspulse/main.dart';
import 'package:flutter/material.dart';
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
    expect(find.textContaining('Reliable, aging'), findsOneWidget);

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();

    expect(find.text('For you: Mobility Access'), findsOneWidget);
    expect(find.text('Freshness / pulse'), findsOneWidget);
    expect(find.text('Reliable, aging'), findsWidgets);
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
    expect(find.text('Recently refreshed'), findsOneWidget);
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
    final evidenceScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('evidence-flow-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    expect(find.text('Optional: Measure ramp slope'), findsOneWidget);
    expect(find.text('Demo-safe capture'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start slope capture'),
      300,
      scrollable: evidenceScrollable,
    );
    await tester.drag(evidenceScrollable, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Start slope capture'));
    await tester.pump();

    expect(find.text('Capturing ramp slope'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Ramp slope captured'), findsOneWidget);
    expect(find.text('Estimated angle'), findsOneWidget);
    expect(find.text('14.8 deg'), findsOneWidget);
    expect(find.text('Quality'), findsOneWidget);
    expect(find.text('Moderate stability'), findsOneWidget);
    expect(find.text('Demo fallback'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Retry measurement'),
      300,
      scrollable: evidenceScrollable,
    );
    await tester.drag(evidenceScrollable, const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Retry measurement'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Ramp slope captured'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Analyze evidence'),
      300,
      scrollable: evidenceScrollable,
    );
    final analyzeButton = find.widgetWithText(FilledButton, 'Analyze evidence');
    await tester.scrollUntilVisible(
      analyzeButton,
      300,
      scrollable: evidenceScrollable,
    );
    await tester.drag(evidenceScrollable, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('AI Guidance'),
      300,
      scrollable: evidenceScrollable,
    );
    expect(find.text('AI Guidance'), findsOneWidget);
    expect(find.text('Recommended next step'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(find.text('Skip AI guidance'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('AI evidence structure'),
      300,
      scrollable: evidenceScrollable,
    );
    expect(find.text('AI evidence structure'), findsOneWidget);
    expect(find.text('Evidence readiness'), findsWidgets);
    expect(find.text('Institution Ready'), findsWidgets);
    expect(find.text('Missing evidence'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Review packet'),
      300,
      scrollable: evidenceScrollable,
    );
    expect(find.text('Review packet'), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
    expect(find.text('Ramp reading included'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Submit review packet'),
      300,
      scrollable: evidenceScrollable,
    );
    await tester.tap(find.text('Submit review packet'));
    await tester.pumpAndSettle();

    expect(
      find.text('Evidence strengthened this place memory'),
      findsOneWidget,
    );
    expect(find.text('Degraded'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
  });

  testWidgets('AI guidance card re-evaluates after adding another photo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add evidence'));
    await tester.pumpAndSettle();
    final evidenceScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('evidence-flow-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.text('Analyze evidence'),
      300,
      scrollable: evidenceScrollable,
    );
    final analyzeButton = find.widgetWithText(FilledButton, 'Analyze evidence');
    await tester.scrollUntilVisible(
      analyzeButton,
      300,
      scrollable: evidenceScrollable,
    );
    await tester.drag(evidenceScrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('AI Guidance'),
      300,
      scrollable: evidenceScrollable,
    );
    expect(find.text('AI Guidance'), findsOneWidget);
    expect(find.text('Almost Ready'), findsWidgets);
    expect(find.text('Recommended next step'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(find.text('Skip AI guidance'), findsOneWidget);
    expect(find.text('Review packet'), findsNothing);

    final addAnotherPhotoButton = find.widgetWithText(
      OutlinedButton,
      'Add another photo',
    );
    await tester.scrollUntilVisible(
      addAnotherPhotoButton,
      300,
      scrollable: evidenceScrollable,
    );
    await tester.drag(evidenceScrollable, const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.ensureVisible(addAnotherPhotoButton);
    await tester.tap(addAnotherPhotoButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Institution Ready').first,
      300,
      scrollable: evidenceScrollable,
    );
    expect(find.text('uploaded photo'), findsWidgets);
    expect(find.text('Institution Ready'), findsWidgets);
    expect(find.text('Submit for review.'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Review packet'),
      300,
      scrollable: evidenceScrollable,
    );
    expect(find.text('Review packet'), findsOneWidget);
  });
}
