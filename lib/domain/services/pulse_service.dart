import '../models/accesspulse_models.dart';

class PulseService {
  const PulseService();

  DimensionPulseRecord calculate({
    required String id,
    required String placeDimensionId,
    required List<Observation> observations,
    required List<Verification> verifications,
    required bool contradictionFlag,
    required DateTime now,
  }) {
    final recentVerification = verifications.any(
      (verification) => now.difference(verification.performedAt).inDays <= 30,
    );
    final latestObservation = observations.isEmpty
        ? null
        : observations.reduce(
            (latest, next) =>
                latest.createdAt.isAfter(next.createdAt) ? latest : next,
          );

    final recencyScore = _recencyScore(latestObservation?.createdAt, now);
    final observationScore = (observations.length * 0.14).clamp(0, 0.34);
    final verificationScore = recentVerification ? 0.24 : 0.0;
    final contradictionPenalty = contradictionFlag ? 0.24 : 0.0;
    final score = (recencyScore + observationScore + verificationScore -
            contradictionPenalty)
        .clamp(0.0, 1.0);
    final level = switch (score) {
      >= 0.72 => DimensionPulseLevel.strong,
      >= 0.40 => DimensionPulseLevel.moderate,
      _ => DimensionPulseLevel.weak,
    };

    return DimensionPulseRecord(
      id: id,
      placeDimensionId: placeDimensionId,
      level: level,
      score: double.parse(score.toStringAsFixed(3)),
      supportingObservationsCount: observations.length,
      hasRecentVerification: recentVerification,
      contradictionFlag: contradictionFlag,
      lastCalculatedAt: now,
      explanation: _explain(
        level: level,
        observations: observations,
        latestObservation: latestObservation,
        hasRecentVerification: recentVerification,
        contradictionFlag: contradictionFlag,
      ),
    );
  }

  double _recencyScore(DateTime? latestObservationAt, DateTime now) {
    if (latestObservationAt == null) {
      return 0.08;
    }

    final ageInDays = now.difference(latestObservationAt).inDays;
    if (ageInDays <= 7) {
      return 0.42;
    }
    if (ageInDays <= 30) {
      return 0.32;
    }
    if (ageInDays <= 90) {
      return 0.18;
    }
    return 0.10;
  }

  String _explain({
    required DimensionPulseLevel level,
    required List<Observation> observations,
    required Observation? latestObservation,
    required bool hasRecentVerification,
    required bool contradictionFlag,
  }) {
    final parts = <String>[
      'Pulse is ${level.name} based on ${observations.length} supporting observation${observations.length == 1 ? '' : 's'}.',
    ];

    if (latestObservation == null) {
      parts.add('No recent visit confirmation is available.');
    } else {
      parts.add('Latest visit signal was captured on ${_date(latestObservation.createdAt)}.');
    }

    if (hasRecentVerification) {
      parts.add('A recent human verification strengthens current knowledge.');
    }
    if (contradictionFlag) {
      parts.add('Contradictory signals reduce confidence in current knowledge.');
    }

    return parts.join(' ');
  }

  String _date(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
