import '../models/accesspulse_models.dart';
import '../repositories/accesspulse_repository.dart';
import 'pulse_service.dart';
import 'ramp_slope_capture_service.dart';

typedef IdFactory = String Function(String prefix);

class VisitUpdateResult {
  const VisitUpdateResult({
    required this.observation,
    required this.previousState,
    required this.currentState,
    required this.previousPulse,
    required this.currentPulse,
  });

  final Observation observation;
  final DimensionStateRecord previousState;
  final DimensionStateRecord currentState;
  final DimensionPulseRecord previousPulse;
  final DimensionPulseRecord currentPulse;
}

class EvidenceSignalResult {
  const EvidenceSignalResult({
    required this.evidence,
    required this.signal,
    required this.accessCase,
    required this.previousState,
    required this.currentState,
    required this.previousPulse,
    required this.currentPulse,
    this.rampMeasurement,
  });

  final Evidence evidence;
  final BarrierSignal signal;
  final AccessCase accessCase;
  final RampMeasurement? rampMeasurement;
  final DimensionStateRecord previousState;
  final DimensionStateRecord currentState;
  final DimensionPulseRecord previousPulse;
  final DimensionPulseRecord currentPulse;
}

class VerificationResult {
  const VerificationResult({
    required this.verification,
    required this.accessCase,
    required this.previousState,
    required this.currentState,
    required this.previousPulse,
    required this.currentPulse,
  });

  final Verification verification;
  final AccessCase accessCase;
  final DimensionStateRecord previousState;
  final DimensionStateRecord currentState;
  final DimensionPulseRecord previousPulse;
  final DimensionPulseRecord currentPulse;
}

class DimensionStateService {
  DimensionStateService({
    required AccessPulseRepository repository,
    PulseService pulseService = const PulseService(),
    IdFactory? idFactory,
  }) : _repository = repository,
       _pulseService = pulseService,
       _idFactory = idFactory ?? _timestampId;

  final AccessPulseRepository _repository;
  final PulseService _pulseService;
  final IdFactory _idFactory;

  Future<VisitUpdateResult> confirmVisit({
    required String placeDimensionId,
    required String submittedBy,
    required bool entranceUsableIndependently,
    required bool rampUsable,
    required bool neededAssistance,
    required bool completedPurpose,
    String? note,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final previousState = await _repository.getDimensionState(placeDimensionId);
    final previousPulse = await _repository.getDimensionPulse(placeDimensionId);
    final outcome = _visitOutcome(
      entranceUsableIndependently: entranceUsableIndependently,
      rampUsable: rampUsable,
      neededAssistance: neededAssistance,
      completedPurpose: completedPurpose,
    );
    final observation = Observation(
      id: _idFactory('observation'),
      placeDimensionId: placeDimensionId,
      submittedBy: submittedBy,
      visitDate: DateTime(timestamp.year, timestamp.month, timestamp.day),
      entranceUsableIndependently: entranceUsableIndependently,
      rampUsable: rampUsable,
      neededAssistance: neededAssistance,
      completedPurpose: completedPurpose,
      note: note,
      outcome: outcome,
      createdAt: timestamp,
    );
    await _repository.addObservation(observation);

    final nextState = _stateAfterObservation(previousState.state, outcome);
    final currentState = previousState.copyWith(
      state: nextState,
      confidence: _confidenceAfterObservation(
        previousState.confidence,
        outcome,
      ),
      explanation: _stateExplanationForObservation(outcome),
      lastConfirmedAt: timestamp,
      source: 'community_visit_confirmation',
      updatedAt: timestamp,
    );
    await _repository.saveDimensionState(currentState);

    final currentPulse = await _recalculatePulse(
      placeDimensionId: placeDimensionId,
      previousPulse: previousPulse,
      now: timestamp,
    );

    await _appendMemory(
      placeDimensionId: placeDimensionId,
      eventType: MemoryEventType.visitConfirmed,
      actorType: 'community_user',
      actorId: submittedBy,
      previousState: previousState.state,
      newState: currentState.state,
      previousPulse: previousPulse.level,
      newPulse: currentPulse.level,
      observationId: observation.id,
      summary: _memorySummaryForVisit(outcome),
      createdAt: timestamp,
    );

    if (previousState.state != currentState.state) {
      await _appendMemory(
        placeDimensionId: placeDimensionId,
        eventType: MemoryEventType.stateChanged,
        actorType: 'system',
        previousState: previousState.state,
        newState: currentState.state,
        observationId: observation.id,
        summary:
            'Mobility Access state changed because a fresh visit challenged the previous public knowledge.',
        createdAt: timestamp,
      );
    }

    if (previousPulse.level != currentPulse.level) {
      await _appendMemory(
        placeDimensionId: placeDimensionId,
        eventType: MemoryEventType.pulseChanged,
        actorType: 'system',
        previousPulse: previousPulse.level,
        newPulse: currentPulse.level,
        observationId: observation.id,
        summary:
            'Dimension Pulse changed after recalculating freshness and supporting observations.',
        createdAt: timestamp,
      );
    }

    return VisitUpdateResult(
      observation: observation,
      previousState: previousState,
      currentState: currentState,
      previousPulse: previousPulse,
      currentPulse: currentPulse,
    );
  }

  Future<EvidenceSignalResult> submitStructuredEvidence({
    required String placeDimensionId,
    required String submittedBy,
    required AiEvidenceAssessment assessment,
    String? observationId,
    String? imagePath,
    String? note,
    RampSlopeMeasurement? rampSlopeMeasurement,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final previousState = await _repository.getDimensionState(placeDimensionId);
    final previousPulse = await _repository.getDimensionPulse(placeDimensionId);
    final capturedRampMeasurement = rampSlopeMeasurement;
    final rampMeasurementId = capturedRampMeasurement == null
        ? null
        : _idFactory('ramp_measurement');
    final evidence = Evidence(
      id: _idFactory('evidence'),
      observationId: observationId,
      placeDimensionId: placeDimensionId,
      submittedBy: submittedBy,
      evidenceType: EvidenceType.image,
      storagePath: imagePath,
      note: note,
      metadata: <String, Object?>{
        'dimension': assessment.dimension,
        'aiSummary': assessment.summary,
        'confidenceLevel': assessment.confidenceLevel.name,
        'confidenceExplanation': assessment.confidenceExplanation,
        'evidenceReadiness': assessment.evidenceReadiness.name,
        'institutionReady': assessment.institutionReady,
        'nextBestAction': assessment.nextBestAction,
        if (capturedRampMeasurement != null && rampMeasurementId != null) ...{
          'rampMeasurementId': rampMeasurementId,
          'rampMeasurementStatus': capturedRampMeasurement.status.name,
          'estimatedRampAngleDegrees':
              capturedRampMeasurement.estimatedAngleDegrees,
          'rampMeasurementQuality': capturedRampMeasurement.qualityLabel,
        },
      },
      createdAt: timestamp,
    );
    await _repository.addEvidence(evidence);

    final rampMeasurement = capturedRampMeasurement == null
        ? null
        : await _repository.addRampMeasurement(
            RampMeasurement(
              id: rampMeasurementId!,
              placeDimensionId: placeDimensionId,
              evidenceId: evidence.id,
              observationId: observationId,
              submittedBy: submittedBy,
              estimatedAngleDegrees:
                  capturedRampMeasurement.estimatedAngleDegrees,
              qualityScore: capturedRampMeasurement.qualityScore,
              qualityLabel: capturedRampMeasurement.qualityLabel,
              captureDurationMs: capturedRampMeasurement.captureDurationMs,
              sampleCount: capturedRampMeasurement.sampleCount,
              status: capturedRampMeasurement.status,
              source: capturedRampMeasurement.sourceLabel,
              capturedAt: capturedRampMeasurement.capturedAt,
              createdAt: timestamp,
            ),
          );

    final signal = BarrierSignal(
      id: _idFactory('barrier_signal'),
      placeDimensionId: placeDimensionId,
      observationId: observationId,
      evidenceId: evidence.id,
      issueType: assessment.issueType,
      observedFeatures: assessment.observedFeatures,
      possibleBarrier: assessment.possibleBarrier,
      missingEvidence: assessment.missingEvidence,
      confidence: assessment.confidence,
      structuredSummary: assessment.summary,
      recommendedAction: assessment.recommendedAction,
      aiModel: 'mock_accessibility_copilot',
      aiExplanation: <String, Object?>{
        'explanation': assessment.explanation,
        'confidenceLevel': assessment.confidenceLevel.name,
        'confidenceExplanation': assessment.confidenceExplanation,
        'evidenceReadiness': assessment.evidenceReadiness.name,
        'institutionReady': assessment.institutionReady,
        'nextBestAction': assessment.nextBestAction,
      },
      createdAt: timestamp,
    );
    await _repository.addBarrierSignal(signal);

    final accessCase = AccessCase(
      id: _idFactory('case'),
      placeDimensionId: placeDimensionId,
      barrierSignalId: signal.id,
      status: CaseStatus.open,
      severity: _severityFromConfidence(assessment.confidence),
      confidence: assessment.confidence,
      title: 'Mobility Access signal needs LGU review',
      summary: assessment.summary,
      openedAt: timestamp,
      updatedAt: timestamp,
    );
    await _repository.addCase(accessCase);

    final nextState = _stateAfterBarrierSignal(previousState.state);
    final currentState = previousState.copyWith(
      state: nextState,
      confidence: _boundedConfidence(
        previousState.confidence + assessment.confidence * 0.18,
      ),
      explanation:
          'AI structured the evidence as a mobility-access barrier signal while preserving uncertainty for human review.',
      lastConfirmedAt: timestamp,
      source: 'ai_structured_barrier_signal',
      updatedAt: timestamp,
    );
    await _repository.saveDimensionState(currentState);

    final currentPulse = await _recalculatePulse(
      placeDimensionId: placeDimensionId,
      previousPulse: previousPulse,
      now: timestamp,
      contradictionFlag: false,
    );

    await _appendMemory(
      placeDimensionId: placeDimensionId,
      eventType: MemoryEventType.evidenceAdded,
      actorType: 'community_user',
      actorId: submittedBy,
      evidenceId: evidence.id,
      summary:
          'A community contributor added evidence to strengthen public Mobility Access knowledge.',
      createdAt: timestamp,
    );
    await _appendMemory(
      placeDimensionId: placeDimensionId,
      eventType: MemoryEventType.aiSignalCreated,
      actorType: 'ai_copilot',
      evidenceId: evidence.id,
      barrierSignalId: signal.id,
      summary:
          'AI structured the evidence into an institution-ready barrier signal without making an official judgment.',
      createdAt: timestamp,
    );
    await _appendMemory(
      placeDimensionId: placeDimensionId,
      eventType: MemoryEventType.caseOpened,
      actorType: 'system',
      barrierSignalId: signal.id,
      caseId: accessCase.id,
      summary:
          'An actionable LGU review case was opened for the Mobility Access signal.',
      createdAt: timestamp,
    );

    if (previousState.state != currentState.state) {
      await _appendMemory(
        placeDimensionId: placeDimensionId,
        eventType: MemoryEventType.stateChanged,
        actorType: 'system',
        previousState: previousState.state,
        newState: currentState.state,
        previousPulse: previousPulse.level,
        newPulse: currentPulse.level,
        evidenceId: evidence.id,
        barrierSignalId: signal.id,
        caseId: accessCase.id,
        summary:
            'The living accessibility state moved to degraded pending human review.',
        createdAt: timestamp,
      );
    }

    return EvidenceSignalResult(
      evidence: evidence,
      signal: signal,
      accessCase: accessCase,
      previousState: previousState,
      currentState: currentState,
      previousPulse: previousPulse,
      currentPulse: currentPulse,
      rampMeasurement: rampMeasurement,
    );
  }

  Future<AccessCase> requestInspection({
    required String caseId,
    required String reviewerId,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final accessCase = await _repository.getCase(caseId);
    final previousState = await _repository.getDimensionState(
      accessCase.placeDimensionId,
    );
    final nextCase = accessCase.copyWith(
      status: CaseStatus.inspectionRequested,
      updatedAt: timestamp,
    );
    await _repository.saveCase(nextCase);

    if (previousState.state == DimensionStateValue.degraded) {
      await _repository.saveDimensionState(
        previousState.copyWith(
          state: DimensionStateValue.underReview,
          explanation:
              'An LGU reviewer requested inspection, so the degraded Mobility Access signal is now under review.',
          source: 'lgu_reviewer',
          updatedAt: timestamp,
        ),
      );
    }

    await _appendMemory(
      placeDimensionId: accessCase.placeDimensionId,
      eventType: MemoryEventType.inspectionRequested,
      actorType: 'lgu_reviewer',
      actorId: reviewerId,
      previousState: previousState.state,
      newState: previousState.state == DimensionStateValue.degraded
          ? DimensionStateValue.underReview
          : previousState.state,
      caseId: caseId,
      summary:
          'LGU reviewer requested inspection for the Mobility Access case.',
      createdAt: timestamp,
    );

    return nextCase;
  }

  Future<AccessCase> triageCase({
    required String caseId,
    required String reviewerId,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final accessCase = await _repository.getCase(caseId);
    final nextCase = accessCase.copyWith(
      status: CaseStatus.triaging,
      updatedAt: timestamp,
    );
    await _repository.saveCase(nextCase);
    await _appendMemory(
      placeDimensionId: accessCase.placeDimensionId,
      eventType: MemoryEventType.caseTriaged,
      actorType: 'lgu_reviewer',
      actorId: reviewerId,
      caseId: caseId,
      summary:
          'LGU reviewer triaged the Mobility Access case for institutional follow-up.',
      createdAt: timestamp,
    );
    return nextCase;
  }

  Future<AccessCase> closeCase({
    required String caseId,
    required String reviewerId,
    required String note,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final accessCase = await _repository.getCase(caseId);
    final nextCase = accessCase.copyWith(
      status: CaseStatus.closed,
      updatedAt: timestamp,
      closedAt: timestamp,
    );
    await _repository.saveCase(nextCase);
    await _appendMemory(
      placeDimensionId: accessCase.placeDimensionId,
      eventType: MemoryEventType.caseClosed,
      actorType: 'lgu_reviewer',
      actorId: reviewerId,
      caseId: caseId,
      summary: 'LGU reviewer closed the case: $note',
      createdAt: timestamp,
    );
    return nextCase;
  }

  Future<VerificationResult> submitVerification({
    required String caseId,
    required String inspectorId,
    required VerificationOutcome outcome,
    required String note,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final accessCase = await _repository.getCase(caseId);
    final previousState = await _repository.getDimensionState(
      accessCase.placeDimensionId,
    );
    final previousPulse = await _repository.getDimensionPulse(
      accessCase.placeDimensionId,
    );
    final verification = Verification(
      id: _idFactory('verification'),
      caseId: caseId,
      placeDimensionId: accessCase.placeDimensionId,
      verifiedBy: inspectorId,
      outcome: outcome,
      note: note,
      performedAt: timestamp,
    );
    await _repository.addVerification(verification);

    final nextState = switch (outcome) {
      VerificationOutcome.confirmed =>
        DimensionStateValue.officiallyVerifiedDegraded,
      VerificationOutcome.disputed => previousState.state,
      VerificationOutcome.insufficientEvidence => previousState.state,
    };
    final nextStatus = switch (outcome) {
      VerificationOutcome.confirmed => CaseStatus.verified,
      VerificationOutcome.disputed => CaseStatus.disputed,
      VerificationOutcome.insufficientEvidence => CaseStatus.triaging,
    };

    final currentState = previousState.copyWith(
      state: nextState,
      confidence: switch (outcome) {
        VerificationOutcome.confirmed => 0.92,
        VerificationOutcome.disputed => 0.48,
        VerificationOutcome.insufficientEvidence => 0.36,
      },
      explanation: switch (outcome) {
        VerificationOutcome.confirmed =>
          'A human inspector confirmed the Mobility Access barrier. This is an official verification outcome.',
        VerificationOutcome.disputed =>
          'A human inspector disputed the barrier signal. The place memory keeps both the signal and the dispute.',
        VerificationOutcome.insufficientEvidence =>
          'A human inspector found that the evidence is not sufficient for an official outcome yet.',
      },
      source: 'human_verification',
      updatedAt: timestamp,
    );
    await _repository.saveDimensionState(currentState);

    final currentCase = accessCase.copyWith(
      status: nextStatus,
      updatedAt: timestamp,
      closedAt: outcome == VerificationOutcome.confirmed ? timestamp : null,
    );
    await _repository.saveCase(currentCase);

    final currentPulse = await _recalculatePulse(
      placeDimensionId: accessCase.placeDimensionId,
      previousPulse: previousPulse,
      now: timestamp,
      contradictionFlag: outcome == VerificationOutcome.disputed,
    );

    await _appendMemory(
      placeDimensionId: accessCase.placeDimensionId,
      eventType: MemoryEventType.verificationSubmitted,
      actorType: 'inspector',
      actorId: inspectorId,
      previousState: previousState.state,
      newState: currentState.state,
      previousPulse: previousPulse.level,
      newPulse: currentPulse.level,
      caseId: caseId,
      verificationId: verification.id,
      summary: _verificationMemorySummary(outcome),
      createdAt: timestamp,
    );

    return VerificationResult(
      verification: verification,
      accessCase: currentCase,
      previousState: previousState,
      currentState: currentState,
      previousPulse: previousPulse,
      currentPulse: currentPulse,
    );
  }

  Future<DimensionPulseRecord> _recalculatePulse({
    required String placeDimensionId,
    required DimensionPulseRecord previousPulse,
    required DateTime now,
    bool contradictionFlag = false,
  }) async {
    final observations = await _repository.listObservations(placeDimensionId);
    final verifications = await _repository.listVerifications(placeDimensionId);
    final pulse = _pulseService.calculate(
      id: previousPulse.id,
      placeDimensionId: placeDimensionId,
      observations: observations,
      verifications: verifications,
      contradictionFlag: contradictionFlag,
      now: now,
    );
    await _repository.saveDimensionPulse(pulse);
    return pulse;
  }

  ObservationOutcome _visitOutcome({
    required bool entranceUsableIndependently,
    required bool rampUsable,
    required bool neededAssistance,
    required bool completedPurpose,
  }) {
    if (entranceUsableIndependently &&
        rampUsable &&
        !neededAssistance &&
        completedPurpose) {
      return ObservationOutcome.positive;
    }
    if (!entranceUsableIndependently ||
        !rampUsable ||
        neededAssistance ||
        !completedPurpose) {
      return ObservationOutcome.negative;
    }
    return ObservationOutcome.mixed;
  }

  DimensionStateValue _stateAfterObservation(
    DimensionStateValue previous,
    ObservationOutcome outcome,
  ) {
    if (outcome == ObservationOutcome.positive &&
        previous == DimensionStateValue.claimedAccessible) {
      return DimensionStateValue.reliable;
    }
    if (outcome == ObservationOutcome.negative &&
        (previous == DimensionStateValue.claimedAccessible ||
            previous == DimensionStateValue.reliable ||
            previous == DimensionStateValue.unknown)) {
      return DimensionStateValue.degraded;
    }
    return previous;
  }

  DimensionStateValue _stateAfterBarrierSignal(DimensionStateValue previous) {
    if (previous == DimensionStateValue.claimedAccessible ||
        previous == DimensionStateValue.reliable ||
        previous == DimensionStateValue.unknown) {
      return DimensionStateValue.degraded;
    }
    return previous;
  }

  double _confidenceAfterObservation(
    double previousConfidence,
    ObservationOutcome outcome,
  ) {
    final adjustment = switch (outcome) {
      ObservationOutcome.positive => 0.14,
      ObservationOutcome.negative => 0.20,
      ObservationOutcome.mixed => 0.08,
      ObservationOutcome.unknown => 0.0,
    };
    return _boundedConfidence(previousConfidence + adjustment);
  }

  double _boundedConfidence(double value) {
    return double.parse(value.clamp(0.0, 0.98).toStringAsFixed(3));
  }

  CaseSeverity _severityFromConfidence(double confidence) {
    if (confidence >= 0.8) {
      return CaseSeverity.high;
    }
    if (confidence >= 0.5) {
      return CaseSeverity.medium;
    }
    return CaseSeverity.low;
  }

  String _stateExplanationForObservation(ObservationOutcome outcome) {
    return switch (outcome) {
      ObservationOutcome.positive =>
        'A fresh visit confirmation supports independent Mobility Access at the entrance.',
      ObservationOutcome.negative =>
        'A fresh visit confirmation indicates independent Mobility Access may be unreliable.',
      ObservationOutcome.mixed =>
        'A fresh visit confirmation gives a partial Mobility Access signal.',
      ObservationOutcome.unknown =>
        'The visit confirmation did not add enough evidence to change current knowledge.',
    };
  }

  String _memorySummaryForVisit(ObservationOutcome outcome) {
    return switch (outcome) {
      ObservationOutcome.positive =>
        'Community visit confirmed that the entrance was usable independently.',
      ObservationOutcome.negative =>
        'Community visit challenged the current state: independent entrance access was not reliable.',
      ObservationOutcome.mixed =>
        'Community visit added a mixed Mobility Access signal.',
      ObservationOutcome.unknown =>
        'Community visit added an uncertain Mobility Access signal.',
    };
  }

  String _verificationMemorySummary(VerificationOutcome outcome) {
    return switch (outcome) {
      VerificationOutcome.confirmed =>
        'Human verifier confirmed the barrier and made the degraded state official.',
      VerificationOutcome.disputed =>
        'Human verifier disputed the barrier signal; the place memory keeps the contradiction visible.',
      VerificationOutcome.insufficientEvidence =>
        'Human verifier marked the evidence insufficient for an official outcome.',
    };
  }

  Future<void> _appendMemory({
    required String placeDimensionId,
    required MemoryEventType eventType,
    required String actorType,
    required String summary,
    required DateTime createdAt,
    String? actorId,
    DimensionStateValue? previousState,
    DimensionStateValue? newState,
    DimensionPulseLevel? previousPulse,
    DimensionPulseLevel? newPulse,
    String? observationId,
    String? evidenceId,
    String? barrierSignalId,
    String? caseId,
    String? verificationId,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    await _repository.appendMemoryEvent(
      MemoryEvent(
        id: _idFactory('memory_event'),
        placeDimensionId: placeDimensionId,
        eventType: eventType,
        actorType: actorType,
        actorId: actorId,
        previousState: previousState,
        newState: newState,
        previousPulse: previousPulse,
        newPulse: newPulse,
        observationId: observationId,
        evidenceId: evidenceId,
        barrierSignalId: barrierSignalId,
        caseId: caseId,
        verificationId: verificationId,
        summary: summary,
        metadata: metadata,
        createdAt: createdAt,
      ),
    );
  }

  static String _timestampId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
