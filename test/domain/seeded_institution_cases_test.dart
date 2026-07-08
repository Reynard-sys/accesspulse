import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pupPlaceId = '40000000-0000-4000-8000-000000000001';
  const lrtPurezaPlaceId = '40000000-0000-4000-8000-000000000002';
  const pupPlaceDimensionId = '50000000-0000-4000-8000-000000000001';
  const lrtPurezaPlaceDimensionId = '50000000-0000-4000-8000-000000000002';

  test('seeded institutional cases are ready on startup', () async {
    final repository = InMemoryAccessPulseRepository.seeded();

    final places = await repository.listPlaces();
    final cases = await repository.listCases();
    final pupCase = cases.singleWhere(
      (accessCase) => accessCase.placeDimensionId == pupPlaceDimensionId,
    );
    final lrtPurezaCase = cases.singleWhere(
      (accessCase) => accessCase.placeDimensionId == lrtPurezaPlaceDimensionId,
    );

    expect(
      places.singleWhere((place) => place.id == pupPlaceId).name,
      'Polytechnic University of the Philippines',
    );
    expect(
      places.singleWhere((place) => place.id == lrtPurezaPlaceId).name,
      'LRT 2 Pureza',
    );
    expect(pupCase.status, CaseStatus.triaging);
    expect(lrtPurezaCase.status, CaseStatus.inspectionRequested);
    expect(
      cases.where((accessCase) => accessCase.status != CaseStatus.closed),
      isNotEmpty,
    );
    expect(
      cases.where(
        (accessCase) => accessCase.status == CaseStatus.inspectionRequested,
      ),
      isNotEmpty,
    );
  });

  test('seeded cases include evidence, AI signal, and memory', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final cases = await repository.listCases();

    for (final placeDimensionId in <String>[
      pupPlaceDimensionId,
      lrtPurezaPlaceDimensionId,
    ]) {
      final accessCase = cases.singleWhere(
        (accessCase) => accessCase.placeDimensionId == placeDimensionId,
      );
      final signal = await repository.getBarrierSignal(
        accessCase.barrierSignalId!,
      );
      final evidence = await repository.getEvidence(signal.evidenceId!);
      final memory = await repository.listMemoryEvents(placeDimensionId);

      expect(signal.aiExplanation['officialVerification'], isNot(true));
      expect(evidence.note, isNotNull);
      expect(
        memory.map((event) => event.eventType),
        containsAll(<MemoryEventType>[
          MemoryEventType.evidenceAdded,
          MemoryEventType.aiSignalCreated,
          MemoryEventType.caseOpened,
        ]),
      );
    }
  });
}
