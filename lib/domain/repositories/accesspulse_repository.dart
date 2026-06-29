import '../models/accesspulse_models.dart';

abstract class AccessPulseRepository {
  Future<List<Place>> listPlaces();

  Future<List<AccessibilityDimension>> listDimensions();

  Future<PlaceDimension> getPlaceDimension(String placeDimensionId);

  Future<PlaceDimension> getPlaceDimensionForPlace({
    required String placeId,
    required String dimensionKey,
  });

  Future<DimensionStateRecord> getDimensionState(String placeDimensionId);

  Future<void> saveDimensionState(DimensionStateRecord state);

  Future<DimensionPulseRecord> getDimensionPulse(String placeDimensionId);

  Future<void> saveDimensionPulse(DimensionPulseRecord pulse);

  Future<List<Observation>> listObservations(String placeDimensionId);

  Future<Observation> addObservation(Observation observation);

  Future<Evidence> addEvidence(Evidence evidence);

  Future<BarrierSignal> addBarrierSignal(BarrierSignal signal);

  Future<AccessCase> addCase(AccessCase accessCase);

  Future<AccessCase> getCase(String caseId);

  Future<List<AccessCase>> listCases({CaseStatus? status});

  Future<void> saveCase(AccessCase accessCase);

  Future<Verification> addVerification(Verification verification);

  Future<List<Verification>> listVerifications(String placeDimensionId);

  Future<void> appendMemoryEvent(MemoryEvent event);

  Future<List<MemoryEvent>> listMemoryEvents(String placeDimensionId);
}
