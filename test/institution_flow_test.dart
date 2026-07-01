import 'dart:typed_data';

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
        confidenceLevel: ConfidenceLevel.high,
        confidenceExplanation:
            'The entrance evidence and contributor note strongly align.',
        evidenceReadiness: EvidenceReadiness.institutionReady,
        summary:
            'The visible entrance suggests mobility access may require assistance.',
        recommendedAction: 'lgu_review',
        nextBestAction: 'Submit for review.',
        explanation:
            'AI structured evidence for review but did not make an official judgment.',
        institutionReady: true,
      ),
      imagePath: 'demo/main-entrance.jpg',
      imageBytes: Uint8List.fromList(_tinyPngBytes),
      imageMimeType: 'image/png',
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
    expect(
      find.textContaining(
        'Priority: Public service building; Request inspection',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    final caseDetailScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('case-detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    expect(find.text('Why This Case Matters'), findsOneWidget);
    expect(find.text('Why this matters'), findsOneWidget);
    expect(find.text('Public service building'), findsOneWidget);
    expect(find.text('Public service entrance affected'), findsOneWidget);
    expect(find.text('Mobility access affected'), findsOneWidget);
    expect(find.text('Assistance may be required'), findsOneWidget);
    expect(find.text('Why now'), findsOneWidget);
    expect(find.text('Recent evidence updated place state'), findsOneWidget);
    expect(find.text('State just degraded'), findsOneWidget);
    expect(find.text('AI confidence: High'), findsOneWidget);
    expect(find.text('Suggested next action'), findsOneWidget);
    expect(find.text('Request inspection'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Evidence bundle'),
      300,
      scrollable: caseDetailScrollable,
    );
    expect(find.text('Evidence bundle'), findsOneWidget);
    expect(find.text('AI confidence'), findsOneWidget);
    expect(find.text('Evidence readiness'), findsOneWidget);
    expect(find.text('Institution Ready'), findsOneWidget);
    expect(find.text('Freshness / pulse'), findsOneWidget);
    expect(find.text('Under review'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Submitted photo reference'),
      300,
      scrollable: caseDetailScrollable,
    );
    expect(find.text('Submitted photo reference'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
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
    final requestInspectionButton = find.widgetWithText(
      FilledButton,
      'Request inspection',
    );
    await tester.scrollUntilVisible(
      requestInspectionButton,
      300,
      scrollable: caseDetailScrollable,
    );
    await tester.ensureVisible(requestInspectionButton);
    await tester.pumpAndSettle();
    expect(requestInspectionButton, findsOneWidget);

    await tester.tap(requestInspectionButton);
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
    expect(find.text('Submitted photo reference'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Submit verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Submit verification'));
    await tester.pumpAndSettle();

    expect(find.text('Human verification updated this place'), findsOneWidget);
    expect(find.text('Officially verified degraded'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);
  });

  testWidgets('triaging case remains visible to LGU but hidden from inspector', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    final result = await stateService.submitStructuredEvidence(
      placeDimensionId: placeDimensionId,
      submittedBy: communityUserId,
      assessment: const AiEvidenceAssessment(
        dimension: 'mobility_access',
        issueType: 'entrance_ramp_usability',
        observedFeatures: ['entrance', 'steps', 'partial ramp'],
        possibleBarrier: 'independent wheelchair access may be unreliable',
        missingEvidence: ['full side view of ramp'],
        confidence: 0.82,
        confidenceLevel: ConfidenceLevel.high,
        confidenceExplanation:
            'The entrance evidence and contributor note strongly align.',
        evidenceReadiness: EvidenceReadiness.institutionReady,
        summary:
            'The visible entrance suggests mobility access may require assistance.',
        recommendedAction: 'lgu_review',
        nextBestAction: 'Submit for review.',
        explanation:
            'AI structured evidence for review but did not make an official judgment.',
        institutionReady: true,
      ),
      imagePath: 'demo/main-entrance.jpg',
    );
    await stateService.triageCase(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
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
    expect(find.text('TRIAGING'), findsOneWidget);

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
    expect(find.text('Quezon City Hall Main Entrance'), findsNothing);
    expect(find.text('No actionable cases yet'), findsOneWidget);
  });

  testWidgets('LGU can request remediation on a verified case', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    final result = await stateService.submitStructuredEvidence(
      placeDimensionId: placeDimensionId,
      submittedBy: communityUserId,
      assessment: const AiEvidenceAssessment(
        dimension: 'mobility_access',
        issueType: 'entrance_ramp_usability',
        observedFeatures: ['entrance', 'steps', 'partial ramp'],
        possibleBarrier: 'independent wheelchair access may be unreliable',
        missingEvidence: ['full side view of ramp'],
        confidence: 0.82,
        confidenceLevel: ConfidenceLevel.high,
        confidenceExplanation:
            'The entrance evidence and contributor note strongly align.',
        evidenceReadiness: EvidenceReadiness.institutionReady,
        summary:
            'The visible entrance suggests mobility access may require assistance.',
        recommendedAction: 'lgu_review',
        nextBestAction: 'Submit for review.',
        explanation:
            'AI structured evidence for review but did not make an official judgment.',
        institutionReady: true,
      ),
      imagePath: 'demo/main-entrance.jpg',
    );
    await stateService.requestInspection(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.submitVerification(
      caseId: result.accessCase.id,
      inspectorId: '20000000-0000-4000-8000-000000000003',
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
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

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    final caseDetailScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('case-detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final requestRemediationButton = find.widgetWithText(
      FilledButton,
      'Request remediation',
    );
    await tester.scrollUntilVisible(
      requestRemediationButton,
      300,
      scrollable: caseDetailScrollable,
    );
    await tester.tap(requestRemediationButton);
    await tester.pumpAndSettle();

    final accessCase = (await repository.listCases()).single;
    final state = await repository.getDimensionState(placeDimensionId);

    expect(accessCase.status, CaseStatus.remediationRequested);
    expect(state.state, DimensionStateValue.officiallyVerifiedDegraded);
  });

  testWidgets('LGU can request remediation verification for inspector queue', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    final result = await stateService.submitStructuredEvidence(
      placeDimensionId: placeDimensionId,
      submittedBy: communityUserId,
      assessment: const AiEvidenceAssessment(
        dimension: 'mobility_access',
        issueType: 'entrance_ramp_usability',
        observedFeatures: ['entrance', 'steps', 'partial ramp'],
        possibleBarrier: 'independent wheelchair access may be unreliable',
        missingEvidence: ['full side view of ramp'],
        confidence: 0.82,
        confidenceLevel: ConfidenceLevel.high,
        confidenceExplanation:
            'The entrance evidence and contributor note strongly align.',
        evidenceReadiness: EvidenceReadiness.institutionReady,
        summary:
            'The visible entrance suggests mobility access may require assistance.',
        recommendedAction: 'lgu_review',
        nextBestAction: 'Submit for review.',
        explanation:
            'AI structured evidence for review but did not make an official judgment.',
        institutionReady: true,
      ),
      imagePath: 'demo/main-entrance.jpg',
    );
    await stateService.requestInspection(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.submitVerification(
      caseId: result.accessCase.id,
      inspectorId: '20000000-0000-4000-8000-000000000003',
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
    );
    await stateService.requestRemediation(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
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

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    final caseDetailScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('case-detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final requestVerificationButton = find.widgetWithText(
      FilledButton,
      'Request remediation verification',
    );
    await tester.scrollUntilVisible(
      requestVerificationButton,
      300,
      scrollable: caseDetailScrollable,
    );
    await tester.tap(requestVerificationButton);
    await tester.pumpAndSettle();

    final accessCase = (await repository.listCases()).single;
    expect(accessCase.status, CaseStatus.remediationVerificationRequested);

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
    expect(find.text('AWAITING REMEDIATION VERIFICATION'), findsOneWidget);
  });

  testWidgets('inspector can confirm remediation from verification queue', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    final result = await stateService.submitStructuredEvidence(
      placeDimensionId: placeDimensionId,
      submittedBy: communityUserId,
      assessment: const AiEvidenceAssessment(
        dimension: 'mobility_access',
        issueType: 'entrance_ramp_usability',
        observedFeatures: ['entrance', 'steps', 'partial ramp'],
        possibleBarrier: 'independent wheelchair access may be unreliable',
        missingEvidence: ['full side view of ramp'],
        confidence: 0.82,
        confidenceLevel: ConfidenceLevel.high,
        confidenceExplanation:
            'The entrance evidence and contributor note strongly align.',
        evidenceReadiness: EvidenceReadiness.institutionReady,
        summary:
            'The visible entrance suggests mobility access may require assistance.',
        recommendedAction: 'lgu_review',
        nextBestAction: 'Submit for review.',
        explanation:
            'AI structured evidence for review but did not make an official judgment.',
        institutionReady: true,
      ),
      imagePath: 'demo/main-entrance.jpg',
    );
    await stateService.requestInspection(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.submitVerification(
      caseId: result.accessCase.id,
      inspectorId: '20000000-0000-4000-8000-000000000003',
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
    );
    await stateService.requestRemediation(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.requestRemediationVerification(
      caseId: result.accessCase.id,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );

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

    expect(find.text('Remediation Verification'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Submit verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Submit verification'));
    await tester.pumpAndSettle();

    final accessCase = (await repository.listCases()).single;
    final state = await repository.getDimensionState(placeDimensionId);

    expect(accessCase.status, CaseStatus.resolved);
    expect(state.state, DimensionStateValue.resolved);
    expect(find.text('Resolved'), findsWidgets);
  });
}

const List<int> _tinyPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
