import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/accesspulse_domain.dart';

const _demoReviewerId = '20000000-0000-4000-8000-000000000002';
const _demoInspectorId = '20000000-0000-4000-8000-000000000003';

enum InstitutionRole { lguReviewer, inspector }

class InstitutionDashboardScreen extends StatefulWidget {
  const InstitutionDashboardScreen({
    required this.repository,
    required this.stateService,
    required this.role,
    this.hideAppBar = false,
    super.key,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final InstitutionRole role;
  final bool hideAppBar;

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
      appBar: widget.hideAppBar
          ? null
          : AppBar(
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
      appBar: AppBar(
        title: const _AccessPulseBrandTitle(),
      ),
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
                    _PriorityExplanationPanel(
                      explanation: _PriorityExplanation.fromCase(
                        place: widget.summary.place,
                        accessCase: detail.accessCase,
                        state: detail.state,
                        pulse: detail.pulse,
                        signal: detail.signal,
                        evidence: detail.evidence,
                      ),
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
      appBar: AppBar(
        title: const _AccessPulseBrandTitle(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Inspector Verification',
                  style: GoogleFonts.afacad(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff17201c),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.place.name,
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff5d6b63),
                  ),
                ),
                const SizedBox(height: 12),
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

  Color _statusColor(CaseStatus status) {
    return switch (status) {
      CaseStatus.open => const Color(0xff52616b),
      CaseStatus.triaging => const Color(0xff1765a6),
      CaseStatus.inspectionRequested => const Color(0xff8a6d00),
      CaseStatus.verified => const Color(0xff17643a),
      CaseStatus.disputed => const Color(0xffb6461a),
      CaseStatus.resolved => const Color(0xff17643a),
      CaseStatus.closed => const Color(0xff52616b),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pulseDisplay = const PulseService().describePlacePulse(
      state: summary.state,
      pulse: summary.pulse,
    );
    final priority = _PriorityExplanation.fromCase(
      place: summary.place,
      accessCase: summary.accessCase,
      state: summary.state,
      pulse: summary.pulse,
    );
    final statusColor = _statusColor(summary.accessCase.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity/Status Left border strip
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    summary.accessCase.status.label.toUpperCase(),
                                    style: GoogleFonts.afacad(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    summary.place.placeType,
                                    style: GoogleFonts.afacad(
                                      color: const Color(0xff5d6b63),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              summary.place.name,
                              style: GoogleFonts.afacad(
                                color: const Color(0xff17201c),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${summary.state.state.label} · ${pulseDisplay.label}',
                              style: GoogleFonts.afacad(
                                color: const Color(0xff5d6b63),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              priority.queueSummary,
                              style: GoogleFonts.afacad(
                                color: const Color(0xff17201c),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xff5d6b63),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityExplanationPanel extends StatelessWidget {
  const _PriorityExplanationPanel({required this.explanation});

  final _PriorityExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.priority_high,
              title: 'Why This Case Matters',
            ),
            const SizedBox(height: 12),
            Text(
              'Why this matters',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            for (final reason in explanation.whyThisMatters)
              _ReasonRow(text: reason),
            const SizedBox(height: 12),
            Text('Why now', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final reason in explanation.whyNow) _ReasonRow(text: reason),
            const Divider(height: 24),
            _MetricRow(
              label: 'Suggested next action',
              value: explanation.suggestedNextAction,
            ),
          ],
        ),
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
              value: _confidenceLevelFromScore(accessCase.confidence).label,
            ),
            _MetricRow(label: 'Severity', value: accessCase.severity.label),
            _MetricRow(
              label: 'Current state confidence',
              value: _confidenceLevelFromScore(state.confidence).label,
            ),
            Text(
              _confidenceExplanationFromScore(accessCase.confidence),
              style: Theme.of(context).textTheme.bodySmall,
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
    final confidenceLevel = _signalConfidenceLevel(signal);
    final confidenceExplanation = _signalConfidenceExplanation(signal);
    final readiness = _signalEvidenceReadiness(signal);
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
            _MetricRow(label: 'AI confidence', value: confidenceLevel.label),
            _MetricRow(label: 'Evidence readiness', value: readiness.label),
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
            Text(confidenceExplanation),
            const SizedBox(height: 8),
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

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PriorityExplanation {
  const _PriorityExplanation({
    required this.whyThisMatters,
    required this.whyNow,
    required this.suggestedNextAction,
  });

  final List<String> whyThisMatters;
  final List<String> whyNow;
  final String suggestedNextAction;

  String get queueSummary {
    final primaryReason = whyThisMatters.isEmpty
        ? 'Institutional review needed'
        : whyThisMatters.first;
    return 'Priority: $primaryReason; $suggestedNextAction';
  }

  static _PriorityExplanation fromCase({
    required Place place,
    required AccessCase accessCase,
    required DimensionStateRecord state,
    required DimensionPulseRecord pulse,
    BarrierSignal? signal,
    Evidence? evidence,
  }) {
    final whyThisMatters = <String>[];
    final whyNow = <String>[];
    final combinedText = [
      place.placeType,
      accessCase.title,
      accessCase.summary,
      state.explanation,
      signal?.issueType,
      signal?.possibleBarrier,
      signal?.structuredSummary,
      evidence?.note,
      ...?signal?.observedFeatures,
    ].whereType<String>().join(' ').toLowerCase();

    if (place.placeType == 'public_service_building') {
      whyThisMatters.add('Public service building');
    }
    if (combinedText.contains('entrance')) {
      whyThisMatters.add('Public service entrance affected');
    }
    whyThisMatters.add('Mobility access affected');
    if (combinedText.contains('assist') || combinedText.contains('help')) {
      whyThisMatters.add('Assistance may be required');
    }
    if (combinedText.contains('purpose')) {
      whyThisMatters.add('Visit purpose may not be completed');
    }

    final pulseDisplay = const PulseService().describePlacePulse(
      state: state,
      pulse: pulse,
    );
    if (state.source == 'ai_structured_barrier_signal') {
      whyNow.add('Recent evidence updated place state');
    }
    if (state.state == DimensionStateValue.degraded) {
      whyNow.add('State just degraded');
    }
    if (state.state == DimensionStateValue.underReview ||
        accessCase.status == CaseStatus.inspectionRequested) {
      whyNow.add('Active review needed');
    }
    if (accessCase.confidence >= 0.8) {
      whyNow.add('AI confidence: High');
    } else if (accessCase.confidence >= 0.5) {
      whyNow.add('AI confidence: Moderate');
    } else {
      whyNow.add('AI confidence: Low');
    }
    whyNow.add('Pulse: ${pulseDisplay.label}');

    return _PriorityExplanation(
      whyThisMatters: _unique(whyThisMatters),
      whyNow: _unique(whyNow),
      suggestedNextAction: _suggestedNextAction(accessCase, signal),
    );
  }

  static String _suggestedNextAction(
    AccessCase accessCase,
    BarrierSignal? signal,
  ) {
    if (accessCase.status == CaseStatus.inspectionRequested) {
      return 'Complete site inspection';
    }
    if (accessCase.status == CaseStatus.verified) {
      return 'Record remediation follow-up';
    }
    if (accessCase.status == CaseStatus.disputed) {
      return 'Review contradictory evidence';
    }
    if (accessCase.status == CaseStatus.closed ||
        accessCase.status == CaseStatus.resolved) {
      return 'Close if out of scope';
    }
    if (signal?.missingEvidence.any(
          (item) => item.toLowerCase().contains('entrance'),
        ) ??
        false) {
      return 'Review alternate entrance';
    }
    return 'Request inspection';
  }

  static List<String> _unique(List<String> values) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (seen.add(value)) value,
    ];
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

extension on ConfidenceLevel {
  String get label {
    return switch (this) {
      ConfidenceLevel.low => 'Low',
      ConfidenceLevel.moderate => 'Moderate',
      ConfidenceLevel.high => 'High',
    };
  }
}

extension on EvidenceReadiness {
  String get label {
    return switch (this) {
      EvidenceReadiness.draft => 'Draft',
      EvidenceReadiness.almostReady => 'Almost Ready',
      EvidenceReadiness.institutionReady => 'Institution Ready',
    };
  }
}

ConfidenceLevel _confidenceLevelFromScore(double confidence) {
  if (confidence >= 0.8) {
    return ConfidenceLevel.high;
  }
  if (confidence >= 0.5) {
    return ConfidenceLevel.moderate;
  }
  return ConfidenceLevel.low;
}

String _confidenceExplanationFromScore(double confidence) {
  return switch (_confidenceLevelFromScore(confidence)) {
    ConfidenceLevel.high =>
      'Evidence is strong enough to support institutional review.',
    ConfidenceLevel.moderate =>
      'Evidence supports review, with some uncertainty still visible.',
    ConfidenceLevel.low =>
      'Evidence is limited and may need more context before action.',
  };
}

ConfidenceLevel _signalConfidenceLevel(BarrierSignal signal) {
  final value = signal.aiExplanation['confidenceLevel'];
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == ConfidenceLevel.high.name) {
      return ConfidenceLevel.high;
    }
    if (normalized == ConfidenceLevel.moderate.name) {
      return ConfidenceLevel.moderate;
    }
    if (normalized == ConfidenceLevel.low.name) {
      return ConfidenceLevel.low;
    }
  }
  return _confidenceLevelFromScore(signal.confidence);
}

String _signalConfidenceExplanation(BarrierSignal signal) {
  final value = signal.aiExplanation['confidenceExplanation'];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return switch (_signalConfidenceLevel(signal)) {
    ConfidenceLevel.high =>
      'The evidence strongly supports the mobility-access concern.',
    ConfidenceLevel.moderate =>
      'The evidence supports the concern, but some context is still missing.',
    ConfidenceLevel.low =>
      'The evidence is too limited for a strong review signal.',
  };
}

EvidenceReadiness _signalEvidenceReadiness(BarrierSignal signal) {
  final value = signal.aiExplanation['evidenceReadiness'];
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == EvidenceReadiness.institutionReady.name) {
      return EvidenceReadiness.institutionReady;
    }
    if (normalized == EvidenceReadiness.almostReady.name) {
      return EvidenceReadiness.almostReady;
    }
    if (normalized == EvidenceReadiness.draft.name) {
      return EvidenceReadiness.draft;
    }
  }
  return signal.aiExplanation['institutionReady'] == true
      ? EvidenceReadiness.institutionReady
      : EvidenceReadiness.almostReady;
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

class _AccessPulseBrandTitle extends StatelessWidget {
  const _AccessPulseBrandTitle({this.fontSize = 20, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Access',
            style: GoogleFonts.afacad(
              color: const Color(0xff17201c),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: 'Pulse',
            style: GoogleFonts.afacad(
              color: const Color(0xff2e7d5b),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: fontSize,
        letterSpacing: -0.5,
      ),
    );
  }
}
