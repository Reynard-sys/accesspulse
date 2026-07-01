import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const stalePlaceDimensionId = '50000000-0000-4000-8000-000000000001';
  const communityUserId = '20000000-0000-4000-8000-000000000001';
  const reviewerId = '20000000-0000-4000-8000-000000000002';
  const inspectorId = '20000000-0000-4000-8000-000000000003';

  test(
    'seeded repository preserves place dimension state, pulse, and memory',
    () async {
      final repository = InMemoryAccessPulseRepository.seeded();

      final places = await repository.listPlaces();
      final state = await repository.getDimensionState(stalePlaceDimensionId);
      final pulse = await repository.getDimensionPulse(stalePlaceDimensionId);
      final memory = await repository.listMemoryEvents(stalePlaceDimensionId);

      expect(places, hasLength(3));
      expect(state.state, DimensionStateValue.claimedAccessible);
      expect(pulse.level, DimensionPulseLevel.moderate);
      expect(memory.single.eventType, MemoryEventType.stateSeeded);
    },
  );

  test(
    'positive visit can move claimed accessible state to reliable',
    () async {
      final repository = InMemoryAccessPulseRepository.seeded();
      final service = DimensionStateService(
        repository: repository,
        idFactory: _deterministicIds(),
      );

      final result = await service.confirmVisit(
        placeDimensionId: stalePlaceDimensionId,
        submittedBy: communityUserId,
        entranceUsableIndependently: true,
        rampUsable: true,
        neededAssistance: false,
        completedPurpose: true,
        note: 'Entrance and ramp were usable independently today.',
        now: DateTime(2026, 6, 29, 10),
      );

      final memory = await repository.listMemoryEvents(stalePlaceDimensionId);

      expect(result.previousState.state, DimensionStateValue.claimedAccessible);
      expect(result.currentState.state, DimensionStateValue.reliable);
      expect(result.currentPulse.supportingObservationsCount, 2);
      expect(
        memory.any((event) => event.eventType == MemoryEventType.stateChanged),
        isTrue,
      );
    },
  );

  test('failed visit degrades the living accessibility state', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = DimensionStateService(
      repository: repository,
      idFactory: _deterministicIds(),
    );

    final result = await service.confirmVisit(
      placeDimensionId: stalePlaceDimensionId,
      submittedBy: communityUserId,
      entranceUsableIndependently: false,
      rampUsable: false,
      neededAssistance: true,
      completedPurpose: false,
      note: 'Steps blocked the main entrance and assistance was needed.',
      now: DateTime(2026, 6, 29, 10),
    );

    final savedState = await repository.getDimensionState(
      stalePlaceDimensionId,
    );
    final memory = await repository.listMemoryEvents(stalePlaceDimensionId);

    expect(result.observation.outcome, ObservationOutcome.negative);
    expect(savedState.state, DimensionStateValue.degraded);
    expect(savedState.source, 'community_visit_confirmation');
    expect(
      memory.any(
        (event) =>
            event.eventType == MemoryEventType.stateChanged &&
            event.summary.contains('fresh visit challenged'),
      ),
      isTrue,
    );
  });

  test(
    'AI structured evidence opens an LGU review case without official verification',
    () async {
      final repository = InMemoryAccessPulseRepository.seeded();
      final service = DimensionStateService(
        repository: repository,
        idFactory: _deterministicIds(),
      );
      const aiService = MockAiEvidenceService();
      final assessment = await aiService.analyzeMobilityEvidence(
        note: 'The entrance has steps and the ramp required assistance.',
        imagePath: 'demo/entrance.jpg',
      );

      final result = await service.submitStructuredEvidence(
        placeDimensionId: stalePlaceDimensionId,
        submittedBy: communityUserId,
        assessment: assessment,
        imagePath: 'demo/entrance.jpg',
        note: 'Photo of the main entrance.',
        rampSlopeMeasurement: RampSlopeMeasurement(
          estimatedAngleDegrees: 14.8,
          qualityScore: 64,
          qualityLabel: 'Moderate stability',
          captureDurationMs: 3200,
          sampleCount: 48,
          status: RampMeasurementStatus.captured,
          capturedAt: DateTime(2026, 6, 29, 10, 4),
          usedFallback: false,
        ),
        now: DateTime(2026, 6, 29, 10, 5),
      );

      final cases = await repository.listCases(status: CaseStatus.open);
      final memory = await repository.listMemoryEvents(stalePlaceDimensionId);
      final savedMeasurement = await repository.getRampMeasurementForEvidence(
        result.evidence.id,
      );

      expect(result.currentState.state, DimensionStateValue.degraded);
      expect(result.signal.recommendedAction, 'lgu_review');
      expect(result.rampMeasurement, isNotNull);
      expect(result.rampMeasurement!.estimatedAngleDegrees, 14.8);
      expect(result.evidence.metadata['rampMeasurementId'], isNotNull);
      expect(result.evidence.metadata['estimatedRampAngleDegrees'], 14.8);
      expect(result.evidence.metadata['confidenceLevel'], 'high');
      expect(result.evidence.metadata['evidenceReadiness'], 'institutionReady');
      expect(result.evidence.metadata['institutionReady'], isTrue);
      expect(result.evidence.metadata['nextBestAction'], 'Submit for review.');
      expect(result.signal.aiExplanation['confidenceLevel'], 'high');
      expect(
        result.signal.aiExplanation['evidenceReadiness'],
        'institutionReady',
      );
      expect(
        result.signal.aiExplanation['nextBestAction'],
        'Submit for review.',
      );
      expect(savedMeasurement?.id, result.rampMeasurement!.id);
      expect(savedMeasurement?.evidenceId, result.evidence.id);
      expect(savedMeasurement?.status, RampMeasurementStatus.captured);
      expect(cases.single.placeDimensionId, stalePlaceDimensionId);
      expect(
        memory.any(
          (event) => event.eventType == MemoryEventType.aiSignalCreated,
        ),
        isTrue,
      );
      expect(
        result.currentState.state,
        isNot(DimensionStateValue.officiallyVerifiedDegraded),
      );
    },
  );

  test('only inspector verification makes degraded state official', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = DimensionStateService(
      repository: repository,
      idFactory: _deterministicIds(),
    );
    final evidenceResult = await service.submitStructuredEvidence(
      placeDimensionId: stalePlaceDimensionId,
      submittedBy: communityUserId,
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
      reviewerId: reviewerId,
      now: DateTime(2026, 6, 29, 10, 10),
    );
    final underReviewState = await repository.getDimensionState(
      stalePlaceDimensionId,
    );

    final verificationResult = await service.submitVerification(
      caseId: evidenceResult.accessCase.id,
      inspectorId: inspectorId,
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
      now: DateTime(2026, 6, 29, 11),
    );

    final memory = await repository.listMemoryEvents(stalePlaceDimensionId);

    expect(underReviewState.state, DimensionStateValue.underReview);
    expect(
      verificationResult.currentState.state,
      DimensionStateValue.officiallyVerifiedDegraded,
    );
    expect(verificationResult.accessCase.status, CaseStatus.verified);
    expect(verificationResult.currentPulse.hasRecentVerification, isTrue);
    expect(
      memory.any(
        (event) => event.eventType == MemoryEventType.verificationSubmitted,
      ),
      isTrue,
    );
  });

  test('LGU can request remediation after inspector confirms barrier', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = DimensionStateService(
      repository: repository,
      idFactory: _deterministicIds(),
    );
    final evidenceResult = await service.submitStructuredEvidence(
      placeDimensionId: stalePlaceDimensionId,
      submittedBy: communityUserId,
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
      reviewerId: reviewerId,
      now: DateTime(2026, 6, 29, 10, 10),
    );
    await service.submitVerification(
      caseId: evidenceResult.accessCase.id,
      inspectorId: inspectorId,
      outcome: VerificationOutcome.confirmed,
      note: 'Inspector confirmed that the main entrance requires assistance.',
      now: DateTime(2026, 6, 29, 11),
    );

    final remediationCase = await service.requestRemediation(
      caseId: evidenceResult.accessCase.id,
      reviewerId: reviewerId,
      now: DateTime(2026, 6, 29, 12),
    );
    final state = await repository.getDimensionState(stalePlaceDimensionId);
    final memory = await repository.listMemoryEvents(stalePlaceDimensionId);

    expect(remediationCase.status, CaseStatus.remediationRequested);
    expect(state.state, DimensionStateValue.officiallyVerifiedDegraded);
    expect(
      memory.any(
        (event) =>
            event.eventType == MemoryEventType.remediationRequested &&
            event.summary.contains('requested remediation'),
      ),
      isTrue,
    );
  });

  test(
    'LGU can request remediation verification after remediation request',
    () async {
      final repository = InMemoryAccessPulseRepository.seeded();
      final service = DimensionStateService(
        repository: repository,
        idFactory: _deterministicIds(),
      );
      final evidenceResult = await service.submitStructuredEvidence(
        placeDimensionId: stalePlaceDimensionId,
        submittedBy: communityUserId,
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
        reviewerId: reviewerId,
        now: DateTime(2026, 6, 29, 10, 10),
      );
      await service.submitVerification(
        caseId: evidenceResult.accessCase.id,
        inspectorId: inspectorId,
        outcome: VerificationOutcome.confirmed,
        note: 'Inspector confirmed that the main entrance requires assistance.',
        now: DateTime(2026, 6, 29, 11),
      );
      await service.requestRemediation(
        caseId: evidenceResult.accessCase.id,
        reviewerId: reviewerId,
        now: DateTime(2026, 6, 29, 12),
      );

      final verificationRequest = await service.requestRemediationVerification(
        caseId: evidenceResult.accessCase.id,
        reviewerId: reviewerId,
        now: DateTime(2026, 6, 29, 13),
      );
      final state = await repository.getDimensionState(stalePlaceDimensionId);
      final memory = await repository.listMemoryEvents(stalePlaceDimensionId);

      expect(
        verificationRequest.status,
        CaseStatus.remediationVerificationRequested,
      );
      expect(state.state, DimensionStateValue.officiallyVerifiedDegraded);
      expect(
        memory.any(
          (event) =>
              event.eventType ==
                  MemoryEventType.remediationVerificationRequested &&
              event.summary.contains('requested inspector verification'),
        ),
        isTrue,
      );
    },
  );
}

IdFactory _deterministicIds() {
  var next = 0;
  return (prefix) {
    next += 1;
    return '${prefix}_$next';
  };
}
