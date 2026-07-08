import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPlaceForm extends StatelessWidget {
  const AddPlaceForm({
    required this.formKey,
    required this.nameController,
    required this.addressController,
    required this.cityController,
    required this.noteController,
    required this.latitudeController,
    required this.longitudeController,
    required this.placeType,
    required this.onPlaceTypeChanged,
    required this.isSubmitting,
    this.locationPicker,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController noteController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final String placeType;
  final ValueChanged<String?> onPlaceTypeChanged;
  final bool isSubmitting;
  final Widget? locationPicker;

  static const Map<String, String> placeTypeLabels = <String, String>{
    'public_service_building': 'Public service building',
    'city_hall': 'City hall o munisipyo',
    'school': 'School',
    'hospital': 'Hospital o clinic',
    'transport_hub': 'Terminal o transport hub',
    'other_public_place': 'Iba pang public place',
  };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Pangalan ng lugar'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ilagay ang pangalan ng lugar';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: placeType,
            decoration: const InputDecoration(labelText: 'Uri ng lugar'),
            items: placeTypeLabels.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(growable: false),
            onChanged: isSubmitting ? null : onPlaceTypeChanged,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: addressController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Address o landmark'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: cityController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'City o municipality'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ilagay ang city o municipality';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: noteController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ano ang alam mo tungkol sa lugar na ito?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          if (locationPicker != null) ...[
            locationPicker!,
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xffedf4f0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffd7e4dc)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasyon muna',
                  style: GoogleFonts.afacad(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff17201c),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pwede mong i-adjust ang coordinates dito kung gusto mong mas eksakto ang lokasyon.',
                  style: GoogleFonts.afacad(
                    fontSize: 14,
                    color: const Color(0xff5d6b63),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        validator: (value) =>
                            _validateCoordinate(value, 'latitude'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        validator: (value) =>
                            _validateCoordinate(value, 'longitude'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _validateCoordinate(String? value, String label) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Ilagay ang $label';
    }
    if (double.tryParse(normalized) == null) {
      return 'Hindi valid ang $label';
    }
    return null;
  }
}
