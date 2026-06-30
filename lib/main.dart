import 'package:flutter/material.dart';

import 'app/accesspulse_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    this.showOnboarding = true,
    super.key,
  });

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return AccessPulseApp(showOnboarding: showOnboarding);
  }
}
