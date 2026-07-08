import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates place with mobility access state, pulse, and memory', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = PlaceCreationService(
      repository: repository,
      idFactory: _deterministicIds(),
    );

    final result = await service.createPublicPlace(
      name: 'Barangay Hall Annex Entrance',
      city: 'Quezon City',
      latitude: 14.6512,
      longitude: 121.0514,
      addressOrLandmark: 'Near the public plaza',
      note: 'Newly added by community contributor.',
      now: DateTime(2026, 7, 8, 9),
    );

    final places = await repository.listPlaces();
    final savedDimension = await repository.getPlaceDimension(
      result.placeDimension.id,
    );
    final savedState = await repository.getDimensionState(
      result.placeDimension.id,
    );
    final savedPulse = await repository.getDimensionPulse(
      result.placeDimension.id,
    );
    final memory = await repository.listMemoryEvents(result.placeDimension.id);

    expect(places, hasLength(5));
    expect(result.place.name, 'Barangay Hall Annex Entrance');
    expect(savedDimension.placeId, result.place.id);
    expect(savedState.state, DimensionStateValue.unknown);
    expect(savedState.source, 'place_creation');
    expect(savedPulse.level, DimensionPulseLevel.weak);
    expect(savedPulse.supportingObservationsCount, 0);
    expect(
      memory.map((event) => event.eventType),
      containsAll([MemoryEventType.placeSeeded, MemoryEventType.stateSeeded]),
    );
    expect(
      memory.any(
        (event) =>
            event.summary.contains('not yet enough accessibility information'),
      ),
      isTrue,
    );
  });

  test('rejects missing place name', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = PlaceCreationService(repository: repository);

    expect(
      () => service.createPublicPlace(
        name: '   ',
        city: 'Quezon City',
        latitude: 14.65,
        longitude: 121.05,
      ),
      throwsArgumentError,
    );
  });

  test('rejects missing city', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = PlaceCreationService(repository: repository);

    expect(
      () => service.createPublicPlace(
        name: 'Barangay Hall Annex Entrance',
        city: '   ',
        latitude: 14.65,
        longitude: 121.05,
      ),
      throwsArgumentError,
    );
  });

  test('suggests obvious nearby duplicate', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = PlaceCreationService(repository: repository);

    final duplicate = await service.findPossibleDuplicate(
      name: 'Quezon City Hall Main Entrance',
      latitude: 14.65091,
      longitude: 121.05092,
    );

    expect(duplicate, isNotNull);
    expect(duplicate!.place.name, 'Quezon City Hall Main Entrance');
    expect(duplicate.distanceMeters, lessThan(75));
  });

  test('does not suggest distant place as duplicate', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final service = PlaceCreationService(repository: repository);

    final duplicate = await service.findPossibleDuplicate(
      name: 'Quezon City Hall Main Entrance',
      latitude: 14.5800,
      longitude: 121.0000,
    );

    expect(duplicate, isNull);
  });
}

IdFactory _deterministicIds() {
  var next = 0;
  return (prefix) {
    next += 1;
    return '${prefix}_$next';
  };
}
