import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/accesspulse_domain.dart';

const _mobilityDimensionKey = 'mobility_access';
const _demoUserId = '20000000-0000-4000-8000-000000000001';
typedef ImagePickerOverride =
    Future<XFile?> Function(ImageSource source, int? imageQuality);

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({
    required this.repository,
    required this.stateService,
    required this.aiService,
    this.hideAppBar = false,
    this.imagePickerOverride,
    super.key,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;
  final bool hideAppBar;
  final ImagePickerOverride? imagePickerOverride;

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Access',
                      style: TextStyle(color: const Color(0xff17201c)),
                    ),
                    TextSpan(
                      text: 'Pulse',
                      style: TextStyle(color: const Color(0xff2e7d5b)),
                    ),
                  ],
                ),
                style: GoogleFonts.afacad(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
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

                final nearbyPlaces = places
                    .where(
                      (place) =>
                          place.id == '40000000-0000-4000-8000-000000000001',
                    )
                    .toList();
                final otherPlaces = places
                    .where(
                      (place) =>
                          place.id != '40000000-0000-4000-8000-000000000001',
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Current accessibility state',
                      style: GoogleFonts.afacad(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: const Color(0xff17201c),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check public service buildings and help update living accessibility knowledge.',
                      style: GoogleFonts.afacad(
                        fontSize: 16,
                        color: const Color(0xff5d6b63),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'Search seeded places',
                      child: TextField(
                        style: GoogleFonts.afacad(
                          fontSize: 16,
                          color: const Color(0xff17201c),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xff5d6b63),
                          ),
                          hintText: 'Search places',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.accessible_forward,
                            size: 16,
                            color: Color(0xff2e7d5b),
                          ),
                          label: Text(
                            'Mobility Access',
                            style: GoogleFonts.afacad(
                              color: const Color(0xff17201c),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: const Color(0xffe8eee9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xff2e7d5b),
                          ),
                          label: Text(
                            'Public service buildings',
                            style: GoogleFonts.afacad(
                              color: const Color(0xff17201c),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: const Color(0xffe8eee9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    if (nearbyPlaces.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xff9eb5a6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nearby public buildings · Quezon City, Metro Manila',
                            style: GoogleFonts.afacad(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff9eb5a6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      for (final place in nearbyPlaces) ...[
                        _NearbyPlaceCard(
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
                                  imagePickerOverride:
                                      widget.imagePickerOverride,
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
                    if (otherPlaces.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'OTHER PLACES',
                        style: GoogleFonts.afacad(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff5d6b63),
                          letterSpacing: 0.78,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final place in otherPlaces) ...[
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
                    const SizedBox(height: 16),
                    const _BeenToPlacesCard(),
                    const SizedBox(height: 24),
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
    this.imagePickerOverride,
    super.key,
  });

  final AccessPulseRepository repository;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;
  final Place place;
  final ImagePickerOverride? imagePickerOverride;

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
    final latestCase = await _latestCaseForPlaceDimension(
      widget.repository,
      placeDimension.id,
    );
    final latestBarrierSignal = await _barrierSignalForCase(
      widget.repository,
      latestCase,
    );
    return _PlaceDetailData(
      placeDimension: placeDimension,
      state: state,
      pulse: pulse,
      memory: memory,
      latestCase: latestCase,
      latestBarrierSignal: latestBarrierSignal,
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
      appBar: AppBar(
        title: const _AccessPulseBrandTitle(),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: FutureBuilder<_PlaceDetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final detail = snapshot.data!;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xff2e7d5b),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff2e7d5b,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.how_to_reg,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confirm Your Visit',
                                style: GoogleFonts.afacad(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xff3b75d1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff2e7d5b,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.of(context).push(
                              _accessPulseRoute<void>(
                                EvidenceFlowScreen(
                                  place: widget.place,
                                  placeDimensionId: detail.placeDimension.id,
                                  stateService: widget.stateService,
                                  aiService: widget.aiService,
                                  imagePickerOverride:
                                      widget.imagePickerOverride,
                                ),
                              ),
                            );
                            _refresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo,
                                color: Colors.white,
                                size: 21,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Evidence',
                                style: GoogleFonts.afacad(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
                var memoryEvents = detail.memory.take(5).toList();
                if (widget.place.id == '40000000-0000-4000-8000-000000000001' &&
                    memoryEvents.length == 1 &&
                    memoryEvents[0].eventType == MemoryEventType.stateSeeded) {
                  memoryEvents = [
                    MemoryEvent(
                      id: 'mock-1',
                      placeDimensionId: detail.placeDimension.id,
                      eventType: MemoryEventType.visitConfirmed,
                      actorType: 'user',
                      summary:
                          'Visitor confirmed ramp was not usable independently',
                      createdAt: DateTime.now(),
                    ),
                    MemoryEvent(
                      id: 'mock-2',
                      placeDimensionId: detail.placeDimension.id,
                      eventType: MemoryEventType.inspectionRequested,
                      actorType: 'ai',
                      summary: 'AI requested wider entrance photo',
                      createdAt: DateTime.now(),
                    ),
                    MemoryEvent(
                      id: 'mock-3',
                      placeDimensionId: detail.placeDimension.id,
                      eventType: MemoryEventType.caseOpened,
                      actorType: 'lgu',
                      summary: 'LGU review case created',
                      createdAt: DateTime.now(),
                    ),
                  ];
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff2e7d5b),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'back',
                                  style: GoogleFonts.afacad(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StateCard(
                      placeName: widget.place.name,
                      state: detail.state,
                      pulse: detail.pulse,
                      latestCase: detail.latestCase,
                    ),
                    const SizedBox(height: 12),
                    _IssueSummaryBlock(
                      summary: _publicIssueSummary(
                        state: detail.state,
                        latestCase: detail.latestCase,
                        barrierSignal: detail.latestBarrierSignal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PLACE MEMORY',
                      style: GoogleFonts.afacad(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff5e7268),
                        letterSpacing: 0.78,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (memoryEvents.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xffdde5e0),
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff17201c,
                              ).withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No memory events recorded yet.',
                            style: GoogleFonts.afacad(
                              color: const Color(0xff5d6b63),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xffdde5e0),
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff17201c,
                              ).withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              for (int i = 0; i < memoryEvents.length; i++) ...[
                                _MemoryTile(
                                  event: memoryEvents[i],
                                  isFirst: i == 0,
                                  isLast: i == memoryEvents.length - 1,
                                ),
                                if (i < memoryEvents.length - 1)
                                  const Divider(
                                    indent: 56,
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xffdde5e0),
                                  ),
                              ],
                            ],
                          ),
                        ),
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
  int _currentStep = 1;
  int? _step1Selection;
  int? _step2Selection;
  int? _step3Selection;

  bool _entranceUsable = false;
  bool _rampUsable = false;
  bool _neededAssistance = false;
  bool _completedPurpose = true; // Default to true as it is not explicitly questioned in Figma steps
  final _noteController = TextEditingController();
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
        _VisitConfirmedScreen(place: widget.place),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xffdde5e0), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 17, top: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (_currentStep > 1) {
                setState(() => _currentStep--);
              } else {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xffeef4f1).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xff17201c),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIRMING VISIT',
                  style: GoogleFonts.afacad(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff5d6b63),
                    letterSpacing: 0.44,
                  ),
                ),
                Text(
                  widget.place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff17201c),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffeaf2ff),
        border: Border.all(color: const Color(0xffc5daff)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'You are not filing a complaint. ',
              style: GoogleFonts.afacad(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xff2558b0),
              ),
            ),
            TextSpan(
              text: 'You are confirming what happened.',
              style: GoogleFonts.afacad(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: const Color(0xff3b75d1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(4, (index) {
                final stepNum = index + 1;
                final isActive = stepNum == _currentStep;
                final color = isActive ? const Color(0xff3b75d1) : const Color(0xffdde5e0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 8),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(33554400),
                  ),
                );
              }),
            ),
            Text(
              'Step $_currentStep of 4',
              style: GoogleFonts.afacad(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xff5d6b63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final filledWidth = totalWidth * (_currentStep / 4);
            return Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffdde5e0),
                borderRadius: BorderRadius.circular(33554400),
              ),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: filledWidth,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff2e7d5b), Color(0xff3b75d1)],
                  ),
                  borderRadius: BorderRadius.circular(33554400),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final choices = [
      'Yes, I could enter independently',
      'No, I needed help',
      'Not sure / didn’t try',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Was the entrance usable without assistance?',
          style: GoogleFonts.afacad(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xff17201c),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 28),
        ...choices.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          final isSelected = _step1Selection == idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _step1Selection = idx;
                  if (idx == 0) {
                    _entranceUsable = true;
                    _neededAssistance = false;
                  } else if (idx == 1) {
                    _entranceUsable = false;
                    _neededAssistance = true;
                  } else {
                    _entranceUsable = false;
                    _neededAssistance = false;
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 17),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xfff1f5f3) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xff2e7d5b) : const Color(0xffdde5e0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xff2e7d5b) : const Color(0xffdde5e0),
                          width: 2.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xff2e7d5b),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        style: GoogleFonts.afacad(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xff17201c) : const Color(0xff5d6b63),
                        ),
                        child: Text(text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2() {
    final options = ['Yes', 'No'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Did you need help to enter?',
          style: GoogleFonts.afacad(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xff17201c),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isSelected = _step2Selection == idx;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx == 0 ? 12.0 : 0.0,
                  left: idx == 1 ? 12.0 : 0.0,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _step2Selection = idx;
                      _neededAssistance = idx == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xfff1f5f3) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xff2e7d5b) : const Color(0xffdde5e0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: GoogleFonts.afacad(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xff2e7d5b) : const Color(0xff5d6b63),
                      ),
                      child: Text(text),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final options = ['Yes', 'Not Sure', 'No'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Was a ramp present at the entrance?',
          style: GoogleFonts.afacad(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xff17201c),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Even if it wasn’t usable, did you see one?',
          style: GoogleFonts.afacad(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: const Color(0xff5d6b63),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isSelected = _step3Selection == idx;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx < 2 ? 10.0 : 0.0,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _step3Selection = idx;
                      _rampUsable = idx == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xfff1f5f3) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xff2e7d5b) : const Color(0xffdde5e0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: GoogleFonts.afacad(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xff2e7d5b) : const Color(0xff5d6b63),
                      ),
                      child: Text(text),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffeaf2ff),
            border: Border.all(color: const Color(0xffc5daff)),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Text(
            'Optional — skip anytime',
            style: GoogleFonts.afacad(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xff3b75d1),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Anything else you noticed?',
          style: GoogleFonts.afacad(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xff17201c),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Surface condition, signage, lighting — anything useful for the next visitor.',
          style: GoogleFonts.afacad(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: const Color(0xff5d6b63),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _noteController,
          minLines: 4,
          maxLines: 5,
          style: GoogleFonts.afacad(
            fontSize: 15,
            color: const Color(0xff17201c),
          ),
          decoration: InputDecoration(
            hintText: 'e.g. The ramp was wet and the signage was unclear...',
            hintStyle: GoogleFonts.afacad(
              fontSize: 15,
              color: const Color(0xff17201c).withOpacity(0.5),
            ),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffdde5e0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xffdde5e0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xff2e7d5b), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(17),
          ),
        ),
      ],
    );
  }

  bool _isCurrentStepValid() {
    if (_currentStep == 1) return _step1Selection != null;
    if (_currentStep == 2) return _step2Selection != null;
    if (_currentStep == 3) return _step3Selection != null;
    return true; // Step 4 is optional
  }

  @override
  Widget build(BuildContext context) {
    final stepWidget = switch (_currentStep) {
      1 => _buildStep1(),
      2 => _buildStep2(),
      3 => _buildStep3(),
      _ => _buildStep4(),
    };

    final isValid = _isCurrentStepValid();
    final isFinalStep = _currentStep == 4;

    return Scaffold(
      backgroundColor: const Color(0xfff8faf9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      _buildAlertBanner(),
                      const SizedBox(height: 16),
                      _buildProgressBar(),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_currentStep),
                          child: stepWidget,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Fixed Bottom Action Bar
            Container(
              color: const Color(0xfff8faf9),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isValid ? const Color(0xff2e7d5b) : const Color(0xffd5e0da),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isValid
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: (!isValid || _isSubmitting)
                              ? null
                              : () {
                                  if (isFinalStep) {
                                    _submit();
                                  } else {
                                    setState(() => _currentStep++);
                                  }
                                },
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isFinalStep ? 'Submit' : 'Continue',
                                    style: GoogleFonts.afacad(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isValid ? Colors.white : const Color(0xffa8b5ae),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentStep > 1)
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (isFinalStep) {
                                  _submit();
                                } else {
                                  setState(() => _currentStep++);
                                }
                              },
                        child: Text(
                          isFinalStep ? 'Skip this step' : 'Skip this question',
                          style: GoogleFonts.afacad(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff5d6b63),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    else
                      Text(
                        'This helps the next person decide before they go.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.afacad(
                          fontSize: 12,
                          color: const Color(0xffa8b5ae),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitConfirmedScreen extends StatelessWidget {
  const _VisitConfirmedScreen({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8faf9),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xffdde5e0), width: 1.0),
                ),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 17, top: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xffeef4f1).withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xff17201c),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONFIRMING VISIT',
                          style: GoogleFonts.afacad(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff5d6b63),
                            letterSpacing: 0.44,
                          ),
                        ),
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.afacad(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff17201c),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Big Check circle
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xffeaf7f0),
                        shape: BoxShape.circle,
                      ),
                      child: const CustomPaint(
                        painter: _CheckmarkPainter(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Visit confirmed',
                      style: GoogleFonts.afacad(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff17201c),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your check-in has been added to ${place.name}'s access record.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.afacad(
                        fontSize: 16,
                        color: const Color(0xff5d6b63),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Info banner
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffdde5e0), width: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "You've helped future visitors make better decisions before they go.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.afacad(
                          fontSize: 15,
                          color: const Color(0xff5d6b63),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Back to place button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xff2e7d5b),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Back to place',
                                  style: GoogleFonts.afacad(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff2e7d5b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the green ring inside (diameter 36, radius 18)
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 18, paint);

    // Draw checkmark inside (centered, radius/thickness matching)
    final path = Path()
      ..moveTo(center.dx - 6, center.dy)
      ..lineTo(center.dx - 1.5, center.dy + 4.5)
      ..lineTo(center.dx + 6, center.dy - 3.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Photo Evidence Item ──────────────────────────────────────────────────────

class PhotoEvidenceItem {
  PhotoEvidenceItem({
    required this.file,
    required this.bytes,
    required this.addedAt,
  });

  final XFile file;
  final Uint8List bytes;
  final DateTime addedAt;
}

// ─────────────────────────────────────────────────────────────────────────────

class EvidenceFlowScreen extends StatefulWidget {
  const EvidenceFlowScreen({
    required this.place,
    required this.placeDimensionId,
    required this.stateService,
    required this.aiService,
    this.imagePickerOverride,
    this.initialPhotos = const <PhotoEvidenceItem>[],
    super.key,
  });

  final Place place;
  final String placeDimensionId;
  final DimensionStateService stateService;
  final AiEvidenceService aiService;
  final ImagePickerOverride? imagePickerOverride;
  final List<PhotoEvidenceItem> initialPhotos;

  @override
  State<EvidenceFlowScreen> createState() => _EvidenceFlowScreenState();
}

enum _EvidenceFlowStep {
  addEvidence,
  rampCapture,
  aiGuidance,
  structureReview,
  reviewPacket,
}

class _EvidenceFlowScreenState extends State<EvidenceFlowScreen> {
  // ── State Machine ────────────────────────────────────────────────────────
  _EvidenceFlowStep _currentStep = _EvidenceFlowStep.addEvidence;

  // ── Photo Accumulation ───────────────────────────────────────────────────
  final List<PhotoEvidenceItem> _photos = [];
  // ── Form State ───────────────────────────────────────────────────────────
  final _noteController = TextEditingController(
    text: 'The entrance has steps and the ramp required assistance.',
  );

  RampSlopeMeasurement? _rampSlopeMeasurement;
  bool _useDemoRampFallback = true;
  int _rampCaptureSessionId = 0;

  // ── AI Analysis State ────────────────────────────────────────────────────
  AiEvidenceAssessment? _assessment;
  bool _isAnalyzing = false;
  String? _analysisError;

  // ── Ramp Capture State ───────────────────────────────────────────────────
  final _rampSlopeCaptureService = const RampSlopeCaptureService();

  // ── Guidance State ───────────────────────────────────────────────────────
  // ── Submission State ────────────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _photos.addAll(widget.initialPhotos);
  }

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

  // ── Photo Management ─────────────────────────────────────────────────────

  Future<void> _addPhoto() async {
    final source = await _showImageSourceSheet();
    if (source == null || !mounted) return;

    final file = widget.imagePickerOverride != null
        ? await widget.imagePickerOverride!(source, 80)
        : await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _photos.add(
        PhotoEvidenceItem(file: file, bytes: bytes, addedAt: DateTime.now()),
      );
      // Reset analysis when new photo is added
      _assessment = null;
      _analysisError = null;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      // Reset analysis when a photo is removed
      _assessment = null;
      _analysisError = null;
    });
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Ramp Slope Capture ───────────────────────────────────────────────────

  void _captureRampSlope() {
    setState(() {
      _rampCaptureSessionId++;
      _currentStep = _EvidenceFlowStep.rampCapture;
    });
  }

  void _onRampCaptureComplete(RampSlopeMeasurement? measurement) {
    setState(() {
      if (measurement != null) {
        _rampSlopeMeasurement = measurement;
      }
      _currentStep = _EvidenceFlowStep.addEvidence;
    });
  }

  // ── AI Analysis ──────────────────────────────────────────────────────────

  Future<void> _analyzeEvidence() async {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      // Analyze with all accumulated photos
      final assessment = await widget.aiService.analyzeMobilityEvidence(
        note: _noteController.text,
        imagePath: _photos.isNotEmpty ? _photos.last.file.path : null,
        rampSlopeMeasurement: _rampSlopeMeasurement,
      );

      if (!mounted) return;

      setState(() {
        _assessment = assessment;
        _isAnalyzing = false;
        _currentStep = _EvidenceFlowStep.aiGuidance;
      });
    } on Object {
      if (!mounted) return;

      setState(() {
        _analysisError =
            'AccessPulse could not structure this evidence. You can retry, or keep the note and measurement for manual review.';
        _isAnalyzing = false;
      });
    }
  }

  // ── Flow Navigation ─────────────────────────────────────────────────────

  void _returnToAddEvidence() {
    setState(() {
      _currentStep = _EvidenceFlowStep.addEvidence;
      // Keep photos accumulated; user can add more
    });
  }

  void _continueToStructure() {
    setState(() {
      _currentStep = _EvidenceFlowStep.structureReview;
    });
  }

  void _skipGuidanceToReview() {
    setState(() {
      _currentStep = _EvidenceFlowStep.reviewPacket;
    });
  }

  void _continueFromStructure() {
    setState(() {
      _currentStep = _EvidenceFlowStep.reviewPacket;
    });
  }

  Future<void> _submitEvidence() async {
    final assessment = _assessment;
    if (assessment == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final result = await widget.stateService.submitStructuredEvidence(
        placeDimensionId: widget.placeDimensionId,
        submittedBy: _demoUserId,
        assessment: assessment,
        imagePath: _photos.isNotEmpty ? _photos.last.file.path : null,
        note: _noteController.text,
        rampSlopeMeasurement: _rampSlopeMeasurement,
      );

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        _submitError =
            'The review packet was not submitted. Please retry while the note and measurement are still on this screen.';
        _isSubmitting = false;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentStep = switch (_currentStep) {
      _EvidenceFlowStep.addEvidence => _buildAddEvidenceStep(),
      _EvidenceFlowStep.rampCapture => _buildRampCaptureStep(),
      _EvidenceFlowStep.aiGuidance => _buildAiGuidanceStep(),
      _EvidenceFlowStep.structureReview => _buildStructureReviewStep(),
      _EvidenceFlowStep.reviewPacket => _buildReviewPacketStep(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const _AccessPulseBrandTitle(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: currentStep,
          ),
        ),
      ),
    );
  }

  // ── Step Builders ────────────────────────────────────────────────────────

  Widget _buildHeader(VoidCallback onBack) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 12),
          child: GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: Color(0xff5d6b63),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Evidence',
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRampCaptureStep() {
    return _RampCaptureStepPage(
      key: ValueKey(_rampCaptureSessionId),
      useDemoFallback: _useDemoRampFallback,
      captureService: _rampSlopeCaptureService,
      onComplete: _onRampCaptureComplete,
    );
  }

  Widget _buildAddEvidenceStep() {
    return ListView(
      key: const ValueKey('step-add-evidence'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(() => Navigator.of(context).pop()),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  icon: Icons.photo_camera_outlined,
                  title: 'Photo evidence',
                ),
                const SizedBox(height: 16),
                if (_photos.isEmpty)
                  _EmptyBin(
                    colorScheme: Theme.of(context).colorScheme,
                    onTap: _addPhoto,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      photo.bytes,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(160),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add another photo'),
                        onPressed: _addPhoto,
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Review note',
                    hintText: 'e.g. Ramp is too steep...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                if (_shouldOfferRampSlopeCapture) ...[
                  _RampSlopeCapturePanel(
                    measurement: _rampSlopeMeasurement,
                    useDemoFallback: _useDemoRampFallback,
                    onDemoFallbackChanged: (value) {
                      setState(() => _useDemoRampFallback = value);
                    },
                    onStart: _captureRampSlope,
                    onRetry: _captureRampSlope,
                  ),
                  const SizedBox(height: 20),
                ],
                if (_analysisError != null) ...[
                  _InlineNotice(
                    icon: Icons.error_outline,
                    message: _analysisError!,
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isAnalyzing ? 'Analyzing...' : 'Analyze evidence',
                    ),
                    onPressed: _isAnalyzing ? null : _analyzeEvidence,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiGuidanceStep() {
    final assessment = _assessment;
    if (assessment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      key: const ValueKey('step-ai-guidance'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(_returnToAddEvidence),
        const SizedBox(height: 20),
        _AiGuidanceCard(
          assessment: assessment,
          onAddAnotherPhoto: _returnToAddEvidence,
          onContinueAnyway: _continueToStructure,
          onSkipGuidance: _skipGuidanceToReview,
        ),
      ],
    );
  }

  Widget _buildStructureReviewStep() {
    final assessment = _assessment;
    if (assessment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      key: const ValueKey('step-structure-review'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(
          () => setState(() => _currentStep = _EvidenceFlowStep.aiGuidance),
        ),
        const SizedBox(height: 20),
        _AiResultPanel(assessment: assessment),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue to review packet'),
            onPressed: _continueFromStructure,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPacketStep() {
    final assessment = _assessment;
    if (assessment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      key: const ValueKey('step-review-packet'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(
          () =>
              setState(() => _currentStep = _EvidenceFlowStep.structureReview),
        ),
        const SizedBox(height: 20),
        _ReviewPacketPanel(
          assessment: assessment,
          hasPhoto: _photos.isNotEmpty,
          hasRampMeasurement: _rampSlopeMeasurement != null,
        ),
        const SizedBox(height: 20),
        if (_submitError != null) ...[
          _InlineNotice(icon: Icons.error_outline, message: _submitError!),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(
              _isSubmitting ? 'Submitting...' : 'Submit Review Packet',
            ),
            onPressed: _isSubmitting ? null : _submitEvidence,
          ),
        ),
      ],
    );
  }
}

// ── Helper Widget ────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Photo upload bin
// ─────────────────────────────────────────────────────────────────────────────

/// A rectangular upload container that sits inside the evidence card.
///
/// **Empty state** — a dashed-border tap target prompts the user to add a photo.
/// **Filled state** — renders the selected image as a thumbnail with
/// "Remove" and "Change photo" action buttons overlaid at the bottom.
///
/// This widget is purely presentational; all business logic lives in
/// [_EvidenceFlowScreenState._pickImage] and [_EvidenceFlowScreenState._removePhoto].

class _EmptyBin extends StatelessWidget {
  const _EmptyBin({required this.colorScheme, required this.onTap});

  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: colorScheme.outlineVariant),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 10),
              Text(
                'Tap to add a photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gallery or camera  ·  JPG / PNG',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = Radius.circular(10);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────

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
      appBar: AppBar(title: const _AccessPulseBrandTitle()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.82, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Color(0xff2e7d5b),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.afacad(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff17201c),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff5d6b63),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: GoogleFonts.afacad(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff17201c),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TransitionRow(
                          label: 'Current accessibility state',
                          before: previousState.state.label,
                          after: currentState.state.label,
                        ),
                        const Divider(height: 24, color: Color(0xffdde5e0)),
                        _TransitionRow(
                          label: 'Pulse / freshness',
                          before: previousPulseDisplay.label,
                          after: currentPulseDisplay.label,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentState.explanation,
                          style: GoogleFonts.afacad(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff17201c),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentPulseDisplay.explanation,
                          style: GoogleFonts.afacad(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff5d6b63),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (nextAction != null) ...[
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
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to home'),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
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

  Widget _buildBar(int heightMultiplier, bool active) {
    return Container(
      width: 3.5,
      height: 4.0 * heightMultiplier,
      decoration: BoxDecoration(
        color: active ? const Color(0xff2e7d5b) : const Color(0xffdde5e0),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PlaceListData>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final publicState = _publicStateDisplay(
          state: data.state,
          latestCase: data.latestCase,
        );
        final stateColor = publicState.color;
        final stateLabel = publicState.label;
        final pulseDisplay = const PulseService().describePlacePulse(
          state: data.state,
          pulse: data.pulse,
        );

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
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
                                color: stateColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: stateColor.withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: stateColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    stateLabel,
                                    style: GoogleFonts.afacad(
                                      color: stateColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${place.placeType} · ${pulseDisplay.label}',
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
                          place.name,
                          style: GoogleFonts.afacad(
                            color: const Color(0xff17201c),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Color(0xff5d6b63),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address ?? place.municipality ?? '',
                                style: GoogleFonts.afacad(
                                  color: const Color(0xff5d6b63),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar(1, data.pulse.score >= 0.2),
                              const SizedBox(width: 2),
                              _buildBar(2, data.pulse.score >= 0.5),
                              const SizedBox(width: 2),
                              _buildBar(3, data.pulse.score >= 0.8),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(data.pulse.score * 100).toInt()}%',
                            style: GoogleFonts.afacad(
                              color: const Color(0xff2e7d5b),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xff5d6b63),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    final latestCase = await _latestCaseForPlaceDimension(
      repository,
      placeDimension.id,
    );
    return _PlaceListData(state: state, pulse: pulse, latestCase: latestCase);
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({
    required this.repository,
    required this.place,
    required this.onTap,
  });

  final AccessPulseRepository repository;
  final Place place;
  final VoidCallback onTap;

  Future<_PlaceListData> _load() async {
    final placeDimension = await repository.getPlaceDimensionForPlace(
      placeId: place.id,
      dimensionKey: _mobilityDimensionKey,
    );
    final state = await repository.getDimensionState(placeDimension.id);
    final pulse = await repository.getDimensionPulse(placeDimension.id);
    final latestCase = await _latestCaseForPlaceDimension(
      repository,
      placeDimension.id,
    );
    return _PlaceListData(state: state, pulse: pulse, latestCase: latestCase);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PlaceListData>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final publicState = _publicStateDisplay(
          state: data.state,
          latestCase: data.latestCase,
        );
        final stateColor = publicState.color;
        final stateLabel = publicState.label;
        final pulseDisplay = const PulseService().describePlacePulse(
          state: data.state,
          pulse: data.pulse,
        );

        final reliabilityScore = data.pulse.score;
        final reliabilityPercent = (reliabilityScore * 100).toInt();

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff2e7d5b),
                        Color(0xff62ba8f),
                        Color(0xffdde5e0),
                      ],
                      stops: [0.0, 0.62, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: GoogleFonts.afacad(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff17201c),
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: stateColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: stateColor.withValues(alpha: 0.3),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: stateColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  stateLabel,
                                  style: GoogleFonts.afacad(
                                    color: stateColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pulseDisplay.explanation,
                        style: GoogleFonts.afacad(
                          fontSize: 14,
                          color: const Color(0xff5e7268),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xffdde5e0)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RELIABILITY',
                            style: GoogleFonts.afacad(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff5e7268),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            pulseDisplay.label,
                            style: GoogleFonts.afacad(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff17201c),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xffdde5e0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: reliabilityScore.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff2e7d5b),
                                        Color(0xff3daf7a),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$reliabilityPercent%',
                            style: GoogleFonts.afacad(
                              color: const Color(0xff2e7d5b),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xffdde5e0)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Color(0xff5e7268),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Last confirmed Today',
                                style: GoogleFonts.afacad(
                                  fontSize: 12,
                                  color: const Color(0xff5e7268),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffeef4f1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 11,
                                  color: Color(0xff2e7d5b),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: GoogleFonts.afacad(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff2e7d5b),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (pulseDisplay.verificationContext != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xfff8faf9),
                            border: Border.all(color: const Color(0xffdde5e0)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.8,
                            vertical: 10.8,
                          ),
                          child: Text(
                            pulseDisplay.verificationContext!,
                            style: GoogleFonts.afacad(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff5e7268),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FigmaPill extends StatelessWidget {
  const _FigmaPill({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.afacad(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.115,
        ),
      ),
    );
  }
}

class _FigmaDetailRow extends StatelessWidget {
  const _FigmaDetailRow({
    required this.label,
    required this.value,
    this.hasBorder = false,
  });

  final String label;
  final String value;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hasBorder
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xffdde5e0))),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: GoogleFonts.afacad(
                  fontSize: 15,
                  color: const Color(0xff5d6b63),
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.afacad(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff17201c),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.placeName,
    required this.state,
    required this.pulse,
    required this.latestCase,
  });

  final String placeName;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final AccessCase? latestCase;

  @override
  Widget build(BuildContext context) {
    final pulseDisplay = const PulseService().describePlacePulse(
      state: state,
      pulse: pulse,
    );
    final publicState = _publicStateDisplay(
      state: state,
      latestCase: latestCase,
    );
    final stateLabel = publicState.label;
    final confidenceLevel = _confidenceLevelFromScore(state.confidence);
    final confidenceExplanation = _confidenceExplanationFromScore(
      state.confidence,
    );
    final lastConfirmedStr = state.lastConfirmedAt == null
        ? 'Unknown'
        : _formatDate(state.lastConfirmedAt!);

    final contextLines = [
      state.explanation,
      pulseDisplay.explanation,
      if (pulseDisplay.verificationContext != null)
        pulseDisplay.verificationContext!,
    ];

    return _FadeSlideIn(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffdde5e0)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff17201c).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top gradient stripe
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff4da87a), Color(0xff9eb5a6)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    placeName,
                    style: GoogleFonts.afacad(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff17201c),
                      letterSpacing: -0.25,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  Text(
                    'For you: Mobility Access',
                    style: GoogleFonts.afacad(
                      fontSize: 12.5,
                      color: const Color(0xff5d6b63),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _FigmaPill(
                        label: '🦽 $stateLabel',
                        bgColor: const Color(0xfffbf5e8),
                        borderColor: const Color(0xffe5d4a0),
                        textColor: const Color(0xff7a5c1e),
                      ),
                      _FigmaPill(
                        label: '📶 ${pulseDisplay.label}',
                        bgColor: const Color(0xfff3f7f4),
                        borderColor: const Color(0xffdde5e0),
                        textColor: const Color(0xff5d6b63),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Detail rows
                  _FigmaDetailRow(
                    label: 'Dimension',
                    value: 'Mobility Access',
                    hasBorder: true,
                  ),
                  _FigmaDetailRow(
                    label: 'Current state',
                    value: stateLabel,
                    hasBorder: true,
                  ),
                  _FigmaDetailRow(
                    label: 'Freshness / pulse',
                    value: pulseDisplay.label,
                    hasBorder: true,
                  ),
                  // Confidence row — value + sub-explanation stacked
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xffdde5e0)),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              'Confidence',
                              style: GoogleFonts.afacad(
                                fontSize: 15,
                                color: const Color(0xff5d6b63),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  confidenceLevel.label,
                                  style: GoogleFonts.afacad(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xff17201c),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  confidenceExplanation,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.afacad(
                                    fontSize: 11.5,
                                    color: const Color(0xff5d6b63),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Last confirmed row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last confirmed',
                          style: GoogleFonts.afacad(
                            fontSize: 15,
                            color: const Color(0xff5d6b63),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: Color(0xff5d6b63),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lastConfirmedStr,
                              style: GoogleFonts.afacad(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xff17201c),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Horizontal divider
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xffdde5e0),
                  ),
                  const SizedBox(height: 8),
                  // Context lines with left border
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in contextLines) ...[
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Color(0xffdde5e0),
                                width: 2,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            line,
                            style: GoogleFonts.afacad(
                              fontSize: 14,
                              color: const Color(0xff5d6b63),
                              height: 1.33,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
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

class _IssueSummaryBlock extends StatelessWidget {
  const _IssueSummaryBlock({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffdde5e0), width: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff17201c).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xff2e7d5b),
              ),
              const SizedBox(width: 8),
              Text(
                'Current Issue Summary',
                style: GoogleFonts.afacad(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff5e7268),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: GoogleFonts.afacad(
              fontSize: 15,
              color: const Color(0xff17201c),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            const Divider(),
            _MetricRow(
              label: 'Confidence',
              value: assessment.confidenceLevel.label,
            ),
            const Divider(),
            _MetricRow(
              label: 'Evidence readiness',
              value: assessment.evidenceReadiness.label,
            ),
            const SizedBox(height: 8),
            Text(assessment.confidenceExplanation),
            const SizedBox(height: 8),
            Text(assessment.summary),
            const SizedBox(height: 12),
            Text('Observed', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final feature in assessment.observedFeatures)
                  Chip(
                    label: Text(
                      feature,
                      style: const TextStyle(color: Color(0xFF17201C)),
                    ),
                    backgroundColor: const Color(0xFFC8DDD4),
                    shape: const StadiumBorder(
                      side: BorderSide(color: Color(0xFF17201C), width: 1.0),
                    ),
                  ),
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

class _AiGuidanceCard extends StatelessWidget {
  const _AiGuidanceCard({
    required this.assessment,
    required this.onAddAnotherPhoto,
    required this.onContinueAnyway,
    required this.onSkipGuidance,
  });

  final AiEvidenceAssessment assessment;
  final VoidCallback? onAddAnotherPhoto;
  final VoidCallback onContinueAnyway;
  final VoidCallback onSkipGuidance;

  @override
  Widget build(BuildContext context) {
    final missing = assessment.missingEvidence.isEmpty
        ? 'No major missing evidence.'
        : assessment.missingEvidence.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.tips_and_updates_outlined,
              title: 'AI Guidance',
            ),
            const SizedBox(height: 12),
            Text('Observed', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final feature in assessment.observedFeatures)
                  Chip(
                    label: Text(
                      feature,
                      style: const TextStyle(color: Color(0xFF17201C)),
                    ),
                    backgroundColor: const Color(0xFFC8DDD4),
                    shape: const StadiumBorder(
                      side: BorderSide(color: Color(0xFF17201C), width: 1.0),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricRow(label: 'Missing', value: missing),
            const Divider(),
            _MetricRow(
              label: 'Confidence',
              value: assessment.confidenceLevel.label,
            ),
            const Divider(),
            _MetricRow(
              label: 'Evidence readiness',
              value: assessment.evidenceReadiness.label,
            ),
            const SizedBox(height: 8),
            Text(assessment.confidenceExplanation),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended next step:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    assessment.nextBestAction,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add another photo'),
                    onPressed: onAddAnotherPhoto,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue anyway'),
                    onPressed: onContinueAnyway,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Skip'),
                    onPressed: onSkipGuidance,
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

class _ReviewPacketPanel extends StatelessWidget {
  const _ReviewPacketPanel({
    required this.assessment,
    required this.hasPhoto,
    required this.hasRampMeasurement,
  });

  final AiEvidenceAssessment assessment;
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
            const SizedBox(height: 10),
            _PacketStep(
              icon: Icons.psychology_alt_outlined,
              title: 'Confidence',
              body:
                  '${assessment.confidenceLevel.label}: ${assessment.confidenceExplanation}',
            ),
            const SizedBox(height: 10),
            _PacketStep(
              icon: Icons.verified_outlined,
              title: 'Evidence readiness',
              body:
                  '${assessment.evidenceReadiness.label}: ${assessment.institutionReady ? 'sufficient evidence collected for LGU review.' : 'useful evidence, with missing context kept visible.'}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF2E7D5B),
                  ),
                  label: Text(
                    'Note included',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shape: StadiumBorder(),
                ),
                Chip(
                  avatar: hasPhoto
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF2E7D5B),
                        )
                      : null,
                  label: Text(
                    hasPhoto ? 'Photo included' : 'No photo yet',
                    style: TextStyle(
                      fontWeight: hasPhoto
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: hasPhoto ? null : Colors.grey.shade700,
                    ),
                  ),
                  shape: const StadiumBorder(),
                ),
                Chip(
                  avatar: assessment.institutionReady
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF2E7D5B),
                        )
                      : null,
                  label: Text(
                    assessment.evidenceReadiness.label,
                    style: TextStyle(
                      fontWeight: assessment.institutionReady
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: assessment.institutionReady
                          ? null
                          : Colors.grey.shade700,
                    ),
                  ),
                  shape: const StadiumBorder(),
                ),
                Chip(
                  avatar: assessment.confidenceLevel.label.contains('High')
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF2E7D5B),
                        )
                      : null,
                  label: Text(
                    'Confidence: ${assessment.confidenceLevel.label}',
                    style: TextStyle(
                      fontWeight:
                          assessment.confidenceLevel.label.contains('High')
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: assessment.confidenceLevel.label.contains('High')
                          ? null
                          : Colors.grey.shade700,
                    ),
                  ),
                  shape: const StadiumBorder(),
                ),
                Chip(
                  avatar: hasRampMeasurement
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFF2E7D5B),
                        )
                      : null,
                  label: Text(
                    hasRampMeasurement
                        ? 'Ramp reading included'
                        : 'No ramp reading yet',
                    style: TextStyle(
                      fontWeight: hasRampMeasurement
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: hasRampMeasurement ? null : Colors.grey.shade700,
                    ),
                  ),
                  shape: const StadiumBorder(),
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
        Icon(icon, size: 20, color: const Color(0xFF2E7D5B)),
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
  const _MemoryTile({
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  final MemoryEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (icon, bgColor, iconColor) = _getTimelineConfig(event.eventType);
    final dateLabel = _getEventDateLabel(event.createdAt);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 28,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: const Color(0xffdde5e0),
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: GoogleFonts.afacad(
                    color: const Color(0xff2e7d5b),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.44,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.summary,
                  style: GoogleFonts.afacad(
                    color: const Color(0xff17201c),
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getTimelineConfig(MemoryEventType type) {
    return switch (type) {
      MemoryEventType.caseOpened ||
      MemoryEventType.caseTriaged ||
      MemoryEventType.verificationSubmitted ||
      MemoryEventType.remediationRequested ||
      MemoryEventType.remediationVerificationRequested => (
        Icons.info_outline,
        const Color(0xfffff0e6),
        const Color(0xffea580c),
      ),
      MemoryEventType.aiSignalCreated => (
        Icons.auto_awesome,
        const Color(0xffeef4f1),
        const Color(0xff2e7d5b),
      ),
      MemoryEventType.inspectionRequested || MemoryEventType.evidenceAdded => (
        Icons.camera_alt_outlined,
        const Color(0xffeef4f1),
        const Color(0xff2e7d5b),
      ),
      _ => (Icons.check, const Color(0xffeef4f1), const Color(0xff2e7d5b)),
    };
  }

  String _getEventDateLabel(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    if (difference == 0 && now.day == dateTime.day) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return _formatDate(dateTime);
    }
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
        title: Text(
          title,
          style: GoogleFonts.afacad(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xff17201c),
          ),
        ),
        activeThumbColor: const Color(0xff2e7d5b),
        activeTrackColor: const Color(0xffe8eee9),
        inactiveThumbColor: const Color(0xff5d6b63),
        inactiveTrackColor: const Color(0xffdde5e0),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({this.icon, this.customIcon, required this.title});

  final IconData? icon;
  final Widget? customIcon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffDDE5E0), width: 1)),
      ),
      child: Row(
        children: [
          customIcon ?? Icon(icon, size: 18, color: const Color(0xff2e7d5b)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

class _PlaceListData {
  const _PlaceListData({
    required this.state,
    required this.pulse,
    required this.latestCase,
  });

  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final AccessCase? latestCase;
}

class _PlaceDetailData {
  const _PlaceDetailData({
    required this.placeDimension,
    required this.state,
    required this.pulse,
    required this.memory,
    required this.latestCase,
    required this.latestBarrierSignal,
  });

  final PlaceDimension placeDimension;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final List<MemoryEvent> memory;
  final AccessCase? latestCase;
  final BarrierSignal? latestBarrierSignal;
}

class PublicResultNextAction {
  const PublicResultNextAction.addEvidence({
    required this.placeDimensionId,
    required this.stateService,
  });

  final String placeDimensionId;
  final DimensionStateService stateService;
}

class _PublicStateDisplay {
  const _PublicStateDisplay({required this.label, required this.color});

  final String label;
  final Color color;
}

Future<AccessCase?> _latestCaseForPlaceDimension(
  AccessPulseRepository repository,
  String placeDimensionId,
) async {
  final cases = await repository.listCases();
  for (final accessCase in cases) {
    if (accessCase.placeDimensionId == placeDimensionId) {
      return accessCase;
    }
  }
  return null;
}

Future<BarrierSignal?> _barrierSignalForCase(
  AccessPulseRepository repository,
  AccessCase? latestCase,
) async {
  final barrierSignalId = latestCase?.barrierSignalId;
  if (barrierSignalId == null) {
    return null;
  }
  try {
    return await repository.getBarrierSignal(barrierSignalId);
  } on StateError {
    return null;
  }
}

_PublicStateDisplay _publicStateDisplay({
  required DimensionStateRecord state,
  required AccessCase? latestCase,
}) {
  final status = latestCase?.status;
  if (status == CaseStatus.remediationRequested ||
      status == CaseStatus.remediationVerificationRequested) {
    return const _PublicStateDisplay(
      label: 'Under Remediation',
      color: Color(0xff8a6d00),
    );
  }

  if (state.state == DimensionStateValue.resolved) {
    if (status == CaseStatus.closed) {
      return const _PublicStateDisplay(
        label: 'Recently Revalidated',
        color: Color(0xff17643a),
      );
    }
    return const _PublicStateDisplay(
      label: 'Resolved',
      color: Color(0xff17643a),
    );
  }

  return _PublicStateDisplay(
    label: state.state.label,
    color: state.state.color,
  );
}

String _publicIssueSummary({
  required DimensionStateRecord state,
  required AccessCase? latestCase,
  required BarrierSignal? barrierSignal,
}) {
  final status = latestCase?.status;
  if (status == CaseStatus.remediationRequested ||
      status == CaseStatus.remediationVerificationRequested) {
    return 'A confirmed mobility access issue is currently under remediation.';
  }

  if (state.state == DimensionStateValue.resolved) {
    if (status == CaseStatus.closed) {
      return 'This place was recently revalidated after remediation.';
    }
    return 'The reported mobility access issue has been fixed and is awaiting final closure.';
  }

  if (barrierSignal != null &&
      state.state == DimensionStateValue.officiallyVerifiedDegraded) {
    return _barrierSignalSummary(barrierSignal);
  }

  return 'No active accessibility issue summary is currently available.';
}

String _barrierSignalSummary(BarrierSignal signal) {
  final issueType = signal.issueType.toLowerCase();
  final possibleBarrier = signal.possibleBarrier.toLowerCase();
  final observedFeatures = signal.observedFeatures
      .map((feature) => feature.toLowerCase())
      .toList();

  if (issueType.contains('ramp') ||
      observedFeatures.any((feature) => feature.contains('ramp'))) {
    if (possibleBarrier.contains('steep') ||
        possibleBarrier.contains('slope')) {
      return 'Ramp was reported to be too steep for independent wheelchair access.';
    }
    return 'Ramp access was reported to be unreliable for independent wheelchair access.';
  }

  if (issueType.contains('entrance') ||
      observedFeatures.any((feature) => feature.contains('entrance'))) {
    return 'The main entrance was reported to require assistance.';
  }

  return 'A confirmed mobility access issue is visible in the latest public report.';
}

extension on DimensionStateValue {
  String get label {
    return switch (this) {
      DimensionStateValue.unknown => 'Unknown',
      DimensionStateValue.claimedAccessible => 'Claimed accessible',
      DimensionStateValue.reliable => 'Reliable',
      DimensionStateValue.degraded => 'Degraded',
      DimensionStateValue.officiallyVerifiedDegraded =>
        'Officially Verified Degraded',
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
      'Recent evidence strongly supports the current Mobility Access state.',
    ConfidenceLevel.moderate =>
      'The current state is supported, but some context should still be refreshed.',
    ConfidenceLevel.low =>
      'Current evidence is limited, so this state should be treated cautiously.',
  };
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

class _BeenToPlacesCard extends StatelessWidget {
  const _BeenToPlacesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffedf2ef),
        border: Border.all(color: const Color(0xffdde5e0), width: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xffd0e8dc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xff2e7d5b),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Been to one of these places recently?',
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff17201c),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your confirmation helps others know what to expect. Ground truth expires — every update counts.',
                  style: GoogleFonts.afacad(
                    fontSize: 12,
                    color: const Color(0xff5d6b63),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPulseBrandTitle extends StatelessWidget {
  const _AccessPulseBrandTitle();

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
      style: const TextStyle(fontSize: 20),
    );
  }
}

// ── Ramp Slope UI ────────────────────────────────────────────────────────────

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
        _SectionHeader(
          customIcon: Transform.rotate(
            angle: -45 * 3.1415926535 / 180,
            child: const Icon(
              Icons.straighten,
              color: Color(0xFF4A5A52),
              size: 24,
            ),
          ),
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
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(width: 2, color: Colors.black),
          ),
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
      key: const ValueKey('ramp-slope-success'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.check_circle_outline,
          title: 'Slope captured',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${measurement.estimatedAngleDegrees.toStringAsFixed(1)}°',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'estimated incline',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Retake measurement'),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _RampCaptureStepPage extends StatefulWidget {
  const _RampCaptureStepPage({
    required this.useDemoFallback,
    required this.captureService,
    required this.onComplete,
    super.key,
  });

  final bool useDemoFallback;
  final RampSlopeCaptureService captureService;
  final ValueChanged<RampSlopeMeasurement?> onComplete;

  @override
  State<_RampCaptureStepPage> createState() => _RampCaptureStepPageState();
}

enum _DialogCaptureState { countdown, success, failure }

class _RampCaptureStepPageState extends State<_RampCaptureStepPage>
    with SingleTickerProviderStateMixin {
  _DialogCaptureState _state = _DialogCaptureState.countdown;
  RampSlopeMeasurement? _measurement;
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _startCapture();
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _startCapture() async {
    setState(() {
      _state = _DialogCaptureState.countdown;
      _measurement = null;
    });

    _countdownController.forward(from: 0.0);

    final measurement = widget.useDemoFallback
        ? await _captureDemoRampSlope()
        : await widget.captureService.capture();

    if (!mounted) return;

    setState(() {
      _measurement = measurement;
      if (measurement.isUsable) {
        _state = _DialogCaptureState.success;
      } else {
        _state = _DialogCaptureState.failure;
      }
    });
  }

  Future<RampSlopeMeasurement> _captureDemoRampSlope() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    return RampSlopeCaptureService.fallbackMeasurement(
      capturedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onComplete(null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xfff1f4f2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xff5d6b63),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Measure Ramp Slope',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff17201c),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xffDDE5E0)),
        Expanded(
          child: Container(
            color: const Color(0xFFF9FAF9),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.useDemoFallback)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffDDE5E0)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D5B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Demo-safe capture — using sample reading',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff5d6b63),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _DialogCaptureState.countdown:
        return _buildCountdown();
      case _DialogCaptureState.success:
        return _buildSuccess();
      case _DialogCaptureState.failure:
        return _buildFailure();
    }
  }

  Widget _buildCountdown() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 200),
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _countdownController,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _countdownController.value,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xffDDE5E0),
                    color: const Color(0xFF2E7D5B),
                  );
                },
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _countdownController,
                  builder: (context, child) {
                    final secondsLeft =
                        3 - (_countdownController.value * 3).floor();
                    return Text(
                      secondsLeft > 0 ? secondsLeft.toString() : '1',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff17201c),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Image.asset('assets/images/ramp_slope_countdown.png'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Hold your device steady against the\nramp surface.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Measuring incline...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xffE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2E7D5B),
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Slope captured',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xff17201c),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${_measurement!.estimatedAngleDegrees.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: Color(0xff17201c),
            ),
          ),
        ),
        const Center(
          child: Text(
            'ESTIMATED INCLINE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: Color(0xff5d6b63),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffDDE5E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricRow(label: 'Quality', value: _measurement!.qualityLabel),
              const Divider(color: Color(0xffDDE5E0)),
              _MetricRow(label: 'Source', value: _measurement!.sourceLabel),
              const Divider(color: Color(0xffDDE5E0)),
              _MetricRow(
                label: 'Capture window',
                value:
                    '${(_measurement!.captureDurationMs / 1000).toStringAsFixed(1)}s',
              ),
              const Divider(color: Color(0xffDDE5E0)),
              _MetricRow(
                label: 'Samples',
                value: '${_measurement!.sampleCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffDDE5E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'This is an estimated field measurement to support review. Official verification may still be required.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xff5d6b63)),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D5B),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => widget.onComplete(_measurement),
          child: const Text('Use this reading', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xffDDE5E0)),
          ),
          icon: const Icon(Icons.refresh, color: Color(0xff17201c)),
          label: const Text(
            'Retake',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff17201c),
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _startCapture,
        ),
      ],
    );
  }

  Widget _buildFailure() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xffFFF3E0),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: Color(0xffE65100),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Capture incomplete',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xff17201c),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "We couldn't get a stable reading. Try holding the device steady against the ramp surface.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xff5d6b63), height: 1.5),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffDDE5E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'A slope reading is optional — you can still submit evidence without it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xff5d6b63)),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D5B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _startCapture,
            child: const Text('Try again', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xffDDE5E0)),
            ),
            onPressed: () => widget.onComplete(null),
            child: const Text(
              'Skip slope reading',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xff17201c),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RampSlopeCapturePanel extends StatelessWidget {
  const _RampSlopeCapturePanel({
    required this.measurement,
    required this.useDemoFallback,
    required this.onDemoFallbackChanged,
    required this.onStart,
    required this.onRetry,
  });

  final RampSlopeMeasurement? measurement;
  final bool useDemoFallback;
  final ValueChanged<bool>? onDemoFallbackChanged;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.science_outlined,
                color: Color(0xFF2E7D5B),
              ),
              title: const Text('Demo-safe capture'),
              subtitle: const Text(
                'Use the seeded 14.8 deg sample for a reliable live demo.',
              ),
              value: useDemoFallback,
              onChanged: onDemoFallbackChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: measurement != null
                  ? _RampSlopeSuccessState(
                      key: ValueKey(measurement!.capturedAt),
                      measurement: measurement!,
                      onRetry: onRetry,
                    )
                  : _RampSlopeEntryState(
                      useDemoFallback: useDemoFallback,
                      onStart: onStart,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
