import 'package:flutter/material.dart';

import '../../domain/accesspulse_domain.dart';

const _demoReviewerId = '20000000-0000-4000-8000-000000000002';
const _demoInspectorId = '20000000-0000-4000-8000-000000000003';

enum InstitutionRole { lguReviewer, inspector }

class InstitutionDashboardScreen extends StatefulWidget {
  const InstitutionDashboardScreen({
    required this.repository,
    required this.stateService,
    required this.role,
    super.key,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final InstitutionRole role;

  @override
  State<InstitutionDashboardScreen> createState() =>
      _InstitutionDashboardScreenState();
}

class _InstitutionDashboardScreenState
    extends State<InstitutionDashboardScreen> {
  late Future<List<_CaseSummary>> _casesFuture;

  @override
  void initState() {
    super.initState();
    _casesFuture = _loadCases();
  }

  Future<List<_CaseSummary>> _loadCases() async {
    final cases = await widget.repository.listCases();
    final filtered = cases.where((accessCase) {
      if (widget.role == InstitutionRole.inspector) {
        return accessCase.status == CaseStatus.inspectionRequested ||
            accessCase.status == CaseStatus.verified ||
            accessCase.status == CaseStatus.disputed ||
            accessCase.status == CaseStatus.triaging;
      }
      return accessCase.status != CaseStatus.closed;
    }).toList();

    final places = await widget.repository.listPlaces();
    final summaries = <_CaseSummary>[];
    for (final accessCase in filtered) {
      final placeDimension = await widget.repository.getPlaceDimension(
        accessCase.placeDimensionId,
      );
      final place = places.firstWhere(
        (place) => place.id == placeDimension.placeId,
      );
      final state = await widget.repository.getDimensionState(
        accessCase.placeDimensionId,
      );
      final pulse = await widget.repository.getDimensionPulse(
        accessCase.placeDimensionId,
      );
      summaries.add(
        _CaseSummary(
          accessCase: accessCase,
          place: place,
          state: state,
          pulse: pulse,
        ),
      );
    }
    return summaries;
  }

  void _refresh() {
    setState(() {
      _casesFuture = _loadCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInspector = widget.role == InstitutionRole.inspector;
    return Scaffold(
      appBar: AppBar(
        title: Text(isInspector ? 'Inspector verification' : 'LGU dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _RolePill(
                label: isInspector ? 'Inspector' : 'LGU reviewer',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: FutureBuilder<List<_CaseSummary>>(
              future: _casesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cases = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      isInspector
                          ? 'Verification queue'
                          : 'Actionable accessibility intelligence',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isInspector
                          ? 'Review cases requested by the LGU and submit a human verification outcome.'
                          : 'Review structured Mobility Access signals and request inspection when action is needed.',
                    ),
                    const SizedBox(height: 16),
                    if (cases.isEmpty)
                      const _EmptyQueue()
                    else
                      for (final summary in cases) ...[
                        _CaseQueueTile(
                          summary: summary,
                          onTap: () async {
                            await Navigator.of(context).push(
                              _institutionRoute<void>(
                                _CaseDetailScreen(
                                  repository: widget.repository,
                                  stateService: widget.stateService,
                                  summary: summary,
                                  role: widget.role,
                                ),
                              ),
                            );
                            _refresh();
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

class _CaseDetailScreen extends StatefulWidget {
  const _CaseDetailScreen({
    required this.repository,
    required this.stateService,
    required this.summary,
    required this.role,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final _CaseSummary summary;
  final InstitutionRole role;

  @override
  State<_CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<_CaseDetailScreen> {
  late Future<_CaseDetailData> _detailFuture;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<_CaseDetailData> _loadDetail() async {
    final freshCase = await widget.repository.getCase(
      widget.summary.accessCase.id,
    );
    final signal = freshCase.barrierSignalId == null
        ? null
        : await widget.repository.getBarrierSignal(freshCase.barrierSignalId!);
    final evidence = signal?.evidenceId == null
        ? null
        : await widget.repository.getEvidence(signal!.evidenceId!);
    final rampMeasurement = evidence == null
        ? null
        : await widget.repository.getRampMeasurementForEvidence(evidence.id);
    final state = await widget.repository.getDimensionState(
      freshCase.placeDimensionId,
    );
    final pulse = await widget.repository.getDimensionPulse(
      freshCase.placeDimensionId,
    );
    final memory = await widget.repository.listMemoryEvents(
      freshCase.placeDimensionId,
    );
    return _CaseDetailData(
      accessCase: freshCase,
      state: state,
      pulse: pulse,
      signal: signal,
      evidence: evidence,
      rampMeasurement: rampMeasurement,
      memory: memory,
    );
  }

  void _refresh() {
    setState(() {
      _detailFuture = _loadDetail();
    });
  }

  Future<void> _triage() async {
    setState(() => _isActing = true);
    await widget.stateService.triageCase(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isActing = false);
    _refresh();
  }

  Future<void> _requestInspection() async {
    setState(() => _isActing = true);
    await widget.stateService.requestInspection(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isActing = false);
    _refresh();
  }

  Future<void> _close() async {
    setState(() => _isActing = true);
    await widget.stateService.closeCase(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
      note: 'Closed during demo after review.',
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openVerification(_CaseDetailData detail) async {
    await Navigator.of(context).push(
      _institutionRoute<void>(
        _InspectorVerificationScreen(
          place: widget.summary.place,
          detail: detail,
          stateService: widget.stateService,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.summary.place.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: FutureBuilder<_CaseDetailData>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final detail = snapshot.data!;
                final isInspector = widget.role == InstitutionRole.inspector;
                return ListView(
                  key: const ValueKey('case-detail-scroll'),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _InstitutionStateCard(
                      placeName: widget.summary.place.name,
                      accessCase: detail.accessCase,
                      state: detail.state,
                      pulse: detail.pulse,
                    ),
                    const SizedBox(height: 16),
                    if (detail.signal != null)
                      _SignalPanel(
                        signal: detail.signal!,
                        evidence: detail.evidence,
                        rampMeasurement: detail.rampMeasurement,
                      ),
                    const SizedBox(height: 16),
                    _MemoryPanel(memory: detail.memory),
                    const SizedBox(height: 16),
                    if (isInspector)
                      FilledButton.icon(
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Open verification'),
                        onPressed: _isActing
                            ? null
                            : () => _openVerification(detail),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.rule),
                            label: const Text('Mark triaging'),
                            onPressed: _isActing ? null : _triage,
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.assignment_turned_in),
                            label: const Text('Request inspection'),
                            onPressed: _isActing ? null : _requestInspection,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Close case'),
                            onPressed: _isActing ? null : _close,
                          ),
                        ],
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

class _InspectorVerificationScreen extends StatefulWidget {
  const _InspectorVerificationScreen({
    required this.place,
    required this.detail,
    required this.stateService,
  });

  final Place place;
  final _CaseDetailData detail;
  final DimensionStateService stateService;

  @override
  State<_InspectorVerificationScreen> createState() =>
      _InspectorVerificationScreenState();
}

class _InspectorVerificationScreenState
    extends State<_InspectorVerificationScreen> {
  VerificationOutcome _outcome = VerificationOutcome.confirmed;
  final _noteController = TextEditingController(
    text: 'Inspector confirmed that the main entrance requires assistance.',
  );
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final result = await widget.stateService.submitVerification(
      caseId: widget.detail.accessCase.id,
      inspectorId: _demoInspectorId,
      outcome: _outcome,
      note: _noteController.text,
    );
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      _institutionRoute<void>(
        _VerificationResultScreen(place: widget.place, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspector verification')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.place.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Human verification is authoritative. AI evidence remains supporting context.',
                ),
                const SizedBox(height: 16),
                SegmentedButton<VerificationOutcome>(
                  segments: const [
                    ButtonSegment(
                      value: VerificationOutcome.confirmed,
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('Confirm'),
                    ),
                    ButtonSegment(
                      value: VerificationOutcome.disputed,
                      icon: Icon(Icons.report_gmailerrorred),
                      label: Text('Dispute'),
                    ),
                    ButtonSegment(
                      value: VerificationOutcome.insufficientEvidence,
                      icon: Icon(Icons.help_outline),
                      label: Text('Insufficient'),
                    ),
                  ],
                  selected: {_outcome},
                  onSelectionChanged: (values) {
                    setState(() => _outcome = values.single);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Verification note',
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
                      : const Icon(Icons.verified),
                  label: const Text('Submit verification'),
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

class _VerificationResultScreen extends StatelessWidget {
  const _VerificationResultScreen({required this.place, required this.result});

  final Place place;
  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final previousPulseDisplay = const PulseService().describePlacePulse(
      state: result.previousState,
      pulse: result.previousPulse,
    );
    final currentPulseDisplay = const PulseService().describePlacePulse(
      state: result.currentState,
      pulse: result.currentPulse,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Verification update')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.82, end: 1),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Icon(
                    Icons.verified_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Human verification updated this place',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(place.name, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TransitionRow(
                          label: 'Current accessibility state',
                          before: result.previousState.state.label,
                          after: result.currentState.state.label,
                        ),
                        const Divider(height: 24),
                        _MetricRow(
                          label: 'Case status',
                          value: result.accessCase.status.label,
                        ),
                        const Divider(height: 24),
                        _TransitionRow(
                          label: 'Pulse / freshness',
                          before: previousPulseDisplay.label,
                          after: currentPulseDisplay.label,
                        ),
                        const SizedBox(height: 12),
                        Text(result.currentState.explanation),
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
                FilledButton.icon(
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Back to queue'),
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

class _CaseQueueTile extends StatelessWidget {
  const _CaseQueueTile({required this.summary, required this.onTap});

  final _CaseSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pulseDisplay = const PulseService().describePlacePulse(
      state: summary.state,
      pulse: summary.pulse,
    );
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(summary.accessCase.status.icon)),
        title: Text(summary.place.name),
        subtitle: Text(
          '${summary.state.state.label} - ${pulseDisplay.label} - ${summary.accessCase.status.label}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InstitutionStateCard extends StatelessWidget {
  const _InstitutionStateCard({
    required this.placeName,
    required this.accessCase,
    required this.state,
    required this.pulse,
  });

  final String placeName;
  final AccessCase accessCase;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;

  @override
  Widget build(BuildContext context) {
    final pulseDisplay = const PulseService().describePlacePulse(
      state: state,
      pulse: pulse,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              placeName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(accessCase.title),
            const SizedBox(height: 12),
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
                _StatusPill(
                  icon: accessCase.status.icon,
                  label: accessCase.status.label,
                  color: const Color(0xff1765a6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricRow(label: 'Freshness / pulse', value: pulseDisplay.label),
            _MetricRow(
              label: 'Case confidence',
              value: '${(accessCase.confidence * 100).round()}%',
            ),
            _MetricRow(label: 'Severity', value: accessCase.severity.label),
            _MetricRow(
              label: 'Current state confidence',
              value: '${(state.confidence * 100).round()}%',
            ),
            const Divider(height: 24),
            Text(pulseDisplay.explanation),
            if (pulseDisplay.verificationContext != null) ...[
              const SizedBox(height: 8),
              Text(
                pulseDisplay.verificationContext!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignalPanel extends StatelessWidget {
  const _SignalPanel({
    required this.signal,
    required this.evidence,
    required this.rampMeasurement,
  });

  final BarrierSignal signal;
  final Evidence? evidence;
  final RampMeasurement? rampMeasurement;

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
              title: 'Evidence bundle',
            ),
            const SizedBox(height: 12),
            _MetricRow(
              label: 'Issue type',
              value: signal.issueType.replaceAll('_', ' '),
            ),
            _MetricRow(
              label: 'AI confidence',
              value: '${(signal.confidence * 100).round()}%',
            ),
            _MetricRow(
              label: 'Recommended action',
              value: signal.recommendedAction.replaceAll('_', ' '),
            ),
            if (evidence?.note != null)
              _MetricRow(label: 'Contributor note', value: evidence!.note!),
            if (rampMeasurement != null) ...[
              const Divider(height: 24),
              _RampMeasurementBlock(measurement: rampMeasurement!),
            ],
            const Divider(height: 24),
            Text(signal.structuredSummary),
            const SizedBox(height: 12),
            Text(
              'Observed features',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final feature in signal.observedFeatures)
                  Chip(label: Text(feature)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Missing context',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            for (final missing in signal.missingEvidence)
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
          ],
        ),
      ),
    );
  }
}

class _RampMeasurementBlock extends StatelessWidget {
  const _RampMeasurementBlock({required this.measurement});

  final RampMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ramp measurement supporting evidence',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                icon: Icons.straighten,
                title: 'Ramp Measurement',
              ),
              const SizedBox(height: 10),
              _MetricRow(
                label: 'Estimated angle',
                value:
                    '${measurement.estimatedAngleDegrees.toStringAsFixed(1)} deg',
              ),
              _MetricRow(
                label: 'Capture quality',
                value: measurement.qualityLabel,
              ),
              _MetricRow(label: 'Source', value: 'Citizen field capture'),
              _MetricRow(
                label: 'Captured at',
                value: _formatDate(measurement.capturedAt),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estimated reading provided to support review; official measurement may still be required.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryPanel extends StatelessWidget {
  const _MemoryPanel({required this.memory});

  final List<MemoryEvent> memory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(icon: Icons.history, title: 'Place memory'),
            const SizedBox(height: 12),
            for (final event in memory.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventType.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(event.summary),
                        ],
                      ),
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

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'No actionable cases yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add evidence from the public flow to create an institution-ready case.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
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
    return DecoratedBox(
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
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
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

class _CaseSummary {
  const _CaseSummary({
    required this.accessCase,
    required this.place,
    required this.state,
    required this.pulse,
  });

  final AccessCase accessCase;
  final Place place;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
}

class _CaseDetailData {
  const _CaseDetailData({
    required this.accessCase,
    required this.state,
    required this.pulse,
    required this.memory,
    this.signal,
    this.evidence,
    this.rampMeasurement,
  });

  final AccessCase accessCase;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final BarrierSignal? signal;
  final Evidence? evidence;
  final RampMeasurement? rampMeasurement;
  final List<MemoryEvent> memory;
}

String _formatDate(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day';
}

Route<T> _institutionRoute<T>(Widget child) {
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

extension on CaseStatus {
  String get label {
    return switch (this) {
      CaseStatus.open => 'Open',
      CaseStatus.triaging => 'Triaging',
      CaseStatus.inspectionRequested => 'Inspection requested',
      CaseStatus.verified => 'Verified',
      CaseStatus.disputed => 'Disputed',
      CaseStatus.resolved => 'Resolved',
      CaseStatus.closed => 'Closed',
    };
  }

  IconData get icon {
    return switch (this) {
      CaseStatus.open => Icons.notification_important_outlined,
      CaseStatus.triaging => Icons.rule,
      CaseStatus.inspectionRequested => Icons.assignment_turned_in,
      CaseStatus.verified => Icons.verified_outlined,
      CaseStatus.disputed => Icons.report_gmailerrorred,
      CaseStatus.resolved => Icons.task_alt,
      CaseStatus.closed => Icons.close,
    };
  }
}

extension on CaseSeverity {
  String get label {
    return switch (this) {
      CaseSeverity.low => 'Low',
      CaseSeverity.medium => 'Medium',
      CaseSeverity.high => 'High',
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
