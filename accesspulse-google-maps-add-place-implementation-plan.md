# AccessPulse Google Maps, Add Place, and Filipino Copy — Implementation Plan

## Purpose

This plan extends the current AccessPulse MVP by adding a lightweight Google Maps discovery layer, a simple `Add a place` flow, and clearer Filipino/Taglish public-facing copy.

This feature must preserve the strongest existing AccessPulse loop:

Public discovery -> place detail -> confirm visit / add evidence -> AI evidence support -> LGU review -> inspector verification -> remediation -> revalidation -> public memory.

The goal is not to rebuild AccessPulse around maps. The map should act as a more engaging entry point into the existing place-detail and evidence-to-action workflow.

## Product Principle

Google Maps helps users discover places. AccessPulse explains the living accessibility truth of those places.

The map should help users quickly answer:

> Saan ang lugar, at ano ang alam natin ngayon tungkol sa accessibility nito?

The existing list, place detail screen, state/pulse/memory model, evidence flow, LGU flow, and inspector flow must remain intact.

## Scope

### In Scope

- Public home map section showing known places as markers.
- Existing place list retained below the map.
- Marker tap opens the existing `PlaceDetailScreen`.
- Graceful fallback when Google Maps is unavailable or no API key is configured.
- Simple `Add a place` flow.
- Newly added place starts with Mobility Access set to `unknown`.
- New place gets weak/unknown pulse and initial memory events.
- New place can immediately use existing confirm visit and evidence submission flows.
- Simpler Filipino/Taglish copy for public-facing screens.
- Tests for place creation service and fallback behavior.

### Out of Scope for This Milestone Set

- Full Supabase-backed place creation.
- Google Places Autocomplete.
- Geocoding.
- Route planning or navigation.
- Live location permission.
- Heatmaps.
- Complex duplicate resolution.
- Multi-dimension accessibility expansion.
- Production authentication changes.
- Major refactor of existing public/LGU/inspector flows.

## Implementation Strategy

Build this in demo-safe milestones. The map must never become a single point of failure. If Google Maps fails, the app should still show the existing list and core flow.

The recommended order is:

1. Copy constants and public wording cleanup.
2. Domain service for place creation.
3. Add place flow with non-map fallback.
4. Map shell with markers and fallback.
5. Map picker integration.
6. Supabase artifact alignment only.
7. Tests, build, and final stabilization.

---

# Milestone 1 — Public Copy Cleanup and Safety Labels

## Goal

Make the public-facing experience easier for Filipino users before adding new UI complexity.

## Implementation Notes

Create or update a centralized copy file if one already exists. If the codebase does not have copy constants yet, add a lightweight file such as:

```dart
lib/shared/copy/accesspulse_copy.dart
```

Use simple Taglish and avoid deep government-heavy terms.

## Suggested Copy

Use these labels for public screens:

```dart
class AccessPulseCopy {
  static const publicHomeTitle = 'Accessibility status ngayon';
  static const publicHomeSubtitle =
      'Tingnan ang public places at tumulong mag-update ng accessibility info.';
  static const searchPlace = 'Hanapin ang lugar';
  static const chooseFromMapOrList = 'Pumili sa mapa o sa listahan.';
  static const addPlace = 'Magdagdag ng lugar';

  static const mobilityAccess = 'Mobility access';
  static const pulseFreshness = 'Gaano kabago ang info';
  static const issueSummary = 'Buod ng issue';
  static const placeMemory = 'History ng lugar';

  static const addEvidence = 'Magdagdag ng ebidensya';
  static const confirmVisit = 'I-confirm ang visit';

  static const notAComplaint =
      'Hindi ito reklamo. Kinukumpirma mo lang ang nangyari.';
  static const aiCheck = 'I-check ng AI';
  static const aiSafetyNote =
      'Tulong lang ang AI. Hindi ito official verification.';
  static const submitToLguReview = 'I-submit sa LGU review';

  static const unknown = 'Wala pang sapat na info';
  static const reliableAging = 'May info, pero luma na';
  static const underReview = 'Nire-review';
  static const recentlyRefreshed = 'Bagong update';
  static const resolved = 'Naayos na';
  static const recentlyRevalidated = 'Accessible ngayon';

  static const mapUnavailable =
      'Hindi muna ma-load ang mapa. Pwede ka pa ring pumili sa listahan.';
}
```

Adjust names to match existing project style.

## Acceptance Criteria

- Public-facing labels are simpler and more local.
- AI safety note remains visible where AI evidence review is shown.
- Human verification remains clearly authoritative.
- No institutional workflow labels are broken.
- Existing tests still pass or are updated only for intentional copy changes.

---

# Milestone 2 — Place Creation Domain Service

## Goal

Add the domain logic required to create a new place safely and consistently.

## Why This Comes Before UI

The `Add a place` screen should not manually scatter initialization logic. A new place must always be created with:

- `Place`
- `PlaceDimension` for `mobility_access`
- initial `DimensionStateRecord`
- initial `DimensionPulseRecord`
- initial `MemoryEvent`

This preserves the AccessPulse model.

## Recommended File

```dart
lib/domain/services/place_creation_service.dart
```

## Service Responsibility

Create a service such as `PlaceCreationService` with a method similar to:

```dart
Future<PlaceCreationResult> createPublicPlace({
  required String name,
  required String city,
  required double latitude,
  required double longitude,
  String? addressOrLandmark,
  String placeType = 'public_service_building',
  String? note,
});
```

Use actual domain types and enums from the codebase.

## Initialization Rules

When a place is created:

- Name is required.
- City/municipality is required.
- Latitude and longitude are required.
- Place type defaults to public service building if the user does not choose one.
- Accessibility dimension defaults to `mobility_access`.
- Dimension state starts as `unknown`.
- Pulse starts as weak/unknown depending on existing enum names.
- Memory records that the place was added and that accessibility info is not yet sufficient.
- The created place should be discoverable immediately in public home.
- The created place should support existing confirm visit and add evidence flows.

## Repository Contract

Prefer one atomic method if it fits the current architecture:

```dart
Future<PlaceCreationResult> createPlaceWithMobilityDimension(...);
```

If the repository already uses separate methods, add only the smallest needed methods:

```dart
Future<Place> addPlace(Place place);
Future<PlaceDimension> addPlaceDimension(PlaceDimension placeDimension);
Future<void> addDimensionStateRecord(DimensionStateRecord state);
Future<void> addDimensionPulseRecord(DimensionPulseRecord pulse);
Future<void> addMemoryEvent(MemoryEvent event);
```

Keep repository changes minimal and aligned with the current in-memory repository style.

## Duplicate Protection

Add a simple deterministic helper, not a full system.

For MVP:

- Normalize names by lowercasing and trimming punctuation.
- Compare to existing places.
- If name is similar and distance is within a small radius, return a duplicate suggestion.
- Do not block creation unless the UI chooses to open the existing place.

Suggested radius: 50–100 meters.

## Acceptance Criteria

- Creating a place creates all required domain records.
- New place starts as `unknown`, not accessible or verified.
- Memory explains that the place was added with insufficient accessibility information.
- Duplicate detection can suggest an existing nearby place.
- New place can enter existing confirm visit and evidence flow.
- Domain tests cover successful creation and missing required fields.

---

# Milestone 3 — Add Place Flow Without Google Maps Dependency

## Goal

Build the `Add a place` flow in a way that works even before Google Maps is wired.

This keeps progress testable and demo-safe.

## Recommended Files

```dart
lib/features/public/add_place_flow.dart
lib/features/public/add_place_form.dart
```

If the codebase already has a public feature folder structure, follow that structure.

## Screen Flow

### Step 1 — Place Details

Fields:

- Place name
- Place type
- Address or landmark
- Municipality / city
- Optional note: `Ano ang alam mo tungkol sa lugar na ito?`

### Step 2 — Location

Before map integration, support either:

- default demo coordinates, or
- manual latitude/longitude fields hidden behind a debug/test fallback, or
- a simple placeholder picker that uses seeded map center coordinates.

For demo purposes, avoid blocking the whole feature on Google Maps.

### Step 3 — Created Result

After creation, show:

```text
Nadagdag ang lugar. Wala pa tayong sapat na accessibility info dito.
```

CTAs:

- `I-confirm ang visit`
- `Magdagdag ng ebidensya`
- `Buksan ang lugar`

## Validation

Required:

- Name
- City/municipality
- Coordinates

Optional:

- Address/landmark
- Place type
- Note

## Navigation Behavior

After successful creation:

- Navigate to the new `PlaceDetailScreen`, or
- show a success screen with CTAs that route into the new place detail and existing actions.

Prefer direct navigation to `PlaceDetailScreen` if it is simpler and stable.

## Acceptance Criteria

- User can add a place without Google Maps working.
- Form validates missing required fields.
- Created place appears in public discovery.
- Created place detail shows unknown accessibility information.
- Existing `confirm visit` and `add evidence` actions work for the created place.
- No LGU/inspector flow is affected.

---

# Milestone 4 — Public Home Map Shell

## Goal

Add a lightweight Google Maps section to public home while keeping the existing list as fallback and support.

## Recommended File

```dart
lib/features/public/public_places_map.dart
```

or similar.

## Dependency

Add:

```yaml
google_maps_flutter: <latest stable compatible version>
```

Use the currently recommended setup from the package documentation.

## API Key Safety

Do not commit real API keys.

Use `--dart-define` or platform-specific configuration as appropriate.

Suggested environment names:

```text
GOOGLE_MAPS_API_KEY_WEB
GOOGLE_MAPS_API_KEY_ANDROID
GOOGLE_MAPS_API_KEY_IOS
```

For demo safety, the UI must work without a key.

## UI Behavior

Public home should show:

1. Header copy
2. Map section with bounded height
3. Search/list section below

Map requirements:

- Use existing `Place.latitude` and `Place.longitude`.
- Render marker for each known place with valid coordinates.
- Marker title should use place name.
- Marker tap opens the same `PlaceDetailScreen`.
- The GoogleMap widget must be inside a bounded-size parent.
- If map cannot load or keys are not configured, show fallback message and keep list visible.

Fallback text:

```text
Hindi muna ma-load ang mapa. Pwede ka pa ring pumili sa listahan.
```

## Important Note

Do not move core place discovery entirely into the map. The list is still important for accessibility, reliability, and fallback.

## Acceptance Criteria

- Public home shows a map when configuration is available.
- Seeded places appear as markers.
- Marker tap opens the existing place detail.
- Public home still works in list-only mode.
- Map failure does not block demo.
- Web build succeeds.

---

# Milestone 5 — Map Picker Integration for Add Place

## Goal

Upgrade the add-place flow so users can choose the new place location on a map when maps are available.

## Recommended File

```dart
lib/features/public/map_place_picker.dart
```

## Behavior

- Show map centered on a default city or first seeded place.
- User taps map to place a pin.
- User can move pin by tapping again.
- CTA: `Gamitin ang lokasyong ito`
- If map is unavailable, use fallback coordinate selection from Milestone 3.

## Add Place Integration

The final add-place flow should support:

1. Pick location on map or fallback.
2. Fill in place details.
3. Save place.
4. Navigate to created place detail.
5. Encourage next action:
   - confirm visit
   - add evidence

## Duplicate Suggestion

After location and name are known:

- Check for possible duplicate.
- If similar nearby place is found, show:

```text
Mukhang nasa listahan na ito. Buksan na lang ang existing place?
```

Actions:

- Open existing place
- Continue adding new place

## Acceptance Criteria

- User can pick a place location on the map.
- Selected coordinates are saved to the new place.
- New marker appears after place creation.
- Duplicate suggestion works for obvious local duplicates.
- Fallback still works without Maps.

---

# Milestone 6 — Supabase Artifact Alignment Only

## Goal

Align backend schema/docs with the new feature without attempting full runtime persistence.

## Important Constraint

Do not build a full Supabase-backed repository in this feature unless explicitly instructed later. The current MVP is intentionally demo-safe with in-memory runtime behavior.

## Recommended Updates

Update Supabase schema/docs/artifacts to include or confirm:

- `places.latitude`
- `places.longitude`
- optional `places.created_by`
- optional `places.created_from`
- optional `places.pending_review`
- case status enum includes:
  - `remediationRequested`
  - `remediationVerificationRequested`

If the schema already has latitude/longitude, do not duplicate fields.

## Acceptance Criteria

- Supabase artifacts describe a future persistence path for added places.
- Runtime behavior remains in-memory unless separately scoped.
- No migration or deploy step is required for the demo.

---

# Milestone 7 — Tests, Build, and Demo Stabilization

## Goal

Ensure the map/add-place feature does not break the core AccessPulse demo.

## Required Tests

### Domain Tests

Cover:

- place creation succeeds
- missing name fails
- missing city fails
- created place has mobility access dimension
- state starts as unknown
- pulse starts weak/unknown
- memory event is appended
- duplicate suggestion detects obvious nearby duplicate

### Widget Tests

Cover:

- public home shows map fallback in test mode
- add-place form validates required fields
- created result appears after successful creation
- created place detail shows unknown info
- CTAs are visible:
  - `I-confirm ang visit`
  - `Magdagdag ng ebidensya`

### Manual Demo Checks

Verify:

- public home loads
- map or fallback displays
- list still displays
- marker tap opens place detail
- add place works
- created place appears in list and map
- confirm visit works for created place
- add evidence works for created place
- LGU review still works
- inspector verification still works
- remediation/revalidation loop still works

## Commands

Run:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

If widget tests are unstable because of the map widget, abstract the map behind a wrapper and test fallback/test mode instead of trying to render native Google Maps in widget tests.

## Acceptance Criteria

- Formatting passes.
- Analyze passes.
- Relevant tests pass.
- Web build passes.
- Demo can run without real Google Maps key.
- No real API keys are committed.

---

# Final Definition of Done

The feature is complete when:

- Public home can show a map of known places.
- Public home still works as a list when maps fail.
- User can add a missing place.
- Added place starts with Mobility Access as unknown.
- Added place gets initial pulse and memory.
- Added place appears in public discovery.
- Added place can use existing confirm visit and evidence flows.
- Public-facing copy is simpler and more Filipino-user friendly.
- AI safety and human verification boundaries remain clear.
- LGU and inspector flows remain stable.
- No real API keys are committed.
- `dart format .`, `flutter analyze`, `flutter test`, and `flutter build web` pass.

## Implementation Notes for the Codebase Agent

- Treat the uploaded AccessPulse map/add-place plan as the source baseline.
- Do not reopen product decisions.
- Do not redesign AccessPulse.
- Do not turn this into a navigation app.
- Do not make Google Maps required for the demo.
- Preserve the existing evidence-to-action loop.
- Prefer small components and services over large rewrites.
- Commit or checkpoint after each milestone.
- If a milestone becomes risky, stop at the safest complete version and document what remains.
