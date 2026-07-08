import 'dart:async';

import 'package:accesspulse/data/in_memory_accesspulse_repository.dart';
import 'package:accesspulse/domain/accesspulse_domain.dart';
import 'package:accesspulse/features/public/add_place_flow.dart';
import 'package:accesspulse/features/public/public_flow.dart';
import 'package:accesspulse/shared/copy/accesspulse_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map autofill failure keeps manual entry available', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    late Future<void> Function(double latitude, double longitude)
    selectLocation;
    final service = _PendingAutofillService();

    await tester.pumpWidget(
      MaterialApp(
        home: AddPlaceFlowScreen(
          repository: repository,
          autofillService: service,
          locationPickerBuilder:
              (context, places, latitude, longitude, onSelected) {
                selectLocation = onSelected;
                return const SizedBox.shrink();
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(selectLocation(14.7, 121.1));
    await tester.pump();

    expect(
      find.textContaining('Kinukuha ang details mula sa mapa'),
      findsOneWidget,
    );

    service.fail();
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hindi nakuha ang details mula sa mapa'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pangalan ng lugar'),
      'Manual Place',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City'),
      'Manual City',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Barangay'),
      'Manual Barangay',
    );

    expect(find.text('Manual Place'), findsOneWidget);
    expect(find.text('Manual City'), findsOneWidget);
    expect(find.text('Manual Barangay'), findsOneWidget);
  });

  testWidgets('map autofill fills empty fields and keeps user edits editable', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    late Future<void> Function(double latitude, double longitude)
    selectLocation;
    final service = _QueuedAutofillService(<PlaceAutofillResult>[
      const PlaceAutofillResult(
        name: 'Suggested PUP Gate',
        address: 'Teresa Street, Sta. Mesa, Manila',
        city: 'Manila',
        barangay: 'Santa Mesa',
        latitude: 14.5996,
        longitude: 121.0085,
        source: 'test',
      ),
      const PlaceAutofillResult(
        name: 'New Suggested Name',
        address: 'New suggested address',
        city: 'New City',
        barangay: 'New Barangay',
        latitude: 14.6,
        longitude: 121.009,
        source: 'test',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AddPlaceFlowScreen(
          repository: repository,
          autofillService: service,
          locationPickerBuilder:
              (context, places, latitude, longitude, onSelected) {
                selectLocation = onSelected;
                return const SizedBox.shrink();
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pangalan ng lugar'),
      'Manual Place Name',
    );
    await selectLocation(14.5996, 121.0085);
    await tester.pumpAndSettle();

    expect(find.text('Manual Place Name'), findsOneWidget);
    expect(find.text('Teresa Street, Sta. Mesa, Manila'), findsOneWidget);
    expect(find.text('Manila'), findsOneWidget);
    expect(find.text('Santa Mesa'), findsOneWidget);
    expect(
      find.textContaining('Na-autofill ang ilang details'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address o landmark'),
      'Edited address',
    );
    await selectLocation(14.6, 121.009);
    await tester.pumpAndSettle();

    expect(find.text('Manual Place Name'), findsOneWidget);
    expect(find.text('Edited address'), findsOneWidget);
    expect(find.text('New Suggested Name'), findsNothing);
    expect(find.text('New suggested address'), findsNothing);
  });

  testWidgets('add place form validates required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddPlaceFlowScreen(
          repository: InMemoryAccessPulseRepository.seeded(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AccessPulseCopy.chooseLocation), findsOneWidget);
    expect(find.text(AccessPulseCopy.mapUnavailable), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(AccessPulseCopy.saveAndOpenPlace),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AccessPulseCopy.saveAndOpenPlace));
    await tester.pump();

    expect(find.text('Ilagay ang pangalan ng lugar'), findsOneWidget);
    expect(find.text('Ilagay ang city'), findsOneWidget);
    expect(find.text('Ilagay ang barangay'), findsOneWidget);
  });

  testWidgets('user can add a place and return to public home', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryAccessPulseRepository.seeded();
    final stateService = DimensionStateService(repository: repository);

    await tester.pumpWidget(
      MaterialApp(
        home: PublicHomeScreen(
          repository: repository,
          stateService: stateService,
          aiService: const MockAiEvidenceService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AccessPulseCopy.addPlace));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pangalan ng lugar'),
      'Marikina Public Library',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City'),
      'Marikina City',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Barangay'),
      'San Roque',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address o landmark'),
      'Gil Fernando Avenue',
    );

    await tester.scrollUntilVisible(
      find.text(AccessPulseCopy.saveAndOpenPlace),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AccessPulseCopy.saveAndOpenPlace));
    await tester.pumpAndSettle();

    expect(find.text(AccessPulseCopy.publicHomeTitle), findsOneWidget);
    expect(find.text(AccessPulseCopy.addPlaceSuccess), findsOneWidget);
    expect(find.text(AccessPulseCopy.confirmVisit), findsNothing);
    expect(find.text(AccessPulseCopy.addEvidence), findsNothing);

    final savedPlace = (await repository.listPlaces()).singleWhere(
      (place) => place.name == 'Marikina Public Library',
    );
    expect(savedPlace.city, 'Marikina City');
    expect(savedPlace.barangay, 'San Roque');
  });
}

class _QueuedAutofillService implements PlaceAutofillService {
  _QueuedAutofillService(this._results);

  final List<PlaceAutofillResult> _results;
  var _index = 0;

  @override
  Future<PlaceAutofillResult> autofillFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final result = _results[_index.clamp(0, _results.length - 1)];
    _index += 1;
    return result;
  }
}

class _PendingAutofillService implements PlaceAutofillService {
  final _completer = Completer<PlaceAutofillResult>();

  @override
  Future<PlaceAutofillResult> autofillFromCoordinates({
    required double latitude,
    required double longitude,
  }) {
    return _completer.future;
  }

  void fail() {
    _completer.completeError(StateError('lookup failed'));
  }
}
