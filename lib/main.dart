import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app/accesspulse_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    this.showOnboarding = true,
    this.imagePickerOverride,
    super.key,
  });

  final bool showOnboarding;
  final Future<XFile?> Function(ImageSource source, int? imageQuality)?
  imagePickerOverride;

  @override
  Widget build(BuildContext context) {
    return AccessPulseApp(
      showOnboarding: showOnboarding,
      imagePickerOverride: imagePickerOverride,
    );
  }
}
