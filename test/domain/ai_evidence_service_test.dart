import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final rampMeasurement = RampSlopeMeasurement(
    estimatedAngleDegrees: 14.8,
    qualityScore: 64,
    qualityLabel: 'Moderate stability',
    captureDurationMs: 3200,
    sampleCount: 48,
    status: RampMeasurementStatus.captured,
    capturedAt: DateTime(2026, 6, 30, 9),
    usedFallback: false,
  );

  test(
    'GeminiServerEvidenceService parses structured wrapper response',
    () async {
      final service = GeminiServerEvidenceService(
        functionUri: Uri.parse('https://example.test/analyze-evidence'),
        client: MockClient((request) async {
          expect(request.headers['content-type'], 'application/json');
          expect(request.body, contains('"rampMeasurement"'));
          expect(request.body, contains('"estimatedAngleDegrees":14.8'));
          expect(request.body, contains('"qualityLabel":"Moderate stability"'));
          return http.Response(
            '''
{
  "dimension": "mobility_access",
  "issueType": "entrance_ramp_usability",
  "observedFeatures": ["entrance", "steps", "uploaded photo"],
  "possibleBarrier": "independent wheelchair access may be unreliable",
  "missingEvidence": ["full side view of ramp"],
  "confidence": 0.81,
  "summary": "The evidence suggests entrance access may require assistance.",
  "recommendedAction": "lgu_review",
  "explanation": "AI structured the evidence but did not make an official judgment."
}
''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final assessment = await service.analyzeMobilityEvidence(
        note: 'The entrance has steps.',
        imagePath: 'demo/main-entrance.jpg',
        rampSlopeMeasurement: rampMeasurement,
      );

      expect(assessment.dimension, 'mobility_access');
      expect(assessment.issueType, 'entrance_ramp_usability');
      expect(assessment.observedFeatures, contains('steps'));
      expect(assessment.confidence, 0.81);
      expect(assessment.recommendedAction, 'lgu_review');
    },
  );

  test(
    'MockAiEvidenceService references measured incline with uncertainty',
    () async {
      const service = MockAiEvidenceService();

      final assessment = await service.analyzeMobilityEvidence(
        note: 'The ramp needed assistance.',
        rampSlopeMeasurement: rampMeasurement,
      );

      expect(
        assessment.observedFeatures,
        contains('estimated ramp angle 14.8 degrees'),
      );
      expect(assessment.summary, contains('14.8 degree ramp incline'));
      expect(assessment.summary, contains('human reviewer should confirm'));
      expect(
        assessment.missingEvidence,
        contains('official on-site ramp measurement'),
      );
      expect(assessment.explanation, contains('supporting evidence'));
      expect(assessment.explanation, isNot(contains('violation confirmed')));
    },
  );

  test(
    'GeminiServerEvidenceService removes forbidden compliance claims',
    () async {
      final service = GeminiServerEvidenceService(
        functionUri: Uri.parse('https://example.test/analyze-evidence'),
        client: MockClient((request) async {
          return http.Response(
            '''
{
  "dimension": "mobility_access",
  "issueType": "entrance_ramp_usability",
  "observedFeatures": ["estimated ramp angle 14.8 degrees"],
  "possibleBarrier": "This confirms legal non-compliance.",
  "missingEvidence": ["official measurement"],
  "confidence": 0.9,
  "summary": "Violation confirmed. The reading proves non-compliance.",
  "recommendedAction": "lgu_review",
  "explanation": "This confirms the ramp is illegal."
}
''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final assessment = await service.analyzeMobilityEvidence(
        note: 'The ramp was hard to use.',
        rampSlopeMeasurement: rampMeasurement,
      );

      final combined =
          '${assessment.possibleBarrier} ${assessment.summary} ${assessment.explanation}'
              .toLowerCase();
      expect(combined, isNot(contains('violation confirmed')));
      expect(combined, isNot(contains('proves non-compliance')));
      expect(combined, isNot(contains('ramp is illegal')));
      expect(combined, contains('supports review'));
    },
  );

  test(
    'GeminiServerEvidenceService falls back to mock on wrapper failure',
    () async {
      final service = GeminiServerEvidenceService(
        functionUri: Uri.parse('https://example.test/analyze-evidence'),
        client: MockClient((request) async {
          return http.Response('server unavailable', 500);
        }),
      );

      final assessment = await service.analyzeMobilityEvidence(
        note: 'The ramp needed assistance.',
      );

      expect(assessment.dimension, 'mobility_access');
      expect(assessment.issueType, 'entrance_ramp_usability');
      expect(assessment.confidence, 0.82);
      expect(
        assessment.explanation,
        contains('cannot determine legal compliance'),
      );
    },
  );
}
