import '../domain/models/accesspulse_models.dart';

final seedGeneratedAt = DateTime(2026, 6, 29, 21, 30);

const seedOrganizations = <Organization>[
  Organization(
    id: '10000000-0000-4000-8000-000000000001',
    name: 'Manila Accessibility Desk',
    organizationType: 'lgu',
    jurisdiction: 'Manila',
  ),
];

const seedUsers = <AccessPulseUser>[
  AccessPulseUser(
    id: '20000000-0000-4000-8000-000000000001',
    displayName: 'Demo Community Contributor',
    role: AccessPulseUserRole.communityUser,
  ),
  AccessPulseUser(
    id: '20000000-0000-4000-8000-000000000002',
    displayName: 'Demo LGU Reviewer',
    role: AccessPulseUserRole.lguReviewer,
    organizationId: '10000000-0000-4000-8000-000000000001',
  ),
  AccessPulseUser(
    id: '20000000-0000-4000-8000-000000000003',
    displayName: 'Demo Inspector',
    role: AccessPulseUserRole.inspector,
    organizationId: '10000000-0000-4000-8000-000000000001',
  ),
];

const mobilityAccessDimension = AccessibilityDimension(
  id: '30000000-0000-4000-8000-000000000001',
  key: 'mobility_access',
  name: 'Mobility Access',
  description:
      'Entrance, route, ramp, and doorway usability for independent wheelchair access.',
);

const seedDimensions = <AccessibilityDimension>[mobilityAccessDimension];

const seedPlaces = <Place>[
  Place(
    id: '40000000-0000-4000-8000-000000000001',
    name: 'Polytechnic University of the Philippines',
    placeType: 'school',
    address: 'Anonas Street, Sta. Mesa, Manila',
    city: 'Manila',
    barangay: 'Santa Mesa',
    municipality: 'Manila',
    province: 'Metro Manila',
    latitude: 14.5979,
    longitude: 121.0108,
  ),
  Place(
    id: '40000000-0000-4000-8000-000000000002',
    name: 'LRT 2 Pureza',
    placeType: 'transport_station',
    address: 'Magsaysay Boulevard, Sta. Mesa, Manila',
    city: 'Manila',
    barangay: 'Santa Mesa',
    municipality: 'Manila',
    province: 'Metro Manila',
    latitude: 14.6018,
    longitude: 121.0057,
  ),
  Place(
    id: '40000000-0000-4000-8000-000000000003',
    name: 'LRT 2 V. Mapa',
    placeType: 'transport_station',
    address: 'Magsaysay Boulevard near V. Mapa Street, Sta. Mesa, Manila',
    city: 'Manila',
    barangay: 'Santa Mesa',
    municipality: 'Manila',
    province: 'Metro Manila',
    latitude: 14.6042,
    longitude: 121.0173,
  ),
  Place(
    id: '40000000-0000-4000-8000-000000000004',
    name: 'Teresa Street',
    placeType: 'street',
    address: 'Teresa Street, Sta. Mesa, Manila',
    city: 'Manila',
    barangay: 'Santa Mesa',
    municipality: 'Manila',
    province: 'Metro Manila',
    latitude: 14.5996,
    longitude: 121.0085,
  ),
];

const seedPlaceDimensions = <PlaceDimension>[
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000001',
    placeId: '40000000-0000-4000-8000-000000000001',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary:
        'Mobility Access state for the PUP main entrance and nearby route. Seeded as claimed accessible but stale for the demo.',
  ),
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000002',
    placeId: '40000000-0000-4000-8000-000000000002',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary: 'Mobility Access state for the LRT 2 Pureza station entrance.',
  ),
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000003',
    placeId: '40000000-0000-4000-8000-000000000003',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary: 'Mobility Access state for the LRT 2 V. Mapa station entrance.',
  ),
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000004',
    placeId: '40000000-0000-4000-8000-000000000004',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary: 'Mobility Access state for Teresa Street.',
  ),
];

List<DimensionStateRecord> buildSeedDimensionStates() {
  return <DimensionStateRecord>[
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      state: DimensionStateValue.degraded,
      confidence: 0.66,
      explanation:
          'Community evidence reports that the PUP entrance route may be difficult to use independently. AI structured this as advisory information for LGU review.',
      lastConfirmedAt: DateTime(2026, 6, 28, 10, 30),
      source: 'ai_structured_barrier_signal',
      updatedAt: seedGeneratedAt,
    ),
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      state: DimensionStateValue.underReview,
      confidence: 0.64,
      explanation:
          'Community evidence reports that station access may have been unreliable during a recent visit. LGU inspection has been requested.',
      lastConfirmedAt: DateTime(2026, 6, 28, 11, 15),
      source: 'lgu_inspection_requested',
      updatedAt: seedGeneratedAt,
    ),
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000003',
      placeDimensionId: '50000000-0000-4000-8000-000000000003',
      state: DimensionStateValue.degraded,
      confidence: 0.24,
      explanation:
          'Recent public knowledge suggests access near this station may need review.',
      lastConfirmedAt: DateTime.now().subtract(const Duration(days: 18)),
      source: 'seed_unknown',
      updatedAt: seedGeneratedAt,
    ),
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000004',
      state: DimensionStateValue.reliable,
      confidence: 0.85,
      explanation:
          'The system does not currently know enough about independent wheelchair access along this street segment.',
      lastConfirmedAt: DateTime.now().subtract(const Duration(days: 31)),
      source: 'seed_official_audit',
      updatedAt: seedGeneratedAt,
    ),
  ];
}

List<DimensionPulseRecord> buildSeedDimensionPulses() {
  return <DimensionPulseRecord>[
    DimensionPulseRecord(
      id: '70000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      level: DimensionPulseLevel.moderate,
      score: 0.68,
      supportingObservationsCount: 2,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation:
          'Recent community evidence opened a Mobility Access case for LGU review, but human verification has not happened yet.',
    ),
    DimensionPulseRecord(
      id: '70000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      level: DimensionPulseLevel.moderate,
      score: 0.66,
      supportingObservationsCount: 2,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation:
          'The station access report is active for inspector verification, with advisory AI context but no official verification yet.',
    ),
    DimensionPulseRecord(
      id: '70000000-0000-4000-8000-000000000003',
      placeDimensionId: '50000000-0000-4000-8000-000000000003',
      level: DimensionPulseLevel.weak,
      score: 0.65,
      supportingObservationsCount: 0,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation:
          'A recent access concern exists, but supporting observations are still limited.',
    ),
    DimensionPulseRecord(
      id: '70000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000004',
      level: DimensionPulseLevel.moderate,
      score: 0.65,
      supportingObservationsCount: 2,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation:
          'No supporting observations are available, so this street needs community confirmation.',
    ),
  ];
}

List<Observation> buildSeedObservations() {
  return <Observation>[
    Observation(
      id: '80000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      submittedBy: '20000000-0000-4000-8000-000000000001',
      visitDate: DateTime(2026, 4, 15),
      entranceUsableIndependently: true,
      rampUsable: true,
      neededAssistance: false,
      completedPurpose: true,
      note:
          'Seeded old confirmation: the PUP entrance route was reported usable independently at the time.',
      outcome: ObservationOutcome.positive,
      createdAt: DateTime(2026, 4, 15, 9),
    ),
    Observation(
      id: '80000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      submittedBy: '20000000-0000-4000-8000-000000000001',
      visitDate: DateTime(2026, 6, 20),
      entranceUsableIndependently: true,
      rampUsable: true,
      neededAssistance: false,
      completedPurpose: true,
      note:
          'Seeded recent confirmation: the LRT 2 Pureza entrance was usable independently.',
      outcome: ObservationOutcome.positive,
      createdAt: DateTime(2026, 6, 20, 14, 30),
    ),
    Observation(
      id: '80000000-0000-4000-8000-000000000003',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      submittedBy: '20000000-0000-4000-8000-000000000001',
      visitDate: DateTime(2026, 6, 28),
      entranceUsableIndependently: false,
      rampUsable: false,
      neededAssistance: true,
      completedPurpose: false,
      note:
          'The entrance route was difficult to use independently. There was an uneven path or high step near the access point, and assistance may be needed.',
      outcome: ObservationOutcome.negative,
      createdAt: DateTime(2026, 6, 28, 10, 30),
    ),
    Observation(
      id: '80000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      submittedBy: '20000000-0000-4000-8000-000000000001',
      visitDate: DateTime(2026, 6, 28),
      entranceUsableIndependently: false,
      rampUsable: null,
      neededAssistance: true,
      completedPurpose: false,
      note:
          'The station access feature was unavailable during the visit, and the accessible route was not clear. A person with mobility needs may need assistance or another route.',
      outcome: ObservationOutcome.negative,
      createdAt: DateTime(2026, 6, 28, 11, 15),
    ),
  ];
}

List<Evidence> buildSeedEvidence() {
  return <Evidence>[
    Evidence(
      id: '81000000-0000-4000-8000-000000000001',
      observationId: '80000000-0000-4000-8000-000000000003',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      submittedBy: '20000000-0000-4000-8000-000000000001',
      evidenceType: EvidenceType.textNote,
      storagePath: 'seed/pup-main-entrance-route-note.txt',
      note:
          'The entrance route was difficult to use independently. There was an uneven path or high step near the access point, and assistance may be needed.',
      metadata: const <String, Object?>{
        'confidenceLevel': 'moderate',
        'evidenceReadiness': 'institutionReady',
        'institutionReady': true,
        'nextBestAction': 'Request inspection.',
      },
      createdAt: DateTime(2026, 6, 28, 10, 35),
    ),
    Evidence(
      id: '81000000-0000-4000-8000-000000000002',
      observationId: '80000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      submittedBy: '20000000-0000-4000-8000-000000000001',
      evidenceType: EvidenceType.textNote,
      storagePath: 'seed/lrt2-pureza-station-access-note.txt',
      note:
          'The station access feature was unavailable during the visit, and the accessible route was not clear. A person with mobility needs may need assistance or another route.',
      metadata: const <String, Object?>{
        'confidenceLevel': 'moderate',
        'evidenceReadiness': 'almostReady',
        'institutionReady': true,
        'nextBestAction': 'Complete site inspection.',
      },
      createdAt: DateTime(2026, 6, 28, 11, 20),
    ),
  ];
}

List<BarrierSignal> buildSeedBarrierSignals() {
  return <BarrierSignal>[
    BarrierSignal(
      id: '82000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      observationId: '80000000-0000-4000-8000-000000000003',
      evidenceId: '81000000-0000-4000-8000-000000000001',
      issueType: 'entrance_route_usability',
      observedFeatures: const <String>[
        'entrance route',
        'uneven path',
        'high step or threshold',
        'assistance may be needed',
      ],
      possibleBarrier:
          'independent mobility access near the entrance route may be difficult',
      missingEvidence: const <String>[
        'wider photo showing the full route',
        'clear side view of the ramp or threshold',
      ],
      confidence: 0.66,
      structuredSummary:
          'The submitted evidence suggests a possible mobility access barrier near the PUP entrance route. The report would be stronger with a wider photo showing the full path and whether assistance was needed.',
      recommendedAction: 'lgu_review',
      aiModel: 'seed_accessibility_copilot',
      aiExplanation: const <String, Object?>{
        'explanation':
            'AI structured the community report for LGU review, but it is not an official verification.',
        'confidenceLevel': 'moderate',
        'confidenceExplanation':
            'Evidence supports review, with some uncertainty still visible.',
        'evidenceReadiness': 'institutionReady',
        'institutionReady': true,
        'nextBestAction': 'Request inspection.',
        'flaggedAsSpam': false,
      },
      createdAt: DateTime(2026, 6, 28, 10, 36),
    ),
    BarrierSignal(
      id: '82000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      observationId: '80000000-0000-4000-8000-000000000004',
      evidenceId: '81000000-0000-4000-8000-000000000002',
      issueType: 'station_access_unavailable',
      observedFeatures: const <String>[
        'station access feature',
        'unclear accessible route',
        'assistance may be needed',
      ],
      possibleBarrier:
          'mobility access at the station may have been unreliable during the visit',
      missingEvidence: const <String>[
        'timestamped photo of unavailable feature',
        'photo of maintenance sign or alternate route',
      ],
      confidence: 0.62,
      structuredSummary:
          'The report suggests that mobility access at LRT 2 Pureza may have been unreliable during the visit. A clearer photo of the unavailable feature or maintenance sign would strengthen the evidence.',
      recommendedAction: 'site_inspection',
      aiModel: 'seed_accessibility_copilot',
      aiExplanation: const <String, Object?>{
        'explanation':
            'AI structured the station access report for human review, but inspector verification remains authoritative.',
        'confidenceLevel': 'moderate',
        'confidenceExplanation':
            'Evidence supports review, with some uncertainty still visible.',
        'evidenceReadiness': 'almostReady',
        'institutionReady': true,
        'nextBestAction': 'Complete site inspection.',
        'flaggedAsSpam': false,
      },
      createdAt: DateTime(2026, 6, 28, 11, 21),
    ),
  ];
}

List<AccessCase> buildSeedAccessCases() {
  return <AccessCase>[
    AccessCase(
      id: '83000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      barrierSignalId: '82000000-0000-4000-8000-000000000001',
      status: CaseStatus.triaging,
      severity: CaseSeverity.medium,
      confidence: 0.66,
      title: 'PUP entrance route needs Mobility Access review',
      summary:
          'Community evidence reports that the PUP entrance route may be difficult to use independently and should be reviewed by the LGU.',
      assignedOrganizationId: '10000000-0000-4000-8000-000000000001',
      openedAt: DateTime(2026, 6, 28, 10, 40),
      updatedAt: DateTime(2026, 6, 28, 10, 45),
    ),
    AccessCase(
      id: '83000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      barrierSignalId: '82000000-0000-4000-8000-000000000002',
      status: CaseStatus.inspectionRequested,
      severity: CaseSeverity.medium,
      confidence: 0.62,
      title: 'LRT 2 Pureza station access needs verification',
      summary:
          'Community evidence reports that station mobility access may have been unavailable or unclear during the visit. Inspector verification is requested.',
      assignedOrganizationId: '10000000-0000-4000-8000-000000000001',
      openedAt: DateTime(2026, 6, 28, 11, 25),
      updatedAt: DateTime(2026, 6, 28, 11, 30),
    ),
  ];
}

List<MemoryEvent> buildSeedMemoryEvents() {
  return <MemoryEvent>[
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      eventType: MemoryEventType.stateSeeded,
      actorType: 'system',
      newState: DimensionStateValue.degraded,
      newPulse: DimensionPulseLevel.moderate,
      observationId: '80000000-0000-4000-8000-000000000001',
      summary:
          'Initial Mobility Access state seeded with a reported PUP entrance route barrier ready for LGU review.',
      metadata: const <String, Object?>{
        'demoRole': 'main lgu demo case',
        'dimension': 'mobility_access',
      },
      createdAt: DateTime(2026, 4, 15, 9),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      eventType: MemoryEventType.stateSeeded,
      actorType: 'system',
      newState: DimensionStateValue.underReview,
      newPulse: DimensionPulseLevel.moderate,
      observationId: '80000000-0000-4000-8000-000000000002',
      summary:
          'Initial Mobility Access state seeded with an LRT 2 Pureza station access case already requested for inspection.',
      metadata: const <String, Object?>{
        'demoRole': 'inspector-ready demo case',
        'dimension': 'mobility_access',
      },
      createdAt: DateTime(2026, 6, 20, 14, 30),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000003',
      placeDimensionId: '50000000-0000-4000-8000-000000000003',
      eventType: MemoryEventType.stateSeeded,
      actorType: 'system',
      newState: DimensionStateValue.unknown,
      newPulse: DimensionPulseLevel.weak,
      summary:
          'Initial Mobility Access state seeded as unknown because there is not enough current public knowledge.',
      metadata: const <String, Object?>{
        'demoRole': 'unknown place',
        'dimension': 'mobility_access',
      },
      createdAt: seedGeneratedAt,
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      eventType: MemoryEventType.evidenceAdded,
      actorType: 'community_user',
      actorId: '20000000-0000-4000-8000-000000000001',
      observationId: '80000000-0000-4000-8000-000000000003',
      evidenceId: '81000000-0000-4000-8000-000000000001',
      summary:
          'Community evidence reported that the PUP entrance route may be difficult to use independently.',
      metadata: const <String, Object?>{
        'dimension': 'mobility_access',
        'demoRole': 'main lgu demo case',
      },
      createdAt: DateTime(2026, 6, 28, 10, 35),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000005',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      eventType: MemoryEventType.aiSignalCreated,
      actorType: 'ai_copilot',
      evidenceId: '81000000-0000-4000-8000-000000000001',
      barrierSignalId: '82000000-0000-4000-8000-000000000001',
      summary:
          'AI structured the PUP report into an advisory Mobility Access signal for LGU review.',
      metadata: const <String, Object?>{
        'dimension': 'mobility_access',
        'officialVerification': false,
      },
      createdAt: DateTime(2026, 6, 28, 10, 36),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000006',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      eventType: MemoryEventType.caseOpened,
      actorType: 'system',
      barrierSignalId: '82000000-0000-4000-8000-000000000001',
      caseId: '83000000-0000-4000-8000-000000000001',
      summary:
          'A seeded LGU review case was opened for the reported PUP Mobility Access barrier.',
      metadata: const <String, Object?>{'dimension': 'mobility_access'},
      createdAt: DateTime(2026, 6, 28, 10, 40),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000007',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      eventType: MemoryEventType.caseTriaged,
      actorType: 'lgu',
      actorId: '20000000-0000-4000-8000-000000000002',
      caseId: '83000000-0000-4000-8000-000000000001',
      summary:
          'LGU reviewer acknowledged the PUP Mobility Access case for institutional follow-up.',
      metadata: const <String, Object?>{'dimension': 'mobility_access'},
      createdAt: DateTime(2026, 6, 28, 10, 45),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000008',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      eventType: MemoryEventType.evidenceAdded,
      actorType: 'community_user',
      actorId: '20000000-0000-4000-8000-000000000001',
      observationId: '80000000-0000-4000-8000-000000000004',
      evidenceId: '81000000-0000-4000-8000-000000000002',
      summary:
          'Community evidence reported that LRT 2 Pureza station access may have been unavailable or unclear.',
      metadata: const <String, Object?>{
        'dimension': 'mobility_access',
        'demoRole': 'inspector-ready demo case',
      },
      createdAt: DateTime(2026, 6, 28, 11, 20),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000009',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      eventType: MemoryEventType.aiSignalCreated,
      actorType: 'ai_copilot',
      evidenceId: '81000000-0000-4000-8000-000000000002',
      barrierSignalId: '82000000-0000-4000-8000-000000000002',
      summary:
          'AI structured the LRT 2 Pureza report into an advisory signal for human review.',
      metadata: const <String, Object?>{
        'dimension': 'mobility_access',
        'officialVerification': false,
      },
      createdAt: DateTime(2026, 6, 28, 11, 21),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000010',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      eventType: MemoryEventType.caseOpened,
      actorType: 'system',
      barrierSignalId: '82000000-0000-4000-8000-000000000002',
      caseId: '83000000-0000-4000-8000-000000000002',
      summary:
          'A seeded LGU review case was opened for the reported LRT 2 Pureza station access issue.',
      metadata: const <String, Object?>{'dimension': 'mobility_access'},
      createdAt: DateTime(2026, 6, 28, 11, 25),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000011',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      eventType: MemoryEventType.inspectionRequested,
      actorType: 'lgu',
      actorId: '20000000-0000-4000-8000-000000000002',
      caseId: '83000000-0000-4000-8000-000000000002',
      summary:
          'LGU reviewer requested inspector verification for the LRT 2 Pureza station access case.',
      metadata: const <String, Object?>{'dimension': 'mobility_access'},
      createdAt: DateTime(2026, 6, 28, 11, 30),
    ),
  ];
}
