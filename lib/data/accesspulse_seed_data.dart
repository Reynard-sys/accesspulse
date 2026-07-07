import '../domain/models/accesspulse_models.dart';

final seedGeneratedAt = DateTime(2026, 6, 29, 21, 30);

const seedOrganizations = <Organization>[
  Organization(
    id: '10000000-0000-4000-8000-000000000001',
    name: 'Quezon City Accessibility Desk',
    organizationType: 'lgu',
    jurisdiction: 'Quezon City',
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
    name: 'Quezon City Hall Main Entrance',
    placeType: 'public_service_building',
    address: 'Elliptical Road, Diliman',
    municipality: 'Quezon City',
    province: 'Metro Manila',
    latitude: 14.6509,
    longitude: 121.0509,
  ),
  Place(
    id: '40000000-0000-4000-8000-000000000002',
    name: 'Philippine General Hospital North Entrance',
    placeType: 'Hospital',
    address: 'Taft Ave, Ermita, Manila',
    municipality: 'Manila',
    province: 'Metro Manila',
    latitude: 14.6413,
    longitude: 121.0487,
  ),
  Place(
    id: '40000000-0000-4000-8000-000000000003',
    name: 'LRT-1 Central Station',
    placeType: 'Transport Hub',
    address: 'Carriedo St, Santa Cruz, Manila',
    municipality: 'Santa Cruz',
    province: 'Metro Manila',
    latitude: 14.6861,
    longitude: 121.0862,
  ),
  Place(
    id: '40000000-0000-4000-8000-000000000004',
    name: 'Marikina City Hall',
    placeType: 'Government Office',
    address: 'J.P. Rizal St, Marikina City',
    municipality: 'Marikina City',
    province: 'Metro Manila',
    latitude: 14.6300,
    longitude: 121.0980,
  ),
];

const seedPlaceDimensions = <PlaceDimension>[
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000001',
    placeId: '40000000-0000-4000-8000-000000000001',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary:
        'Mobility Access state for the main public entrance. Seeded as claimed accessible but stale for the demo.',
  ),
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000002',
    placeId: '40000000-0000-4000-8000-000000000002',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary: 'Mobility Access state for the hospital main entrance.',
  ),
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000003',
    placeId: '40000000-0000-4000-8000-000000000003',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary: 'Mobility Access state for the terminal entrance.',
  ),
  PlaceDimension(
    id: '50000000-0000-4000-8000-000000000004',
    placeId: '40000000-0000-4000-8000-000000000004',
    dimensionId: '30000000-0000-4000-8000-000000000001',
    summary: 'Mobility Access state for the Marikina City Hall.',
  ),
];

List<DimensionStateRecord> buildSeedDimensionStates() {
  return <DimensionStateRecord>[
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000001',
      placeDimensionId: '50000000-0000-4000-8000-000000000001',
      state: DimensionStateValue.claimedAccessible,
      confidence: 0.58,
      explanation:
          'Existing public record claims entrance access, but the confirmation is old and should be refreshed.',
      lastConfirmedAt: DateTime(2026, 4, 15, 9),
      source: 'seed_public_record',
      updatedAt: seedGeneratedAt,
    ),
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      state: DimensionStateValue.reliable,
      confidence: 0.76,
      explanation:
          'Recent community confirmations support independent entrance access.',
      lastConfirmedAt: DateTime.now().subtract(const Duration(days: 3)),
      source: 'seed_community_confirmation',
      updatedAt: seedGeneratedAt,
    ),
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000003',
      placeDimensionId: '50000000-0000-4000-8000-000000000003',
      state: DimensionStateValue.degraded,
      confidence: 0.24,
      explanation:
          'The system does not currently know enough about independent wheelchair access at this entrance.',
      lastConfirmedAt: DateTime.now().subtract(const Duration(days: 18)),
      source: 'seed_unknown',
      updatedAt: seedGeneratedAt,
    ),
    DimensionStateRecord(
      id: '60000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000004',
      state: DimensionStateValue.reliable,
      confidence: 0.85,
      explanation: 'Official access audit confirmed wheelchair usability.',
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
      score: 0.52,
      supportingObservationsCount: 1,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation:
          'Knowledge is still usable for the demo, but the last confirmation is old enough to invite a fresh visit update.',
    ),
    DimensionPulseRecord(
      id: '70000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      level: DimensionPulseLevel.strong,
      score: 0.92,
      supportingObservationsCount: 3,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation:
          'Recent supporting confirmations make this current Mobility Access knowledge relatively fresh.',
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
          'No recent supporting observations are available, so this place needs community confirmation.',
    ),
    DimensionPulseRecord(
      id: '70000000-0000-4000-8000-000000000004',
      placeDimensionId: '50000000-0000-4000-8000-000000000004',
      level: DimensionPulseLevel.moderate,
      score: 0.65,
      supportingObservationsCount: 2,
      hasRecentVerification: true,
      contradictionFlag: false,
      lastCalculatedAt: seedGeneratedAt,
      explanation: 'The initial verification is strong, but there are no recent community visit reports.',
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
          'Seeded old confirmation: entrance was reported usable independently at the time.',
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
          'Seeded recent confirmation: ramp and entrance were usable independently.',
      outcome: ObservationOutcome.positive,
      createdAt: DateTime(2026, 6, 20, 14, 30),
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
      newState: DimensionStateValue.claimedAccessible,
      newPulse: DimensionPulseLevel.moderate,
      observationId: '80000000-0000-4000-8000-000000000001',
      summary:
          'Initial Mobility Access state seeded from an older public record and supporting confirmation.',
      metadata: const <String, Object?>{
        'demoRole': 'stale starting point',
        'dimension': 'mobility_access',
      },
      createdAt: DateTime(2026, 4, 15, 9),
    ),
    MemoryEvent(
      id: '90000000-0000-4000-8000-000000000002',
      placeDimensionId: '50000000-0000-4000-8000-000000000002',
      eventType: MemoryEventType.stateSeeded,
      actorType: 'system',
      newState: DimensionStateValue.reliable,
      newPulse: DimensionPulseLevel.strong,
      observationId: '80000000-0000-4000-8000-000000000002',
      summary:
          'Initial Mobility Access state seeded from recent positive community confirmations.',
      metadata: const <String, Object?>{
        'demoRole': 'comparison reliable place',
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
  ];
}
