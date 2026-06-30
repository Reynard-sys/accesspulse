import '../models/accesspulse_models.dart';

class PlacePulseDisplay {
  const PlacePulseDisplay({
    required this.status,
    required this.label,
    required this.explanation,
    this.verificationContext,
  });

  final PlacePulseStatus status;
  final String label;
  final String explanation;
  final String? verificationContext;
}

class PulseService {
  const PulseService();

  PlacePulseDisplay describePlacePulse({
    required DimensionStateRecord state,
    required DimensionPulseRecord pulse,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final lastConfirmedAt = state.lastConfirmedAt;
    final refreshedRecently =
        lastConfirmedAt != null &&
        referenceTime.difference(lastConfirmedAt).inDays <= 1;

    if (state.state == DimensionStateValue.unknown) {
      return const PlacePulseDisplay(
        status: PlacePulseStatus.unknown,
        label: 'Unknown',
        explanation:
            'We do not currently have enough recent evidence for this place.',
      );
    }

    if (state.state == DimensionStateValue.underReview ||
        state.source == 'ai_structured_barrier_signal') {
      return PlacePulseDisplay(
        status: PlacePulseStatus.underReview,
        label: 'Under review',
        explanation:
            'Recent evidence may change this place\'s current Mobility Access state.',
        verificationContext: pulse.hasRecentVerification
            ? 'A recent human verification is part of the current record.'
            : 'Human review is still needed before this becomes an official outcome.',
      );
    }

    if (refreshedRecently || state.source == 'community_visit_confirmation') {
      return PlacePulseDisplay(
        status: PlacePulseStatus.recentlyRefreshed,
        label: 'Recently refreshed',
        explanation: 'Updated today based on a recent visit confirmation.',
        verificationContext: pulse.hasRecentVerification
            ? 'A recent human verification also supports this record.'
            : null,
      );
    }

    if (state.state == DimensionStateValue.claimedAccessible ||
        pulse.level == DimensionPulseLevel.moderate ||
        pulse.level == DimensionPulseLevel.weak) {
      return PlacePulseDisplay(
        status: PlacePulseStatus.reliableAging,
        label: 'Reliable, aging',
        explanation: 'Previously reliable, but not confirmed recently.',
        verificationContext: pulse.hasRecentVerification
            ? 'A recent human verification supports this record, but the visit signal is aging.'
            : null,
      );
    }

    return PlacePulseDisplay(
      status: PlacePulseStatus.reliable,
      label: 'Reliable',
      explanation: 'Recently confirmed as independently usable.',
      verificationContext: pulse.hasRecentVerification
          ? 'A recent human verification supports this record.'
          : null,
    );
  }

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
    final score =
        (recencyScore +
                observationScore +
                verificationScore -
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
      parts.add(
        'Latest visit signal was captured on ${_date(latestObservation.createdAt)}.',
      );
    }

    if (hasRecentVerification) {
      parts.add('A recent human verification strengthens current knowledge.');
    }
    if (contradictionFlag) {
      parts.add(
        'Contradictory signals reduce confidence in current knowledge.',
      );
    }

    return parts.join(' ');
  }

  String _date(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
