import 'package:flutter/material.dart';

import '../../domain/accesspulse_domain.dart';

const _mobilityDimensionKey = 'mobility_access';
const _demoUserId = '20000000-0000-4000-8000-000000000001';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({
    required this.repository,
    required this.stateService,
    required this.aiService,
    super.key,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AccessPulse'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: _RolePill()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: FutureBuilder<List<Place>>(
              future: widget.repository.listPlaces(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final places = snapshot.data!
                    .where(
                      (place) => place.name.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Current accessibility state',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check public service buildings and help update living accessibility knowledge.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Search seeded places',
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Search places',
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(Icons.accessible_forward, size: 18),
                          label: Text('Mobility Access'),
                        ),
                        Chip(
                          avatar: Icon(Icons.business, size: 18),
                          label: Text('Public service buildings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (final place in places) ...[
                      _PlaceListTile(
                        repository: widget.repository,
                        place: place,
                        onTap: () async {
                          await Navigator.of(context).push(
                            _accessPulseRoute<void>(
                              PlaceDetailScreen(
                                repository: widget.repository,
                                stateService: widget.stateService,
                                aiService: widget.aiService,
                                place: place,
                              ),
                            ),
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({
    required this.repository,
    required this.stateService,
    required this.aiService,
    required this.place,
    super.key,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;
  final Place place;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<_PlaceDetailData> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _load();
  }

  Future<_PlaceDetailData> _load() async {
    final placeDimension = await widget.repository.getPlaceDimensionForPlace(
      placeId: widget.place.id,
      dimensionKey: _mobilityDimensionKey,
    );
    final state = await widget.repository.getDimensionState(placeDimension.id);
    final pulse = await widget.repository.getDimensionPulse(placeDimension.id);
    final memory = await widget.repository.listMemoryEvents(placeDimension.id);
    return _PlaceDetailData(
      placeDimension: placeDimension,
      state: state,
      pulse: pulse,
      memory: memory,
    );
  }

  void _refresh() {
    setState(() {
      _detailFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.place.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: FutureBuilder<_PlaceDetailData>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final detail = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _StateCard(
                      placeName: widget.place.name,
                      state: detail.state,
                      pulse: detail.pulse,
                    ),
                    const SizedBox(height: 16),
                    _DetailActions(
                      onConfirmVisit: () async {
                        await Navigator.of(context).push(
                          _accessPulseRoute<void>(
                            ConfirmVisitScreen(
                              place: widget.place,
                              placeDimensionId: detail.placeDimension.id,
                              stateService: widget.stateService,
                            ),
                          ),
                        );
                        _refresh();
                      },
                      onAddEvidence: () async {
                        await Navigator.of(context).push(
                          _accessPulseRoute<void>(
                            EvidenceFlowScreen(
                              place: widget.place,
                              placeDimensionId: detail.placeDimension.id,
                              stateService: widget.stateService,
                              aiService: widget.aiService,
                            ),
                          ),
                        );
                        _refresh();
                      },
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(icon: Icons.history, title: 'Place memory'),
                    const SizedBox(height: 8),
                    for (final event in detail.memory.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MemoryTile(event: event),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ConfirmVisitScreen extends StatefulWidget {
  const ConfirmVisitScreen({
    required this.place,
    required this.placeDimensionId,
    required this.stateService,
    super.key,
  });

  final Place place;
  final String placeDimensionId;
  final DimensionStateService stateService;

  @override
  State<ConfirmVisitScreen> createState() => _ConfirmVisitScreenState();
}

class _ConfirmVisitScreenState extends State<ConfirmVisitScreen> {
  bool _entranceUsable = false;
  bool _rampUsable = false;
  bool _neededAssistance = true;
  bool _completedPurpose = false;
  final _noteController = TextEditingController(
    text: 'The main entrance had steps and I needed assistance to get in.',
  );
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final result = await widget.stateService.confirmVisit(
      placeDimensionId: widget.placeDimensionId,
      submittedBy: _demoUserId,
      entranceUsableIndependently: _entranceUsable,
      rampUsable: _rampUsable,
      neededAssistance: _neededAssistance,
      completedPurpose: _completedPurpose,
      note: _noteController.text,
    );
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      _accessPulseRoute<void>(
        SubmissionResultScreen(
          place: widget.place,
          title: 'Your visit updated this place',
          message:
              'The Mobility Access state now reflects your fresh visit confirmation.',
          previousState: result.previousState,
          currentState: result.currentState,
          previousPulse: result.previousPulse,
          currentPulse: result.currentPulse,
          nextAction: PublicResultNextAction.addEvidence(
            placeDimensionId: widget.placeDimensionId,
            stateService: widget.stateService,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm visit')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.place.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Answer a few simple questions to help update this place.',
                ),
                const SizedBox(height: 16),
                _QuestionSwitch(
                  title: 'Was the entrance usable independently?',
                  value: _entranceUsable,
                  onChanged: (value) => setState(() => _entranceUsable = value),
                ),
                _QuestionSwitch(
                  title: 'Was the ramp usable?',
                  value: _rampUsable,
                  onChanged: (value) => setState(() => _rampUsable = value),
                ),
                _QuestionSwitch(
                  title: 'Did you need assistance?',
                  value: _neededAssistance,
                  onChanged: (value) =>
                      setState(() => _neededAssistance = value),
                ),
                _QuestionSwitch(
                  title: 'Were you able to complete your purpose for visiting?',
                  value: _completedPurpose,
                  onChanged: (value) =>
                      setState(() => _completedPurpose = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Optional note',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.update),
                  label: const Text('Update living state'),
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EvidenceFlowScreen extends StatefulWidget {
  const EvidenceFlowScreen({
    required this.place,
    required this.placeDimensionId,
    required this.stateService,
    required this.aiService,
    super.key,
  });

  final Place place;
  final String placeDimensionId;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;

  @override
  State<EvidenceFlowScreen> createState() => _EvidenceFlowScreenState();
}

class _EvidenceFlowScreenState extends State<EvidenceFlowScreen> {
  final _noteController = TextEditingController(
    text: 'The entrance has steps and the ramp required assistance.',
  );
  bool _demoPhotoSelected = false;
  bool _useDemoRampFallback = true;
  bool _isCapturingRampSlope = false;
  bool _rampSlopeCaptureFailed = false;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  final _rampSlopeCaptureService = const RampSlopeCaptureService();
  RampSlopeMeasurement? _rampSlopeMeasurement;
  String? _rampSlopeFailureMessage;
  String? _analysisError;
  String? _submitError;
  AiEvidenceAssessment? _assessment;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _shouldOfferRampSlopeCapture {
    final note = _noteController.text.toLowerCase();
    return note.contains('ramp') ||
        note.contains('steep') ||
        note.contains('incline') ||
        note.contains('slope') ||
        note.contains('unsafe') ||
        note.contains('wheelchair entrance');
  }

  Future<void> _captureRampSlope() async {
    setState(() {
      _isCapturingRampSlope = true;
      _rampSlopeCaptureFailed = false;
      _rampSlopeFailureMessage = null;
      _analysisError = null;
      _submitError = null;
      _assessment = null;
    });
    final measurement = _useDemoRampFallback
        ? await _captureDemoRampSlope()
        : await _rampSlopeCaptureService.capture();
    if (!mounted) {
      return;
    }
    setState(() {
      _isCapturingRampSlope = false;
      if (measurement.isUsable) {
        _rampSlopeMeasurement = measurement;
      } else {
        _rampSlopeMeasurement = null;
        _rampSlopeCaptureFailed = true;
        _rampSlopeFailureMessage = measurement.failureReason;
      }
    });
  }

  Future<RampSlopeMeasurement> _captureDemoRampSlope() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return RampSlopeCaptureService.fallbackMeasurement(
      capturedAt: DateTime.now(),
    );
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _submitError = null;
    });
    try {
      final assessment = await widget.aiService.analyzeMobilityEvidence(
        note: _noteController.text,
        imagePath: _demoPhotoSelected ? 'demo/main-entrance.jpg' : null,
        rampSlopeMeasurement: _rampSlopeMeasurement,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _assessment = assessment;
        _isAnalyzing = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _analysisError =
            'AccessPulse could not structure this evidence. You can retry, or keep the note and measurement for manual review.';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _submit() async {
    final assessment = _assessment;
    if (assessment == null) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      final result = await widget.stateService.submitStructuredEvidence(
        placeDimensionId: widget.placeDimensionId,
        submittedBy: _demoUserId,
        assessment: assessment,
        imagePath: _demoPhotoSelected ? 'demo/main-entrance.jpg' : null,
        note: _noteController.text,
        rampSlopeMeasurement: _rampSlopeMeasurement,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        _accessPulseRoute<void>(
          SubmissionResultScreen(
            place: widget.place,
            title: 'Evidence strengthened this place memory',
            message:
                'The report now carries the note, optional photo, measured incline, and AI summary into LGU review.',
            previousState: result.previousState,
            currentState: result.currentState,
            previousPulse: result.previousPulse,
            currentPulse: result.currentPulse,
          ),
        ),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError =
            'The review packet was not submitted. Please retry while the note and measurement are still on this screen.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add evidence')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              key: const ValueKey('evidence-flow-scroll'),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.place.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a review packet with the note, optional photo, ramp reading, and AI summary.',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_camera_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _demoPhotoSelected
                                    ? 'Demo entrance photo selected'
                                    : 'No photo selected',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.upload),
                              label: const Text('Use demo photo'),
                              onPressed: () {
                                setState(() {
                                  _demoPhotoSelected = true;
                                  _assessment = null;
                                  _submitError = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Evidence note',
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) {
                            setState(() {
                              _assessment = null;
                              _analysisError = null;
                              _submitError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_shouldOfferRampSlopeCapture) ...[
                          _RampSlopeCapturePanel(
                            measurement: _rampSlopeMeasurement,
                            isCapturing: _isCapturingRampSlope,
                            captureFailed: _rampSlopeCaptureFailed,
                            failureMessage: _rampSlopeFailureMessage,
                            useDemoFallback: _useDemoRampFallback,
                            onDemoFallbackChanged: _isCapturingRampSlope
                                ? null
                                : (value) {
                                    setState(() {
                                      _useDemoRampFallback = value;
                                      _rampSlopeMeasurement = null;
                                      _rampSlopeCaptureFailed = false;
                                      _rampSlopeFailureMessage = null;
                                      _analysisError = null;
                                      _submitError = null;
                                      _assessment = null;
                                    });
                                  },
                            onStart: _captureRampSlope,
                            onRetry: _captureRampSlope,
                          ),
                          const SizedBox(height: 12),
                        ],
                        FilledButton.icon(
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isAnalyzing
                                ? 'Structuring evidence...'
                                : 'Analyze evidence',
                          ),
                          onPressed: _isAnalyzing ? null : _analyze,
                        ),
                        if (_analysisError != null) ...[
                          const SizedBox(height: 12),
                          _InlineNotice(
                            icon: Icons.error_outline,
                            message: _analysisError!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_assessment != null) ...[
                  _AiResultPanel(assessment: _assessment!),
                  const SizedBox(height: 16),
                  _ReviewPacketPanel(
                    hasPhoto: _demoPhotoSelected,
                    hasRampMeasurement: _rampSlopeMeasurement != null,
                  ),
                ],
                if (_assessment != null) ...[
                  const SizedBox(height: 16),
                  if (_submitError != null) ...[
                    _InlineNotice(
                      icon: Icons.error_outline,
                      message: _submitError!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fact_check_outlined),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting review packet...'
                          : 'Submit review packet',
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RampSlopeCapturePanel extends StatelessWidget {
  const _RampSlopeCapturePanel({
    required this.measurement,
    required this.isCapturing,
    required this.captureFailed,
    required this.failureMessage,
    required this.useDemoFallback,
    required this.onDemoFallbackChanged,
    required this.onStart,
    required this.onRetry,
  });

  final RampSlopeMeasurement? measurement;
  final bool isCapturing;
  final bool captureFailed;
  final String? failureMessage;
  final bool useDemoFallback;
  final ValueChanged<bool>? onDemoFallbackChanged;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final measurement = this.measurement;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.science_outlined),
              title: const Text('Demo-safe capture'),
              subtitle: const Text(
                'Use the seeded 14.8 deg sample for a reliable live demo.',
              ),
              value: useDemoFallback,
              onChanged: onDemoFallbackChanged,
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isCapturing
                  ? _RampSlopeCapturingState(useDemoFallback: useDemoFallback)
                  : measurement != null
                  ? _RampSlopeSuccessState(
                      key: ValueKey(measurement.capturedAt),
                      measurement: measurement,
                      onRetry: onRetry,
                    )
                  : captureFailed
                  ? _RampSlopeFailureState(
                      message: failureMessage,
                      onRetry: onRetry,
                    )
                  : _RampSlopeEntryState(
                      useDemoFallback: useDemoFallback,
                      onStart: onStart,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RampSlopeEntryState extends StatelessWidget {
  const _RampSlopeEntryState({
    required this.useDemoFallback,
    required this.onStart,
  });

  final bool useDemoFallback;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('ramp-slope-entry'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.straighten,
          title: 'Optional: Measure ramp slope',
        ),
        const SizedBox(height: 8),
        const Text(
          'Add an estimated incline reading so reviewers see the reported ramp condition with more context.',
        ),
        const SizedBox(height: 12),
        Text(
          useDemoFallback
              ? 'Demo-safe mode is on, so this capture will use a clearly labeled sample reading.'
              : 'Place your phone flat on the ramp surface and point it in the direction someone would move up or down the ramp. Hold it still for a few seconds.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.speed),
          label: const Text('Start slope capture'),
          onPressed: onStart,
        ),
        const SizedBox(height: 8),
        Text(
          'This is an estimated field measurement to support review. Official verification may still be required.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RampSlopeCapturingState extends StatelessWidget {
  const _RampSlopeCapturingState({required this.useDemoFallback});

  final bool useDemoFallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('ramp-slope-capturing'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.speed, title: 'Capturing ramp slope'),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Text(
          useDemoFallback
              ? 'Loading the demo-safe measurement sample.'
              : 'Keep the phone still while AccessPulse captures motion sensor samples.',
        ),
      ],
    );
  }
}

class _RampSlopeSuccessState extends StatelessWidget {
  const _RampSlopeSuccessState({
    required this.measurement,
    required this.onRetry,
    super.key,
  });

  final RampSlopeMeasurement measurement;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.task_alt,
          title: 'Ramp slope captured',
        ),
        const SizedBox(height: 10),
        _MetricRow(
          label: 'Estimated angle',
          value: '${measurement.estimatedAngleDegrees.toStringAsFixed(1)} deg',
        ),
        _MetricRow(label: 'Quality', value: measurement.qualityLabel),
        _MetricRow(label: 'Source', value: measurement.sourceLabel),
        _MetricRow(
          label: 'Capture window',
          value:
              '${(measurement.captureDurationMs / 1000).toStringAsFixed(1)}s',
        ),
        _MetricRow(label: 'Samples', value: '${measurement.sampleCount}'),
        const SizedBox(height: 10),
        const Text('This estimated reading will be attached to your report.'),
        const SizedBox(height: 8),
        Text(
          'Estimated field measurement only. It does not prove legal non-compliance.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (measurement.status == RampMeasurementStatus.lowQuality) ...[
          const SizedBox(height: 8),
          const Text(
            'We captured a reading, but the phone moved too much to trust it strongly. You can retry for a better result.',
          ),
        ],
        if (measurement.usedFallback) ...[
          const SizedBox(height: 8),
          const Text(
            'Demo fallback mode was used because live sensor capture was unavailable in this environment.',
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Retry measurement'),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _RampSlopeFailureState extends StatelessWidget {
  const _RampSlopeFailureState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('ramp-slope-failure'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.error_outline,
          title: 'Ramp reading not stable',
        ),
        const SizedBox(height: 8),
        const Text(
          'We could not capture a stable ramp reading. Please place your phone flat on the ramp and try again.',
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Retry measurement'),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class SubmissionResultScreen extends StatelessWidget {
  const SubmissionResultScreen({
    required this.place,
    required this.title,
    required this.message,
    required this.previousState,
    required this.currentState,
    required this.previousPulse,
    required this.currentPulse,
    this.nextAction,
    super.key,
  });

  final Place place;
  final String title;
  final String message;
  final DimensionStateRecord previousState;
  final DimensionStateRecord currentState;
  final DimensionPulseRecord previousPulse;
  final DimensionPulseRecord currentPulse;
  final PublicResultNextAction? nextAction;

  @override
  Widget build(BuildContext context) {
    final previousPulseDisplay = const PulseService().describePlacePulse(
      state: previousState,
      pulse: previousPulse,
    );
    final currentPulseDisplay = const PulseService().describePlacePulse(
      state: currentState,
      pulse: currentPulse,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('State update')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.82, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _TransitionRow(
                          label: 'Current accessibility state',
                          before: previousState.state.label,
                          after: currentState.state.label,
                        ),
                        const Divider(height: 24),
                        _TransitionRow(
                          label: 'Pulse / freshness',
                          before: previousPulseDisplay.label,
                          after: currentPulseDisplay.label,
                        ),
                        const SizedBox(height: 12),
                        Text(currentState.explanation),
                        const SizedBox(height: 8),
                        Text(
                          currentPulseDisplay.explanation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (nextAction != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add evidence'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        _accessPulseRoute<void>(
                          EvidenceFlowScreen(
                            place: place,
                            placeDimensionId: nextAction!.placeDimensionId,
                            stateService: nextAction!.stateService,
                            aiService: const MockAiEvidenceService(),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Back to place'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceListTile extends StatelessWidget {
  const _PlaceListTile({
    required this.repository,
    required this.place,
    required this.onTap,
  });

  final AccessPulseRepository repository;
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PlaceListData>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final pulseDisplay = data == null
            ? null
            : const PulseService().describePlacePulse(
                state: data.state,
                pulse: data.pulse,
              );
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.location_city)),
            title: Text(place.name),
            subtitle: data == null
                ? const Text('Loading living accessibility state')
                : Text('${data.state.state.label} - ${pulseDisplay!.label}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: data == null ? null : onTap,
          ),
        );
      },
    );
  }

  Future<_PlaceListData> _load() async {
    final placeDimension = await repository.getPlaceDimensionForPlace(
      placeId: place.id,
      dimensionKey: _mobilityDimensionKey,
    );
    final state = await repository.getDimensionState(placeDimension.id);
    final pulse = await repository.getDimensionPulse(placeDimension.id);
    return _PlaceListData(state: state, pulse: pulse);
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.onConfirmVisit,
    required this.onAddEvidence,
  });

  final VoidCallback onConfirmVisit;
  final VoidCallback onAddEvidence;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;
        final confirmButton = Semantics(
          label: 'Confirm a recent visit for this place',
          button: true,
          child: FilledButton.icon(
            icon: const Icon(Icons.how_to_reg),
            label: const Text('I visited this place'),
            onPressed: onConfirmVisit,
          ),
        );
        final evidenceButton = Semantics(
          label: 'Add mobility access evidence for this place',
          button: true,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add evidence'),
            onPressed: onAddEvidence,
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              confirmButton,
              const SizedBox(height: 10),
              evidenceButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: confirmButton),
            const SizedBox(width: 12),
            Expanded(child: evidenceButton),
          ],
        );
      },
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.placeName,
    required this.state,
    required this.pulse,
  });

  final String placeName;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;

  @override
  Widget build(BuildContext context) {
    final pulseDisplay = const PulseService().describePlacePulse(
      state: state,
      pulse: pulse,
    );
    return _FadeSlideIn(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                placeName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text('For you: Mobility Access'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusPill(
                    icon: Icons.accessible_forward,
                    label: state.state.label,
                    color: state.state.color,
                  ),
                  _StatusPill(
                    icon: Icons.monitor_heart_outlined,
                    label: pulseDisplay.label,
                    color: pulseDisplay.status.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricRow(label: 'Dimension', value: 'Mobility Access'),
              _MetricRow(label: 'Current state', value: state.state.label),
              _MetricRow(label: 'Freshness / pulse', value: pulseDisplay.label),
              _MetricRow(
                label: 'Confidence',
                value: '${(state.confidence * 100).round()}%',
              ),
              _MetricRow(
                label: 'Last confirmed',
                value: state.lastConfirmedAt == null
                    ? 'Unknown'
                    : _formatDate(state.lastConfirmedAt!),
              ),
              const Divider(height: 24),
              Text(state.explanation),
              const SizedBox(height: 8),
              Text(pulseDisplay.explanation),
              if (pulseDisplay.verificationContext != null) ...[
                const SizedBox(height: 8),
                Text(
                  pulseDisplay.verificationContext!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                pulse.explanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiResultPanel extends StatelessWidget {
  const _AiResultPanel({required this.assessment});

  final AiEvidenceAssessment assessment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.auto_awesome,
              title: 'AI evidence structure',
            ),
            const SizedBox(height: 12),
            _MetricRow(
              label: 'Issue type',
              value: assessment.issueType.replaceAll('_', ' '),
            ),
            _MetricRow(
              label: 'Confidence',
              value: '${(assessment.confidence * 100).round()}%',
            ),
            const SizedBox(height: 8),
            Text(assessment.summary),
            const SizedBox(height: 12),
            Text('Observed', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final feature in assessment.observedFeatures)
                  Chip(label: Text(feature)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Missing evidence',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            for (final missing in assessment.missingEvidence)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(missing)),
                  ],
                ),
              ),
            const Divider(height: 24),
            Text(assessment.explanation),
          ],
        ),
      ),
    );
  }
}

class _ReviewPacketPanel extends StatelessWidget {
  const _ReviewPacketPanel({
    required this.hasPhoto,
    required this.hasRampMeasurement,
  });

  final bool hasPhoto;
  final bool hasRampMeasurement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Review packet',
            ),
            const SizedBox(height: 12),
            _PacketStep(
              icon: Icons.edit_note,
              title: 'Before review',
              body: hasRampMeasurement
                  ? 'Your note and measured incline are ready for the LGU queue.'
                  : 'Your note is ready. A ramp reading can still be added before submission.',
            ),
            const SizedBox(height: 10),
            _PacketStep(
              icon: Icons.fact_check_outlined,
              title: 'After submission',
              body:
                  'AccessPulse opens a review case, updates the living state, and keeps official verification separate.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Chip(label: Text('Note included')),
                Chip(label: Text(hasPhoto ? 'Photo included' : 'No photo yet')),
                Chip(
                  label: Text(
                    hasRampMeasurement
                        ? 'Ramp reading included'
                        : 'No ramp reading yet',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PacketStep extends StatelessWidget {
  const _PacketStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(body),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.event});

  final MemoryEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bolt_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventType.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(event.summary),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(event.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionSwitch extends StatelessWidget {
  const _QuestionSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _TransitionRow extends StatelessWidget {
  const _TransitionRow({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(before)),
            const Icon(Icons.arrow_forward),
            Chip(label: Text(after)),
          ],
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text('Community user'),
      ),
    );
  }
}

class _PlaceListData {
  const _PlaceListData({required this.state, required this.pulse});

  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
}

class _PlaceDetailData {
  const _PlaceDetailData({
    required this.placeDimension,
    required this.state,
    required this.pulse,
    required this.memory,
  });

  final PlaceDimension placeDimension;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final List<MemoryEvent> memory;
}

class PublicResultNextAction {
  const PublicResultNextAction.addEvidence({
    required this.placeDimensionId,
    required this.stateService,
  });

  final String placeDimensionId;
  final DimensionStateService stateService;
}

extension on DimensionStateValue {
  String get label {
    return switch (this) {
      DimensionStateValue.unknown => 'Unknown',
      DimensionStateValue.claimedAccessible => 'Claimed accessible',
      DimensionStateValue.reliable => 'Reliable',
      DimensionStateValue.degraded => 'Degraded',
      DimensionStateValue.officiallyVerifiedDegraded =>
        'Officially verified degraded',
      DimensionStateValue.underReview => 'Under review',
      DimensionStateValue.resolved => 'Resolved',
    };
  }

  Color get color {
    return switch (this) {
      DimensionStateValue.unknown => const Color(0xff52616b),
      DimensionStateValue.claimedAccessible => const Color(0xff8a6d00),
      DimensionStateValue.reliable => const Color(0xff17643a),
      DimensionStateValue.degraded => const Color(0xffb6461a),
      DimensionStateValue.officiallyVerifiedDegraded => const Color(0xff9d1b1e),
      DimensionStateValue.underReview => const Color(0xff1765a6),
      DimensionStateValue.resolved => const Color(0xff17643a),
    };
  }
}

extension on PlacePulseStatus {
  Color get color {
    return switch (this) {
      PlacePulseStatus.reliable => const Color(0xff17643a),
      PlacePulseStatus.reliableAging => const Color(0xff8a6d00),
      PlacePulseStatus.unknown => const Color(0xff52616b),
      PlacePulseStatus.underReview => const Color(0xff1765a6),
      PlacePulseStatus.recentlyRefreshed => const Color(0xff17643a),
    };
  }
}

extension on MemoryEventType {
  String get label {
    return switch (this) {
      MemoryEventType.placeSeeded => 'Place seeded',
      MemoryEventType.stateSeeded => 'State seeded',
      MemoryEventType.visitConfirmed => 'Visit confirmed',
      MemoryEventType.evidenceAdded => 'Evidence added',
      MemoryEventType.aiSignalCreated => 'AI signal created',
      MemoryEventType.caseOpened => 'Case opened',
      MemoryEventType.caseTriaged => 'Case triaged',
      MemoryEventType.inspectionRequested => 'Inspection requested',
      MemoryEventType.verificationSubmitted => 'Verification submitted',
      MemoryEventType.stateChanged => 'State changed',
      MemoryEventType.pulseChanged => 'Pulse changed',
      MemoryEventType.caseClosed => 'Case closed',
      MemoryEventType.remediationVerified => 'Remediation verified',
    };
  }
}

String _formatDate(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day';
}

Route<T> _accessPulseRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
