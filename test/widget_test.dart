import 'dart:io';

import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/public/public_flow.dart';
import 'package:accesspulse/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  late Directory tempDirectory;
  late File fakeImageFile;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'accesspulse_widget_test_',
    );
    fakeImageFile = File('${tempDirectory.path}\\mock_photo.png');
    await fakeImageFile.writeAsBytes(_tinyPngBytes, flush: true);
  });

  tearDownAll(() async {});

  testWidgets('public flow shows seeded living accessibility states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        showOnboarding: false,
        imagePickerOverride: _fakePicker(fakeImageFile.path),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AccessPulse'), findsOneWidget);
    expect(find.text('Current accessibility state'), findsOneWidget);
    expect(find.text('Quezon City Hall Main Entrance'), findsOneWidget);
    expect(find.textContaining('Claimed accessible'), findsOneWidget);
    expect(find.textContaining('Reliable, aging'), findsOneWidget);

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();

    expect(find.text('For you: Mobility Access'), findsOneWidget);
    expect(find.text('Freshness / pulse'), findsOneWidget);
    expect(find.text('Reliable, aging'), findsWidgets);
    final placeDetailScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('PLACE MEMORY'),
      300,
      scrollable: placeDetailScrollable,
    );
    expect(find.text('PLACE MEMORY'), findsOneWidget);
    expect(find.text('Confirm Your Visit'), findsOneWidget);
    expect(find.text('Add Evidence'), findsOneWidget);
  });

  testWidgets('confirm visit visibly updates a place state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        showOnboarding: false,
        imagePickerOverride: _fakePicker(fakeImageFile.path),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quezon City Hall Main Entrance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Your Visit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update living state'));
    await tester.pumpAndSettle();

    expect(find.text('Your visit updated this place'), findsOneWidget);
    expect(find.text('Claimed accessible'), findsOneWidget);
    expect(find.text('Degraded'), findsOneWidget);
    expect(find.text('Recently refreshed'), findsOneWidget);
  });

  testWidgets('evidence flow shows AI structure and submits a signal', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    final place = (await repository.listPlaces()).firstWhere(
      (candidate) => candidate.id == '40000000-0000-4000-8000-000000000001',
    );
    final seededPhoto = PhotoEvidenceItem(
      file: XFile(fakeImageFile.path),
      bytes: await fakeImageFile.readAsBytes(),
      addedAt: DateTime(2026, 7, 1, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceFlowScreen(
          place: place,
          placeDimensionId: '50000000-0000-4000-8000-000000000001',
          stateService: stateService,
          aiService: const MockAiEvidenceService(),
          initialPhotos: [seededPhoto],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final addEvidenceScrollable = _stepScrollable('step-add-evidence');

    expect(find.text('Optional: Measure ramp slope'), findsOneWidget);
    expect(find.text('Demo-safe capture'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start slope capture'),
      300,
      scrollable: addEvidenceScrollable,
    );
    await tester.drag(addEvidenceScrollable, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Start slope capture'));
    await tester.pump();

    expect(find.text('Measure Ramp Slope'), findsOneWidget);
    expect(find.text('Measuring incline...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump(const Duration(milliseconds: 250));

    final rampCaptureScrollable = find.byType(Scrollable).first;
    expect(find.text('Slope captured'), findsWidgets);
    expect(find.text('ESTIMATED INCLINE'), findsOneWidget);
    expect(find.text('Quality'), findsOneWidget);
    expect(find.text('Moderate stability'), findsOneWidget);
    expect(find.text('Demo fallback'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Retake'),
      300,
      scrollable: rampCaptureScrollable,
    );
    await tester.drag(rampCaptureScrollable, const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Retake'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Slope captured'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Use this reading'),
      300,
      scrollable: rampCaptureScrollable,
    );
    await tester.tap(find.text('Use this reading'));
    await tester.pumpAndSettle();

    final addEvidenceScrollableAfterCapture = _stepScrollable(
      'step-add-evidence',
    );
    await tester.scrollUntilVisible(
      find.text('Analyze evidence'),
      300,
      scrollable: addEvidenceScrollableAfterCapture,
    );
    final analyzeButton = find.widgetWithText(FilledButton, 'Analyze evidence');
    await tester.scrollUntilVisible(
      analyzeButton,
      300,
      scrollable: addEvidenceScrollableAfterCapture,
    );
    await tester.drag(addEvidenceScrollableAfterCapture, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('step-ai-guidance')), findsOneWidget);
    expect(find.text('AI Guidance'), findsOneWidget);
    expect(find.text('Recommended next step'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    final structureReviewScrollable = _stepScrollable('step-structure-review');
    await tester.scrollUntilVisible(
      find.text('AI evidence structure'),
      300,
      scrollable: structureReviewScrollable,
    );
    expect(find.text('AI evidence structure'), findsOneWidget);
    expect(find.text('Evidence readiness'), findsWidgets);
    expect(find.text('Institution Ready'), findsWidgets);
    expect(find.text('Missing evidence'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Continue to review packet'),
      300,
      scrollable: structureReviewScrollable,
    );
    await tester.tap(find.text('Continue to review packet'));
    await tester.pumpAndSettle();

    final reviewPacketScrollable = _stepScrollable('step-review-packet');
    await tester.scrollUntilVisible(
      find.text('Review packet'),
      300,
      scrollable: reviewPacketScrollable,
    );
    expect(find.text('Review packet'), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
    expect(find.text('Ramp reading included'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Submit Review Packet'),
      300,
      scrollable: reviewPacketScrollable,
    );
    await tester.tap(find.text('Submit Review Packet'));
    await tester.pumpAndSettle();

    expect(
      find.text('Evidence strengthened this place memory'),
      findsOneWidget,
    );
    expect(find.text('Degraded'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
  });

  testWidgets('AI guidance card re-evaluates after adding another photo', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);
    final place = (await repository.listPlaces()).firstWhere(
      (candidate) => candidate.id == '40000000-0000-4000-8000-000000000001',
    );
    final seededPhoto = PhotoEvidenceItem(
      file: XFile(fakeImageFile.path),
      bytes: await fakeImageFile.readAsBytes(),
      addedAt: DateTime(2026, 7, 1, 9),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceFlowScreen(
          place: place,
          placeDimensionId: '50000000-0000-4000-8000-000000000001',
          stateService: stateService,
          aiService: const MockAiEvidenceService(),
          initialPhotos: [seededPhoto],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final addEvidenceScrollable = _stepScrollable('step-add-evidence');

    await tester.scrollUntilVisible(
      find.text('Analyze evidence'),
      300,
      scrollable: addEvidenceScrollable,
    );
    final analyzeButton = find.widgetWithText(FilledButton, 'Analyze evidence');
    await tester.scrollUntilVisible(
      analyzeButton,
      300,
      scrollable: addEvidenceScrollable,
    );
    await tester.drag(addEvidenceScrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    await tester.pumpAndSettle();

    final aiGuidanceScrollable = _stepScrollable('step-ai-guidance');
    expect(find.byKey(const ValueKey('step-ai-guidance')), findsOneWidget);
    expect(find.text('AI Guidance'), findsOneWidget);
    expect(find.text('Almost Ready'), findsWidgets);
    expect(find.text('Recommended next step'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Review packet'), findsNothing);

    final addAnotherPhotoButton = find.widgetWithText(
      OutlinedButton,
      'Add another photo',
    );
    await tester.scrollUntilVisible(
      addAnotherPhotoButton,
      300,
      scrollable: aiGuidanceScrollable,
    );
    await tester.drag(aiGuidanceScrollable, const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.ensureVisible(addAnotherPhotoButton);
    expect(addAnotherPhotoButton, findsOneWidget);
  });
}

Finder _stepScrollable(String stepKey) {
  return find
      .descendant(
        of: find.byKey(ValueKey(stepKey)),
        matching: find.byType(Scrollable),
      )
      .first;
}

Future<XFile?> Function(ImageSource source, int? imageQuality) _fakePicker(
  String filePath,
) {
  return (source, imageQuality) async => XFile(filePath);
}

const List<int> _tinyPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
