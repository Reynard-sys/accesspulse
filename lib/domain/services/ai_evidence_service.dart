import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/accesspulse_models.dart';

abstract class AiEvidenceService {
  Future<AiEvidenceAssessment> analyzeMobilityEvidence({
    required String note,
    String? imagePath,
  });
}

class MockAiEvidenceService implements AiEvidenceService {
  const MockAiEvidenceService();

  @override
  Future<AiEvidenceAssessment> analyzeMobilityEvidence({
    required String note,
    String? imagePath,
  }) async {
    final lowerNote = note.toLowerCase();
    final mentionsSteps =
        lowerNote.contains('step') || lowerNote.contains('stairs');
    final mentionsRamp = lowerNote.contains('ramp');
    final mentionsAssistance =
        lowerNote.contains('assist') || lowerNote.contains('help');

    return AiEvidenceAssessment(
      dimension: 'mobility_access',
      issueType: 'entrance_ramp_usability',
      observedFeatures: <String>[
        'entrance',
        if (mentionsSteps) 'steps',
        if (mentionsRamp) 'ramp',
        if (imagePath != null) 'uploaded photo',
      ],
      possibleBarrier: mentionsAssistance
          ? 'independent wheelchair access may require assistance'
          : 'independent wheelchair access may be unreliable',
      missingEvidence: const <String>[
        'full side view of ramp',
        'landing visibility',
        'confirmation whether another accessible entrance exists',
      ],
      confidence: mentionsSteps || mentionsRamp || mentionsAssistance
          ? 0.82
          : 0.58,
      summary:
          'The evidence suggests Mobility Access at the entrance may be unreliable, but a human reviewer should confirm the site context.',
      recommendedAction: 'lgu_review',
      explanation:
          'I can structure visible and described mobility-access signals, but I cannot determine legal compliance or official verification.',
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
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback.analyzeMobilityEvidence(
          note: note,
          imagePath: imagePath,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        return _fallback.analyzeMobilityEvidence(
          note: note,
          imagePath: imagePath,
        );
      }
      return AiEvidenceAssessment(
        dimension: _stringValue(decoded['dimension'], 'mobility_access'),
        issueType: _stringValue(
          decoded['issueType'],
          'entrance_ramp_usability',
        ),
        observedFeatures: _stringList(decoded['observedFeatures']),
        possibleBarrier: _stringValue(
          decoded['possibleBarrier'],
          'independent wheelchair access may be unreliable',
        ),
        missingEvidence: _stringList(decoded['missingEvidence']),
        confidence: _doubleValue(decoded['confidence'], 0.5).clamp(0.0, 1.0),
        summary: _stringValue(
          decoded['summary'],
          'Evidence needs human review.',
        ),
        recommendedAction: _stringValue(
          decoded['recommendedAction'],
          'lgu_review',
        ),
        explanation: _stringValue(
          decoded['explanation'],
          'AI structured this signal but did not make an official judgment.',
        ),
      );
    } on Object {
      return _fallback.analyzeMobilityEvidence(
        note: note,
        imagePath: imagePath,
      );
    }
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
}
