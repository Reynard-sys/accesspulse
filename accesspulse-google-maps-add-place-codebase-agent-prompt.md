# AccessPulse Google Maps, Add Place, and Filipino Copy — Codebase Agent Prompt

You are working on the AccessPulse Flutter MVP.

Your task is to implement the Google Maps discovery layer, a simple Add Place flow, and simpler Filipino/Taglish public-facing copy based on the current AccessPulse Maps, Add Place, and Filipino Copy Plan.

Do not redesign the product. Do not expand scope beyond this prompt. AccessPulse is still primarily a living accessibility intelligence system, not a maps app.

## Core Product Rule

Preserve the existing AccessPulse loop:

Public place discovery -> place detail -> confirm visit / add evidence -> AI evidence support -> LGU review -> inspector verification -> remediation -> revalidation -> public memory.

Google Maps is only a discovery layer. It must not replace the existing list or the existing place-detail flow.

## Working Thesis

Google Maps helps users discover places. AccessPulse explains the living accessibility truth of those places.

The map should help users answer:

> Saan ang lugar, at ano ang alam natin ngayon tungkol sa accessibility nito?

## Strict Constraints

- Keep the existing Public, LGU, and Inspector flows intact.
- Keep the existing State, Pulse, and Memory model intact.
- Keep AI as evidence support only.
- Do not let AI make official or legal verification claims.
- Human inspectors remain the authority for verification.
- Do not require Google Maps to work for the demo.
- Always provide a list-only fallback if the map is unavailable.
- Do not commit real Google Maps API keys.
- Do not implement full Supabase runtime persistence in this task.
- Do not add autocomplete, geocoding, live location, heatmaps, or routing unless explicitly asked later.
- Keep changes small and milestone-based.
- After every milestone, run relevant checks and fix regressions before moving on.

---

# Milestone 1 — Public Copy Cleanup

## Goal

Simplify public-facing copy using normal Filipino/Taglish while preserving AccessPulse concepts.

## Tasks

1. Find where public-facing strings are currently defined.
2. If no centralized copy file exists, create:

```dart
lib/shared/copy/accesspulse_copy.dart
```

3. Add or update copy constants for public home, place detail, evidence flow, and state labels.
4. Use these labels where safe without causing a broad refactor.

## Suggested Copy

Use these or close variants that fit the existing UI:

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
  static const recentlyRevalidated = 'Bagong na-verify ulit';

  static const mapUnavailable =
      'Hindi muna ma-load ang mapa. Pwede ka pa ring pumili sa listahan.';
}
```

## Checks

- Run `dart format .`
- Run `flutter analyze`
- Run relevant tests if copy changes affect widget assertions.

## Acceptance Criteria

- Public copy is simpler and more local.
- AI safety note remains clear.
- Human verification boundary remains clear.
- Existing flows still compile.

Stop and fix issues before continuing.

---

# Milestone 2 — Add Place Domain Service

## Goal

Create a safe and testable way to add a new place into the existing in-memory architecture.

## Tasks

1. Inspect existing domain models:
   - `Place`
   - `PlaceDimension`
   - `DimensionStateRecord`
   - `DimensionPulseRecord`
   - `MemoryEvent`
   - relevant enums
2. Inspect current repository interfaces and `InMemoryAccessPulseRepository`.
3. Add the smallest repository method or methods needed to create a place and its initial mobility dimension.
4. Create:

```dart
lib/domain/services/place_creation_service.dart
```

5. Implement a method similar to:

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

Adapt the method signature to the actual codebase.

## Creation Rules

When a new place is created:

- Create a `Place`.
- Create a `PlaceDimension` for `mobility_access`.
- Create initial state as `unknown`.
- Create initial pulse as weak/unknown using existing enum names.
- Append memory event that the place was added.
- Append or include memory explaining there is not enough accessibility info yet.
- Make the place visible in public discovery immediately.
- Make the place usable by existing confirm visit and evidence flows immediately.

## Duplicate Suggestion

Add simple local duplicate detection.

Rules:

- Normalize names by lowercasing and removing extra spaces/punctuation.
- Compare new place against existing places.
- If name is similar and distance is within 50–100 meters, return a possible duplicate.
- Do not hard-block creation; allow UI to open existing place or continue.

## Tests

Add domain tests for:

- successful place creation
- missing name
- missing city
- created place has mobility access dimension
- created state is unknown
- created pulse is weak/unknown
- memory event exists
- duplicate suggestion detects obvious nearby duplicate

## Checks

Run:

```powershell
dart format .
flutter analyze
flutter test
```

Stop and fix issues before continuing.

---

# Milestone 3 — Add Place Flow Without Maps Dependency

## Goal

Create a working Add Place flow that does not depend on Google Maps yet.

## Tasks

1. Add screen files using the existing feature structure. Suggested files:

```dart
lib/features/public/add_place_flow.dart
lib/features/public/add_place_form.dart
```

2. Add an entry point from public home:
   - `Magdagdag ng lugar`
   - Optional empty/search state: `Wala dito? Magdagdag ng lugar`
3. Build a form with:
   - place name
   - place type
   - address or landmark
   - city/municipality
   - optional note
4. Add temporary/fallback location behavior:
   - use default demo coordinates, or
   - use hidden/manual coordinates for test mode, or
   - use a simple placeholder location picker
5. On save, call `PlaceCreationService`.
6. Show created result or navigate directly to the created place detail.

## Success Message

Use:

```text
Nadagdag ang lugar. Wala pa tayong sapat na accessibility info dito.
```

## CTAs

Show:

- `I-confirm ang visit`
- `Magdagdag ng ebidensya`
- `Buksan ang lugar`

Use whichever routes are already safest in the app.

## Validation

Require:

- name
- city/municipality
- coordinates

Do not require address, note, or place type.

## Tests

Add or update widget tests for:

- required field validation
- successful add-place submission
- success message
- created place appears in public discovery
- created place detail shows unknown state
- confirm visit and add evidence CTAs are visible

## Checks

Run:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

Stop and fix issues before continuing.

---

# Milestone 4 — Public Home Map Shell

## Goal

Add Google Maps markers for known places without making maps required for the demo.

## Tasks

1. Add dependency:

```yaml
google_maps_flutter: <latest stable compatible version>
```

Use a version compatible with the current Flutter SDK.

2. Add a map widget file:

```dart
lib/features/public/public_places_map.dart
```

3. Put the GoogleMap widget inside a bounded-size parent.
4. Use existing `Place.latitude` and `Place.longitude`.
5. Render one marker per place with valid coordinates.
6. Marker tap should open the existing `PlaceDetailScreen`.
7. Public home should become map-plus-list:
   - map section at top
   - existing search/list below
8. Add fallback UI when map is unavailable or no key/config is present.

## API Key Rules

- Do not commit real keys.
- Use `--dart-define` or official platform-specific setup.
- Add only placeholders or documentation for:
  - `GOOGLE_MAPS_API_KEY_WEB`
  - `GOOGLE_MAPS_API_KEY_ANDROID`
  - `GOOGLE_MAPS_API_KEY_IOS`

## Fallback Text

Use:

```text
Hindi muna ma-load ang mapa. Pwede ka pa ring pumili sa listahan.
```

## Testing Strategy

Do not try to render native Google Maps in widget tests if it causes instability.

Instead:

- abstract map rendering behind a small wrapper
- add test/fallback mode
- test that fallback renders
- manually check actual map in browser/device

## Checks

Run:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

Stop and fix issues before continuing.

---

# Milestone 5 — Map Picker for Add Place

## Goal

Allow users to choose a new place location using a map when maps are available.

## Tasks

1. Add:

```dart
lib/features/public/map_place_picker.dart
```

2. Behavior:
   - show map centered on default city or first seeded place
   - user taps map to place a pin
   - user taps again to move pin
   - selected coordinates are passed back to add-place flow
   - CTA: `Gamitin ang lokasyong ito`
3. Preserve fallback coordinate behavior from Milestone 3.
4. Integrate picker before or during the add-place form.
5. After place creation, ensure the new marker appears on the map.

## Duplicate Suggestion UI

When a possible duplicate exists, show:

```text
Mukhang nasa listahan na ito. Buksan na lang ang existing place?
```

Actions:

- Open existing place
- Continue adding new place

Keep this simple and deterministic.

## Checks

Run:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

Stop and fix issues before continuing.

---

# Milestone 6 — Supabase Artifact Alignment Only

## Goal

Update backend schema/docs so the feature has a future persistence path without changing runtime persistence now.

## Tasks

1. Inspect current Supabase schema/docs/artifacts.
2. Confirm `places.latitude` and `places.longitude` exist.
3. If useful, add optional future fields:
   - `created_by`
   - `created_from`
   - `pending_review`
4. Confirm case status enum includes:
   - `remediationRequested`
   - `remediationVerificationRequested`
5. Do not build a full Supabase-backed repository.
6. Do not require migrations for the demo unless they are already part of the project workflow.

## Checks

Run formatting/analyze/tests as relevant.

## Acceptance Criteria

- Supabase artifacts are aligned with the new feature.
- Runtime remains in-memory.
- No production persistence work is introduced.

---

# Milestone 7 — Final Stabilization and Demo Check

## Goal

Make sure the new feature improves the pitch without weakening the existing demo.

## Required Commands

Run:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

## Manual Demo Script Check

Verify this path:

1. Public home opens.
2. Map appears, or fallback appears.
3. Existing place list still appears.
4. Tap a seeded place marker or list item.
5. Place detail opens.
6. State, pulse, issue summary, and memory still display.
7. Add a new place.
8. New place starts as unknown.
9. New place appears in public discovery.
10. New place can confirm visit.
11. New place can add evidence.
12. Evidence can open LGU case.
13. LGU can triage/request inspection.
14. Inspector can verify.
15. LGU can request remediation and re-check.
16. Inspector can verify remediation.
17. Public state shows resolved/revalidated wording.

## Final Definition of Done

- Public home supports map-plus-list discovery.
- Map marker tap opens existing place detail.
- Map failure does not break the demo.
- User can add a place.
- Added place starts as unknown with weak/unknown pulse.
- Added place has memory.
- Added place works with existing confirm/evidence flows.
- Filipino/Taglish copy is clearer on public screens.
- AI remains advisory.
- Inspectors remain authoritative.
- No real API keys are committed.
- Formatting, analyze, tests, and web build pass.

## Final Notes

If any milestone becomes risky or unstable, keep the safest working version and document what remains.

Priority order:

1. Existing AccessPulse demo must remain stable.
2. List-only fallback must always work.
3. Add Place should preserve State/Pulse/Memory.
4. Map should improve discovery, not become the product.
5. Filipino copy should improve clarity, not change domain meaning.

Begin with Milestone 1 only. Complete and verify it before moving to Milestone 2.
