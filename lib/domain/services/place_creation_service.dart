import 'dart:math' as math;

import '../models/accesspulse_models.dart';
import '../repositories/accesspulse_repository.dart';
import 'dimension_state_service.dart';

class PlaceCreationResult {
  const PlaceCreationResult({
    required this.place,
    required this.placeDimension,
    required this.state,
    required this.pulse,
    required this.memoryEvents,
  });

  final Place place;
  final PlaceDimension placeDimension;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final List<MemoryEvent> memoryEvents;
}

class PlaceDuplicateSuggestion {
  const PlaceDuplicateSuggestion({
    required this.place,
    required this.distanceMeters,
  });

  final Place place;
  final double distanceMeters;
}

class PlaceCreationService {
  PlaceCreationService({
    required AccessPulseRepository repository,
    IdFactory? idFactory,
    this.duplicateRadiusMeters = 75,
  }) : _repository = repository,
       _idFactory = idFactory ?? _timestampId;

  final AccessPulseRepository _repository;
  final IdFactory _idFactory;
  final double duplicateRadiusMeters;

  Future<PlaceCreationResult> createPublicPlace({
    required String name,
    required String city,
    required double latitude,
    required double longitude,
    String? addressOrLandmark,
    String placeType = 'public_service_building',
    String? note,
    DateTime? now,
  }) async {
    final normalizedName = name.trim();
    final normalizedCity = city.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Place name is required.');
    }
    if (normalizedCity.isEmpty) {
      throw ArgumentError.value(city, 'city', 'City is required.');
    }
    if (latitude.isNaN || longitude.isNaN) {
      throw ArgumentError('Coordinates are required.');
    }

    final timestamp = now ?? DateTime.now();
    final dimensions = await _repository.listDimensions();
    final mobilityDimension = dimensions.firstWhere(
      (dimension) => dimension.key == 'mobility_access',
      orElse: () => throw StateError(
        'Mobility access dimension is required before creating a place.',
      ),
    );

    final place = Place(
      id: _idFactory('place'),
      name: normalizedName,
      placeType: placeType,
      address: _trimOrNull(addressOrLandmark),
      municipality: normalizedCity,
      latitude: latitude,
      longitude: longitude,
    );
    await _repository.addPlace(place);

    final placeDimension = PlaceDimension(
      id: _idFactory('place_dimension'),
      placeId: place.id,
      dimensionId: mobilityDimension.id,
      summary:
          'Mobility Access state for a newly added place. Public information is still limited.',
    );
    await _repository.addPlaceDimension(placeDimension);

    final state = DimensionStateRecord(
      id: _idFactory('dimension_state'),
      placeDimensionId: placeDimension.id,
      state: DimensionStateValue.unknown,
      confidence: 0.18,
      explanation:
          'This place was newly added, so there is not yet enough accessibility information.',
      source: 'place_creation',
      updatedAt: timestamp,
    );
    await _repository.saveDimensionState(state);

    final pulse = DimensionPulseRecord(
      id: _idFactory('dimension_pulse'),
      placeDimensionId: placeDimension.id,
      level: DimensionPulseLevel.weak,
      score: 0.12,
      supportingObservationsCount: 0,
      hasRecentVerification: false,
      contradictionFlag: false,
      lastCalculatedAt: timestamp,
      explanation:
          'No visit confirmations or human verification are available yet for this place.',
    );
    await _repository.saveDimensionPulse(pulse);

    final trimmedNote = _trimOrNull(note);
    final placeMemoryMetadata = <String, Object?>{
      'placeId': place.id,
      'dimension': 'mobility_access',
    };
    if (trimmedNote != null) {
      placeMemoryMetadata['note'] = trimmedNote;
    }

    final memoryEvents = <MemoryEvent>[
      MemoryEvent(
        id: _idFactory('memory_event'),
        placeDimensionId: placeDimension.id,
        eventType: MemoryEventType.placeSeeded,
        actorType: 'community_user',
        summary:
            'A community contributor added this place to AccessPulse for future accessibility updates.',
        metadata: placeMemoryMetadata,
        createdAt: timestamp,
      ),
      MemoryEvent(
        id: _idFactory('memory_event'),
        placeDimensionId: placeDimension.id,
        eventType: MemoryEventType.stateSeeded,
        actorType: 'system',
        newState: state.state,
        newPulse: pulse.level,
        summary:
            'Mobility Access starts as unknown because there is not yet enough accessibility information for this place.',
        metadata: const <String, Object?>{
          'dimension': 'mobility_access',
          'reason': 'new_place',
        },
        createdAt: timestamp,
      ),
    ];

    for (final event in memoryEvents) {
      await _repository.appendMemoryEvent(event);
    }

    return PlaceCreationResult(
      place: place,
      placeDimension: placeDimension,
      state: state,
      pulse: pulse,
      memoryEvents: memoryEvents,
    );
  }

  Future<PlaceDuplicateSuggestion?> findPossibleDuplicate({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      return null;
    }

    final places = await _repository.listPlaces();
    PlaceDuplicateSuggestion? nearestSuggestion;
    for (final place in places) {
      final placeLatitude = place.latitude;
      final placeLongitude = place.longitude;
      if (placeLatitude == null || placeLongitude == null) {
        continue;
      }
      if (!_isSimilarName(normalizedName, _normalizeName(place.name))) {
        continue;
      }

      final distanceMeters = _distanceMeters(
        latitude,
        longitude,
        placeLatitude,
        placeLongitude,
      );
      if (distanceMeters > duplicateRadiusMeters) {
        continue;
      }
      if (nearestSuggestion == null ||
          distanceMeters < nearestSuggestion.distanceMeters) {
        nearestSuggestion = PlaceDuplicateSuggestion(
          place: place,
          distanceMeters: distanceMeters,
        );
      }
    }
    return nearestSuggestion;
  }

  bool _isSimilarName(String candidate, String existing) {
    return candidate == existing ||
        candidate.contains(existing) ||
        existing.contains(candidate);
  }

  String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _distanceMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(endLatitude - startLatitude);
    final longitudeDelta = _toRadians(endLongitude - startLongitude);
    final startLatitudeRadians = _toRadians(startLatitude);
    final endLatitudeRadians = _toRadians(endLatitude);
    final haversine =
        _sinSquared(latitudeDelta / 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            _sinSquared(longitudeDelta / 2);
    final angularDistance =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusMeters * angularDistance;
  }

  double _toRadians(double degrees) => degrees * 0.017453292519943295;

  double _sinSquared(double value) {
    final sine = math.sin(value);
    return sine * sine;
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String _timestampId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
