import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/features/public/place_filtering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded PUP cluster has city and barangay metadata', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final places = await repository.listPlaces();

    expect(
      places.map((place) => place.name),
      containsAll(<String>[
        'Polytechnic University of the Philippines',
        'LRT 2 Pureza',
        'LRT 2 V. Mapa',
        'Teresa Street',
      ]),
    );
    expect(places.every((place) => place.city.trim().isNotEmpty), isTrue);
    expect(places.every((place) => place.barangay.trim().isNotEmpty), isTrue);
  });

  test('city and barangay options are generated from visible places', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final places = await repository.listPlaces();

    expect(getCityOptions(places), <String>['All', 'Manila']);
    expect(getBarangayOptions(places, 'Manila'), <String>['All', 'Santa Mesa']);
  });

  test('filters by Manila and Santa Mesa while combining search', () async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final places = await repository.listPlaces();

    final pupAreaPlaces = getVisiblePlaces(
      places: places,
      selectedCity: ' Manila ',
      selectedBarangay: ' santa mesa ',
      searchQuery: '',
    );
    expect(pupAreaPlaces, hasLength(4));

    final stationPlaces = getVisiblePlaces(
      places: places,
      selectedCity: 'Manila',
      selectedBarangay: 'Santa Mesa',
      searchQuery: 'lrt',
    );
    expect(stationPlaces.map((place) => place.name), <String>[
      'LRT 2 Pureza',
      'LRT 2 V. Mapa',
    ]);
  });
}
