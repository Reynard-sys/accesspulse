import '../../domain/accesspulse_domain.dart';

const allPlacesFilterValue = 'All';

List<String> getCityOptions(List<Place> places) {
  final cities =
      places
          .map((place) => place.city.trim())
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return <String>[allPlacesFilterValue, ...cities];
}

List<String> getBarangayOptions(List<Place> places, String selectedCity) {
  final normalizedCity = selectedCity.trim().toLowerCase();
  final source = normalizedCity == allPlacesFilterValue.toLowerCase()
      ? places
      : places.where(
          (place) => place.city.trim().toLowerCase() == normalizedCity,
        );

  final barangays =
      source
          .map((place) => place.barangay.trim())
          .where((barangay) => barangay.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return <String>[allPlacesFilterValue, ...barangays];
}

List<Place> getVisiblePlaces({
  required List<Place> places,
  required String selectedCity,
  required String selectedBarangay,
  required String searchQuery,
}) {
  final city = selectedCity.trim().toLowerCase();
  final barangay = selectedBarangay.trim().toLowerCase();
  final query = searchQuery.trim().toLowerCase();

  return places
      .where((place) {
        final placeCity = place.city.trim().toLowerCase();
        final placeBarangay = place.barangay.trim().toLowerCase();
        final matchesCity =
            city == allPlacesFilterValue.toLowerCase() || placeCity == city;
        final matchesBarangay =
            barangay == allPlacesFilterValue.toLowerCase() ||
            placeBarangay == barangay;
        final matchesSearch =
            query.isEmpty ||
            place.name.toLowerCase().contains(query) ||
            (place.address?.toLowerCase().contains(query) ?? false) ||
            placeCity.contains(query) ||
            placeBarangay.contains(query);

        return matchesCity && matchesBarangay && matchesSearch;
      })
      .toList(growable: false);
}
