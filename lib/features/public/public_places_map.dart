import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/maps_config.dart';
import '../../config/maps_web_loader.dart';
import '../../domain/accesspulse_domain.dart';
import '../../shared/copy/accesspulse_copy.dart';

class PublicPlacesMap extends StatelessWidget {
  const PublicPlacesMap({
    required this.places,
    required this.onPlaceSelected,
    this.config = MapsConfig.fromEnvironment,
    super.key,
  });

  final List<Place> places;
  final ValueChanged<Place> onPlaceSelected;
  final MapsConfig config;

  @override
  Widget build(BuildContext context) {
    final mappedPlaces = places
        .where((place) => place.latitude != null && place.longitude != null)
        .toList(growable: false);

    if (mappedPlaces.isEmpty) {
      return _MapMessageCard(
        title: 'Wala pang lokasyon sa mapa',
        message:
            'Pwede ka pa ring pumili sa listahan habang inaayos ang lokasyon ng mga lugar.',
      );
    }

    if (!config.shouldRenderMap) {
      return const _MapMessageCard(
        title: 'Map preview unavailable',
        message: AccessPulseCopy.mapUnavailable,
      );
    }

    final initialPlace = mappedPlaces.first;
    final markers = mappedPlaces
        .map(
          (place) => Marker(
            markerId: MarkerId(place.id),
            position: LatLng(place.latitude!, place.longitude!),
            infoWindow: InfoWindow(title: place.name),
            onTap: () => onPlaceSelected(place),
          ),
        )
        .toSet();

    return FutureBuilder<void>(
      future: ensureGoogleMapsScriptLoaded(config.webApiKey),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _MapMessageCard(
            title: 'Map preview unavailable',
            message: AccessPulseCopy.mapUnavailable,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _MapLoadingCard();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(initialPlace.latitude!, initialPlace.longitude!),
                zoom: 13.2,
              ),
              markers: markers,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),
          ),
        );
      },
    );
  }
}

class _MapLoadingCard extends StatelessWidget {
  const _MapLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffdde5e0), width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MapMessageCard extends StatelessWidget {
  const _MapMessageCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffdde5e0), width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xffedf4f0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined, color: Color(0xff2e7d5b)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.afacad(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff17201c),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.afacad(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xff5d6b63),
              height: 1.25,
            ),
          ),
          const Spacer(),
          Text(
            AccessPulseCopy.chooseFromMapOrList,
            style: GoogleFonts.afacad(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2e7d5b),
            ),
          ),
        ],
      ),
    );
  }
}
