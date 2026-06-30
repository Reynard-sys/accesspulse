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
    final confidence = measurement == null
        ? baseConfidence
        : (baseConfidence + 0.05).clamp(0.0, 0.9).toDouble();
    final readiness = measurement != null || imagePath != null
        ? EvidenceReadiness.institutionReady
        : EvidenceReadiness.almostReady;
    final confidenceLevel = _confidenceLevelFromScore(confidence);

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
      confidence: confidence,
      confidenceLevel: confidenceLevel,
      confidenceExplanation: _confidenceExplanation(
        confidenceLevel: confidenceLevel,
        hasMeasurement: measurement != null,
        hasPhoto: imagePath != null,
        mentionsRamp: mentionsRamp,
      ),
      evidenceReadiness: readiness,
      summary: measurement == null
          ? 'The evidence suggests Mobility Access at the entrance may be unreliable, but a human reviewer should confirm the site context.'
          : 'The evidence suggests Mobility Access at the entrance may be unreliable. An estimated ${measurement.estimatedAngleDegrees.toStringAsFixed(1)} degree ramp incline reading with ${measurement.qualityLabel.toLowerCase()} supports the reported concern, but a human reviewer should confirm the site context.',
      recommendedAction: 'lgu_review',
      explanation: measurement == null
          ? 'I can structure visible and described mobility-access signals, but I cannot determine legal compliance or official verification.'
          : 'I can use the estimated incline reading as supporting evidence, but it is not an official measurement and does not determine legal compliance.',
      institutionReady: readiness == EvidenceReadiness.institutionReady,
    );
  }

  static ConfidenceLevel _confidenceLevelFromScore(double confidence) {
    if (confidence >= 0.8) {
      return ConfidenceLevel.high;
    }
    if (confidence >= 0.5) {
      return ConfidenceLevel.moderate;
    }
    return ConfidenceLevel.low;
  }

  static String _confidenceExplanation({
    required ConfidenceLevel confidenceLevel,
    required bool hasMeasurement,
    required bool hasPhoto,
    required bool mentionsRamp,
  }) {
    return switch (confidenceLevel) {
      ConfidenceLevel.high =>
        hasMeasurement
            ? 'The note and field ramp reading align, while official review remains separate.'
            : 'The note and visible evidence strongly support a mobility-access concern.',
      ConfidenceLevel.moderate =>
        hasPhoto || mentionsRamp
            ? 'The mobility issue is supported, but one key access detail is still missing.'
            : 'The concern is plausible, but the evidence needs clearer visual context.',
      ConfidenceLevel.low =>
        'The evidence is too limited to understand the entrance access issue clearly.',
    };
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
        confidenceLevel: _confidenceLevelValue(
          decoded['confidenceLevel'],
          _doubleValue(decoded['confidence'], 0.5),
        ),
        confidenceExplanation: _safeText(
          _stringValue(
            decoded['confidenceExplanation'],
            _defaultConfidenceExplanation(
              _confidenceLevelValue(
                decoded['confidenceLevel'],
                _doubleValue(decoded['confidence'], 0.5),
              ),
            ),
          ),
        ),
        evidenceReadiness: _evidenceReadinessValue(
          decoded['evidenceReadiness'],
          decoded['institutionReady'] == true,
        ),
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
        institutionReady: _boolValue(
          decoded['institutionReady'],
          _evidenceReadinessValue(
                decoded['evidenceReadiness'],
                decoded['institutionReady'] == true,
              ) ==
              EvidenceReadiness.institutionReady,
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

  bool _boolValue(Object? value, bool fallback) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  ConfidenceLevel _confidenceLevelValue(Object? value, double confidence) {
    if (value is String) {
      final normalized = value.trim().toLowerCase().replaceAll('_', '');
      if (normalized == 'high') {
        return ConfidenceLevel.high;
      }
      if (normalized == 'moderate') {
        return ConfidenceLevel.moderate;
      }
      if (normalized == 'low') {
        return ConfidenceLevel.low;
      }
    }
    if (confidence >= 0.8) {
      return ConfidenceLevel.high;
    }
    if (confidence >= 0.5) {
      return ConfidenceLevel.moderate;
    }
    return ConfidenceLevel.low;
  }

  EvidenceReadiness _evidenceReadinessValue(
    Object? value,
    bool institutionReady,
  ) {
    if (value is String) {
      final normalized = value.trim().toLowerCase().replaceAll('_', '');
      if (normalized == 'institutionready') {
        return EvidenceReadiness.institutionReady;
      }
      if (normalized == 'almostready') {
        return EvidenceReadiness.almostReady;
      }
      if (normalized == 'draft') {
        return EvidenceReadiness.draft;
      }
    }
    return institutionReady
        ? EvidenceReadiness.institutionReady
        : EvidenceReadiness.almostReady;
  }

  String _defaultConfidenceExplanation(ConfidenceLevel confidenceLevel) {
    return switch (confidenceLevel) {
      ConfidenceLevel.high =>
        'The evidence strongly supports the mobility-access concern.',
      ConfidenceLevel.moderate =>
        'The evidence supports the concern, but some context is still missing.',
      ConfidenceLevel.low =>
        'The evidence is too limited for a strong review signal.',
    };
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
