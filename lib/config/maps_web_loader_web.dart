// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<void> ensureGoogleMapsScriptLoaded(String apiKey) {
  if (apiKey.trim().isEmpty) {
    return Future.error(
      StateError('GOOGLE_MAPS_API_KEY_WEB is required for Flutter web maps.'),
    );
  }

  final existingLoader = html.document.getElementById(
    'accesspulse-google-maps-loader',
  );
  if (existingLoader != null) {
    return Future.value();
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = 'accesspulse-google-maps-loader'
    ..async = true
    ..defer = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&v=weekly';

  script.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('Google Maps JavaScript API could not load.'),
      );
    }
  });

  script.onLoad.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  html.document.head?.append(script);
  return completer.future;
}
