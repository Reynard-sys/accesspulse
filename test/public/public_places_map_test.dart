import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/public/public_flow.dart';
import 'package:accesspulse/shared/copy/accesspulse_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('public home shows map fallback and keeps list visible', (
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

    expect(find.text(AccessPulseCopy.mapUnavailable), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Polytechnic University of the Philippines'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsOneWidget,
    );
    expect(find.text(AccessPulseCopy.chooseFromMapOrList), findsWidgets);
  });
}
