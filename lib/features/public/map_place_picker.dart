import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/maps_config.dart';
import '../../config/maps_web_loader.dart';
import '../../domain/accesspulse_domain.dart';
import '../../shared/copy/accesspulse_copy.dart';

class MapPlacePicker extends StatefulWidget {
  const MapPlacePicker({
    required this.places,
    required this.latitude,
    required this.longitude,
    required this.onLocationSelected,
    this.config = MapsConfig.fromEnvironment,
    super.key,
  });

  final List<Place> places;
  final double latitude;
  final double longitude;
  final void Function(double latitude, double longitude) onLocationSelected;
  final MapsConfig config;

  @override
  State<MapPlacePicker> createState() => _MapPlacePickerState();
}

class _MapPlacePickerState extends State<MapPlacePicker> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.latitude, widget.longitude);
  }

  @override
  void didUpdateWidget(covariant MapPlacePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _selectedLocation = LatLng(widget.latitude, widget.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.shouldRenderMap) {
      return _LocationFallbackCard(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
    }

    return FutureBuilder<void>(
      future: ensureGoogleMapsScriptLoaded(widget.config.webApiKey),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LocationFallbackCard(
            latitude: widget.latitude,
            longitude: widget.longitude,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _MapPickerLoadingCard();
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffdde5e0), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AccessPulseCopy.chooseLocation,
                      style: GoogleFonts.afacad(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff17201c),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AccessPulseCopy.chooseLocationHelp,
                      style: GoogleFonts.afacad(
                        fontSize: 14,
                        color: const Color(0xff5d6b63),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 260,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _defaultCameraTarget(
                      widget.places,
                      _selectedLocation,
                    ),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_place'),
                      position: _selectedLocation,
                    ),
                  },
                  onTap: (position) {
                    setState(() => _selectedLocation = position);
                  },
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Napiling lokasyon: ${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.afacad(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff17201c),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        widget.onLocationSelected(
                          _selectedLocation.latitude,
                          _selectedLocation.longitude,
                        );
                      },
                      icon: const Icon(Icons.place_outlined),
                      label: const Text(AccessPulseCopy.useThisLocation),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LatLng _defaultCameraTarget(List<Place> places, LatLng fallback) {
    for (final place in places) {
      if (place.latitude != null && place.longitude != null) {
        return LatLng(place.latitude!, place.longitude!);
      }
    }
    return fallback;
  }
}

class _MapPickerLoadingCard extends StatelessWidget {
  const _MapPickerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffdde5e0), width: 1.2),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LocationFallbackCard extends StatelessWidget {
  const _LocationFallbackCard({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffedf4f0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd7e4dc)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AccessPulseCopy.chooseLocation,
            style: GoogleFonts.afacad(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xff17201c),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AccessPulseCopy.mapUnavailable,
            style: GoogleFonts.afacad(
              fontSize: 14,
              color: const Color(0xff5d6b63),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pwede mong i-edit sa ibaba ang coordinates kung alam mo ang lokasyon.',
            style: GoogleFonts.afacad(
              fontSize: 14,
              color: const Color(0xff5d6b63),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kasalukuyang demo pin: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
            style: GoogleFonts.afacad(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff17201c),
            ),
          ),
        ],
      ),
    );
  }
}
