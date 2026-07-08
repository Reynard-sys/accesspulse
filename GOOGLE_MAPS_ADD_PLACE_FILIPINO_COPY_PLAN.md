# AccessPulse Maps, Add Place, and Filipino Copy Plan

## Goal

Add Google Maps and an `Add a place` flow without breaking the current AccessPulse loop:

Public place discovery -> place detail -> confirm visit / add evidence -> LGU review -> inspector verification -> remediation -> public memory.

At the same time, simplify public-facing copy for Filipino users using normal, concise Tagalog or light Taglish. The product should feel easier to understand, but still preserve AccessPulse concepts: living state, pulse/freshness, place memory, AI as support, and human verification.

## Product Direction

Maps should help people answer one question quickly:

> "Saan ang lugar, at ano ang alam natin ngayon tungkol sa accessibility nito?"

The map should not replace the existing list. The safest first version is a map-plus-list public home:

- Map at the top with markers for known places.
- Search/list below for accessibility scanning.
- Tapping a marker opens the same `PlaceDetailScreen`.
- `Add a place` lets users add a missing public place, then routes into the existing place detail where they can confirm a visit or add evidence.

This keeps the current strongest flow intact while making discovery more spatial and practical.

## Recommended Implementation Strategy

### Phase 1 - Map Shell, No New Backend Risk

Use the official `google_maps_flutter` package and existing `Place.latitude` / `Place.longitude` fields.

Add:

- `google_maps_flutter` dependency.
- Google Maps API key configuration for Web and mobile targets.
- A public-home map section that renders markers from `repository.listPlaces()`.
- Fallback UI when no Maps API key is configured or map loading fails.
- Marker tap -> existing `PlaceDetailScreen`.

Important technical notes:

- Google Maps for Flutter supports Android, iOS, and Web; desktop app targets outside a browser are not supported by the SDK.
- The `GoogleMap` widget must be placed inside a bounded-size parent.
- Use separate restricted API keys per platform where possible.

### Phase 2 - Add Place, In-Memory First

Add a simple `Add a place` flow using the existing in-memory architecture first.

Minimal fields:

- Place name
- Place type
- Address or landmark
- Municipality / city
- Map pin location
- Optional note: "Ano ang alam mo tungkol sa lugar na ito?"

Creation behavior:

- Create a new `Place`.
- Create a `PlaceDimension` for `mobility_access`.
- Create an initial `DimensionStateRecord` as `unknown`.
- Create an initial `DimensionPulseRecord` as `weak`.
- Append memory events:
  - `placeSeeded` or new `placeAdded`
  - `stateSeeded` or `stateChanged` with `unknown`

After creation:

- Navigate to the new `PlaceDetailScreen`.
- Show clear next actions:
  - `I-confirm ang visit`
  - `Magdagdag ng ebidensya`

This makes the feature useful immediately while preserving the current state/pulse/memory model.

### Phase 3 - Supabase Schema Alignment

After the local flow works, update backend artifacts so the feature has a future persistence path.

Recommended schema additions:

- Ensure `places.latitude` and `places.longitude` are used consistently.
- Add optional metadata to places if needed:
  - `created_by`
  - `created_from`
  - `pending_review`
- Add remediation statuses to the base `case_status` enum, because Dart already has:
  - `remediationRequested`
  - `remediationVerificationRequested`

Do not build a full Supabase-backed repository during this feature unless explicitly scoped later.

### Phase 4 - Optional Location Helpers

Only after the basic map and add-place flow are stable:

- Use current location to center the map.
- Allow "Use my current location" for the new place pin.
- Consider Places Autocomplete or Geocoding for address search.

Keep these optional because they add API, billing, permissions, and failure-state complexity.

## Add Place Flow

### Entry Points

Public home:

- Floating or top-row action: `Add a place`
- Empty/search state action: `Wala dito? Add a place`

Place list/map:

- A small button near search: `Magdagdag ng lugar`

### Screen Steps

1. **Choose Location**
   - Show map.
   - User taps where the place is.
   - Pin can be moved.
   - CTA: `Gamitin ang lokasyong ito`

2. **Place Details**
   - Name
   - Type
   - Address / landmark
   - City
   - CTA: `I-save ang lugar`

3. **Created Result**
   - Message: `Nadagdag ang lugar. Wala pa tayong sapat na accessibility info dito.`
   - CTAs:
     - `I-confirm ang visit`
     - `Magdagdag ng ebidensya`

### Validation

Required:

- Name
- Municipality / city
- Coordinates

Optional:

- Address
- Place type defaults to `public_service_building`

Duplicate protection:

- If a new place is very close to an existing one and the name is similar, show:
  - `Mukhang nasa listahan na ito. Buksan na lang ang existing place?`

For MVP, this can be deterministic and local:

- Normalize names.
- Compare distance within a small radius.
- Suggest the nearest match.

## Filipino Copy Direction

Use simple, everyday Tagalog. Avoid deep Filipino words, government-heavy language, and technical product terms when a plain phrase works.

Recommended style:

- Use `lugar` for place.
- Use `accessibility info` when simpler than translating accessibility deeply.
- Use `kasalukuyang estado` sparingly; prefer `status ngayon`.
- Keep `AI` as `AI`.
- Keep `LGU` and `inspector` as-is.
- Avoid blame-heavy words like `reklamo` unless explaining that it is not a complaint.

### Copy Principles

- Short sentences.
- One idea per line.
- Explain what users can do, not system internals.
- Use Taglish where natural.
- Preserve safety boundaries:
  - AI does not verify.
  - Inspector remains official.
  - Reports update knowledge, not legal conclusions.

## Suggested Copy Replacements

| Current / Technical | Simpler Filipino Copy |
| --- | --- |
| Current accessibility state | Accessibility status ngayon |
| Check public service buildings and help update living accessibility knowledge. | Tingnan kung accessible ang lugar ngayon. Tumulong mag-update ng info. |
| Add Evidence | Magdagdag ng ebidensya |
| Confirm | I-confirm ang visit |
| Freshness / pulse | Gaano kabago ang info |
| Place memory | History ng lugar |
| Current Issue Summary | Buod ng issue |
| You are not filing a complaint. You are confirming what happened. | Hindi ito reklamo. Kinukumpirma mo lang ang nangyari. |
| Analyze evidence | I-check ng AI |
| Review packet submitted | Na-submit na ang ebidensya |
| Awaiting LGU review | Hinihintay ang LGU review |
| Human verification is authoritative. | Inspector pa rin ang official na magve-verify. |
| Official verification remains with human reviewers. | Official verification ay sa inspector pa rin. |
| Unknown | Wala pang sapat na info |
| Reliable, aging | May info, pero luma na |
| Under review | Nire-review |
| Recently refreshed | Bagong update |
| Resolved | Naayos na |
| Recently Revalidated | Bagong na-verify ulit |

## Screen-Level Copy Plan

### Public Home

Headline:

`Accessibility status ngayon`

Supporting text:

`Tingnan ang public places at tumulong mag-update ng accessibility info.`

Search placeholder:

`Hanapin ang lugar`

Add place CTA:

`Magdagdag ng lugar`

Map/list bridge:

`Pumili sa mapa o sa listahan.`

### Place Detail

State label section:

`Mobility access`

Pulse label:

`Gaano kabago ang info`

Issue summary:

`Buod ng issue`

Memory:

`History ng lugar`

Actions:

- `Magdagdag ng ebidensya`
- `I-confirm ang visit`

### Confirm Visit

Banner:

`Hindi ito reklamo. Kinukumpirma mo lang ang nangyari.`

Question examples:

- `Nagamit mo ba ang entrance nang walang tulong?`
- `Kailangan mo ba ng assistance para makapasok?`
- `May ramp ba sa entrance?`
- `May iba ka pa bang napansin?`

### Evidence Flow

Photo:

`Larawan ng entrance o ramp`

Note:

`Ano ang nangyari?`

AI button:

`I-check ng AI`

AI guidance title:

`AI guide`

AI safety note:

`Tulong lang ang AI. Hindi ito official verification.`

Review packet:

`Review summary`

Submit:

`I-submit sa LGU review`

### LGU / Inspector

Keep more English than public screens if needed, because institutional users may expect operational labels.

Still simplify:

- `Why This Case Matters` -> `Bakit ito importante`
- `Why now` -> `Bakit ngayon`
- `Suggested next action` -> `Susunod na action`
- `Evidence bundle` -> `Ebidensya`
- `Submitted photo reference` -> `Submitted na larawan`
- `Request inspection` -> `Request inspection`
- `Request remediation` -> `Request remediation`
- `Request remediation verification` -> `Request re-check`

## Data and Domain Changes

### Models

Current `Place` already has:

- `latitude`
- `longitude`

Likely additions:

- No required model change for Phase 1.
- Optional future fields for add-place provenance:
  - `createdBy`
  - `createdAt`
  - `pendingReview`

### Repository Contract

Add methods:

```dart
Future<Place> addPlace(Place place);
Future<PlaceDimension> addPlaceDimension(PlaceDimension placeDimension);
Future<void> initializePlaceDimension({
  required Place place,
  required PlaceDimension placeDimension,
  required DimensionStateRecord state,
  required DimensionPulseRecord pulse,
  required List<MemoryEvent> memoryEvents,
});
```

Alternative:

```dart
Future<PlaceDimension> createPlaceWithMobilityDimension(...)
```

Prefer the second option if we want to keep creation atomic and avoid scattering initialization logic across UI.

### Service

Add a small domain service:

`PlaceCreationService`

Responsibilities:

- Validate required fields.
- Generate IDs.
- Create place + mobility dimension.
- Seed unknown state + weak pulse.
- Append memory.
- Return created place and place dimension.

This keeps `AddPlaceScreen` thin and makes the feature testable.

## UI Architecture

Recommended files:

- `lib/domain/services/place_creation_service.dart`
- `lib/features/public/add_place_flow.dart`
- `lib/features/public/map_place_picker.dart`
- Keep existing `public_flow.dart` integration small:
  - show map section
  - add `Add a place` navigation
  - marker tap navigation

If `public_flow.dart` gets too large, use this as a chance to split only the new map/add-place code out, not to refactor the whole public feature.

## Google Maps Configuration

Add dependency:

```yaml
google_maps_flutter: latest stable
```

Environment/API key plan:

- Add `.env.example` placeholder:
  - `GOOGLE_MAPS_API_KEY_WEB`
  - `GOOGLE_MAPS_API_KEY_ANDROID`
  - `GOOGLE_MAPS_API_KEY_IOS`
- For Flutter web, inject Maps JavaScript script in `web/index.html` or use the currently recommended package setup.
- For Android/iOS, configure platform files according to the official Google Maps Flutter docs.
- Restrict API keys by platform.
- Do not commit real keys.

App behavior:

- If map cannot load, show list-only mode:
  - `Hindi muna ma-load ang mapa. Pwede ka pa ring pumili sa listahan.`

## Testing Plan

### Domain Tests

- Creating a place creates:
  - place
  - place dimension
  - unknown state
  - weak pulse
  - memory event
- Duplicate detection suggests existing nearby place.
- New place can immediately accept visit confirmation.
- New place can accept evidence submission and open LGU case.

### Widget Tests

- Public home shows map fallback when maps are unavailable in test mode.
- Add place form validates missing name/location.
- Add place success routes to the created place detail.
- Created place detail shows:
  - `Wala pang sapat na info`
  - `Gaano kabago ang info`
  - `I-confirm ang visit`
  - `Magdagdag ng ebidensya`

### Manual / Browser Checks

- Web map loads with markers.
- Marker tap opens place detail.
- Add place via map tap.
- Newly added place appears in list and map.
- Existing confirm/evidence/LGU/inspector flow still works.

## Rollout Order

1. Add Filipino copy constants/helpers for public-facing labels.
2. Add `PlaceCreationService` and repository creation methods.
3. Add `AddPlaceScreen` with non-map coordinate fallback for tests.
4. Add map display to public home with graceful fallback.
5. Wire map picker into add-place flow.
6. Update Supabase schema docs/artifacts.
7. Run:

```powershell
dart format .
flutter analyze
flutter test
flutter build web
```

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Maps API key missing during demo | List-only fallback; add place can use manual city/address and default coordinates until map is configured. |
| Map package complicates widget tests | Abstract map behind a small widget and use fallback/test mode. |
| Add place creates incomplete data | Use service-level creation so state, pulse, and memory are always initialized together. |
| Filipino copy becomes too formal | Use concise Taglish and validate visible text screen by screen. |
| User thinks AI verifies accessibility | Keep AI safety notes in evidence and result screens. |
| New place bypasses institution flow | Route created places into existing detail, confirm visit, evidence, and case creation paths. |

## Definition of Done

- Public home can show places on a map.
- Public home still works as a list when maps fail.
- User can add a place.
- Added place has Mobility Access state initialized as unknown.
- Added place appears in public discovery.
- Added place can use existing confirm visit and evidence flows.
- Filipino copy is simpler on public-facing screens.
- Institutional flow remains understandable and unchanged where operational English is clearer.
- No real API keys are committed.
- `flutter analyze`, relevant tests, and `flutter build web` pass.

## References

- Google Maps for Flutter setup: https://developers.google.com/maps/flutter-package/config
- Google Maps for Flutter overview: https://developers.google.com/maps/flutter-package/overview
- `google_maps_flutter` package docs: https://pub.dev/documentation/google_maps_flutter/latest/
