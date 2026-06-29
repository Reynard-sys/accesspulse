import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'GeminiServerEvidenceService parses structured wrapper response',
    () async {
      final service = GeminiServerEvidenceService(
        functionUri: Uri.parse('https://example.test/analyze-evidence'),
        client: MockClient((request) async {
          expect(request.headers['content-type'], 'application/json');
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
      );

      expect(assessment.dimension, 'mobility_access');
      expect(assessment.issueType, 'entrance_ramp_usability');
      expect(assessment.observedFeatures, contains('steps'));
      expect(assessment.confidence, 0.81);
      expect(assessment.recommendedAction, 'lgu_review');
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
