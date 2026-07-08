import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/public/add_place_flow.dart';
import 'package:accesspulse/features/public/public_flow.dart';
import 'package:accesspulse/shared/copy/accesspulse_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('add place form validates required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddPlaceFlowScreen(
          repository: InMemoryAccessPulseRepository.seeded(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AccessPulseCopy.chooseLocation), findsOneWidget);
    expect(find.text(AccessPulseCopy.mapUnavailable), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(AccessPulseCopy.saveAndOpenPlace),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AccessPulseCopy.saveAndOpenPlace));
    await tester.pump();

    expect(find.text('Ilagay ang pangalan ng lugar'), findsOneWidget);
    expect(find.text('Ilagay ang city o municipality'), findsOneWidget);
  });

  testWidgets('user can add a place and open its public detail', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);

    await tester.pumpWidget(
      MaterialApp(
        home: PublicHomeScreen(
          repository: repository,
          stateService: stateService,
          aiService: const MockAiEvidenceService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AccessPulseCopy.addPlace));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pangalan ng lugar'),
      'Marikina Public Library',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City o municipality'),
      'Marikina City',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address o landmark'),
      'Gil Fernando Avenue',
    );

    await tester.scrollUntilVisible(
      find.text(AccessPulseCopy.saveAndOpenPlace),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AccessPulseCopy.saveAndOpenPlace));
    await tester.pumpAndSettle();

    expect(find.text(AccessPulseCopy.addPlaceSuccess), findsOneWidget);
    expect(find.text('Marikina Public Library'), findsWidgets);
    expect(find.text('No Info'), findsWidgets);
    expect(find.text(AccessPulseCopy.confirmVisit), findsOneWidget);
    expect(find.text(AccessPulseCopy.addEvidence), findsOneWidget);

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Marikina Public Library'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Marikina Public Library'), findsOneWidget);
  });
}
