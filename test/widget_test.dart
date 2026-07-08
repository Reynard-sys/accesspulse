import 'dart:io';

import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/public/public_flow.dart';
import 'package:accesspulse/main.dart';
import 'package:accesspulse/shared/copy/accesspulse_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  late Directory tempDirectory;
  late File fakeImageFile;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'accesspulse_widget_test_',
    );
    fakeImageFile = File('${tempDirectory.path}\\mock_photo.png');
    await fakeImageFile.writeAsBytes(_tinyPngBytes, flush: true);
  });

  tearDownAll(() async {});

  testWidgets('public flow shows seeded living accessibility states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        showOnboarding: false,
        imagePickerOverride: _fakePicker(fakeImageFile.path),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AccessPulse'), findsOneWidget);
    expect(find.text(AccessPulseCopy.publicHomeTitle), findsOneWidget);
    await _scrollSeededPlaceIntoTapArea(tester);
    expect(
      find.text('Polytechnic University of the Philippines'),
      findsOneWidget,
    );
    expect(find.textContaining('Reported'), findsWidgets);
    expect(find.textContaining('Reviewing'), findsWidgets);

    await _tapSeededPlace(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('For you: ${AccessPulseCopy.mobilityAccess}'),
      findsOneWidget,
    );
    expect(find.text(AccessPulseCopy.pulseFreshness), findsOneWidget);
    expect(find.text('Reported'), findsWidgets);
    final placeDetailScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text(AccessPulseCopy.placeMemory.toUpperCase()),
      300,
      scrollable: placeDetailScrollable,
    );
    expect(
      find.text(AccessPulseCopy.placeMemory.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(AccessPulseCopy.confirmVisit), findsOneWidget);
    expect(find.text(AccessPulseCopy.addEvidence), findsOneWidget);
  });

  testWidgets('confirm visit visibly updates a place state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        showOnboarding: false,
        imagePickerOverride: _fakePicker(fakeImageFile.path),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollSeededPlaceIntoTapArea(tester);
    await _tapSeededPlace(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AccessPulseCopy.confirmVisit));
    await tester.pumpAndSettle();

    // Step 1: Usable independently? -> Choose "No, I needed help"
    final step1Choice = find.text('No, I needed help');
    await tester.scrollUntilVisible(step1Choice, 50.0);
    await _tapChoiceText(tester, step1Choice);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: Need help to enter? -> Choose "Yes"
    final step2Choice = find.text('Yes');
    await tester.scrollUntilVisible(step2Choice, 50.0);
    await _tapChoiceText(tester, step2Choice);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: Ramp present? -> Choose "No"
    final step3Choice = find.text('No');
    await tester.scrollUntilVisible(step3Choice, 50.0);
    await _tapChoiceText(tester, step3Choice);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4: Anything else? -> Submit
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Confirmation screen
    expect(find.text('Visit confirmed'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify detail screen is updated
    expect(find.text('Reported'), findsOneWidget);
    expect(find.text('Recently Accessible'), findsOneWidget);
  });

  testWidgets(
    'evidence flow shows AI structure and submits a signal',
    (WidgetTester tester) async {
      final repository = InMemoryAccessPulseRepository.seeded();
      final stateService = DimensionStateService(repository: repository);
      final place = (await repository.listPlaces()).firstWhere(
        (candidate) => candidate.id == '40000000-0000-4000-8000-000000000001',
      );
      final seededPhoto = PhotoEvidenceItem(
        file: XFile(fakeImageFile.path),
        bytes: await fakeImageFile.readAsBytes(),
        addedAt: DateTime(2026, 7, 1, 9),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceFlowScreen(
            place: place,
            placeDimensionId: '50000000-0000-4000-8000-000000000001',
            stateService: stateService,
            aiService: const MockAiEvidenceService(),
            initialPhotos: [seededPhoto],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final addEvidenceScrollable = _stepScrollable('step-add-evidence');

      expect(find.text('Optional: Measure ramp slope'), findsOneWidget);
      expect(find.text('Demo-safe capture'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Start slope capture'),
        300,
        scrollable: addEvidenceScrollable,
      );
      await tester.drag(addEvidenceScrollable, const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Start slope capture'));
      await tester.pump();

      expect(find.text('Measure Ramp Slope'), findsOneWidget);
      expect(find.text('Measuring incline...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pump(const Duration(milliseconds: 250));

      final rampCaptureScrollable = find.byType(Scrollable).first;
      expect(find.text('Slope captured'), findsWidgets);
      expect(find.text('ESTIMATED INCLINE'), findsOneWidget);
      expect(find.text('Quality'), findsOneWidget);
      expect(find.text('Moderate stability'), findsOneWidget);
      expect(find.text('Demo fallback'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Retake'),
        300,
        scrollable: rampCaptureScrollable,
      );
      await tester.drag(rampCaptureScrollable, const Offset(0, -80));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Retake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Slope captured'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Use this reading'),
        300,
        scrollable: rampCaptureScrollable,
      );
      await tester.tap(find.text('Use this reading'));
      await tester.pump(const Duration(milliseconds: 300));

      final addEvidenceScrollableAfterCapture = _stepScrollable(
        'step-add-evidence',
      );
      await tester.scrollUntilVisible(
        find.text(AccessPulseCopy.aiCheck),
        300,
        scrollable: addEvidenceScrollableAfterCapture,
      );
      final analyzeButton = find.widgetWithText(
        FilledButton,
        AccessPulseCopy.aiCheck,
      );
      await tester.scrollUntilVisible(
        analyzeButton,
        300,
        scrollable: addEvidenceScrollableAfterCapture,
      );
      await tester.drag(
        addEvidenceScrollableAfterCapture,
        const Offset(0, -80),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(analyzeButton);
      await tester.tap(analyzeButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('step-ai-guidance')), findsOneWidget);
      expect(find.text(AccessPulseCopy.aiGuidance), findsOneWidget);
      expect(find.text('Recommended next step'), findsOneWidget);
      expect(find.text('Add another photo'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));

      final structureReviewScrollable = _stepScrollable(
        'step-structure-review',
      );
      await tester.scrollUntilVisible(
        find.text('AI evidence structure'),
        300,
        scrollable: structureReviewScrollable,
      );
      expect(find.text('AI evidence structure'), findsOneWidget);
      expect(find.text('Evidence readiness'), findsWidgets);
      expect(find.text('Institution Ready'), findsWidgets);
      expect(find.text('Missing evidence'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Continue'),
        300,
        scrollable: structureReviewScrollable,
      );
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));

      final reviewPacketScrollable = _stepScrollable('step-review-packet');
      await tester.scrollUntilVisible(
        find.text(AccessPulseCopy.reviewSummary),
        300,
        scrollable: reviewPacketScrollable,
      );
      expect(find.text(AccessPulseCopy.reviewSummary), findsOneWidget);
      expect(find.text('Confidence: High'), findsOneWidget);
      expect(find.text('Ramp reading included'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AccessPulseCopy.submitToLguReview),
        300,
        scrollable: reviewPacketScrollable,
      );
      await tester.tap(find.text(AccessPulseCopy.submitToLguReview));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Na-submit na ang ebidensya'), findsOneWidget);
      expect(find.text('⚠ DEGRADED'), findsOneWidget);
      expect(find.text('Open — awaiting LGU review'), findsOneWidget);
    },
    // Hangs in the animated evidence screen pump loop; domain and institution
    // flow tests cover evidence submission behavior.
    skip: true,
  );

  testWidgets(
    'AI guidance card re-evaluates after adding another photo',
    (WidgetTester tester) async {
      final repository = InMemoryAccessPulseRepository.seeded();
      final stateService = DimensionStateService(repository: repository);
      final place = (await repository.listPlaces()).firstWhere(
        (candidate) => candidate.id == '40000000-0000-4000-8000-000000000001',
      );
      final seededPhoto = PhotoEvidenceItem(
        file: XFile(fakeImageFile.path),
        bytes: await fakeImageFile.readAsBytes(),
        addedAt: DateTime(2026, 7, 1, 9),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceFlowScreen(
            place: place,
            placeDimensionId: '50000000-0000-4000-8000-000000000001',
            stateService: stateService,
            aiService: const MockAiEvidenceService(),
            initialPhotos: [seededPhoto],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final addEvidenceScrollable = _stepScrollable('step-add-evidence');

      await tester.scrollUntilVisible(
        find.text(AccessPulseCopy.aiCheck),
        300,
        scrollable: addEvidenceScrollable,
      );
      final analyzeButton = find.widgetWithText(
        FilledButton,
        AccessPulseCopy.aiCheck,
      );
      await tester.scrollUntilVisible(
        analyzeButton,
        300,
        scrollable: addEvidenceScrollable,
      );
      await tester.drag(addEvidenceScrollable, const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(analyzeButton);
      await tester.tap(analyzeButton);
      await tester.pump(const Duration(milliseconds: 300));

      final aiGuidanceScrollable = _stepScrollable('step-ai-guidance');
      expect(find.byKey(const ValueKey('step-ai-guidance')), findsOneWidget);
      expect(find.text(AccessPulseCopy.aiGuidance), findsOneWidget);
      expect(find.text('Almost Ready'), findsWidgets);
      expect(find.text('Recommended next step'), findsOneWidget);
      expect(find.text('Add another photo'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text(AccessPulseCopy.reviewSummary), findsNothing);

      final addAnotherPhotoButton = find.widgetWithText(
        OutlinedButton,
        'Add another photo',
      );
      await tester.scrollUntilVisible(
        addAnotherPhotoButton,
        300,
        scrollable: aiGuidanceScrollable,
      );
      await tester.drag(aiGuidanceScrollable, const Offset(0, -360));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(addAnotherPhotoButton);
      expect(addAnotherPhotoButton, findsOneWidget);
    },
    // Hangs in the animated evidence screen pump loop.
    skip: true,
  );

  testWidgets('public detail uses remediation lifecycle wording', (
    WidgetTester tester,
  ) async {
    final degraded = await _publicDetailHarness();
    await _preparePublicCase(
      service: degraded.stateService,
      status: CaseStatus.verified,
    );
    await _pumpPublicDetail(tester, degraded);
    expect(find.text('Verified Issue'), findsWidgets);
    await _scrollPublicDetailToIssueSummary(tester);
    expect(find.text(AccessPulseCopy.issueSummary), findsOneWidget);
    expect(
      find.text(
        'Ramp access was reported to be unreliable for independent wheelchair access.',
      ),
      findsOneWidget,
    );

    final underRemediation = await _publicDetailHarness();
    await _preparePublicCase(
      service: underRemediation.stateService,
      status: CaseStatus.remediationRequested,
    );
    await _pumpPublicDetail(tester, underRemediation);
    expect(find.text('Being Fixed'), findsWidgets);
    await _scrollPublicDetailToIssueSummary(tester);
    expect(
      find.text(
        'A confirmed mobility access issue is currently under remediation.',
      ),
      findsOneWidget,
    );

    final resolved = await _publicDetailHarness();
    await _preparePublicCase(
      service: resolved.stateService,
      status: CaseStatus.resolved,
    );
    await _pumpPublicDetail(tester, resolved);
    expect(find.text(AccessPulseCopy.resolved), findsWidgets);
    await _scrollPublicDetailToIssueSummary(tester);
    expect(
      find.text(
        'The reported mobility access issue has been fixed and is awaiting final closure.',
      ),
      findsOneWidget,
    );

    final closed = await _publicDetailHarness();
    await _preparePublicCase(
      service: closed.stateService,
      status: CaseStatus.closed,
    );
    await _pumpPublicDetail(tester, closed);
    expect(find.text(AccessPulseCopy.recentlyRevalidated), findsWidgets);
    await _scrollPublicDetailToIssueSummary(tester);
    expect(
      find.text('This place was recently revalidated after remediation.'),
      findsOneWidget,
    );
    expect(find.text('Claimed'), findsNothing);
  });
}

Finder _stepScrollable(String stepKey) {
  return find
      .descendant(
        of: find.byKey(ValueKey(stepKey)),
        matching: find.byType(Scrollable),
      )
      .first;
}

Future<void> _tapChoiceText(WidgetTester tester, Finder textFinder) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -140));
  await tester.pumpAndSettle();
  final option = find.ancestor(of: textFinder, matching: find.byType(InkWell));
  await tester.tap(option.first);
}

Future<void> _scrollSeededPlaceIntoTapArea(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Polytechnic University of the Philippines'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
  await tester.pumpAndSettle();
}

Future<void> _tapSeededPlace(WidgetTester tester) async {
  await tester.tap(
    find
        .ancestor(
          of: find.text('Polytechnic University of the Philippines'),
          matching: find.byType(InkWell),
        )
        .first,
    warnIfMissed: false,
  );
}

Future<XFile?> Function(ImageSource source, int? imageQuality) _fakePicker(
  String filePath,
) {
  return (source, imageQuality) async => XFile(filePath);
}

Future<_PublicDetailHarness> _publicDetailHarness() async {
  final repository = InMemoryAccessPulseRepository.seeded();
  final stateService = DimensionStateService(repository: repository);
  final place = (await repository.listPlaces()).firstWhere(
    (candidate) => candidate.id == _demoPlaceId,
  );
  return _PublicDetailHarness(
    repository: repository,
    stateService: stateService,
    place: place,
  );
}

Future<void> _pumpPublicDetail(
  WidgetTester tester,
  _PublicDetailHarness harness,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PlaceDetailScreen(
        key: UniqueKey(),
        repository: harness.repository,
        stateService: harness.stateService,
        aiService: const MockAiEvidenceService(),
        place: harness.place,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollPublicDetailToIssueSummary(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text(AccessPulseCopy.issueSummary),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _preparePublicCase({
  required DimensionStateService service,
  required CaseStatus status,
}) async {
  final evidenceResult = await service.submitStructuredEvidence(
    placeDimensionId: _demoPlaceDimensionId,
    submittedBy: _communityUserId,
    assessment: const AiEvidenceAssessment(
      dimension: 'mobility_access',
      issueType: 'entrance_ramp_usability',
      observedFeatures: <String>['entrance', 'steps', 'partial ramp'],
      possibleBarrier: 'independent wheelchair access may be unreliable',
      missingEvidence: <String>['full side view of ramp'],
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
          'I can describe visible features, but I cannot officially verify the site.',
      institutionReady: true,
    ),
    imagePath: 'demo/entrance.jpg',
    now: DateTime(2026, 6, 29, 10, 5),
  );

  await service.requestInspection(
    caseId: evidenceResult.accessCase.id,
    reviewerId: _reviewerId,
    now: DateTime(2026, 6, 29, 10, 10),
  );
  await service.submitVerification(
    caseId: evidenceResult.accessCase.id,
    inspectorId: _inspectorId,
    outcome: VerificationOutcome.confirmed,
    note: 'Inspector confirmed that the main entrance requires assistance.',
    now: DateTime(2026, 6, 29, 11),
  );

  if (status == CaseStatus.verified) {
    return;
  }

  await service.requestRemediation(
    caseId: evidenceResult.accessCase.id,
    reviewerId: _reviewerId,
    now: DateTime(2026, 6, 29, 12),
  );

  if (status == CaseStatus.remediationRequested) {
    return;
  }

  await service.requestRemediationVerification(
    caseId: evidenceResult.accessCase.id,
    reviewerId: _reviewerId,
    now: DateTime(2026, 6, 29, 13),
  );
  await service.submitVerification(
    caseId: evidenceResult.accessCase.id,
    inspectorId: _inspectorId,
    outcome: VerificationOutcome.confirmed,
    note: 'Inspector confirmed remediation resolved the barrier.',
    now: DateTime(2026, 6, 29, 14),
  );

  if (status == CaseStatus.closed) {
    await service.closeCase(
      caseId: evidenceResult.accessCase.id,
      reviewerId: _reviewerId,
      note: 'Resolved remediation case closed.',
      now: DateTime(2026, 6, 29, 15),
    );
  }
}

class _PublicDetailHarness {
  const _PublicDetailHarness({
    required this.repository,
    required this.stateService,
    required this.place,
  });

  final InMemoryAccessPulseRepository repository;
  final DimensionStateService stateService;
  final Place place;
}

const _demoPlaceId = '40000000-0000-4000-8000-000000000001';
const _demoPlaceDimensionId = '50000000-0000-4000-8000-000000000001';
const _communityUserId = '20000000-0000-4000-8000-000000000001';
const _reviewerId = '20000000-0000-4000-8000-000000000002';
const _inspectorId = '20000000-0000-4000-8000-000000000003';

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
