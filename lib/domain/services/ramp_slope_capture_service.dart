import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

enum RampSlopeMeasurementStatus { captured, lowQuality, failed, fallback }

class RampSlopeMeasurement {
  const RampSlopeMeasurement({
    required this.estimatedAngleDegrees,
    required this.qualityScore,
    required this.qualityLabel,
    required this.captureDurationMs,
    required this.sampleCount,
    required this.status,
    required this.capturedAt,
    required this.usedFallback,
    this.failureReason,
  });

  final double estimatedAngleDegrees;
  final int qualityScore;
  final String qualityLabel;
  final int captureDurationMs;
  final int sampleCount;
  final RampSlopeMeasurementStatus status;
  final DateTime capturedAt;
  final bool usedFallback;
  final String? failureReason;

  bool get isUsable {
    return status == RampSlopeMeasurementStatus.captured ||
        status == RampSlopeMeasurementStatus.lowQuality ||
        status == RampSlopeMeasurementStatus.fallback;
  }

  String get sourceLabel {
    return usedFallback ? 'Demo fallback' : 'Phone sensors';
  }
}

class RampSlopeSensorSample {
  const RampSlopeSensorSample({
    required this.x,
    required this.y,
    required this.z,
  });

  final double x;
  final double y;
  final double z;
}

class RampSlopeCaptureService {
  const RampSlopeCaptureService({
    this.captureDuration = const Duration(milliseconds: 3200),
    this.samplingPeriod = SensorInterval.uiInterval,
    this.minimumAccelerometerSamples = 12,
    this.allowFallback = true,
  });

  final Duration captureDuration;
  final Duration samplingPeriod;
  final int minimumAccelerometerSamples;
  final bool allowFallback;

  Future<RampSlopeMeasurement> capture() async {
    final accelerometerSamples = <RampSlopeSensorSample>[];
    final gyroscopeSamples = <RampSlopeSensorSample>[];
    Object? streamError;

    StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;

    try {
      accelerometerSubscription =
          accelerometerEventStream(samplingPeriod: samplingPeriod).listen(
            (event) => accelerometerSamples.add(
              RampSlopeSensorSample(x: event.x, y: event.y, z: event.z),
            ),
            onError: (Object error) => streamError = error,
          );

      gyroscopeSubscription =
          gyroscopeEventStream(samplingPeriod: samplingPeriod).listen(
            (event) => gyroscopeSamples.add(
              RampSlopeSensorSample(x: event.x, y: event.y, z: event.z),
            ),
            onError: (Object error) => streamError = error,
          );

      await Future<void>.delayed(captureDuration);
    } on Object catch (error) {
      streamError = error;
    } finally {
      final cancelFutures = <Future<void>>[
        if (accelerometerSubscription != null)
          accelerometerSubscription.cancel().timeout(
            const Duration(milliseconds: 250),
            onTimeout: () {},
          ),
        if (gyroscopeSubscription != null)
          gyroscopeSubscription.cancel().timeout(
            const Duration(milliseconds: 250),
            onTimeout: () {},
          ),
      ];
      await Future.wait(cancelFutures);
    }

    if (streamError != null && accelerometerSamples.isEmpty) {
      return _fallbackOrFailed(
        'Live motion sensors were unavailable for this capture.',
      );
    }

    final measurement = evaluateSamples(
      accelerometerSamples: accelerometerSamples,
      gyroscopeSamples: gyroscopeSamples,
      captureDuration: captureDuration,
      capturedAt: DateTime.now(),
      minimumAccelerometerSamples: minimumAccelerometerSamples,
    );

    if (measurement.status == RampSlopeMeasurementStatus.failed &&
        accelerometerSamples.isEmpty) {
      return _fallbackOrFailed(
        'Live motion sensors did not provide enough samples.',
      );
    }

    return measurement;
  }

  RampSlopeMeasurement _fallbackOrFailed(String reason) {
    if (!allowFallback) {
      return RampSlopeMeasurement(
        estimatedAngleDegrees: 0,
        qualityScore: 0,
        qualityLabel: 'Low stability',
        captureDurationMs: captureDuration.inMilliseconds,
        sampleCount: 0,
        status: RampSlopeMeasurementStatus.failed,
        capturedAt: DateTime.now(),
        usedFallback: false,
        failureReason: reason,
      );
    }

    return fallbackMeasurement(
      captureDuration: captureDuration,
      capturedAt: DateTime.now(),
    );
  }

  static RampSlopeMeasurement fallbackMeasurement({
    Duration captureDuration = const Duration(milliseconds: 3200),
    DateTime? capturedAt,
  }) {
    return RampSlopeMeasurement(
      estimatedAngleDegrees: 14.8,
      qualityScore: 64,
      qualityLabel: 'Moderate stability',
      captureDurationMs: captureDuration.inMilliseconds,
      sampleCount: 48,
      status: RampSlopeMeasurementStatus.fallback,
      capturedAt: capturedAt ?? DateTime.now(),
      usedFallback: true,
      failureReason:
          'Demo fallback was used because live sensor capture was unavailable.',
    );
  }

  static RampSlopeMeasurement evaluateSamples({
    required List<RampSlopeSensorSample> accelerometerSamples,
    required List<RampSlopeSensorSample> gyroscopeSamples,
    required Duration captureDuration,
    required DateTime capturedAt,
    int minimumAccelerometerSamples = 12,
  }) {
    if (accelerometerSamples.length < minimumAccelerometerSamples) {
      return RampSlopeMeasurement(
        estimatedAngleDegrees: 0,
        qualityScore: 0,
        qualityLabel: 'Low stability',
        captureDurationMs: captureDuration.inMilliseconds,
        sampleCount: accelerometerSamples.length,
        status: RampSlopeMeasurementStatus.failed,
        capturedAt: capturedAt,
        usedFallback: false,
        failureReason:
            'We could not capture enough accelerometer samples for a stable estimate.',
      );
    }

    final angles = accelerometerSamples.map(_tiltDegrees).toList();
    final angle = _average(angles);
    final angleDeviation = _standardDeviation(angles);
    final gyroMovement = gyroscopeSamples.isEmpty
        ? 0.0
        : _average(gyroscopeSamples.map(_magnitude).toList());

    final score = (100 - angleDeviation * 14 - gyroMovement * 80).clamp(0, 100);
    final roundedScore = score.round();

    final qualityLabel = switch (roundedScore) {
      >= 78 => 'High stability',
      >= 50 => 'Moderate stability',
      _ => 'Low stability',
    };
    final status = switch (roundedScore) {
      >= 50 => RampSlopeMeasurementStatus.captured,
      >= 25 => RampSlopeMeasurementStatus.lowQuality,
      _ => RampSlopeMeasurementStatus.failed,
    };

    return RampSlopeMeasurement(
      estimatedAngleDegrees: double.parse(angle.toStringAsFixed(1)),
      qualityScore: roundedScore,
      qualityLabel: qualityLabel,
      captureDurationMs: captureDuration.inMilliseconds,
      sampleCount: accelerometerSamples.length,
      status: status,
      capturedAt: capturedAt,
      usedFallback: false,
      failureReason: status == RampSlopeMeasurementStatus.failed
          ? 'The phone moved too much to trust this ramp reading.'
          : null,
    );
  }

  static double _tiltDegrees(RampSlopeSensorSample sample) {
    final horizontal = math.sqrt(sample.x * sample.x + sample.y * sample.y);
    final vertical = sample.z.abs();
    return math.atan2(horizontal, vertical) * 180 / math.pi;
  }

  static double _magnitude(RampSlopeSensorSample sample) {
    return math.sqrt(
      sample.x * sample.x + sample.y * sample.y + sample.z * sample.z,
    );
  }

  static double _average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _standardDeviation(List<double> values) {
    if (values.length < 2) {
      return 0;
    }
    final average = _average(values);
    final variance =
        values
            .map((value) => math.pow(value - average, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }
}
