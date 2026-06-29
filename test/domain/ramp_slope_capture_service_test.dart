import 'dart:math' as math;

import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stable accelerometer samples estimate ramp tilt', () {
    final capturedAt = DateTime(2026, 6, 30, 9);
    final samples = List<RampSlopeSensorSample>.generate(24, (index) {
      final angleRadians =
          (14.8 + (index.isEven ? 0.08 : -0.08)) * math.pi / 180;
      return RampSlopeSensorSample(
        x: 0,
        y: math.sin(angleRadians) * 9.81,
        z: math.cos(angleRadians) * 9.81,
      );
    });
    final gyroSamples = List<RampSlopeSensorSample>.filled(
      24,
      const RampSlopeSensorSample(x: 0.01, y: 0.01, z: 0.01),
    );

    final measurement = RampSlopeCaptureService.evaluateSamples(
      accelerometerSamples: samples,
      gyroscopeSamples: gyroSamples,
      captureDuration: const Duration(milliseconds: 3200),
      capturedAt: capturedAt,
    );

    expect(measurement.status, RampSlopeMeasurementStatus.captured);
    expect(measurement.estimatedAngleDegrees, closeTo(14.8, 0.2));
    expect(measurement.qualityLabel, 'High stability');
    expect(measurement.usedFallback, isFalse);
  });

  test('unstable gyro and angle variance fail the capture', () {
    final capturedAt = DateTime(2026, 6, 30, 9);
    final samples = <RampSlopeSensorSample>[
      for (final angle in <double>[4, 19, 38, 7, 31, 12, 42, 9, 25, 36, 5, 29])
        RampSlopeSensorSample(
          x: 0,
          y: math.sin(angle * math.pi / 180) * 9.81,
          z: math.cos(angle * math.pi / 180) * 9.81,
        ),
    ];
    final gyroSamples = List<RampSlopeSensorSample>.filled(
      12,
      const RampSlopeSensorSample(x: 0.9, y: 0.8, z: 0.7),
    );

    final measurement = RampSlopeCaptureService.evaluateSamples(
      accelerometerSamples: samples,
      gyroscopeSamples: gyroSamples,
      captureDuration: const Duration(milliseconds: 3200),
      capturedAt: capturedAt,
    );

    expect(measurement.status, RampSlopeMeasurementStatus.failed);
    expect(measurement.qualityLabel, 'Low stability');
    expect(measurement.failureReason, isNotNull);
  });

  test('fallback measurement is clearly labeled as demo fallback', () {
    final measurement = RampSlopeCaptureService.fallbackMeasurement(
      captureDuration: const Duration(milliseconds: 3200),
      capturedAt: DateTime(2026, 6, 30, 9),
    );

    expect(measurement.status, RampSlopeMeasurementStatus.fallback);
    expect(measurement.usedFallback, isTrue);
    expect(measurement.sourceLabel, 'Demo fallback');
    expect(measurement.estimatedAngleDegrees, 14.8);
  });
}
