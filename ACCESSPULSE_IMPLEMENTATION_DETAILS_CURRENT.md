# AccessPulse Current Implementation Details

## What AccessPulse Is

AccessPulse is a Flutter MVP for living accessibility intelligence. The current product is centered on one accessibility dimension, `mobility_access`, and one place category, public service buildings.

The core idea implemented in the codebase is:

- public contributors can update a place's living accessibility state
- contributors can attach stronger evidence, including photo-based reports and optional ramp-slope capture
- AI can structure that evidence into an institutional review signal
- LGU reviewers can triage and request inspection
- inspectors can submit authoritative verification outcomes
- place memory preserves what happened over time

The app is currently a polished demo-first MVP with strong local logic and a Supabase backend scaffold, but it still uses an in-memory repository at runtime.

## Current Product Scope

The current implementation supports:

- one accessibility dimension: `Mobility Access`
- three seeded public demo places
- three role views inside one app shell:
  - Public
  - LGU
  - Inspector
- onboarding
- living state updates from public visits
- evidence submission with note, photo, optional ramp-slope reading
- AI guidance and structured review packet creation
- LGU triage, inspection request, and case close actions
- inspector verification outcomes
- append-only place memory

## Current Tech Stack

- Frontend: Flutter with Material 3
- Language: Dart 3.11
- UI styling: custom Flutter UI plus `google_fonts`
- HTTP: `http`
- Device motion capture: `sensors_plus`
- Photo selection: `image_picker`
- Backend scaffolding: Supabase SQL migrations, seed data, Edge Function
- AI wrapper: Supabase Edge Function calling Gemini

## Runtime Architecture

### Entry and dependency wiring

[`lib/main.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/main.dart:1) builds `MyApp`, which delegates to [`AccessPulseApp`](/abs/path/C:/Users/reyna/accesspulse/lib/app/accesspulse_app.dart:1).

`AccessPulseApp` currently wires:

- `InMemoryAccessPulseRepository.seeded()`
- `DimensionStateService`
- AI service selection:
  - `GeminiServerEvidenceService` when `ACCESSPULSE_AI_FUNCTION_URL` is provided
  - `MockAiEvidenceService` otherwise

There is also now an `imagePickerOverride` seam passed from app entry through the public flow. This keeps production behavior unchanged while making photo-dependent flows testable without relying on platform picker registration.

### Role shell

The main shell is a 3-tab bottom navigation experience:

- Public
- LGU
- Inspector

It uses an `AnimatedSwitcher` for role transitions and now supports optionally skipping onboarding in tests.

## Data and Persistence Model

### Runtime persistence today

The app still runs entirely on top of [`InMemoryAccessPulseRepository`](/abs/path/C:/Users/reyna/accesspulse/lib/data/in_memory_accesspulse_repository.dart:1).

That means:

- all data resets on app restart
- the app is demo-persistent only during a single session
- Supabase is not yet the live runtime store

### Supabase scaffolding

The Supabase side already mirrors the domain model:

- [`supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`](/abs/path/C:/Users/reyna/accesspulse/supabase/migrations/20260629133000_accesspulse_mvp_schema.sql:1)
- [`supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`](/abs/path/C:/Users/reyna/accesspulse/supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql:1)
- [`supabase/seed.sql`](/abs/path/C:/Users/reyna/accesspulse/supabase/seed.sql:1)

The schema includes:

- organizations
- users
- places
- accessibility dimensions
- place dimensions
- dimension states
- dimension pulses
- observations
- evidence
- barrier signals
- cases
- verifications
- memory events
- ramp measurements

`memory_events` are intentionally append-only.

## Core Domain Model

The important domain types live in [`accesspulse_models.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/models/accesspulse_models.dart:1).

The key business objects are:

- `Place`
- `AccessibilityDimension`
- `PlaceDimension`
- `DimensionStateRecord`
- `DimensionPulseRecord`
- `Observation`
- `Evidence`
- `RampMeasurement`
- `BarrierSignal`
- `AccessCase`
- `Verification`
- `MemoryEvent`
- `AiEvidenceAssessment`

Important workflow enums:

- `DimensionStateValue`
  - `unknown`
  - `claimedAccessible`
  - `reliable`
  - `degraded`
  - `officiallyVerifiedDegraded`
  - `underReview`
  - `resolved`
- `CaseStatus`
  - `open`
  - `triaging`
  - `inspectionRequested`
  - `verified`
  - `disputed`
  - `resolved`
  - `closed`
- `VerificationOutcome`
  - `confirmed`
  - `disputed`
  - `insufficientEvidence`
- `ConfidenceLevel`
  - `low`
  - `moderate`
  - `high`
- `EvidenceReadiness`
  - `draft`
  - `almostReady`
  - `institutionReady`

## Seeded Demo State

The app starts with three places:

1. `Quezon City Hall Main Entrance`
   Story: stale claimed-accessible state, moderate pulse
2. `Public Hospital Main Entrance`
   Story: reliable state, strong pulse
3. `Transport Terminal Entrance`
   Story: unknown state, weak pulse

There are three demo users:

- community contributor
- LGU reviewer
- inspector

This gives the UI a complete demo narrative from first load.

## Current UI Implementation

## App-wide UI direction

The current UI is custom, not stock Flutter starter UI.

Notable UI characteristics:

- custom typography with `GoogleFonts.afacad`
- lighter card-heavy operational styling
- public, LGU, and inspector screens each use dedicated layouts
- onboarding experience before the main shell
- animated transitions across roles, result screens, and some evidence states
- ramp-capture uses a dedicated full-step experience rather than an inline spinner

### Onboarding

[`lib/features/onboarding/onboarding_screen.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/onboarding/onboarding_screen.dart:1) implements a 3-page intro:

- living accessibility states
- public visit updates
- AI plus institution action

It uses page-based onboarding with skip and next controls.

### Public UI

[`lib/features/public/public_flow.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/public/public_flow.dart:1) contains the bulk of the public experience.

Current public UI includes:

- place search
- nearby and other place grouping
- place detail
- large state card
- freshness/pulse explanation
- confidence explanation
- visit confirmation action
- evidence submission action
- place memory timeline

### LGU / Inspector UI

[`lib/features/institution/institution_flow.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/institution/institution_flow.dart:1) contains:

- LGU dashboard
- inspector queue
- case detail
- structured evidence review
- priority explanation panel
- memory panel
- verification form and result surface

## Working Feature Flows

## 1. Public place browsing

Working today:

- users can browse seeded places
- place cards show current state and pulse
- place detail surfaces the current `Mobility Access` status
- place memory is shown as a recent timeline

## 2. Confirm visit flow

Working today:

- the public user can open a confirm-visit form
- the form records structured visit answers
- submitting creates an `Observation`
- the living state updates based on the visit result
- pulse is recalculated
- memory events are appended
- the result screen shows before/after state and pulse

Current logic:

- positive visit can move `claimedAccessible` to `reliable`
- negative visit can degrade `claimedAccessible`, `reliable`, or `unknown`
- mixed/unclear signals generally preserve current state

## 3. Public evidence flow

This is the most complex public flow in the current app.

Working today:

- user can add a photo
- user can add a review note
- user can optionally measure ramp slope
- AI can analyze the evidence
- AI guidance can show confidence, evidence readiness, and next step
- structured review can be shown before submission
- the review packet can be submitted into institutional review

### Current step model

The evidence flow is now step-based:

- add evidence
- ramp capture
- AI guidance
- structure review
- review packet

Important current fix:

The step renderer was changed so only the active step is built. This prevents the hidden ramp-capture step from auto-starting in the background when the user first opens the evidence flow.

### Photo behavior

The flow now intentionally depends on a real photo.

That means:

- AI analysis does not proceed without at least one photo
- this is now a product decision, not an accidental regression
- testability required an image-picker override seam

### Ramp slope capture

Working today:

- user can opt into ramp capture
- demo-safe mode is available
- demo-safe mode uses a clearly labeled sample reading
- the capture step shows countdown, measurement result, and reuse/retake options

Ramp capture data includes:

- estimated angle
- quality score
- quality label
- sample count
- capture duration
- source label

### AI guidance and review packet

Working today:

- AI returns `AiEvidenceAssessment`
- guidance shows:
  - observed features
  - missing evidence
  - confidence
  - evidence readiness
  - confidence explanation
  - recommended next action
- the user can:
  - add another photo
  - continue anyway
  - skip
- structured review shows the AI interpretation
- review packet shows confidence, readiness, and whether ramp reading is included

## 4. LGU case workflow

Working today:

- evidence submission creates a `BarrierSignal`
- a case is opened
- LGU dashboard lists actionable cases
- case detail shows:
  - current state
  - confidence explanation
  - pulse/freshness
  - why the case matters
  - why now
  - suggested next action
  - evidence bundle
  - ramp measurement
  - place memory

LGU actions working today:

- mark triaging
- request inspection
- close case

## 5. Inspector verification workflow

Working today:

- inspector queue shows relevant cases
- inspector can open verification
- inspector can submit:
  - confirmed
  - disputed
  - insufficient evidence

Current authoritative rule:

- only inspector verification can make a degraded state official

Current verification effects:

- `confirmed` -> `officiallyVerifiedDegraded`
- `disputed` -> case disputed, contradiction preserved
- `insufficientEvidence` -> back to triaging-like follow-up state

## Pulse and State Logic

[`pulse_service.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/services/pulse_service.dart:1) calculates freshness/pulse and maps records into human-facing labels.

Public-facing pulse labels currently include:

- Reliable
- Reliable, aging
- Unknown
- Under review
- Recently refreshed

Pulse score currently considers:

- recency of observations
- number of supporting observations
- recent human verification
- contradiction penalty

## AI Integration

### Client side

[`ai_evidence_service.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/services/ai_evidence_service.dart:1) includes:

- `MockAiEvidenceService`
- `GeminiServerEvidenceService`

The mock service is still important because:

- it powers demo behavior without backend setup
- it acts as fallback if the server wrapper fails

### Server side

[`supabase/functions/analyze-evidence/index.ts`](/abs/path/C:/Users/reyna/accesspulse/supabase/functions/analyze-evidence/index.ts:1) is a Gemini wrapper that:

- receives evidence context
- sends a constrained prompt to Gemini
- requests strict JSON output
- returns normalized structured evidence assessment

Important AI safety constraints already implemented:

- AI must not declare legal non-compliance
- AI must not say "violation confirmed"
- AI must not mark a place officially verified
- AI must not overrule a human inspector
- ramp reading is only supporting field evidence

The client also sanitizes risky wording if the model still returns it.

## Current Test Coverage

## Domain tests

Passing:

- [`test/domain/ai_evidence_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/ai_evidence_service_test.dart:1)
- [`test/domain/dimension_state_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/dimension_state_service_test.dart:1)
- [`test/domain/pulse_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/pulse_service_test.dart:1)
- [`test/domain/ramp_slope_capture_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/ramp_slope_capture_service_test.dart:1)

These confirm:

- state transitions
- pulse label behavior
- AI fallback and sanitization
- ramp capture evaluation logic
- authoritative inspector verification

## Institutional widget test

Passing:

- [`test/institution_flow_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/institution_flow_test.dart:1)

This confirms:

- LGU request-inspection flow
- inspector verification flow
- case progression
- official state update

## Public widget tests

Current state:

- simple public browsing test passes when run individually
- confirm-visit widget test passes when run individually
- the two evidence-heavy widget tests are still unstable and need further stabilization

The evidence widget tests were already updated toward the current architecture:

- real-photo requirement accounted for
- step-based flow accounted for
- ramp capture flow accounted for

But they are still not fully reliable end-to-end in the current form.

## Current Verification Status

### Passed recently

- `flutter build web`
- `flutter test test\institution_flow_test.dart`
- `flutter test test\domain`
- public simple widget tests when run individually

### Current analyzer status

`flutter analyze` still reports warnings/info items but no new hard errors from the latest flow fix.

Current notable analyzer items:

- unused optional parameters
- deprecated `withOpacity`
- deprecated `activeColor`
- unnecessary import of `dart:ui`
- some unused locals/helpers

These are cleanup issues, not currently confirmed runtime bugs.

## Current Issues

## 1. Evidence-heavy widget tests are still unstable

This is the main current issue.

Status:

- the original hidden ramp-capture bug has been fixed
- the evidence tests are now the weakest part of verification
- this looks like a test-surface stability problem, not a confirmed production blocker

## 2. Runtime repository is still in-memory

This is a known product limitation.

Impact:

- no persistence after restart
- no real multi-user sync
- Supabase schema exists but is not yet the live source of truth

## 3. Photo handling is real-flow dependent, but still demo-scoped

What is working:

- real photo is required in the flow
- image picker is wired into UI

What is not yet complete:

- no production storage/upload pipeline
- no durable evidence hosting path in the running app
- photo references are still mostly local session artifacts

## 4. Analyzer cleanup remains

These are not high severity but they are real debt:

- deprecations
- minor unused code
- minor style cleanup

## 5. Some UI content is partially demo-crafted

There are still demo-oriented elements in the public detail flow and memory shaping, including seeded or mocked-feeling narrative content designed to support presentation.

That is fine for the MVP, but it is not yet a production-grade truthful data surface.

## What Is Working Well

- clear separation between public evidence, AI structure, LGU review, and inspector authority
- strong domain model
- solid institutional flow
- Supabase schema already mirrors the app model well
- Gemini wrapper includes good safety boundaries
- current UI is meaningfully custom, not starter-template UI
- ramp-slope flow is much more polished than a minimal MVP

## Current Biggest Gaps

- live Supabase repository implementation
- stable evidence-flow widget coverage
- full production-grade photo pipeline
- real authentication and role/session handling
- multi-dimension support beyond mobility access
- remediation/resolution lifecycle completion in UI

## Recommended Next Priorities

If continuing from the current state, the best next priorities are:

1. stabilize the evidence-flow widget tests fully
2. clean analyzer warnings in the public flow
3. implement a real Supabase-backed repository under the existing repository contract
4. move photo evidence from local session flow to real storage-backed evidence records
5. extend the institutional lifecycle into remediation and resolved-state follow-through

## Bottom Line

AccessPulse currently presents a credible end-to-end MVP for living accessibility intelligence.

The app already demonstrates:

- living place states
- public signal updates
- evidence strengthening
- AI-structured institutional review
- official human verification
- memory over time

The codebase is strongest in its architecture, domain modeling, and institutional verification logic. The current weakest area is still the public evidence-flow test surface, not the overall product concept.
