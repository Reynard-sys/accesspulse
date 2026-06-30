enum AccessPulseUserRole { communityUser, lguReviewer, inspector }

enum DimensionStateValue {
  unknown,
  claimedAccessible,
  reliable,
  degraded,
  officiallyVerifiedDegraded,
  underReview,
  resolved,
}

enum DimensionPulseLevel { weak, moderate, strong }

enum PlacePulseStatus {
  reliable,
  reliableAging,
  unknown,
  underReview,
  recentlyRefreshed,
}

enum CaseStatus {
  open,
  triaging,
  inspectionRequested,
  verified,
  disputed,
  resolved,
  closed,
}

enum ObservationOutcome { positive, negative, mixed, unknown }

enum EvidenceType { image, textNote, structuredResponse }

enum RampMeasurementStatus { captured, lowQuality, failed, fallback, discarded }

enum CaseSeverity { low, medium, high }

enum VerificationOutcome { confirmed, disputed, insufficientEvidence }

enum MemoryEventType {
  placeSeeded,
  stateSeeded,
  visitConfirmed,
  evidenceAdded,
  aiSignalCreated,
  caseOpened,
  caseTriaged,
  inspectionRequested,
  verificationSubmitted,
  stateChanged,
  pulseChanged,
  caseClosed,
  remediationVerified,
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.organizationType,
    this.jurisdiction,
  });

  final String id;
  final String name;
  final String organizationType;
  final String? jurisdiction;
}

class AccessPulseUser {
  const AccessPulseUser({
    required this.id,
    required this.displayName,
    required this.role,
    this.organizationId,
  });

  final String id;
  final String displayName;
  final AccessPulseUserRole role;
  final String? organizationId;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.placeType,
    this.address,
    this.municipality,
    this.province,
    this.country = 'Philippines',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String placeType;
  final String? address;
  final String? municipality;
  final String? province;
  final String country;
  final double? latitude;
  final double? longitude;
}

class AccessibilityDimension {
  const AccessibilityDimension({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
  });

  final String id;
  final String key;
  final String name;
  final String description;
}

class PlaceDimension {
  const PlaceDimension({
    required this.id,
    required this.placeId,
    required this.dimensionId,
    this.summary,
  });

  final String id;
  final String placeId;
  final String dimensionId;
  final String? summary;
}

class DimensionStateRecord {
  const DimensionStateRecord({
    required this.id,
    required this.placeDimensionId,
    required this.state,
    required this.confidence,
    required this.explanation,
    required this.source,
    required this.updatedAt,
    this.lastConfirmedAt,
  });

  final String id;
  final String placeDimensionId;
  final DimensionStateValue state;
  final double confidence;
  final String explanation;
  final DateTime? lastConfirmedAt;
  final String source;
  final DateTime updatedAt;

  DimensionStateRecord copyWith({
    DimensionStateValue? state,
    double? confidence,
    String? explanation,
    DateTime? lastConfirmedAt,
    String? source,
    DateTime? updatedAt,
  }) {
    return DimensionStateRecord(
      id: id,
      placeDimensionId: placeDimensionId,
      state: state ?? this.state,
      confidence: confidence ?? this.confidence,
      explanation: explanation ?? this.explanation,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DimensionPulseRecord {
  const DimensionPulseRecord({
    required this.id,
    required this.placeDimensionId,
    required this.level,
    required this.score,
    required this.supportingObservationsCount,
    required this.hasRecentVerification,
    required this.contradictionFlag,
    required this.lastCalculatedAt,
    required this.explanation,
  });

  final String id;
  final String placeDimensionId;
  final DimensionPulseLevel level;
  final double score;
  final int supportingObservationsCount;
  final bool hasRecentVerification;
  final bool contradictionFlag;
  final DateTime lastCalculatedAt;
  final String explanation;
}

class Observation {
  const Observation({
    required this.id,
    required this.placeDimensionId,
    required this.visitDate,
    required this.outcome,
    required this.createdAt,
    this.submittedBy,
    this.entranceUsableIndependently,
    this.rampUsable,
    this.neededAssistance,
    this.completedPurpose,
    this.note,
  });

  final String id;
  final String placeDimensionId;
  final String? submittedBy;
  final DateTime visitDate;
  final bool? entranceUsableIndependently;
  final bool? rampUsable;
  final bool? neededAssistance;
  final bool? completedPurpose;
  final String? note;
  final ObservationOutcome outcome;
  final DateTime createdAt;
}

class Evidence {
  const Evidence({
    required this.id,
    required this.placeDimensionId,
    required this.evidenceType,
    required this.createdAt,
    this.observationId,
    this.submittedBy,
    this.storagePath,
    this.publicUrl,
    this.note,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String? observationId;
  final String placeDimensionId;
  final String? submittedBy;
  final EvidenceType evidenceType;
  final String? storagePath;
  final String? publicUrl;
  final String? note;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}

class RampMeasurement {
  const RampMeasurement({
    required this.id,
    required this.placeDimensionId,
    required this.evidenceId,
    required this.estimatedAngleDegrees,
    required this.qualityScore,
    required this.qualityLabel,
    required this.captureDurationMs,
    required this.sampleCount,
    required this.status,
    required this.source,
    required this.capturedAt,
    required this.createdAt,
    this.observationId,
    this.submittedBy,
  });

  final String id;
  final String placeDimensionId;
  final String evidenceId;
  final String? observationId;
  final String? submittedBy;
  final double estimatedAngleDegrees;
  final int qualityScore;
  final String qualityLabel;
  final int captureDurationMs;
  final int sampleCount;
  final RampMeasurementStatus status;
  final String source;
  final DateTime capturedAt;
  final DateTime createdAt;
}

class BarrierSignal {
  const BarrierSignal({
    required this.id,
    required this.placeDimensionId,
    required this.issueType,
    required this.observedFeatures,
    required this.possibleBarrier,
    required this.missingEvidence,
    required this.confidence,
    required this.structuredSummary,
    required this.recommendedAction,
    required this.createdAt,
    this.observationId,
    this.evidenceId,
    this.aiModel,
    this.aiExplanation = const <String, Object?>{},
  });

  final String id;
  final String placeDimensionId;
  final String? observationId;
  final String? evidenceId;
  final String issueType;
  final List<String> observedFeatures;
  final String possibleBarrier;
  final List<String> missingEvidence;
  final double confidence;
  final String structuredSummary;
  final String recommendedAction;
  final String? aiModel;
  final Map<String, Object?> aiExplanation;
  final DateTime createdAt;
}

class AccessCase {
  const AccessCase({
    required this.id,
    required this.placeDimensionId,
    required this.status,
    required this.severity,
    required this.confidence,
    required this.title,
    required this.summary,
    required this.openedAt,
    required this.updatedAt,
    this.barrierSignalId,
    this.assignedOrganizationId,
    this.closedAt,
  });

  final String id;
  final String placeDimensionId;
  final String? barrierSignalId;
  final CaseStatus status;
  final CaseSeverity severity;
  final double confidence;
  final String title;
  final String summary;
  final String? assignedOrganizationId;
  final DateTime openedAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  AccessCase copyWith({
    CaseStatus? status,
    CaseSeverity? severity,
    double? confidence,
    String? title,
    String? summary,
    String? assignedOrganizationId,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return AccessCase(
      id: id,
      placeDimensionId: placeDimensionId,
      barrierSignalId: barrierSignalId,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      assignedOrganizationId:
          assignedOrganizationId ?? this.assignedOrganizationId,
      openedAt: openedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class Verification {
  const Verification({
    required this.id,
    required this.caseId,
    required this.placeDimensionId,
    required this.outcome,
    required this.note,
    required this.performedAt,
    this.verifiedBy,
  });

  final String id;
  final String caseId;
  final String placeDimensionId;
  final String? verifiedBy;
  final VerificationOutcome outcome;
  final String note;
  final DateTime performedAt;
}

class MemoryEvent {
  const MemoryEvent({
    required this.id,
    required this.placeDimensionId,
    required this.eventType,
    required this.actorType,
    required this.summary,
    required this.createdAt,
    this.actorId,
    this.previousState,
    this.newState,
    this.previousPulse,
    this.newPulse,
    this.observationId,
    this.evidenceId,
    this.barrierSignalId,
    this.caseId,
    this.verificationId,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String placeDimensionId;
  final MemoryEventType eventType;
  final String actorType;
  final String? actorId;
  final DimensionStateValue? previousState;
  final DimensionStateValue? newState;
  final DimensionPulseLevel? previousPulse;
  final DimensionPulseLevel? newPulse;
  final String? observationId;
  final String? evidenceId;
  final String? barrierSignalId;
  final String? caseId;
  final String? verificationId;
  final String summary;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}

class AiEvidenceAssessment {
  const AiEvidenceAssessment({
    required this.dimension,
    required this.issueType,
    required this.observedFeatures,
    required this.possibleBarrier,
    required this.missingEvidence,
    required this.confidence,
    required this.summary,
    required this.recommendedAction,
    required this.explanation,
  });

  final String dimension;
  final String issueType;
  final List<String> observedFeatures;
  final String possibleBarrier;
  final List<String> missingEvidence;
  final double confidence;
  final String summary;
  final String recommendedAction;
  final String explanation;
}
