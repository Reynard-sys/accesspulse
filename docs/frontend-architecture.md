# AccessPulse — Frontend Architecture

> **Status:** Current as of MVP build  
> **Stack:** Flutter · Dart · Material 3  
> **Platform:** Mobile-first, responsive up to 980px max content width

---

## Directory Structure

```
lib/
├── main.dart                                    # Entry point
├── app/
│   └── accesspulse_app.dart                     # Root widget, DI, theme, role shell
├── config/
│   └── ai_config.dart                           # AI backend config (Gemini vs. mock)
├── data/
│   ├── in_memory_accesspulse_repository.dart    # In-memory data store (MVP)
│   └── accesspulse_seed_data.dart               # Seeded demo data
├── domain/
│   ├── accesspulse_domain.dart                  # Barrel export
│   ├── models/
│   │   └── accesspulse_models.dart              # All domain models (enums + classes)
│   ├── repositories/
│   │   └── accesspulse_repository.dart          # Abstract repository interface
│   └── services/
│       ├── dimension_state_service.dart         # Core state-transition orchestration
│       ├── ai_evidence_service.dart             # AI analysis abstraction
│       ├── pulse_service.dart                   # Pulse calculation logic
│       └── ramp_slope_capture_service.dart      # Device accelerometer capture
└── features/
    ├── public/
    │   └── public_flow.dart                     # All community-user screens + widgets
    └── institution/
        └── institution_flow.dart                # All institution screens + widgets
```

---

## Architecture Overview

```
main.dart
  └── AccessPulseApp          (creates repo + services; owns the DI root)
        └── _AccessPulseRoleShell   (BottomNavigationBar, 3 tabs)
              ├── PublicHomeScreen           (public_flow.dart)
              │     └── PlaceDetailScreen
              │           ├── ConfirmVisitScreen → SubmissionResultScreen
              │           └── EvidenceFlowScreen → SubmissionResultScreen
              ├── InstitutionDashboardScreen [LGU]   (institution_flow.dart)
              │     └── _CaseDetailScreen
              └── InstitutionDashboardScreen [Inspector]
                    └── _CaseDetailScreen
                          └── _InspectorVerificationScreen → _VerificationResultScreen
```

---

## 1. Entry Point & Dependency Injection

**Files:** `lib/main.dart`, `lib/app/accesspulse_app.dart`

`main.dart` is a thin shell that runs `AccessPulseApp`. All real setup happens inside `AccessPulseApp.initState()`.

There is **no external DI framework**. The three core dependencies are created once and prop-drilled down:

| Dependency | Concrete type | Purpose |
|---|---|---|
| `AccessPulseRepository` | `InMemoryAccessPulseRepository.seeded()` | Data store |
| `DimensionStateService` | — | Orchestrates all state transitions |
| `AiEvidenceService` | `GeminiServerEvidenceService` or `MockAiEvidenceService` | AI analysis |

The AI service selection is decided at startup via `AiConfig.fromEnvironment.hasServerWrapper`. If a Supabase Edge Function URL and anon key are present in the environment, the real Gemini service is used; otherwise, the mock is used for demo.

---

## 2. Role Shell & Navigation

**File:** `lib/app/accesspulse_app.dart`

`_AccessPulseRoleShell` is the `home` of the `MaterialApp`. It renders a `BottomNavigationBar` with 3 destinations:

| Index | Tab label | Screen | Role context |
|---|---|---|---|
| 0 | Public | `PublicHomeScreen` | Community user |
| 1 | LGU | `InstitutionDashboardScreen` | `InstitutionRole.lguReviewer` |
| 2 | Inspector | `InstitutionDashboardScreen` | `InstitutionRole.inspector` |

Tab switching uses `AnimatedSwitcher` with a **fade + 2% diagonal slide** transition (240ms, `easeOutCubic`/`easeInCubic`). Each tab child is wrapped in `KeyedSubtree(key: ValueKey(_selectedIndex))` to force a full rebuild on switch.

### Page Transitions

Each feature defines its own `PageRouteBuilder`:

- `_accessPulseRoute<T>` — used in the public flow
- `_institutionRoute<T>` — used in the institution flow

Both produce identical transitions: **fade + 2% diagonal slide**, `easeOutCubic` in, `easeInCubic` out.

---

## 3. Public Flow

**File:** `lib/features/public/public_flow.dart` (~1,800 lines)

The entire community-user experience lives in a single file. Navigation is imperative via `Navigator.push` / `Navigator.pushReplacement`.

### Screen Map

```
PublicHomeScreen
  └─(tap place)─► PlaceDetailScreen
                    ├─(confirm visit)─► ConfirmVisitScreen ─► SubmissionResultScreen
                    └─(add evidence)─► EvidenceFlowScreen  ─► SubmissionResultScreen
```

### Screens

#### `PublicHomeScreen`
- Loads all places via `FutureBuilder<List<Place>>`
- Renders a `TextField` search filter (client-side, updates `_query` on `onChanged`)
- Each place row is a `_PlaceListTile` that independently loads its own state + pulse via a nested `FutureBuilder`

#### `PlaceDetailScreen`
- Loads `PlaceDimension`, `DimensionStateRecord`, `DimensionPulseRecord`, and the last N `MemoryEvent`s
- Uses a private `_PlaceDetailData` class to bundle the async result
- Renders `_StateCard` (animated fade-slide-in), two action buttons (`_DetailActions`), and memory timeline
- After returning from a sub-screen, calls `_refresh()` which reassigns `_detailFuture = _load()` to trigger a rebuild

#### `ConfirmVisitScreen`
- 4 `_QuestionSwitch` toggle cards: entrance usable, ramp usable, needed assistance, completed purpose
- Optional `TextField` note (pre-filled with a demo string)
- Calls `stateService.confirmVisit()` → navigates to `SubmissionResultScreen`

#### `EvidenceFlowScreen`
- Evidence collection in layers:
  1. Demo photo toggle (simulates image pick)
  2. `TextField` evidence note
  3. **Conditional ramp slope capture panel** — shown if the note contains keywords: `ramp`, `steep`, `incline`, `slope`, `unsafe`, `wheelchair entrance`
  4. `_AiResultPanel` — appears after calling `aiService.analyzeMobilityEvidence()`
  5. `_ReviewPacketPanel` — summary of what's in the packet
  6. Submit button → `stateService.submitStructuredEvidence()`
- Uses a `MockAiEvidenceService` fallback if real AI fails (error is surfaced via `_InlineNotice`)

#### `SubmissionResultScreen`
- Animated scale-in checkmark icon (`TweenAnimationBuilder`, `easeOutBack`)
- `_TransitionRow` showing before → after state and pulse
- Optional "Add evidence" next action button

### Ramp Slope Sub-flow

`EvidenceFlowScreen` embeds a mini state machine via `_RampSlopeCapturePanel`:

```
Entry ─(start)─► Capturing ─(success)─► Success (retry available)
                           └(failure)─► Failure (retry available)
```

Transitions use `AnimatedSwitcher` (200ms). The demo toggle forces `RampSlopeCaptureService.fallbackMeasurement()` (900ms simulated delay, seeded 14.8° reading) instead of the live accelerometer path.

### Key Private Widgets (Public Flow)

| Widget | Description |
|---|---|
| `_PlaceListTile` | Card tile, async loads state + pulse per place |
| `_StateCard` | Animated entry card: state label, pulse, confidence, last confirmed, explanation |
| `_StatusPill` | Color-coded pill badge with `AnimatedContainer` + `AnimatedSwitcher` for smooth label/color transitions |
| `_AiResultPanel` | AI output: issue type, confidence %, observed features (Chips), missing evidence list |
| `_ReviewPacketPanel` | Submission checklist: note / photo / ramp reading included |
| `_RampSlopeCapturePanel` | Multi-state sensor UI (entry / capturing / success / failure) |
| `_FadeSlideIn` | `TweenAnimationBuilder` wrapper — 280ms fade + 10px Y slide for the state card |
| `_MemoryTile` | Single memory event: event type label, summary, date |
| `_QuestionSwitch` | `Card` + `SwitchListTile` |
| `_MetricRow` | Label/value row, value is bold and right-aligned |
| `_TransitionRow` | Before → after Chip pair with arrow icon |
| `_InlineNotice` | Error notice with colored border and icon |
| `_SectionHeader` | Icon + bold title row used to separate card sections |

---

## 4. Institution Flow

**File:** `lib/features/institution/institution_flow.dart` (~1,170 lines)

The `InstitutionRole` enum (`lguReviewer` | `inspector`) is passed into `InstitutionDashboardScreen` and flows down through every screen. It gates which cases are shown and which actions appear.

### Screen Map

```
InstitutionDashboardScreen
  └─(tap case)─► _CaseDetailScreen
                    └─(inspector only)─► _InspectorVerificationScreen
                                           └─► _VerificationResultScreen
```

### Screens

#### `InstitutionDashboardScreen`
- Loads cases filtered by role:
  - **LGU:** all non-closed cases
  - **Inspector:** `inspectionRequested`, `verified`, `disputed`, `triaging`
- Enriches each case with its `Place`, `DimensionStateRecord`, and `DimensionPulseRecord` into a `_CaseSummary` view object
- Each row is a `_CaseQueueTile` with status icon, state label, pulse label

#### `_CaseDetailScreen`
- Loads full case detail: case, barrier signal, evidence, ramp measurement, state, pulse, memory
- Bundles into `_CaseDetailData`
- Renders:
  - `_InstitutionStateCard` — place name, case title, severity, confidence, status/state/pulse pills
  - `_SignalPanel` — AI evidence bundle with ramp measurement block
  - `_MemoryPanel` — last 6 memory events
- **LGU actions:** Mark triaging / Request inspection / Close case
- **Inspector action:** Open verification → navigates to `_InspectorVerificationScreen`

#### `_InspectorVerificationScreen`
- `SegmentedButton<VerificationOutcome>` with 3 options: Confirm / Dispute / Insufficient evidence
- `TextField` verification note
- Calls `stateService.submitVerification()` → navigates to `_VerificationResultScreen`

#### `_VerificationResultScreen`
- Animated scale-in verified icon
- Before → after rows for state, pulse, and case status

### Key Private Widgets (Institution Flow)

| Widget | Description |
|---|---|
| `_CaseQueueTile` | Case list card with status icon from `CaseStatus.icon` extension |
| `_InstitutionStateCard` | Full case header card with `_StatusPill` badges |
| `_SignalPanel` | AI evidence bundle: issue type, AI confidence, contributor note, features, missing context |
| `_RampMeasurementBlock` | Structured ramp measurement display in a highlighted container |
| `_MemoryPanel` | Inline timeline of last 6 memory events |
| `_EmptyQueue` | Empty state placeholder |

---

## 5. State Management

There is **no state management library** (no Provider, Riverpod, Bloc, etc.).

The pattern across all screens is:

```
1. initState() → _detailFuture = _load()
2. FutureBuilder renders from _detailFuture
3. User action → await stateService.action()
4. _refresh() → setState(() { _detailFuture = _load(); })
5. FutureBuilder rebuilds with fresh data
```

Loading state is covered by `CircularProgressIndicator()` in the `FutureBuilder` builder when `!snapshot.hasData`. Errors during actions are surfaced inline via local `String?` error fields and `_InlineNotice` widgets.

---

## 6. Domain Layer

The domain layer is **pure Dart** — no Flutter dependency.

| File | Purpose |
|---|---|
| `accesspulse_models.dart` | All enums and immutable `const` data classes |
| `accesspulse_repository.dart` | Abstract interface — UI depends only on this, not the concrete impl |
| `dimension_state_service.dart` | Orchestrates confirmVisit, submitStructuredEvidence, triageCase, requestInspection, submitVerification, closeCase |
| `ai_evidence_service.dart` | Abstract AI interface with Gemini and mock implementations |
| `pulse_service.dart` | Pulse score and level calculation |
| `ramp_slope_capture_service.dart` | Accelerometer capture and `RampSlopeMeasurement` result |

### Core Domain Models

| Model | Key fields |
|---|---|
| `Place` | id, name, placeType, address, municipality |
| `PlaceDimension` | placeId, dimensionId — the join between place and dimension |
| `DimensionStateRecord` | state (`DimensionStateValue`), confidence, explanation, source, updatedAt |
| `DimensionPulseRecord` | level (`DimensionPulseLevel`), score, supportingObservationsCount, contradictionFlag |
| `Observation` | entranceUsable, rampUsable, neededAssistance, completedPurpose, note |
| `Evidence` | evidenceType, storagePath, publicUrl, note, metadata |
| `BarrierSignal` | issueType, observedFeatures, possibleBarrier, missingEvidence, confidence, structuredSummary |
| `AccessCase` | status (`CaseStatus`), severity, confidence, barrierSignalId |
| `Verification` | caseId, outcome (`VerificationOutcome`), note, verifiedBy |
| `MemoryEvent` | eventType, previousState, newState, previousPulse, newPulse, summary |

---

## 7. Theme & Visual Language

Defined once in `AccessPulseApp.build()`:

- **Material 3** with `useMaterial3: true`
- **Seed color:** `#27665F` (deep teal-green)
- **Background:** `#F7F9F8` (off-white)
- **Card style:** elevation 0, `#DBE4E0` border, 8px radius
- **Max content widths:** 760px (forms) · 820px (evidence) · 920px (lists) · 980px (institution)

### State Color Palette

| State | Color |
|---|---|
| Unknown | `#52616B` (grey-blue) |
| Claimed Accessible | `#8A6D00` (amber) |
| Reliable | `#17643A` (green) |
| Degraded | `#B6461A` (orange-red) |
| Officially Verified Degraded | `#9D1B1E` (deep red) |
| Under Review | `#1765A6` (blue) |
| Resolved | `#17643A` (green) |

### Pulse Color Palette

| Pulse | Color |
|---|---|
| Weak | `#7A4D00` (brown-amber) |
| Moderate | `#1765A6` (blue) |
| Strong | `#17643A` (green) |

---

## 8. Known Architecture Notes & Refactor Opportunities

> These are observations for future work, not bugs.

- **`DimensionStateValue` and `DimensionPulseLevel` extensions are duplicated** in both `public_flow.dart` and `institution_flow.dart`. Moving these to the domain layer or a shared `ui_extensions.dart` file would eliminate the duplication.
- **Prop drilling is verbose.** As the feature set grows, introducing an `InheritedWidget`, `Provider`, or `Riverpod` layer for the repo/service trio would reduce boilerplate.
- **Two large single files** per feature. The current structure is easy to trace end-to-end, but each file will need splitting into screen files + widget files as more screens and dimensions are added.
- **No routing library.** Imperative `Navigator.push` works for the MVP scope. A `go_router` or `auto_route` setup would be needed once deep linking, web support, or more complex navigation stacks are required.
- **`FutureBuilder` pattern causes flicker on refresh.** Wrapping the data fetch in a `StreamController` or caching the last known value before `_refresh()` would prevent the loading spinner from appearing on every state update.
