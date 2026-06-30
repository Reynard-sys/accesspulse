import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/accesspulse_models.dart';
import 'ramp_slope_capture_service.dart';

abstract class AiEvidenceService {
  Future<AiEvidenceAssessment> analyzeMobilityEvidence({
    required String note,
    String? imagePath,
    RampSlopeMeasurement? rampSlopeMeasurement,
  });
}

class MockAiEvidenceService implements AiEvidenceService {
  const MockAiEvidenceService();

  @override
  Future<AiEvidenceAssessment> analyzeMobilityEvidence({
    required String note,
    String? imagePath,
    RampSlopeMeasurement? rampSlopeMeasurement,
  }) async {
    final lowerNote = note.toLowerCase();
    final mentionsSteps =
        lowerNote.contains('step') || lowerNote.contains('stairs');
    final mentionsRamp = lowerNote.contains('ramp');
    final mentionsAssistance =
        lowerNote.contains('assist') || lowerNote.contains('help');
    final measurement = rampSlopeMeasurement;
    final measurementText = measurement == null
        ? null
        : 'estimated ramp angle ${measurement.estimatedAngleDegrees.toStringAsFixed(1)} degrees';
    final baseConfidence = mentionsSteps || mentionsRamp || mentionsAssistance
        ? 0.82
        : 0.58;

    return AiEvidenceAssessment(
      dimension: 'mobility_access',
      issueType: 'entrance_ramp_usability',
      observedFeatures: <String>[
        'entrance',
        if (mentionsSteps) 'steps',
        if (mentionsRamp) 'ramp',
        if (imagePath != null) 'uploaded photo',
        ?measurementText,
      ],
      possibleBarrier: mentionsAssistance
          ? 'independent wheelchair access may require assistance'
          : 'independent wheelchair access may be unreliable',
      missingEvidence: <String>[
        'full side view of ramp',
        'landing visibility',
        'confirmation whether another accessible entrance exists',
        if (measurement != null) 'official on-site ramp measurement',
      ],
      confidence: measurement == null
          ? baseConfidence
          : (baseConfidence + 0.05).clamp(0.0, 0.9).toDouble(),
      summary: measurement == null
          ? 'The evidence suggests Mobility Access at the entrance may be unreliable, but a human reviewer should confirm the site context.'
          : 'The evidence suggests Mobility Access at the entrance may be unreliable. An estimated ${measurement.estimatedAngleDegrees.toStringAsFixed(1)} degree ramp incline reading with ${measurement.qualityLabel.toLowerCase()} supports the reported concern, but a human reviewer should confirm the site context.',
      recommendedAction: 'lgu_review',
      explanation: measurement == null
          ? 'I can structure visible and described mobility-access signals, but I cannot determine legal compliance or official verification.'
          : 'I can use the estimated incline reading as supporting evidence, but it is not an official measurement and does not determine legal compliance.',
    );
  }
}

class GeminiServerEvidenceService implements AiEvidenceService {
  GeminiServerEvidenceService({
    required Uri functionUri,
    String? supabaseAnonKey,
    http.Client? client,
    AiEvidenceService fallback = const MockAiEvidenceService(),
  }) : _functionUri = functionUri,
       _supabaseAnonKey = supabaseAnonKey,
       _client = client ?? http.Client(),
       _fallback = fallback;

  final Uri _functionUri;
  final String? _supabaseAnonKey;
  final http.Client _client;
  final AiEvidenceService _fallback;

  @override
  Future<AiEvidenceAssessment> analyzeMobilityEvidence({
    required String note,
    String? imagePath,
    RampSlopeMeasurement? rampSlopeMeasurement,
  }) async {
    try {
      final headers = <String, String>{
        'content-type': 'application/json',
        if (_supabaseAnonKey != null && _supabaseAnonKey.trim().isNotEmpty) ...{
          'apikey': _supabaseAnonKey,
          'authorization': 'Bearer $_supabaseAnonKey',
        },
      };
      final response = await _client.post(
        _functionUri,
        headers: headers,
        body: jsonEncode(<String, Object?>{
          'dimension': 'mobility_access',
          'note': note,
          'imagePath': imagePath,
          if (rampSlopeMeasurement != null)
            'rampMeasurement': _rampMeasurementPayload(rampSlopeMeasurement),
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback.analyzeMobilityEvidence(
          note: note,
          imagePath: imagePath,
          rampSlopeMeasurement: rampSlopeMeasurement,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        return _fallback.analyzeMobilityEvidence(
          note: note,
          imagePath: imagePath,
          rampSlopeMeasurement: rampSlopeMeasurement,
        );
      }
      return AiEvidenceAssessment(
        dimension: _stringValue(decoded['dimension'], 'mobility_access'),
        issueType: _stringValue(
          decoded['issueType'],
          'entrance_ramp_usability',
        ),
        observedFeatures: _stringList(decoded['observedFeatures']),
        possibleBarrier: _safeText(
          _stringValue(
            decoded['possibleBarrier'],
            'independent wheelchair access may be unreliable',
          ),
        ),
        missingEvidence: _stringList(decoded['missingEvidence']),
        confidence: _doubleValue(decoded['confidence'], 0.5).clamp(0.0, 1.0),
        summary: _safeText(
          _stringValue(decoded['summary'], 'Evidence needs human review.'),
        ),
        recommendedAction: _stringValue(
          decoded['recommendedAction'],
          'lgu_review',
        ),
        explanation: _safeText(
          _stringValue(
            decoded['explanation'],
            'AI structured this signal but did not make an official judgment.',
          ),
        ),
      );
    } on Object {
      return _fallback.analyzeMobilityEvidence(
        note: note,
        imagePath: imagePath,
        rampSlopeMeasurement: rampSlopeMeasurement,
      );
    }
  }

  Map<String, Object?> _rampMeasurementPayload(
    RampSlopeMeasurement measurement,
  ) {
    return <String, Object?>{
      'estimatedAngleDegrees': measurement.estimatedAngleDegrees,
      'qualityScore': measurement.qualityScore,
      'qualityLabel': measurement.qualityLabel,
      'captureDurationMs': measurement.captureDurationMs,
      'sampleCount': measurement.sampleCount,
      'status': measurement.status.name,
      'source': measurement.sourceLabel,
    };
  }

  String _stringValue(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  double _doubleValue(Object? value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  String _safeText(String value) {
    return value
        .replaceAll(
          RegExp('violation confirmed', caseSensitive: false),
          'requires official review',
        )
        .replaceAll(
          RegExp('proves? non-compliance', caseSensitive: false),
          'supports review',
        )
        .replaceAll(
          RegExp('confirms? (the )?ramp is illegal', caseSensitive: false),
          'supports review of the ramp',
        )
        .replaceAll(
          RegExp('confirms? legal non-compliance', caseSensitive: false),
          'supports review',
        );
  }
}
