import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/institution/institution_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placeDimensionId = '50000000-0000-4000-8000-000000000001';
  const communityUserId = '20000000-0000-4000-8000-000000000001';

  testWidgets('LGU reviewer requests inspection and inspector verifies case', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    await stateService.submitStructuredEvidence(
      placeDimensionId: placeDimensionId,
      submittedBy: communityUserId,
      assessment: const AiEvidenceAssessment(
        dimension: 'mobility_access',
        issueType: 'entrance_ramp_usability',
        observedFeatures: ['entrance', 'steps', 'partial ramp'],
        possibleBarrier: 'independent wheelchair access may be unreliable',
        missingEvidence: ['full side view of ramp'],
        confidence: 0.82,
        summary:
            'The visible entrance suggests mobility access may require assistance.',
        recommendedAction: 'lgu_review',
        explanation:
            'AI structured evidence for review but did not make an official judgment.',
      ),
      imagePath: 'demo/main-entrance.jpg',
      rampSlopeMeasurement: RampSlopeMeasurement(
        estimatedAngleDegrees: 14.8,
        qualityScore: 64,
        qualityLabel: 'Moderate stability',
        captureDurationMs: 3200,
        sampleCount: 48,
        status: RampMeasurementStatus.captured,
        capturedAt: DateTime(2026, 6, 30, 9),
        usedFallback: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: InstitutionDashboardScreen(
          repository: repository,
          stateService: stateService,
          role: InstitutionRole.lguReviewer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LGU dashboard'), findsOneWidget);
    expect(find.text('Quezon City Hall Main Entrance'), findsOneWidget);
    expect(find.textContaining('Degraded'), findsOneWidget);

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();

    expect(find.text('Evidence bundle'), findsOneWidget);
    expect(find.text('Ramp Measurement'), findsOneWidget);
    expect(find.text('Estimated angle'), findsOneWidget);
    expect(find.text('14.8 deg'), findsOneWidget);
    expect(find.text('Capture quality'), findsOneWidget);
    expect(find.text('Moderate stability'), findsOneWidget);
    expect(find.text('Citizen field capture'), findsOneWidget);
    expect(
      find.text(
        'Estimated reading provided to support review; official measurement may still be required.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Request inspection'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('case-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Request inspection'), findsOneWidget);

    await tester.tap(find.text('Request inspection'));
    await tester.pumpAndSettle();

    final underReviewState = await repository.getDimensionState(
      placeDimensionId,
    );
    final inspectionCase = (await repository.listCases()).single;
    expect(underReviewState.state, DimensionStateValue.underReview);
    expect(inspectionCase.status, CaseStatus.inspectionRequested);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: InstitutionDashboardScreen(
          repository: repository,
          stateService: stateService,
          role: InstitutionRole.inspector,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inspector verification'), findsOneWidget);
    expect(find.text('Quezon City Hall Main Entrance'), findsOneWidget);

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Open verification'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('case-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Human verification is authoritative. AI evidence remains supporting context.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Submit verification'));
    await tester.pumpAndSettle();

    expect(find.text('Human verification updated this place'), findsOneWidget);
    expect(find.text('Officially verified degraded'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);
  });
}
