import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/accesspulse_domain.dart';
import '../../shared/copy/accesspulse_copy.dart';
import 'add_place_form.dart';
import 'map_place_picker.dart';

class AddPlaceFlowResult {
  const AddPlaceFlowResult({required this.place, this.bannerMessage});

  final Place place;
  final String? bannerMessage;
}

class AddPlaceFlowScreen extends StatefulWidget {
  const AddPlaceFlowScreen({required this.repository, super.key});

  final AccessPulseRepository repository;

  @override
  State<AddPlaceFlowScreen> createState() => _AddPlaceFlowScreenState();
}

class _AddPlaceFlowScreenState extends State<AddPlaceFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _noteController = TextEditingController();
  final _latitudeController = TextEditingController(text: '14.6760');
  final _longitudeController = TextEditingController(text: '121.0437');

  var _selectedPlaceType = 'public_service_building';
  var _isSubmitting = false;

  void _setSelectedLocation(double latitude, double longitude) {
    setState(() {
      _latitudeController.text = latitude.toStringAsFixed(6);
      _longitudeController.text = longitude.toStringAsFixed(6);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _noteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());
    final service = PlaceCreationService(repository: widget.repository);

    setState(() => _isSubmitting = true);
    try {
      final duplicate = await service.findPossibleDuplicate(
        name: _nameController.text,
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) {
        return;
      }

      if (duplicate != null) {
        final action = await showDialog<_DuplicateAction>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Mukhang may kapareho na'),
              content: Text(
                'Mukhang nasa listahan na ito. Buksan na lang ang existing place?\n\n${duplicate.place.name}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(_DuplicateAction.continueAdding);
                  },
                  child: const Text('Ituloy pa rin'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_DuplicateAction.openExisting);
                  },
                  child: const Text('Buksan'),
                ),
              ],
            );
          },
        );

        if (!mounted) {
          return;
        }
        if (action == _DuplicateAction.openExisting) {
          Navigator.of(context).pop(AddPlaceFlowResult(place: duplicate.place));
          return;
        }
      }

      final creation = await service.createPublicPlace(
        name: _nameController.text,
        city: _cityController.text,
        latitude: latitude,
        longitude: longitude,
        addressOrLandmark: _addressController.text,
        placeType: _selectedPlaceType,
        note: _noteController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        AddPlaceFlowResult(
          place: creation.place,
          bannerMessage: AccessPulseCopy.addPlaceSuccess,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AccessPulseCopy.addPlaceTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: FutureBuilder<List<Place>>(
              future: widget.repository.listPlaces(),
              builder: (context, snapshot) {
                final places = snapshot.data ?? const <Place>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    Text(
                      AccessPulseCopy.addPlaceTitle,
                      style: GoogleFonts.afacad(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff17201c),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AccessPulseCopy.addPlaceSubtitle,
                      style: GoogleFonts.afacad(
                        fontSize: 16,
                        color: const Color(0xff5d6b63),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AddPlaceForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      addressController: _addressController,
                      cityController: _cityController,
                      noteController: _noteController,
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      placeType: _selectedPlaceType,
                      onPlaceTypeChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPlaceType = value);
                        }
                      },
                      isSubmitting: _isSubmitting,
                      locationPicker: MapPlacePicker(
                        places: places,
                        latitude:
                            double.tryParse(_latitudeController.text.trim()) ??
                            14.6760,
                        longitude:
                            double.tryParse(_longitudeController.text.trim()) ??
                            121.0437,
                        onLocationSelected: _setSelectedLocation,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_location_alt_outlined),
                      label: Text(
                        _isSubmitting
                            ? 'Sine-save...'
                            : AccessPulseCopy.saveAndOpenPlace,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _DuplicateAction { continueAdding, openExisting }
