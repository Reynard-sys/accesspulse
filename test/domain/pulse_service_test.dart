import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PulseService();
  final now = DateTime(2026, 6, 30, 12);

  test('describes reliable current place pulse', () {
    final display = service.describePlacePulse(
      state: _state(
        state: DimensionStateValue.reliable,
        source: 'seed_community_confirmation',
        lastConfirmedAt: DateTime(2026, 6, 20, 14),
      ),
      pulse: _pulse(level: DimensionPulseLevel.strong),
      now: now,
    );

    expect(display.status, PlacePulseStatus.reliable);
    expect(display.label, 'Reliable');
  });

  test('describes reliable aging place pulse', () {
    final display = service.describePlacePulse(
      state: _state(
        state: DimensionStateValue.claimedAccessible,
        source: 'seed_public_record',
        lastConfirmedAt: DateTime(2026, 4, 15, 9),
      ),
      pulse: _pulse(level: DimensionPulseLevel.moderate),
      now: now,
    );

    expect(display.status, PlacePulseStatus.reliableAging);
    expect(display.label, 'Reliable, aging');
  });

  test('describes unknown place pulse', () {
    final display = service.describePlacePulse(
      state: _state(state: DimensionStateValue.unknown, source: 'seed_unknown'),
      pulse: _pulse(level: DimensionPulseLevel.weak),
      now: now,
    );

    expect(display.status, PlacePulseStatus.unknown);
    expect(display.label, 'Unknown');
  });

  test('describes under review place pulse', () {
    final display = service.describePlacePulse(
      state: _state(
        state: DimensionStateValue.degraded,
        source: 'ai_structured_barrier_signal',
        lastConfirmedAt: now,
      ),
      pulse: _pulse(level: DimensionPulseLevel.strong),
      now: now,
    );

    expect(display.status, PlacePulseStatus.underReview);
    expect(display.label, 'Under review');
  });

  test('describes recently refreshed place pulse', () {
    final display = service.describePlacePulse(
      state: _state(
        state: DimensionStateValue.degraded,
        source: 'community_visit_confirmation',
        lastConfirmedAt: now,
      ),
      pulse: _pulse(level: DimensionPulseLevel.strong),
      now: now,
    );

    expect(display.status, PlacePulseStatus.recentlyRefreshed);
    expect(display.label, 'Recently refreshed');
  });
}

DimensionStateRecord _state({
  required DimensionStateValue state,
  required String source,
  DateTime? lastConfirmedAt,
}) {
  return DimensionStateRecord(
    id: 'state',
    placeDimensionId: 'place_dimension',
    state: state,
    confidence: 0.72,
    explanation: 'State explanation.',
    source: source,
    updatedAt: DateTime(2026, 6, 30),
    lastConfirmedAt: lastConfirmedAt,
  );
}

DimensionPulseRecord _pulse({required DimensionPulseLevel level}) {
  return DimensionPulseRecord(
    id: 'pulse',
    placeDimensionId: 'place_dimension',
    level: level,
    score: 0.8,
    supportingObservationsCount: 1,
    hasRecentVerification: false,
    contradictionFlag: false,
    lastCalculatedAt: DateTime(2026, 6, 30),
    explanation: 'Pulse explanation.',
  );
}
