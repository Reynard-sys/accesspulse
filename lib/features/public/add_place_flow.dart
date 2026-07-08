import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/accesspulse_domain.dart';
import '../../shared/copy/accesspulse_copy.dart';
import 'add_place_form.dart';
import 'map_place_picker.dart';

typedef AddPlaceLocationPickerBuilder =
    Widget Function(
      BuildContext context,
      List<Place> places,
      double latitude,
      double longitude,
      Future<void> Function(double latitude, double longitude) onSelected,
    );

class AddPlaceFlowResult {
  const AddPlaceFlowResult({required this.place, this.bannerMessage});

  final Place place;
  final String? bannerMessage;
}

class AddPlaceFlowScreen extends StatefulWidget {
  const AddPlaceFlowScreen({
    required this.repository,
    this.initialCity,
    this.initialBarangay,
    this.autofillService = const FallbackPlaceAutofillService(),
    this.locationPickerBuilder,
    super.key,
  });

  final AccessPulseRepository repository;
  final String? initialCity;
  final String? initialBarangay;
  final PlaceAutofillService autofillService;
  final AddPlaceLocationPickerBuilder? locationPickerBuilder;

  @override
  State<AddPlaceFlowScreen> createState() => _AddPlaceFlowScreenState();
}

class _AddPlaceFlowScreenState extends State<AddPlaceFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  late final TextEditingController _cityController;
  late final TextEditingController _barangayController;
  final _noteController = TextEditingController();
  final _latitudeController = TextEditingController(text: '14.5979');
  final _longitudeController = TextEditingController(text: '121.0108');

  var _selectedPlaceType = 'public_service_building';
  var _isSubmitting = false;
  var _isAutofilling = false;
  String? _autofillMessage;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _barangayController = TextEditingController(
      text: widget.initialBarangay ?? '',
    );
  }

  Future<void> _setSelectedLocation(double latitude, double longitude) async {
    setState(() {
      _latitudeController.text = latitude.toStringAsFixed(6);
      _longitudeController.text = longitude.toStringAsFixed(6);
      _isAutofilling = true;
      _autofillMessage = 'Kinukuha ang details mula sa mapa...';
    });

    try {
      final result = await widget.autofillService.autofillFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _applyAutofillResult(result);
        _isAutofilling = false;
        _autofillMessage = _hasAutofillText(result)
            ? 'Na-autofill ang ilang details. Pwede mo pa itong i-edit.'
            : 'Hindi nakuha ang details mula sa mapa. Pwede mong i-edit o ilagay manually.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAutofilling = false;
        _autofillMessage =
            'Hindi nakuha ang details mula sa mapa. Pwede mong i-edit o ilagay manually.';
      });
    }
  }

  void _applyAutofillResult(PlaceAutofillResult result) {
    _fillIfEmpty(_nameController, result.name);
    _fillIfEmpty(_addressController, result.address);
    _fillIfEmpty(_cityController, result.city);
    _fillIfEmpty(_barangayController, result.barangay);
    _latitudeController.text = result.latitude.toStringAsFixed(6);
    _longitudeController.text = result.longitude.toStringAsFixed(6);
  }

  void _fillIfEmpty(TextEditingController controller, String? value) {
    final trimmed = value?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        controller.text.trim().isNotEmpty) {
      return;
    }
    controller.text = trimmed;
  }

  bool _hasAutofillText(PlaceAutofillResult result) {
    return <String?>[
      result.name,
      result.address,
      result.city,
      result.barangay,
    ].any((value) => value != null && value.trim().isNotEmpty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _barangayController.dispose();
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
        barangay: _barangayController.text,
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
                final latitude =
                    double.tryParse(_latitudeController.text.trim()) ?? 14.5979;
                final longitude =
                    double.tryParse(_longitudeController.text.trim()) ??
                    121.0108;
                final locationPicker =
                    widget.locationPickerBuilder?.call(
                      context,
                      places,
                      latitude,
                      longitude,
                      _setSelectedLocation,
                    ) ??
                    MapPlacePicker(
                      places: places,
                      latitude: latitude,
                      longitude: longitude,
                      onLocationSelected: _setSelectedLocation,
                    );
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
                      barangayController: _barangayController,
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
                      locationPicker: locationPicker,
                      isAutofilling: _isAutofilling,
                      autofillMessage: _autofillMessage,
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
