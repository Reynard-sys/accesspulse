import '../domain/models/accesspulse_models.dart';
import '../domain/repositories/accesspulse_repository.dart';
import 'accesspulse_seed_data.dart';

class InMemoryAccessPulseRepository implements AccessPulseRepository {
  InMemoryAccessPulseRepository.seeded()
    : _places = {for (final place in seedPlaces) place.id: place},
      _dimensions = {
        for (final dimension in seedDimensions) dimension.id: dimension,
      },
      _placeDimensions = {
        for (final placeDimension in seedPlaceDimensions)
          placeDimension.id: placeDimension,
      },
      _states = {
        for (final state in buildSeedDimensionStates())
          state.placeDimensionId: state,
      },
      _pulses = {
        for (final pulse in buildSeedDimensionPulses())
          pulse.placeDimensionId: pulse,
      },
      _observations = {
        for (final observation in buildSeedObservations())
          observation.id: observation,
      },
      _memoryEvents = buildSeedMemoryEvents();

  InMemoryAccessPulseRepository.empty()
    : _places = <String, Place>{},
      _dimensions = <String, AccessibilityDimension>{},
      _placeDimensions = <String, PlaceDimension>{},
      _states = <String, DimensionStateRecord>{},
      _pulses = <String, DimensionPulseRecord>{},
      _observations = <String, Observation>{},
      _memoryEvents = <MemoryEvent>[];

  final Map<String, Place> _places;
  final Map<String, AccessibilityDimension> _dimensions;
  final Map<String, PlaceDimension> _placeDimensions;
  final Map<String, DimensionStateRecord> _states;
  final Map<String, DimensionPulseRecord> _pulses;
  final Map<String, Observation> _observations;
  final Map<String, Evidence> _evidence = <String, Evidence>{};
  final Map<String, RampMeasurement> _rampMeasurements =
      <String, RampMeasurement>{};
  final Map<String, BarrierSignal> _signals = <String, BarrierSignal>{};
  final Map<String, AccessCase> _cases = <String, AccessCase>{};
  final Map<String, Verification> _verifications = <String, Verification>{};
  final List<MemoryEvent> _memoryEvents;

  @override
  Future<List<Place>> listPlaces() async {
    return _places.values.toList(growable: false);
  }

  @override
  Future<List<AccessibilityDimension>> listDimensions() async {
    return _dimensions.values.toList(growable: false);
  }

  @override
  Future<PlaceDimension> getPlaceDimension(String placeDimensionId) async {
    final placeDimension = _placeDimensions[placeDimensionId];
    if (placeDimension == null) {
      throw StateError('No place dimension found for $placeDimensionId.');
    }
    return placeDimension;
  }

  @override
  Future<PlaceDimension> getPlaceDimensionForPlace({
    required String placeId,
    required String dimensionKey,
  }) async {
    final dimension = _dimensions.values.where(
      (dimension) => dimension.key == dimensionKey,
    );
    if (dimension.isEmpty) {
      throw StateError('No dimension found for $dimensionKey.');
    }

    final placeDimension = _placeDimensions.values.where(
      (placeDimension) =>
          placeDimension.placeId == placeId &&
          placeDimension.dimensionId == dimension.single.id,
    );
    if (placeDimension.isEmpty) {
      throw StateError(
        'No place dimension found for $placeId and $dimensionKey.',
      );
    }
    return placeDimension.single;
  }

  @override
  Future<DimensionStateRecord> getDimensionState(
    String placeDimensionId,
  ) async {
    final state = _states[placeDimensionId];
    if (state == null) {
      throw StateError('No dimension state found for $placeDimensionId.');
    }
    return state;
  }

  @override
  Future<void> saveDimensionState(DimensionStateRecord state) async {
    _states[state.placeDimensionId] = state;
  }

  @override
  Future<DimensionPulseRecord> getDimensionPulse(
    String placeDimensionId,
  ) async {
    final pulse = _pulses[placeDimensionId];
    if (pulse == null) {
      throw StateError('No dimension pulse found for $placeDimensionId.');
    }
    return pulse;
  }

  @override
  Future<void> saveDimensionPulse(DimensionPulseRecord pulse) async {
    _pulses[pulse.placeDimensionId] = pulse;
  }

  @override
  Future<List<Observation>> listObservations(String placeDimensionId) async {
    final observations =
        _observations.values
            .where(
              (observation) => observation.placeDimensionId == placeDimensionId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return observations;
  }

  @override
  Future<Observation> addObservation(Observation observation) async {
    _observations[observation.id] = observation;
    return observation;
  }

  @override
  Future<Evidence> addEvidence(Evidence evidence) async {
    _evidence[evidence.id] = evidence;
    return evidence;
  }

  @override
  Future<Evidence> getEvidence(String evidenceId) async {
    final evidence = _evidence[evidenceId];
    if (evidence == null) {
      throw StateError('No evidence found for $evidenceId.');
    }
    return evidence;
  }

  @override
  Future<RampMeasurement> addRampMeasurement(
    RampMeasurement measurement,
  ) async {
    _rampMeasurements[measurement.id] = measurement;
    return measurement;
  }

  @override
  Future<RampMeasurement?> getRampMeasurementForEvidence(
    String evidenceId,
  ) async {
    for (final measurement in _rampMeasurements.values) {
      if (measurement.evidenceId == evidenceId) {
        return measurement;
      }
    }
    return null;
  }

  @override
  Future<List<RampMeasurement>> listRampMeasurements(
    String placeDimensionId,
  ) async {
    final measurements =
        _rampMeasurements.values
            .where(
              (measurement) => measurement.placeDimensionId == placeDimensionId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return measurements;
  }

  @override
  Future<BarrierSignal> addBarrierSignal(BarrierSignal signal) async {
    _signals[signal.id] = signal;
    return signal;
  }

  @override
  Future<BarrierSignal> getBarrierSignal(String signalId) async {
    final signal = _signals[signalId];
    if (signal == null) {
      throw StateError('No barrier signal found for $signalId.');
    }
    return signal;
  }

  @override
  Future<AccessCase> addCase(AccessCase accessCase) async {
    _cases[accessCase.id] = accessCase;
    return accessCase;
  }

  @override
  Future<AccessCase> getCase(String caseId) async {
    final accessCase = _cases[caseId];
    if (accessCase == null) {
      throw StateError('No case found for $caseId.');
    }
    return accessCase;
  }

  @override
  Future<List<AccessCase>> listCases({CaseStatus? status}) async {
    final cases =
        _cases.values
            .where(
              (accessCase) => status == null || accessCase.status == status,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return cases;
  }

  @override
  Future<void> saveCase(AccessCase accessCase) async {
    _cases[accessCase.id] = accessCase;
  }

  @override
  Future<Verification> addVerification(Verification verification) async {
    _verifications[verification.id] = verification;
    return verification;
  }

  @override
  Future<List<Verification>> listVerifications(String placeDimensionId) async {
    final verifications =
        _verifications.values
            .where(
              (verification) =>
                  verification.placeDimensionId == placeDimensionId,
            )
            .toList()
          ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return verifications;
  }

  @override
  Future<void> appendMemoryEvent(MemoryEvent event) async {
    _memoryEvents.add(event);
  }

  @override
  Future<List<MemoryEvent>> listMemoryEvents(String placeDimensionId) async {
    final events =
        _memoryEvents
            .where((event) => event.placeDimensionId == placeDimensionId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }
}
