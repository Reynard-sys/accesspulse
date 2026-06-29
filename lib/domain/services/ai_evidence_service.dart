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
    final mentionsSteps = lowerNote.contains('step') || lowerNote.contains('stairs');
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
