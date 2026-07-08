import 'package:flutter/foundation.dart';

class MapsConfig {
  const MapsConfig({
    required this.enableGoogleMaps,
    required this.webApiKey,
    required this.androidApiKey,
    required this.iosApiKey,
  });

  static const fromEnvironment = MapsConfig(
    enableGoogleMaps: bool.fromEnvironment(
      'ACCESSPULSE_ENABLE_GOOGLE_MAPS',
      defaultValue: false,
    ),
    webApiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY_WEB'),
    androidApiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY_ANDROID'),
    iosApiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY_IOS'),
  );

  final bool enableGoogleMaps;
  final String webApiKey;
  final String androidApiKey;
  final String iosApiKey;

  bool get shouldRenderMap {
    if (!enableGoogleMaps) {
      return false;
    }
    if (kIsWeb) {
      return webApiKey.trim().isNotEmpty;
    }
    return true;
  }
}
