import '../../domain/models/accesspulse_models.dart';

String humanizeEvidenceText(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) {
    return value;
  }

  final words = normalized.split(' ');
  return words
      .map((word) {
        if (word.isEmpty) {
          return word;
        }
        final lower = word.toLowerCase();
        if (lower == 'ai' || lower == 'lgu') {
          return lower.toUpperCase();
        }
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String pillLabelForState(DimensionStateValue state) {
  return switch (state) {
    DimensionStateValue.unknown => 'No Info',
    DimensionStateValue.claimedAccessible => 'Claimed',
    DimensionStateValue.reliable => 'Was Accessible',
    DimensionStateValue.degraded => 'Reported',
    DimensionStateValue.officiallyVerifiedDegraded => 'Verified Issue',
    DimensionStateValue.underReview => 'Reviewing',
    DimensionStateValue.resolved => 'Fixed',
  };
}

String pillLabelForPulseStatus(PlacePulseStatus status) {
  return switch (status) {
    PlacePulseStatus.reliable => 'Was Accessible',
    PlacePulseStatus.reliableAging => 'Old Info',
    PlacePulseStatus.unknown => 'No Info',
    PlacePulseStatus.underReview => 'Reviewing',
    PlacePulseStatus.recentlyRefreshed => 'Recently Accessible',
  };
}

String pillLabelForCaseStatus(CaseStatus status) {
  return switch (status) {
    CaseStatus.open => 'Reported',
    CaseStatus.triaging => 'Acknowledged',
    CaseStatus.inspectionRequested => 'Reviewing',
    CaseStatus.verified => 'Verified Issue',
    CaseStatus.remediationRequested => 'Being Fixed',
    CaseStatus.remediationVerificationRequested => 'Checking Fix',
    CaseStatus.disputed => 'Reviewing',
    CaseStatus.resolved => 'Fixed',
    CaseStatus.closed => 'Recently Accessible',
  };
}
