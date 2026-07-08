class PlaceAutofillResult {
  const PlaceAutofillResult({
    this.name,
    this.address,
    this.city,
    this.barangay,
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final String? name;
  final String? address;
  final String? city;
  final String? barangay;
  final double latitude;
  final double longitude;
  final String source;
}

abstract class PlaceAutofillService {
  Future<PlaceAutofillResult> autofillFromCoordinates({
    required double latitude,
    required double longitude,
  });
}

class FallbackPlaceAutofillService implements PlaceAutofillService {
  const FallbackPlaceAutofillService();

  @override
  Future<PlaceAutofillResult> autofillFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (_isNearPupArea(latitude: latitude, longitude: longitude)) {
      return PlaceAutofillResult(
        address:
            'Near PUP / Teresa Street, Sta. Mesa, Manila (${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})',
        city: 'Manila',
        barangay: 'Santa Mesa',
        latitude: latitude,
        longitude: longitude,
        source: 'fallback_demo_area',
      );
    }

    return PlaceAutofillResult(
      latitude: latitude,
      longitude: longitude,
      source: 'fallback_coordinates_only',
    );
  }

  bool _isNearPupArea({required double latitude, required double longitude}) {
    return latitude >= 14.59 &&
        latitude <= 14.61 &&
        longitude >= 121.00 &&
        longitude <= 121.025;
  }
}
