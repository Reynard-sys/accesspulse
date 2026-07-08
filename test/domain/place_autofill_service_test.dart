import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback service preserves coordinates', () async {
    const service = FallbackPlaceAutofillService();

    final result = await service.autofillFromCoordinates(
      latitude: 14.7,
      longitude: 121.1,
    );

    expect(result.latitude, 14.7);
    expect(result.longitude, 121.1);
    expect(result.name, isNull);
    expect(result.address, isNull);
    expect(result.city, isNull);
    expect(result.barangay, isNull);
    expect(result.source, 'fallback_coordinates_only');
  });

  test('fallback service infers Manila and Santa Mesa near PUP', () async {
    const service = FallbackPlaceAutofillService();

    final result = await service.autofillFromCoordinates(
      latitude: 14.5979,
      longitude: 121.0108,
    );

    expect(result.latitude, 14.5979);
    expect(result.longitude, 121.0108);
    expect(result.city, 'Manila');
    expect(result.barangay, 'Santa Mesa');
    expect(result.address, contains('Sta. Mesa, Manila'));
    expect(result.source, 'fallback_demo_area');
  });
}
