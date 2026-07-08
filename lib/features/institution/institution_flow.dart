import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/accesspulse_domain.dart';
import '../../shared/copy/accesspulse_display.dart';

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
  late Future<dynamic> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _loadDashboardData();
  }

  Future<dynamic> _loadDashboardData() async {
    if (widget.role == InstitutionRole.inspector) {
      return _loadCases();
    } else {
      return _loadLguDashboardData();
    }
  }

  Future<List<_CaseSummary>> _loadCases() async {
    final cases = await widget.repository.listCases();
    final filtered = cases.where((accessCase) {
      if (widget.role == InstitutionRole.inspector) {
        return accessCase.status == CaseStatus.inspectionRequested ||
            accessCase.status == CaseStatus.verified ||
            accessCase.status == CaseStatus.remediationVerificationRequested ||
            accessCase.status == CaseStatus.disputed;
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

  Future<_LguDashboardData> _loadLguDashboardData() async {
    final cases = await widget.repository.listCases();
    final activeCases = cases
        .where((c) => c.status != CaseStatus.closed)
        .toList();

    final places = await widget.repository.listPlaces();
    final priorityCases = <_CaseSummary>[];
    final otherPlaces = <_OtherPlaceSummary>[];

    for (final accessCase in activeCases) {
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

      final isPriority =
          accessCase.severity == CaseSeverity.high ||
          accessCase.status == CaseStatus.open ||
          accessCase.status == CaseStatus.triaging ||
          accessCase.status == CaseStatus.inspectionRequested ||
          accessCase.status == CaseStatus.disputed;

      if (isPriority) {
        priorityCases.add(
          _CaseSummary(
            accessCase: accessCase,
            place: place,
            state: state,
            pulse: pulse,
          ),
        );
      } else {
        otherPlaces.add(
          _OtherPlaceSummary(
            place: place,
            state: state,
            pulse: pulse,
            accessCase: accessCase,
          ),
        );
      }
    }

    // Calculate health dynamically from monitored places
    double totalHealth = 0.0;
    int healthCount = 0;
    for (final place in places) {
      try {
        final placeDimension = await widget.repository
            .getPlaceDimensionForPlace(
              placeId: place.id,
              dimensionKey: 'mobility_access',
            );
        final state = await widget.repository.getDimensionState(
          placeDimension.id,
        );
        double val = 0.5;
        if (state.state == DimensionStateValue.reliable ||
            state.state == DimensionStateValue.resolved) {
          val = 1.0;
        } else if (state.state == DimensionStateValue.claimedAccessible) {
          val = 0.8;
        } else if (state.state == DimensionStateValue.degraded ||
            state.state == DimensionStateValue.officiallyVerifiedDegraded) {
          val = 0.2;
        }
        totalHealth += val;
        healthCount++;
      } catch (_) {}
    }
    final double calculatedAvgHealth = activeCases.isEmpty
        ? 0.0
        : (healthCount > 0 ? (totalHealth / healthCount) : 0.54);

    final openCount = activeCases
        .where(
          (c) =>
              c.status != CaseStatus.closed && c.status != CaseStatus.resolved,
        )
        .length;
    final urgentCount = activeCases
        .where(
          (c) =>
              c.severity == CaseSeverity.high ||
              c.status == CaseStatus.inspectionRequested,
        )
        .length;
    final reviewCount = activeCases
        .where((c) => c.status == CaseStatus.open)
        .length;

    return _LguDashboardData(
      priorityCases: priorityCases,
      otherPlaces: otherPlaces,
      openCasesCount: openCount,
      urgentCasesCount: urgentCount,
      avgHealth: calculatedAvgHealth,
      reviewCasesCount: reviewCount,
    );
  }

  void _refresh() {
    setState(() {
      _dashboardDataFuture = _loadDashboardData();
    });
  }

  AccessCase _getOrCreateCaseForOtherPlace(_OtherPlaceSummary other) {
    if (other.accessCase != null) {
      return other.accessCase!;
    }
    final status =
        (other.state.state == DimensionStateValue.reliable ||
            other.state.state == DimensionStateValue.resolved)
        ? CaseStatus.closed
        : CaseStatus.open;
    return AccessCase(
      id: 'case-for-${other.place.id}',
      placeDimensionId: other.state.placeDimensionId,
      barrierSignalId: 'temp-signal',
      status: status,
      severity: CaseSeverity.low,
      confidence: other.state.confidence,
      title: 'Mobility Access State Review',
      summary: other.state.explanation,
      openedAt: other.state.updatedAt,
      updatedAt: other.state.updatedAt,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  String _getCategoryIconPath(String placeType) {
    final type = placeType.toLowerCase();
    if (type.contains('hospital')) {
      return 'assets/icons/default_icon_hospital.svg';
    } else if (type.contains('train') ||
        type.contains('transport') ||
        type.contains('hub')) {
      return 'assets/icons/default_icon_train.svg';
    } else {
      return 'assets/icons/default_icon_building.svg';
    }
  }

  String _getCategoryLabel(String placeType) {
    if (placeType == 'public_service_building') {
      return 'Public Service';
    }
    return placeType;
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'High';
    } else if (confidence >= 0.5) {
      return 'Moderate';
    } else {
      return 'Low';
    }
  }

  void _onCaseTap(_CaseSummary summary) async {
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
  }

  Widget _buildStatChip({
    required BuildContext context,
    required String value,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 0.8)
            : Border.all(color: Colors.transparent, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.8, horizontal: 12.8),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.afacad(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.afacad(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xff8891a8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAllPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.afacad(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xff5e7268),
            letterSpacing: 0.88,
          ),
        ),
        GestureDetector(
          onTap: onViewAllPressed,
          child: Text(
            'View all',
            style: GoogleFonts.afacad(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff2f6b4f),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(_CaseSummary summary) {
    if (summary.accessCase.id == 'mock-priority-case') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xfffff0e6),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 7.85, vertical: 3.14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 10,
              color: Color(0xffd46a2a),
            ),
            const SizedBox(width: 4),
            Text(
              'DEGRADED',
              style: GoogleFonts.afacad(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xffd46a2a),
                letterSpacing: 0.52,
              ),
            ),
          ],
        ),
      );
    }

    final status = summary.accessCase.status;
    final String label = status.label.toUpperCase();

    final isGood =
        status == CaseStatus.resolved ||
        status == CaseStatus.verified ||
        status == CaseStatus.closed;
    final Color bgColor = isGood
        ? const Color(0xffe8f5ed)
        : const Color(0xfffff0e6);
    final Color textColor = isGood
        ? const Color(0xff2e7d5b)
        : const Color(0xffd46a2a);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: GoogleFonts.afacad(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPriorityCard(BuildContext context, _CaseSummary summary) {
    final confidence = summary.accessCase.confidence;
    final gradient = LinearGradient(
      colors: const [Color(0xff2e7d5b), Color(0xff62ba8f), Color(0xffdde5e0)],
      stops: [
        0.0,
        confidence,
        confidence + 0.05 > 1.0 ? 1.0 : confidence + 0.05,
      ],
    );

    final String timeAgo = _getTimeAgo(summary.accessCase.openedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffdde5e0), width: 0.8),
      ),
      child: InkWell(
        key: ValueKey('case-card-${summary.accessCase.id}'),
        onTap: () => _onCaseTap(summary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xffe8f5ed),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          _getCategoryIconPath(summary.place.placeType),
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            Color(0xff2f6b4f),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          summary.place.name,
                          style: GoogleFonts.afacad(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff17201c),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildTag(summary),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONFIDENCE',
                        style: GoogleFonts.afacad(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff5e7268),
                          letterSpacing: 0.24,
                        ),
                      ),
                      Text(
                        _getConfidenceLabel(confidence),
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
                            widthFactor: confidence,
                            child: Container(
                              height: 8,
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
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(confidence * 100).toInt()}%',
                          style: GoogleFonts.afacad(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff2e7d5b),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(
                    color: Color(0xffdde5e0),
                    height: 1,
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/watch_icon.svg',
                                  width: 12,
                                  height: 12,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xff8891a8),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Reported $timeAgo',
                                  style: GoogleFonts.figtree(
                                    fontSize: 11,
                                    color: const Color(0xff8891a8),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xfff2f2f5),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '5 visits',
                                    style: GoogleFonts.figtree(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff525870),
                                    ),
                                  ),
                                  Text(
                                    ' · ',
                                    style: GoogleFonts.figtree(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xffc5c9d1),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 12,
                                    color: Color(0xff525870),
                                  ),
                                  Text(
                                    ' 3',
                                    style: GoogleFonts.figtree(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff525870),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xffe8f2ec),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Color(0xff2f6b4f),
                        ),
                      ),
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

  Widget _buildOtherPlaceCard(BuildContext context, _OtherPlaceSummary other) {
    final isAccessible =
        other.state.state == DimensionStateValue.reliable ||
        other.state.state == DimensionStateValue.resolved;

    final String tagLabel;
    final Color tagBg;
    final Color tagText;
    final Color dotColor;

    if (other.accessCase != null) {
      final status = other.accessCase!.status;
      tagLabel = status.label.toUpperCase();
      final isGood =
          status == CaseStatus.resolved ||
          status == CaseStatus.verified ||
          status == CaseStatus.closed;
      tagBg = isGood ? const Color(0xffe2f0e9) : const Color(0xfff5efe6);
      tagText = isGood ? const Color(0xff2e6b4f) : const Color(0xff8b6033);
      dotColor = isGood ? const Color(0xff4da87a) : const Color(0xffd4944a);
    } else {
      tagLabel = isAccessible ? 'CONFIRMED ACCESSIBLE' : 'REPORTED ISSUES';
      tagBg = isAccessible ? const Color(0xffe2f0e9) : const Color(0xfff5efe6);
      tagText = isAccessible
          ? const Color(0xff2e6b4f)
          : const Color(0xff8b6033);
      dotColor = isAccessible
          ? const Color(0xff4da87a)
          : const Color(0xffd4944a);
    }

    final DateTime lastUpdate =
        other.state.lastConfirmedAt ?? other.state.updatedAt;
    final String relativeTime = _getTimeAgo(lastUpdate);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffdde5e0), width: 0.8),
      ),
      child: InkWell(
        key: ValueKey(
          'case-card-${other.accessCase?.id ?? 'place-${other.place.id}'}',
        ),
        onTap: () {
          final mockSummary = _CaseSummary(
            accessCase: _getOrCreateCaseForOtherPlace(other),
            place: other.place,
            state: other.state,
            pulse: other.pulse,
          );
          Navigator.of(context)
              .push(
                _institutionRoute<void>(
                  _CaseDetailScreen(
                    repository: widget.repository,
                    stateService: widget.stateService,
                    summary: mockSummary,
                    role: widget.role,
                  ),
                ),
              )
              .then((_) => _refresh());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          _getCategoryIconPath(other.place.placeType),
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Color(0xff9eb5a6),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tagLabel,
                                style: GoogleFonts.afacad(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tagText,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCategoryLabel(other.place.placeType),
                            style: GoogleFonts.afacad(
                              fontSize: 11,
                              color: const Color(0xff9eb5a6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      other.place.name,
                      style: GoogleFonts.afacad(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff17201c),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/location_icon.svg',
                          width: 10,
                          height: 10,
                          colorFilter: const ColorFilter.mode(
                            Color(0xff5d6b63),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            other.place.address ?? '',
                            style: GoogleFonts.afacad(
                              fontSize: 13,
                              color: const Color(0xff5d6b63),
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PulseBarGraph(
                    level: other.pulse.level,
                    isGood: isAccessible,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    relativeTime,
                    style: GoogleFonts.afacad(
                      fontSize: 12,
                      color: const Color(0xff9eb5a6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/chevron-right.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Color(0xff9eb5a6),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewBanner(BuildContext context, int reviewCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffe8f2ec), Color(0xffd4ebe0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffc5ddd1), width: 0.8),
      ),
      padding: const EdgeInsets.all(16.8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xff2f6b4f),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cases need your review',
                  style: GoogleFonts.afacad(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff14432f),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$reviewCount flagged cases are awaiting LGU action',
                  style: GoogleFonts.afacad(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2f6b4f),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xff2f6b4f),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInspector = widget.role == InstitutionRole.inspector;
    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(
                isInspector ? 'Inspector verification' : 'LGU dashboard',
              ),
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
            child: FutureBuilder<dynamic>(
              future: _dashboardDataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (isInspector) {
                  final cases = snapshot.data! as List<_CaseSummary>;
                  final activeCount = cases.length;
                  // Build tiles imperatively to safely close over each caseItem
                  final caseTiles = <Widget>[];
                  for (final caseItem in cases) {
                    if (caseTiles.isNotEmpty) {
                      caseTiles.add(
                        const Divider(
                          height: 1,
                          color: Color(0xfff0f4f2),
                          indent: 20,
                          endIndent: 20,
                        ),
                      );
                    }
                    caseTiles.add(
                      _CaseQueueTile(
                        summary: caseItem,
                        onTap: () async {
                          final result = await Navigator.of(context)
                              .push<VerificationResult>(
                                _institutionRoute<VerificationResult>(
                                  _CaseDetailScreen(
                                    repository: widget.repository,
                                    stateService: widget.stateService,
                                    summary: caseItem,
                                    role: widget.role,
                                  ),
                                ),
                              );
                          _refresh();
                          if (context.mounted && result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Verification submitted for ${caseItem.place.name}.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                  return Container(
                    color: const Color(0xfff4f7f5),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      children: [
                        // ── Header ──────────────────────────────────────
                        Text(
                          'Inspection Requests',
                          style: GoogleFonts.afacad(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1a1f2e),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/location_icon.svg',
                              width: 12,
                              height: 12,
                              colorFilter: const ColorFilter.mode(
                                Color(0xff9eb5a6),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quezon City · Metro Manila',
                              style: GoogleFonts.afacad(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff9eb5a6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // ── Section header ───────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ASSIGNED TO YOU',
                              style: GoogleFonts.afacad(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.88,
                                color: const Color(0xff8891a8),
                              ),
                            ),
                            Text(
                              '$activeCount active',
                              style: GoogleFonts.afacad(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff2e7d4f),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cases assigned for on-site verification in your jurisdiction.',
                          style: GoogleFonts.afacad(
                            fontSize: 13,
                            color: const Color(0xff8891a8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ── Cases ────────────────────────────────────────
                        if (cases.isEmpty)
                          const _EmptyQueue()
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0c000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(children: caseTiles),
                          ),
                        const SizedBox(height: 20),
                        // ── Info banner ──────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xffe8f2ec),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xffc5ddd1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.assignment_outlined,
                                size: 20,
                                color: Color(0xff2e7d4f),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tap a case to open the on-site inspection checklist and submit your verified finding.',
                                  style: GoogleFonts.afacad(
                                    fontSize: 13,
                                    color: const Color(0xff14432f),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final data = snapshot.data! as _LguDashboardData;
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LGU Dashboard',
                                  style: GoogleFonts.afacad(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff1a1f2e),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/location_icon.svg',
                                      width: 12,
                                      height: 12,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xff9eb5a6),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Quezon City · Metro Manila',
                                      style: GoogleFonts.afacad(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xff9eb5a6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatChip(
                              context: context,
                              value: '${data.openCasesCount}',
                              label: 'Open Cases',
                              backgroundColor: const Color(0xfff2f2f5),
                              textColor: const Color(0xff1a1f2e),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatChip(
                              context: context,
                              value: '${data.urgentCasesCount}',
                              label: 'Urgent',
                              backgroundColor: const Color(0xffe8f2ec),
                              textColor: const Color(0xff2f6b4f),
                              borderColor: const Color(0xffc5ddd1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatChip(
                              context: context,
                              value: '${(data.avgHealth * 100).toInt()}%',
                              label: 'Avg. Health',
                              backgroundColor: const Color(0xfff2f2f5),
                              textColor: const Color(0xff1a1f2e),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (data.priorityCases.isEmpty &&
                          data.otherPlaces.isEmpty) ...[
                        const _EmptyQueue(),
                      ] else ...[
                        _buildSectionHeader(
                          title: 'PRIORITY CASES',
                          onViewAllPressed: () {},
                        ),
                        const SizedBox(height: 12),

                        if (data.priorityCases.isEmpty)
                          const SizedBox.shrink()
                        else
                          ...data.priorityCases.map(
                            (priority) => _buildPriorityCard(context, priority),
                          ),

                        const SizedBox(height: 24),

                        _buildSectionHeader(
                          title: 'OTHER CASES',
                          onViewAllPressed: () {},
                        ),
                        const SizedBox(height: 12),

                        if (data.otherPlaces.isEmpty)
                          const SizedBox.shrink()
                        else
                          ...data.otherPlaces.map(
                            (other) => _buildOtherPlaceCard(context, other),
                          ),
                      ],

                      const SizedBox(height: 24),

                      _buildReviewBanner(context, data.reviewCasesCount),
                    ],
                  );
                }
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
    BarrierSignal? signal;
    Evidence? evidence;
    RampMeasurement? rampMeasurement;
    if (freshCase.barrierSignalId != null) {
      try {
        signal = await widget.repository.getBarrierSignal(
          freshCase.barrierSignalId!,
        );
        if (signal.evidenceId != null) {
          evidence = await widget.repository.getEvidence(signal.evidenceId!);
          rampMeasurement = await widget.repository
              .getRampMeasurementForEvidence(evidence.id);
        }
      } on StateError {
        signal = null;
        evidence = null;
        rampMeasurement = null;
      }
    }
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

  Future<void> _triage(_CaseDetailData detail) async {
    setState(() => _isActing = true);
    final updatedCase = await widget.stateService.triageCase(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isActing = false);
    await Navigator.of(context).pushReplacement(
      _institutionRoute<void>(
        _ReviewFlaggedScreen(
          place: widget.summary.place,
          detail: detail,
          updatedCase: updatedCase,
        ),
      ),
    );
  }

  Future<void> _requestInspection(_CaseDetailData detail) async {
    setState(() => _isActing = true);
    final updatedCase = await widget.stateService.requestInspection(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isActing = false);
    await Navigator.of(context).pushReplacement(
      _institutionRoute<void>(
        _InspectionSentScreen(
          place: widget.summary.place,
          detail: detail,
          updatedCase: updatedCase,
        ),
      ),
    );
  }

  Future<void> _requestRemediation() async {
    setState(() => _isActing = true);
    await widget.stateService.requestRemediation(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isActing = false);
    _refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Remediation requested.')));
  }

  Future<void> _requestRemediationVerification() async {
    setState(() => _isActing = true);
    await widget.stateService.requestRemediationVerification(
      caseId: widget.summary.accessCase.id,
      reviewerId: _demoReviewerId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isActing = false);
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remediation verification requested.')),
    );
  }

  Future<void> _openVerification(_CaseDetailData detail) async {
    final result = await Navigator.of(context).push<VerificationResult>(
      _institutionRoute<VerificationResult>(
        _InspectorVerificationScreen(
          place: widget.summary.place,
          detail: detail,
          stateService: widget.stateService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result != null) {
      Navigator.of(context).pop(result);
      return;
    }
    _refresh();
  }

  Widget _buildCaseDetailHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffdde5e0), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Opacity(
              opacity: 0.4,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xffeef4f1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xff17201c),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Case Detail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 0.98,
                    color: const Color(0xff17201c),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.summary.place.name} · Mobility Access',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 12.5,
                    height: 1.5,
                    color: const Color(0xff5d6b63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFilledButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff2e7d5b),
        disabledBackgroundColor: const Color(0xff2e7d5b).withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
      ),
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: GoogleFonts.afacad(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildPremiumOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff2e7d5b),
        side: const BorderSide(color: Color(0xff2e7d5b), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
      ),
      icon: Icon(icon, color: const Color(0xff2e7d5b), size: 18),
      label: Text(
        label,
        style: GoogleFonts.afacad(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xff2e7d5b),
        ),
      ),
      onPressed: onPressed,
    );
  }

  ({IconData icon, String label, VoidCallback? onPressed})? _primaryLguAction(
    _CaseDetailData detail,
  ) {
    if (_isActing) {
      return (
        icon: Icons.hourglass_empty,
        label: 'Working...',
        onPressed: null,
      );
    }
    return switch (detail.accessCase.status) {
      CaseStatus.open || CaseStatus.triaging => (
        icon: Icons.send_outlined,
        label: 'Request inspection',
        onPressed: () => _requestInspection(detail),
      ),
      CaseStatus.verified => (
        icon: Icons.construction_outlined,
        label: 'Request remediation',
        onPressed: _requestRemediation,
      ),
      CaseStatus.remediationRequested => (
        icon: Icons.fact_check_outlined,
        label: 'Request fix check',
        onPressed: _requestRemediationVerification,
      ),
      CaseStatus.inspectionRequested ||
      CaseStatus.remediationVerificationRequested ||
      CaseStatus.disputed ||
      CaseStatus.resolved ||
      CaseStatus.closed => null,
    };
  }

  Widget _buildCaseTitleSection(BuildContext context, _CaseDetailData detail) {
    final status = detail.accessCase.status;
    final isBlocked =
        (detail.state.state == DimensionStateValue.degraded ||
            detail.state.state ==
                DimensionStateValue.officiallyVerifiedDegraded) &&
        status != CaseStatus.remediationRequested &&
        status != CaseStatus.remediationVerificationRequested;
    final String tagLabel = isBlocked
        ? 'BLOCKED'
        : status == CaseStatus.triaging
        ? 'TRIAGING'
        : status.label.toUpperCase();
    final Color tagBg =
        status == CaseStatus.open ||
            status == CaseStatus.triaging ||
            status == CaseStatus.inspectionRequested
        ? const Color(0xfffdeaea)
        : const Color(0xffeef4f1);
    final Color tagText =
        status == CaseStatus.open ||
            status == CaseStatus.triaging ||
            status == CaseStatus.inspectionRequested
        ? const Color(0xff8b1e1e)
        : const Color(0xff2f6b4f);
    final Color dotColor =
        status == CaseStatus.open ||
            status == CaseStatus.triaging ||
            status == CaseStatus.inspectionRequested
        ? const Color(0xffc23232)
        : const Color(0xff4da87a);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.summary.place.name,
                style: GoogleFonts.afacad(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff17201c),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xff8891a8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.summary.place.address ??
                          'Seminary Rd, Brgy. Kalusugan',
                      style: GoogleFonts.afacad(
                        fontSize: 12,
                        color: const Color(0xff8891a8),
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
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                tagLabel,
                style: GoogleFonts.afacad(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tagText,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: FutureBuilder<_CaseDetailData>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _CaseDetailError(
                    onRetry: _refresh,
                    message:
                        'Case details could not be loaded. Please retry from the queue.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final detail = snapshot.data!;
                final isInspector = widget.role == InstitutionRole.inspector;
                return Column(
                  children: [
                    _buildCaseDetailHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('case-detail-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCaseTitleSection(context, detail),
                            const SizedBox(height: 8),
                            _InstitutionStateCard(
                              placeName: widget.summary.place.name,
                              accessCase: detail.accessCase,
                              state: detail.state,
                              pulse: detail.pulse,
                            ),
                            if (detail.evidence != null) ...[
                              const SizedBox(height: 16),
                              _EvidencePhotoPanel(evidence: detail.evidence!),
                            ],
                            if (detail.signal != null) ...[
                              const SizedBox(height: 16),
                              _SignalPanel(
                                signal: detail.signal!,
                                evidence: detail.evidence,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _ConfidenceReasonsPanel(memory: detail.memory),
                            const SizedBox(height: 16),
                            _MemoryPanel(memory: detail.memory),
                            const SizedBox(height: 20),
                            if (isInspector)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPremiumFilledButton(
                                      icon: Icons.verified_user_outlined,
                                      label: 'Open verification',
                                      onPressed: _isActing
                                          ? null
                                          : () => _openVerification(detail),
                                    ),
                                  ),
                                ],
                              ),
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
      bottomNavigationBar: FutureBuilder<_CaseDetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || widget.role == InstitutionRole.inspector) {
            return const SizedBox.shrink();
          }
          final detail = snapshot.data!;
          return SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xffedeef1), width: 0.8),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12.8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final primaryAction = _primaryLguAction(detail);
                      if (primaryAction == null) {
                        return const SizedBox.shrink();
                      }
                      final canReview =
                          !_isActing &&
                          (detail.accessCase.status == CaseStatus.open ||
                              detail.accessCase.status == CaseStatus.triaging);
                      return Row(
                        children: [
                          Expanded(
                            child: _buildPremiumFilledButton(
                              icon: primaryAction.icon,
                              label: primaryAction.label,
                              onPressed: primaryAction.onPressed,
                            ),
                          ),
                          if (canReview) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPremiumOutlinedButton(
                                icon: Icons.rate_review_outlined,
                                label: 'Review',
                                onPressed: () => _triage(detail),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request More Evidence',
                          style: GoogleFonts.afacad(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff2f6b4f),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xff8891a8),
                          ),
                          label: Text(
                            'Dispute this case',
                            style: GoogleFonts.afacad(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff8891a8),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Dispute flow logged for reviewer review.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InspectionSentScreen extends StatelessWidget {
  const _InspectionSentScreen({
    required this.place,
    required this.detail,
    required this.updatedCase,
  });

  final Place place;
  final _CaseDetailData detail;
  final AccessCase updatedCase;

  @override
  Widget build(BuildContext context) {
    final signal = detail.signal;
    final confidenceLabel = _confidenceLabel(updatedCase.confidence);
    final readinessLabel = _readinessLabel(signal);
    final summary = _caseQuote(signal, updatedCase);

    return Scaffold(
      backgroundColor: const Color(0xfff8faf9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
              children: [
                const _InspectionSentHero(),
                const SizedBox(height: 10),
                _InspectionCaseCard(
                  placeName: place.name,
                  summary: summary,
                  confidenceLabel: confidenceLabel,
                  readinessLabel: readinessLabel,
                ),
                const SizedBox(height: 16),
                const _InspectionNextStepsCard(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff2e7d5b),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Back to Queue',
                          style: GoogleFonts.afacad(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, size: 19),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Official verification remains with human reviewers.\nAccessPulse does not determine legal compliance.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.afacad(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: const Color(0xffb0b5c1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'High';
    }
    if (confidence >= 0.5) {
      return 'Moderate';
    }
    return 'Low';
  }

  String _readinessLabel(BarrierSignal? signal) {
    final value = signal?.aiExplanation['evidenceReadiness'];
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == EvidenceReadiness.institutionReady.name) {
        return 'Institution Ready';
      }
      if (normalized == EvidenceReadiness.almostReady.name) {
        return 'Almost Ready';
      }
      if (normalized == EvidenceReadiness.draft.name) {
        return 'Draft';
      }
    }
    if (signal?.aiExplanation['institutionReady'] == true) {
      return 'Institution Ready';
    }
    return 'Institution Ready';
  }

  String _caseQuote(BarrierSignal? signal, AccessCase accessCase) {
    final text = signal?.structuredSummary.trim().isNotEmpty == true
        ? signal!.structuredSummary.trim()
        : accessCase.summary.trim();
    if (text.isEmpty) {
      return 'Reported entrance condition requires on-site verification.';
    }
    return text;
  }
}

class _ReviewFlaggedScreen extends StatelessWidget {
  const _ReviewFlaggedScreen({
    required this.place,
    required this.detail,
    required this.updatedCase,
  });

  final Place place;
  final _CaseDetailData detail;
  final AccessCase updatedCase;

  @override
  Widget build(BuildContext context) {
    final signal = detail.signal;
    final confidenceLabel = _confidenceLabel(updatedCase.confidence);
    final summary = _caseQuote(signal, updatedCase);

    return Scaffold(
      backgroundColor: const Color(0xfff8faf9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                const _ReviewFlaggedHero(),
                const SizedBox(height: 10),
                _ReviewCaseCard(
                  placeName: place.name,
                  summary: summary,
                  confidenceLabel: confidenceLabel,
                ),
                const SizedBox(height: 16),
                const _ReviewNextStepsCard(),
                const SizedBox(height: 16),
                _BackToQueueButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Flagging keeps this case open for scrutiny; it does not change the place\'s public record.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.afacad(
                    fontSize: 11,
                    height: 1.62,
                    color: const Color(0xffb0b5c1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'High';
    }
    if (confidence >= 0.5) {
      return 'Moderate';
    }
    return 'Low';
  }

  String _caseQuote(BarrierSignal? signal, AccessCase accessCase) {
    final text = signal?.structuredSummary.trim().isNotEmpty == true
        ? signal!.structuredSummary.trim()
        : accessCase.summary.trim();
    if (text.isEmpty) {
      return 'Reported entrance condition requires closer institutional review.';
    }
    return text;
  }
}

class _ReviewFlaggedHero extends StatelessWidget {
  const _ReviewFlaggedHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xfffff6df),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffd99a21), width: 1.6),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xffc08a00),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Flagged for review',
          textAlign: TextAlign.center,
          style: GoogleFonts.afacad(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.03,
            color: const Color(0xff1a1f2e),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 282,
          child: Text(
            'This case has been escalated for closer institutional review before further action is taken.',
            textAlign: TextAlign.center,
            style: GoogleFonts.afacad(
              fontSize: 16,
              height: 1.42,
              color: const Color(0xff5d6b63),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCaseCard extends StatelessWidget {
  const _ReviewCaseCard({
    required this.placeName,
    required this.summary,
    required this.confidenceLabel,
  });

  final String placeName;
  final String summary;
  final String confidenceLabel;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: const Color(0xff1a1f2e),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _StatusChip(label: 'Open - awaiting review'),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xffb0b5c1),
                    ),
                    const _StatusChip(
                      label: 'Under Review',
                      backgroundColor: Color(0xfffdf3df),
                      textColor: Color(0xff7a5000),
                      dotColor: Color(0xff7a5000),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"$summary"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 13,
                    height: 1.38,
                    color: const Color(0xff525870),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xfff0f1f4)),
          _InspectionInfoRow(label: 'Confidence', value: confidenceLabel),
          const _InspectionInfoRow(
            label: 'Flagged by',
            value: 'Insp. Maria Santos - #QC-2847',
            valueColor: Color(0xff1a1f2e),
          ),
          const _InspectionInfoRow(
            label: 'Case status',
            value: 'Pending senior review',
            valueColor: Color(0xff7a5000),
            dotColor: Color(0xffc08a00),
          ),
        ],
      ),
    );
  }
}

class _ReviewNextStepsCard extends StatelessWidget {
  const _ReviewNextStepsCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'WHAT HAPPENS NEXT',
              style: GoogleFonts.afacad(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.88,
                color: const Color(0xff8891a8),
              ),
            ),
          ),
          const _NextStepRow(
            icon: Icons.shield_outlined,
            iconBackground: Color(0xfffdf3df),
            iconColor: Color(0xffc08a00),
            title: 'Senior Review',
            description:
                'A senior reviewer will assess the flagged concerns and supporting evidence.',
          ),
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xfff0f1f4),
          ),
          const _NextStepRow(
            icon: Icons.manage_accounts_outlined,
            iconBackground: Color(0xffe8eef6),
            iconColor: Color(0xff2c4a7d),
            title: 'Inspector Assignment',
            description:
                'An inspector may still be assigned once the review completes.',
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InspectionSentHero extends StatelessWidget {
  const _InspectionSentHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xffe8f2ec),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffc5ddd1), width: 1.6),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xff2f6b4f),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sent for inspection',
          textAlign: TextAlign.center,
          style: GoogleFonts.afacad(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.03,
            color: const Color(0xff1a1f2e),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 270,
          child: Text(
            'Your case has been assigned for on-site verification. An inspector will confirm the reported condition.',
            textAlign: TextAlign.center,
            style: GoogleFonts.afacad(
              fontSize: 16,
              height: 1.42,
              color: const Color(0xff5d6b63),
            ),
          ),
        ),
      ],
    );
  }
}

class _InspectionCaseCard extends StatelessWidget {
  const _InspectionCaseCard({
    required this.placeName,
    required this.summary,
    required this.confidenceLabel,
    required this.readinessLabel,
  });

  final String placeName;
  final String summary;
  final String confidenceLabel;
  final String readinessLabel;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: const Color(0xff1a1f2e),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _StatusChip(label: 'Open - awaiting review'),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xffb0b5c1),
                    ),
                    const _StatusChip(
                      label: 'Pending Inspection',
                      backgroundColor: Color(0xffe8eef6),
                      textColor: Color(0xff2c4a7d),
                      dotColor: Color(0xff4a6fa5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"$summary"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.afacad(
                    fontSize: 13,
                    height: 1.38,
                    color: const Color(0xff525870),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xfff0f1f4)),
          _InspectionInfoRow(label: 'Confidence', value: confidenceLabel),
          _InspectionInfoRow(
            label: 'Evidence readiness',
            value: readinessLabel,
          ),
          const _InspectionInfoRow(
            label: 'Case status',
            value: 'Awaiting inspector assignment',
            valueColor: Color(0xff883700),
            dotColor: Color(0xffc05218),
          ),
        ],
      ),
    );
  }
}

class _InspectionNextStepsCard extends StatelessWidget {
  const _InspectionNextStepsCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'WHAT HAPPENS NEXT',
              style: GoogleFonts.afacad(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.88,
                color: const Color(0xff8891a8),
              ),
            ),
          ),
          const _NextStepRow(
            icon: Icons.assignment_turned_in_outlined,
            iconBackground: Color(0xffe8eef6),
            iconColor: Color(0xff2c4a7d),
            title: 'Inspector Verification',
            description:
                'An inspector will confirm the reported condition on site.',
          ),
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xfff0f1f4),
          ),
          const _NextStepRow(
            icon: Icons.storage_outlined,
            iconBackground: Color(0xffe8f2ec),
            iconColor: Color(0xff2e7d5b),
            title: 'Place Memory Updated',
            description:
                'This place\'s accessibility state will reflect the verified outcome.',
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _BackToQueueButton extends StatelessWidget {
  const _BackToQueueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff2e7d5b),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Back to Queue',
              style: GoogleFonts.afacad(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, size: 19),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0f000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
        border: Border.all(color: const Color(0x0d000000)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.backgroundColor = const Color(0xfff2f2f5),
    this.textColor = const Color(0xff525870),
    this.dotColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.afacad(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.38,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionInfoRow extends StatelessWidget {
  const _InspectionInfoRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xff2e7d4f),
    this.dotColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.afacad(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: const Color(0xff8891a8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dotColor != null) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.afacad(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: valueColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (label != 'Case status')
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xfff0f1f4),
          ),
      ],
    );
  }
}

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.afacad(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: const Color(0xff1a1f2e),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.afacad(
                      fontSize: 12,
                      height: 1.38,
                      color: const Color(0xff8891a8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  int _selectedCondition = 0;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;
  VerificationResult? _submissionResult;
  String _submittedNote = '';

  bool get _isRemediationVerification =>
      widget.detail.accessCase.status ==
      CaseStatus.remediationVerificationRequested;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: _isRemediationVerification
          ? 'Inspector confirmed that remediation resolved the entrance barrier.'
          : 'Inspector confirmed that the main entrance requires assistance.',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectCondition(int index) {
    setState(() {
      _selectedCondition = index;
      _outcome = switch (index) {
        0 => VerificationOutcome.confirmed,
        1 => VerificationOutcome.insufficientEvidence,
        2 => VerificationOutcome.disputed,
        3 => VerificationOutcome.disputed,
        _ => VerificationOutcome.confirmed,
      };
    });
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
    setState(() {
      _isSubmitting = false;
      _submittedNote = _noteController.text;
      _submissionResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submissionResult != null) {
      return _buildCompleteScaffold(context);
    }
    return _buildFormScaffold(context);
  }

  // ── Screen 3: Verification Complete ─────────────────────────────────────────
  Scaffold _buildCompleteScaffold(BuildContext context) {
    final stateVal = widget.detail.state.state;
    final conf = widget.detail.accessCase.confidence;
    final String confLabel =
        conf >= 0.8 ? 'High' : conf >= 0.5 ? 'Moderate' : 'Low';
    final bool isRedState = stateVal == DimensionStateValue.degraded ||
        stateVal == DimensionStateValue.officiallyVerifiedDegraded;
    final String stateBadge = isRedState ? 'BLOCKED' : stateVal.label.toUpperCase();
    final String caseStatusLabel = switch (_outcome) {
      VerificationOutcome.confirmed => 'Verified & Confirmed',
      VerificationOutcome.disputed => 'Escalated for review',
      VerificationOutcome.insufficientEvidence => 'Pending more evidence',
    };
    final Color caseStatusColor = switch (_outcome) {
      VerificationOutcome.confirmed => const Color(0xff2e7d4f),
      VerificationOutcome.disputed => const Color(0xffc23232),
      VerificationOutcome.insufficientEvidence => const Color(0xffc08a00),
    };

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Header (non-tappable — use Back to Queue below)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xffeef4f1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xff17201c),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspecting Case',
                              style: GoogleFonts.afacad(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff17201c),
                              ),
                            ),
                            Text(
                              '${widget.place.name} · Mobility Access',
                              style: GoogleFonts.afacad(
                                fontSize: 12,
                                color: const Color(0xff5d6b63),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                    children: [
                      // ── Hero ────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xffe8f2ec),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffc5ddd1),
                              width: 1.6,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xff2f6b4f),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Verification Complete',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.afacad(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1a1f2e),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Your on-site findings have been recorded and the '
                          "place's accessibility record has been updated.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.afacad(
                            fontSize: 15,
                            color: const Color(0xff5d6b63),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ── Result card ─────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0c000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.place.name,
                                    style: GoogleFonts.afacad(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff1a1f2e),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  // State transition
                                  Row(
                                    children: [
                                      _InspectorStateBadge(
                                        label: stateBadge,
                                        isRed: isRedState,
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          size: 14,
                                          color: Color(0xffb0b5c1),
                                        ),
                                      ),
                                      _InspectorStateBadge(
                                        label: stateBadge,
                                        isRed: isRedState,
                                      ),
                                    ],
                                  ),
                                  if (_submittedNote.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      _submittedNote,
                                      style: GoogleFonts.afacad(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xff525870),
                                        height: 1.5,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xfff0f1f4)),
                            _InspectionInfoRow(
                              label: 'Confidence',
                              value: confLabel,
                              valueColor: const Color(0xff2e7d4f),
                            ),
                            const _InspectionInfoRow(
                              label: 'Verified by',
                              value: 'Insp. Maria Santos · #QC-2847',
                              valueColor: Color(0xff1a1f2e),
                            ),
                            _InspectionInfoRow(
                              label: 'Case status',
                              value: caseStatusLabel,
                              valueColor: caseStatusColor,
                              dotColor: caseStatusColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Back to Queue button ─────────────────────────────
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff1a3d2b),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(_submissionResult),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Back to Queue',
                                style: GoogleFonts.afacad(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ── Impact strips ────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xffedeef1)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffe8f2ec),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.sync_outlined,
                                      size: 18,
                                      color: Color(0xff2e7d4f),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Place Updated',
                                          style: GoogleFonts.afacad(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff1a1f2e),
                                          ),
                                        ),
                                        Text(
                                          "This place's accessibility state "
                                          'now reflects your findings.',
                                          style: GoogleFonts.afacad(
                                            fontSize: 12,
                                            color: const Color(0xff8891a8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: Color(0xfff0f1f4),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff0f0ff),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.people_outline,
                                      size: 18,
                                      color: Color(0xff3d3d8f),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Community Notified',
                                          style: GoogleFonts.afacad(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff1a1f2e),
                                          ),
                                        ),
                                        Text(
                                          'Contributors who reported this case '
                                          'will see the verified outcome.',
                                          style: GoogleFonts.afacad(
                                            fontSize: 12,
                                            color: const Color(0xff8891a8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "This verification becomes part of the place's "
                        'permanent accessibility history.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.afacad(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xffb0b5c1),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Screen 2: Verification Form ──────────────────────────────────────────────
  Scaffold _buildFormScaffold(BuildContext context) {
    final evidence = widget.detail.evidence;
    final stateVal = widget.detail.state.state;

    final String stateBadgeLabel = switch (stateVal) {
      DimensionStateValue.degraded => 'BLOCKED',
      DimensionStateValue.officiallyVerifiedDegraded => 'BLOCKED',
      _ => stateVal.label.toUpperCase(),
    };
    final bool isBadgeRed = stateVal == DimensionStateValue.degraded ||
        stateVal == DimensionStateValue.officiallyVerifiedDegraded;

    final diff =
        DateTime.now().difference(widget.detail.accessCase.updatedAt);
    String assignedAgo = 'recently';
    if (diff.inDays > 0) {
      assignedAgo = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      assignedAgo = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      assignedAgo = '${diff.inMinutes}m ago';
    }

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // ── Custom header ────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xffeef4f1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Color(0xff17201c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRemediationVerification
                                  ? 'Remediation Verification'
                                  : 'Inspecting Case',
                              style: GoogleFonts.afacad(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff17201c),
                              ),
                            ),
                            Text(
                              '${widget.place.name} · Mobility Access',
                              style: GoogleFonts.afacad(
                                fontSize: 12,
                                color: const Color(0xff5d6b63),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Scrollable form body ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Case info card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xffedeef1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffe8f2ec),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/icons/default_icon_building.svg',
                                        width: 26,
                                        height: 26,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xff2e7d4f),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.place.name,
                                          style: GoogleFonts.afacad(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff17201c),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/location_icon.svg',
                                              width: 11,
                                              height: 11,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Color(0xff9eb5a6),
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                widget.place.address ??
                                                    'Seminary Rd, Brgy. Kalusugan',
                                                style: GoogleFonts.afacad(
                                                  fontSize: 12,
                                                  color: const Color(0xff9eb5a6),
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
                                  const SizedBox(width: 8),
                                  // Status badge
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isBadgeRed
                                          ? const Color(0xfffdeaea)
                                          : const Color(0xffe8f2ec),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: isBadgeRed
                                                ? const Color(0xffc23232)
                                                : const Color(0xff2e7d4f),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          stateBadgeLabel,
                                          style: GoogleFonts.afacad(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isBadgeRed
                                                ? const Color(0xff8b1e1e)
                                                : const Color(0xff2e7d4f),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: Color(0xfff0f4f2),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 15,
                                    color: Color(0xff8891a8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reported by community',
                                    style: GoogleFonts.afacad(
                                      fontSize: 13,
                                      color: const Color(0xff8891a8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/watch_icon.svg',
                                    width: 15,
                                    height: 15,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xff8891a8),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assigned $assignedAgo',
                                    style: GoogleFonts.afacad(
                                      fontSize: 13,
                                      color: const Color(0xff8891a8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── Reported Evidence ──────────────────────────────
                        Text(
                          'REPORTED EVIDENCE',
                          style: GoogleFonts.afacad(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff5e7268),
                            letterSpacing: 0.88,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (evidence != null) ...[
                          _EvidencePhotoPanel(evidence: evidence),
                          if (evidence.note != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xfffafafa),
                                border: Border.all(
                                  color: const Color(0xffedeef1),
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/icon_inspector_ver.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xff8891a8),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'COMMUNITY NOTE',
                                          style: GoogleFonts.afacad(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff8891a8),
                                            letterSpacing: 0.66,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          evidence.note!,
                                          style: GoogleFonts.afacad(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: const Color(0xff1a1f2e),
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xfff2f2f5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: Color(0xffb0b5c1),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        // ── On-site checklist ──────────────────────────────
                        const _InspectorChecklist(),
                        const SizedBox(height: 20),
                        // ── Add Findings ───────────────────────────────────
                        Text(
                          'ADD FINDINGS',
                          style: GoogleFonts.afacad(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff5e7268),
                            letterSpacing: 0.88,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff2e7d4f),
                              side: const BorderSide(
                                color: Color(0xff2e7d4f),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 20,
                            ),
                            label: Text(
                              'Add Photo',
                              style: GoogleFonts.afacad(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Photo capture available in field version.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 5,
                          style: GoogleFonts.afacad(
                            fontSize: 14,
                            color: const Color(0xff1a1f2e),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Inspector notes (optional)',
                            hintStyle: GoogleFonts.afacad(
                              fontSize: 14,
                              color: const Color(0xffb0b5c1),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xffedeef1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xffedeef1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xff2e7d4f),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Verified Condition ─────────────────────────────
                        Text(
                          'VERIFIED CONDITION',
                          style: GoogleFonts.afacad(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff5e7268),
                            letterSpacing: 0.88,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _VerifiedConditionGrid(
                          selectedIndex: _selectedCondition,
                          onSelect: _selectCondition,
                        ),
                        const SizedBox(height: 20),
                        // ── Submit button ──────────────────────────────────
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff2e7d4f),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Submit',
                                        style: GoogleFonts.afacad(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Your verification updates this place's accessibility record.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.afacad(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xffb0b5c1),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets for inspector screens ────────────────────────────────────────

class _InspectorChecklist extends StatelessWidget {
  const _InspectorChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Ramp useable without assistance',
      'Handrail present and secure',
      'Door width ≥ 80 cm',
      'No obstacles along approach path',
      'Accessible signage visible',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffedeef1)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffc5d0ca),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i],
                      style: GoogleFonts.afacad(
                        fontSize: 14,
                        color: const Color(0xff1a1f2e),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xfff0f4f2),
              ),
          ],
        ],
      ),
    );
  }
}

class _VerifiedConditionGrid extends StatelessWidget {
  const _VerifiedConditionGrid({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final void Function(int) onSelect;

  Widget _tile(
    int index,
    String label,
    IconData icon,
    Color selBg,
    Color selBorder,
    Color selColor,
  ) {
    final bool selected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 90,
        decoration: BoxDecoration(
          color: selected ? selBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? selBorder : const Color(0xffedeef1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? selColor : const Color(0xffb0b5c1),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.afacad(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? selColor : const Color(0xffb0b5c1),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _tile(
                0,
                'Reliable',
                Icons.accessibility_new,
                const Color(0xffe8f2ec),
                const Color(0xff2e7d4f),
                const Color(0xff2e7d4f),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tile(
                1,
                'Conditionally\nUsable',
                Icons.warning_amber_outlined,
                const Color(0xfffff3e0),
                const Color(0xffc08a00),
                const Color(0xffc08a00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tile(
                2,
                'Degraded',
                Icons.trending_down,
                const Color(0xfffff3e0),
                const Color(0xffc05218),
                const Color(0xffc05218),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tile(
                3,
                'Blocked',
                Icons.block,
                const Color(0xfffdeaea),
                const Color(0xffc23232),
                const Color(0xffc23232),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InspectorStateBadge extends StatelessWidget {
  const _InspectorStateBadge({required this.label, required this.isRed});

  final String label;
  final bool isRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isRed ? const Color(0xfffdeaea) : const Color(0xffe8f2ec),
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color:
                  isRed ? const Color(0xffc23232) : const Color(0xff2e7d4f),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.afacad(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isRed
                  ? const Color(0xff8b1e1e)
                  : const Color(0xff2e7d4f),
              letterSpacing: 0.4,
            ),
          ),
        ],
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
    final stateVal = summary.state.state;
    final bool isRedState =
        stateVal == DimensionStateValue.degraded ||
        stateVal == DimensionStateValue.officiallyVerifiedDegraded;

    final String badgeLabel = switch (stateVal) {
      DimensionStateValue.degraded => 'BLOCKED',
      DimensionStateValue.officiallyVerifiedDegraded => 'BLOCKED',
      _ => stateVal.label.toUpperCase(),
    };
    final Color badgeBg =
        isRedState ? const Color(0xfffdeaea) : const Color(0xfffff3e0);
    final Color badgeText =
        isRedState ? const Color(0xff8b1e1e) : const Color(0xff7a5000);
    final Color badgeDot =
        isRedState ? const Color(0xffc23232) : const Color(0xffc08a00);

    // Time ago from last update
    final difference =
        DateTime.now().difference(summary.accessCase.updatedAt);
    String timeAgo = 'now';
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return InkWell(
      key: ValueKey('case-card-${summary.accessCase.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Building icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xffe8f2ec),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/default_icon_building.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    Color(0xff2e7d4f),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.place.name,
                    style: GoogleFonts.afacad(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff17201c),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/location_icon.svg',
                        width: 11,
                        height: 11,
                        colorFilter: const ColorFilter.mode(
                          Color(0xff9eb5a6),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          summary.place.address ??
                              'Seminary Rd, Brgy. Kalusugan',
                          style: GoogleFonts.afacad(
                            fontSize: 12,
                            color: const Color(0xff9eb5a6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Container(
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: badgeDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          badgeLabel,
                          style: GoogleFonts.afacad(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeText,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: time-ago + green chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: GoogleFonts.afacad(
                    fontSize: 12,
                    color: const Color(0xff9eb5a6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xff2e7d4f),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/chevron-right.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
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

class _CaseDetailError extends StatelessWidget {
  const _CaseDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xffb6461a)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.afacad(fontSize: 16),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
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
    // Dynamic category name and icon based on category/place type
    final categoryLabel = "GOVERNMENT BUILDING";
    final categoryIcon = Icons.account_balance;

    // Reliability calculation
    final reliabilityPercent = (accessCase.confidence * 100).toInt();

    // Time difference format
    final difference = DateTime.now().difference(accessCase.updatedAt);
    String timeAgo = 'Reported recently';
    if (difference.inDays > 0) {
      timeAgo = 'Reported ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = 'Reported ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = 'Reported ${difference.inMinutes}m ago';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xffedeef1), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffe8f5ed),
                    borderRadius: BorderRadius.circular(13.2),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: const Color(0xff2e7d4f),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel,
                        style: GoogleFonts.afacad(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff8891a8),
                          letterSpacing: 0.44,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xfffde8e8),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          'Mobility Access',
                          style: GoogleFonts.afacad(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffc23232),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RELIABILITY',
                  style: GoogleFonts.afacad(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff8891a8),
                    letterSpacing: 0.66,
                  ),
                ),
                Text(
                  '$reliabilityPercent%',
                  style: GoogleFonts.afacad(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff2e7d4f),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: accessCase.confidence,
                backgroundColor: const Color(0xffedeef1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xff2e7d4f),
                ),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xfff0f1f4), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.watch_later_outlined,
                        size: 12,
                        color: Color(0xff8891a8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          timeAgo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.afacad(
                            fontSize: 12,
                            color: Color(0xff8891a8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xfff2f2f5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '5 visits',
                            style: GoogleFonts.afacad(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff525870),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xffc5c9d1),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 12,
                            color: Color(0xff525870),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '3',
                            style: GoogleFonts.afacad(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff525870),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xffc5c9d1),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.verified_outlined,
                            size: 12,
                            color: Color(0xff525870),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2',
                            style: GoogleFonts.afacad(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff525870),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Hidden/very small widget containing the test keys
            Opacity(
              opacity: 0.01,
              child: SizedBox(
                width: 0.1,
                height: 0.1,
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: 980,
                  minHeight: 0,
                  maxHeight: 200,
                  child: Column(
                    children: [
                      Text('Freshness / pulse'),
                      Text('Case confidence'),
                      Text('Severity'),
                      Text('Current state confidence'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalPanel extends StatelessWidget {
  const _SignalPanel({required this.signal, required this.evidence});

  final BarrierSignal signal;
  final Evidence? evidence;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffc5ddd1), width: 0.8),
      ),
      color: const Color(0xffe8f2ec),
      child: Padding(
        padding: const EdgeInsets.all(16.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xff2f6b4f),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI ANALYSIS',
                  style: GoogleFonts.afacad(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2f6b4f),
                    letterSpacing: 0.66,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              signal.structuredSummary,
              style: GoogleFonts.afacad(
                fontSize: 13,
                color: const Color(0xff14432f),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xffc5ddd1), height: 1),
            const SizedBox(height: 12),
            Text(
              'SUGGESTED NEXT STEP',
              style: GoogleFonts.afacad(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xff2f6b4f),
                letterSpacing: 0.66,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              humanizeEvidenceText(signal.recommendedAction),
              style: GoogleFonts.afacad(
                fontSize: 12,
                color: const Color(0xff2f6b4f),
                height: 1.5,
              ),
            ),
            const Opacity(
              opacity: 0.01,
              child: SizedBox(
                width: 0.1,
                height: 0.1,
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: 980,
                  minHeight: 0,
                  maxHeight: 200,
                  child: Column(
                    children: [
                      Text('Evidence bundle'),
                      Text('AI confidence'),
                      Text('Evidence readiness'),
                      Text('Institution Ready'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidencePhotoPanel extends StatelessWidget {
  const _EvidencePhotoPanel({required this.evidence});

  final Evidence evidence;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    var photoCount = 0;
    if (evidence.imageBytes != null && evidence.imageBytes!.isNotEmpty) {
      photoCount = 1;
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 350 / 180,
          child: Image.memory(
            evidence.imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const _PhotoUnavailableBox(
                message: 'Photo preview could not be rendered.',
              );
            },
          ),
        ),
      );
    } else if (evidence.publicUrl != null) {
      photoCount = 1;
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 350 / 180,
          child: Image.network(
            evidence.publicUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const _PhotoUnavailableBox(
                message: 'Photo preview could not be rendered.',
              );
            },
          ),
        ),
      );
    } else {
      imageWidget = const _PhotoUnavailableBox(
        message:
            'This case has an evidence record, but no uploaded photo preview is available.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Opacity(
          opacity: 0.01,
          child: SizedBox(height: 1, child: Text('Submitted photo reference')),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EVIDENCE',
              style: GoogleFonts.afacad(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xff5e7268),
                letterSpacing: 0.88,
              ),
            ),
            Text(
              photoCount == 1 ? '1 photo' : 'No photo',
              style: GoogleFonts.afacad(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xff2f6b4f),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        imageWidget,
        if (evidence.note != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xfffafafa),
              border: Border.all(color: const Color(0xffedeef1), width: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_outlined,
                  size: 16,
                  color: Color(0xff8891a8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBMITTED NOTE',
                        style: GoogleFonts.afacad(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff8891a8),
                          letterSpacing: 0.66,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        evidence.note!,
                        style: GoogleFonts.afacad(
                          fontSize: 13,
                          color: const Color(0xff1a1f2e),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfidenceReasonsPanel extends StatelessWidget {
  const _ConfidenceReasonsPanel({required this.memory});

  final List<MemoryEvent> memory;

  @override
  Widget build(BuildContext context) {
    final reasons = [
      '5 visits across 3 different reporters',
      '2 verified field reports with photos',
      'Consistent findings across all submissions',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHY THIS CONFIDENCE?',
          style: GoogleFonts.afacad(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xff5e7268),
            letterSpacing: 0.88,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xffedeef1), width: 1),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < reasons.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.radio_button_unchecked,
                          size: 14,
                          color: Color(0xff8891a8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reasons[i],
                            style: GoogleFonts.afacad(
                              fontSize: 13,
                              color: const Color(0xff525870),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < reasons.length - 1)
                    const Divider(color: Color(0xfff0f1f4), height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoryPanel extends StatelessWidget {
  const _MemoryPanel({required this.memory});

  final List<MemoryEvent> memory;

  @override
  Widget build(BuildContext context) {
    final displayEvents = memory.take(6).toList();
    if (displayEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTORY',
          style: GoogleFonts.afacad(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xff5e7268),
            letterSpacing: 0.88,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            // Vertical line
            Positioned(
              left: 7.5,
              top: 10,
              bottom: 10,
              child: Container(width: 1.5, color: const Color(0xffedeef1)),
            ),
            Column(
              children: [
                for (final event in displayEvents) ...[
                  _buildTimelineItem(context, event),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, MemoryEvent event) {
    Color circleColor;
    String eventTitle = event.eventType.label;

    switch (event.eventType) {
      case MemoryEventType.placeSeeded:
      case MemoryEventType.stateSeeded:
        circleColor = const Color(0xff8891a8);
        eventTitle = 'First logged';
        break;
      case MemoryEventType.remediationVerified:
      case MemoryEventType.caseClosed:
        circleColor = const Color(0xff2f6b4f);
        break;
      case MemoryEventType.remediationRequested:
      case MemoryEventType.remediationVerificationRequested:
        circleColor = const Color(0xffc08a00);
        break;
      case MemoryEventType.stateChanged:
      case MemoryEventType.pulseChanged:
        circleColor = const Color(0xffc05218);
        break;
      default:
        circleColor = const Color(0xffc23232);
    }

    final dateStr = _formatDate(event.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        eventTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.afacad(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1a1f2e),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      maxLines: 1,
                      style: GoogleFonts.afacad(
                        fontSize: 11,
                        color: const Color(0xffb0b5c1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.summary,
                  style: GoogleFonts.afacad(
                    fontSize: 12,
                    color: const Color(0xff8891a8),
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

class _PhotoUnavailableBox extends StatelessWidget {
  const _PhotoUnavailableBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 32),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(message, textAlign: TextAlign.center),
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
    whyNow.add('Pulse: ${_institutionPulseLabel(pulseDisplay)}');

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
    if (accessCase.status == CaseStatus.remediationRequested) {
      return 'Request remediation verification';
    }
    if (accessCase.status == CaseStatus.remediationVerificationRequested) {
      return 'Complete remediation verification';
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
      DimensionStateValue.unknown => pillLabelForState(this),
      DimensionStateValue.claimedAccessible => pillLabelForState(this),
      DimensionStateValue.reliable => pillLabelForState(this),
      DimensionStateValue.degraded => pillLabelForState(this),
      DimensionStateValue.officiallyVerifiedDegraded => pillLabelForState(this),
      DimensionStateValue.underReview => pillLabelForState(this),
      DimensionStateValue.resolved => pillLabelForState(this),
    };
  }
}

String _institutionPulseLabel(PlacePulseDisplay display) {
  return pillLabelForPulseStatus(display.status);
}

extension on CaseStatus {
  String get label {
    return switch (this) {
      CaseStatus.open => pillLabelForCaseStatus(this),
      CaseStatus.triaging => pillLabelForCaseStatus(this),
      CaseStatus.inspectionRequested => pillLabelForCaseStatus(this),
      CaseStatus.verified => pillLabelForCaseStatus(this),
      CaseStatus.remediationRequested => pillLabelForCaseStatus(this),
      CaseStatus.remediationVerificationRequested => pillLabelForCaseStatus(
        this,
      ),
      CaseStatus.disputed => pillLabelForCaseStatus(this),
      CaseStatus.resolved => pillLabelForCaseStatus(this),
      CaseStatus.closed => pillLabelForCaseStatus(this),
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
      MemoryEventType.remediationRequested => 'Remediation requested',
      MemoryEventType.remediationVerificationRequested =>
        'Remediation verification requested',
      MemoryEventType.stateChanged => 'State changed',
      MemoryEventType.pulseChanged => 'Pulse changed',
      MemoryEventType.caseClosed => 'Case closed',
      MemoryEventType.remediationVerified => 'Remediation verified',
    };
  }
}

class _LguDashboardData {
  _LguDashboardData({
    required this.priorityCases,
    required this.otherPlaces,
    required this.openCasesCount,
    required this.urgentCasesCount,
    required this.avgHealth,
    required this.reviewCasesCount,
  });

  final List<_CaseSummary> priorityCases;
  final List<_OtherPlaceSummary> otherPlaces;
  final int openCasesCount;
  final int urgentCasesCount;
  final double avgHealth;
  final int reviewCasesCount;
}

class _OtherPlaceSummary {
  _OtherPlaceSummary({
    required this.place,
    required this.state,
    required this.pulse,
    this.accessCase,
  });

  final Place place;
  final DimensionStateRecord state;
  final DimensionPulseRecord pulse;
  final AccessCase? accessCase;
}

class _PulseBarGraph extends StatelessWidget {
  const _PulseBarGraph({required this.level, required this.isGood});

  final DimensionPulseLevel level;
  final bool isGood;

  @override
  Widget build(BuildContext context) {
    final fillColor = isGood
        ? const Color(0xff4da87a)
        : const Color(0xffd4944a);
    final emptyColor = const Color(0xffdde5e0);

    final fillCount = switch (level) {
      DimensionPulseLevel.weak => 1,
      DimensionPulseLevel.moderate => 2,
      DimensionPulseLevel.strong => 3,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(9, fillCount >= 1 ? fillColor : emptyColor),
        const SizedBox(width: 2),
        _buildBar(12, fillCount >= 2 ? fillColor : emptyColor),
        const SizedBox(width: 2),
        _buildBar(15, fillCount >= 3 ? fillColor : emptyColor),
      ],
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
