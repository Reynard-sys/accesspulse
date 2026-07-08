import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/institution/institution_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placeDimensionId = '50000000-0000-4000-8000-000000000001';
  const lrtPurezaPlaceDimensionId = '50000000-0000-4000-8000-000000000002';
  const seededPupCaseId = '83000000-0000-4000-8000-000000000001';
  const seededLrtPurezaCaseId = '83000000-0000-4000-8000-000000000002';

  testWidgets('LGU reviewer requests inspection and inspector verifies case', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);

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
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsOneWidget,
    );
    expect(find.text('LRT 2 Pureza'), findsOneWidget);
    expect(find.textContaining('Reported'), findsOneWidget);
    expect(find.textContaining('Request inspection'), findsWidgets);

    await tester.tap(find.text('Polytechnic University of the Philippines'));
    await tester.pumpAndSettle();
    final caseDetailScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('case-detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    expect(find.text('Why This Case Matters'), findsOneWidget);
    expect(find.text('Why this matters'), findsOneWidget);
    expect(find.text('Mobility access affected'), findsOneWidget);
    expect(find.text('Assistance may be required'), findsOneWidget);
    expect(find.text('Why now'), findsOneWidget);
    expect(find.text('Recent evidence updated place state'), findsOneWidget);
    expect(find.text('State just degraded'), findsOneWidget);
    expect(find.text('AI confidence: Moderate'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('Submitted photo reference'),
      300,
      scrollable: caseDetailScrollable,
    );
    expect(find.text('Submitted photo reference'), findsOneWidget);
    expect(
      find.text(
        'This case has an evidence record, but no uploaded photo preview is available.',
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
    final inspectionCase = await repository.getCase(seededPupCaseId);
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
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsOneWidget,
    );
    expect(find.text('LRT 2 Pureza'), findsOneWidget);

    await tester.tap(find.text('Polytechnic University of the Philippines'));
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
    expect(
      find.text(
        'This case has an evidence record, but no uploaded photo preview is available.',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Submit verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Submit verification'));
    await tester.pumpAndSettle();

    final verifiedCase = await repository.getCase(seededPupCaseId);
    expect(verifiedCase.status, CaseStatus.verified);
    expect(find.text('Inspector verification'), findsOneWidget);
    expect(
      find.text(
        'Verification submitted for Polytechnic University of the Philippines.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsOneWidget,
    );
    expect(find.text('Verified'), findsNothing);
  });

  testWidgets(
    'triaging case remains visible to LGU but hidden from inspector',
    (WidgetTester tester) async {
      final repository = InMemoryAccessPulseRepository.seeded();
      final stateService = DimensionStateService(repository: repository);

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
      expect(
        find.text('Polytechnic University of the Philippines'),
        findsOneWidget,
      );
      expect(find.text('ACKNOWLEDGED'), findsOneWidget);

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
      expect(
        find.text('Polytechnic University of the Philippines'),
        findsNothing,
      );
      expect(find.text('LRT 2 Pureza'), findsOneWidget);
    },
  );

  testWidgets('seeded LRT 2 Pureza case is ready for inspector verification', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);

    final seededCase = await repository.getCase(seededLrtPurezaCaseId);
    final memory = await repository.listMemoryEvents(lrtPurezaPlaceDimensionId);
    expect(seededCase.status, CaseStatus.inspectionRequested);
    expect(
      memory.any(
        (event) => event.eventType == MemoryEventType.inspectionRequested,
      ),
      isTrue,
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

    expect(find.text('Inspector verification'), findsOneWidget);
    expect(find.text('LRT 2 Pureza'), findsOneWidget);

    await tester.tap(find.text('LRT 2 Pureza'));
    await tester.pumpAndSettle();
    final caseDetailScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('case-detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Evidence bundle'),
      300,
      scrollable: caseDetailScrollable,
    );
    expect(find.text('Evidence bundle'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open verification'),
      300,
      scrollable: caseDetailScrollable,
    );
    expect(find.text('Open verification'), findsOneWidget);
  });

  testWidgets('LGU can request remediation on a verified case', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    await stateService.requestInspection(
      caseId: seededPupCaseId,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.submitVerification(
      caseId: seededPupCaseId,
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

    await tester.tap(find.text('Polytechnic University of the Philippines'));
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

    final accessCase = await repository.getCase(seededPupCaseId);
    final state = await repository.getDimensionState(placeDimensionId);

    expect(accessCase.status, CaseStatus.remediationRequested);
    expect(state.state, DimensionStateValue.officiallyVerifiedDegraded);
  });

  testWidgets('LGU can request remediation verification for inspector queue', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    await stateService.requestInspection(
      caseId: seededPupCaseId,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.submitVerification(
      caseId: seededPupCaseId,
      inspectorId: '20000000-0000-4000-8000-000000000003',
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
    );
    await stateService.requestRemediation(
      caseId: seededPupCaseId,
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

    await tester.tap(find.text('Polytechnic University of the Philippines'));
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

    final accessCase = await repository.getCase(seededPupCaseId);
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
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsOneWidget,
    );
    expect(find.text('CHECKING FIX'), findsOneWidget);
  });

  testWidgets('inspector can confirm remediation from verification queue', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    await stateService.requestInspection(
      caseId: seededPupCaseId,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.submitVerification(
      caseId: seededPupCaseId,
      inspectorId: '20000000-0000-4000-8000-000000000003',
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
    );
    await stateService.requestRemediation(
      caseId: seededPupCaseId,
      reviewerId: '20000000-0000-4000-8000-000000000002',
    );
    await stateService.requestRemediationVerification(
      caseId: seededPupCaseId,
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

    await tester.tap(find.text('Polytechnic University of the Philippines'));
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

    final accessCase = await repository.getCase(seededPupCaseId);
    final state = await repository.getDimensionState(placeDimensionId);

    expect(accessCase.status, CaseStatus.resolved);
    expect(state.state, DimensionStateValue.resolved);
    expect(find.text('Inspector verification'), findsOneWidget);
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsNothing,
    );
    expect(find.text('LRT 2 Pureza'), findsOneWidget);
  });
}
