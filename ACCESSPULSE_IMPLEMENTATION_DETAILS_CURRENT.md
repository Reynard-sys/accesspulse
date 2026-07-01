# AccessPulse Current Implementation Details

## Project Snapshot

AccessPulse is a Flutter MVP for "living accessibility intelligence" focused on one dimension today: `mobility_access` for public service building entrances. The app demonstrates how community signals, AI-structured evidence, LGU review, and inspector verification update a shared place state over time.

The current implementation is a working demo with:

- a seeded in-memory repository as the live app data source
- a Supabase schema and seed script that mirror the domain model
- a Supabase Edge Function wrapper for Gemini-backed evidence analysis
- public, LGU, and inspector flows in one Flutter app
- domain tests and widget tests covering the main demo story

## Tech Stack

- Frontend: Flutter, Material 3
- Language: Dart 3.11
- HTTP client: `http`
- Sensor capture: `sensors_plus`
- Backend scaffolding: Supabase SQL migrations, seed data, Edge Function
- AI wrapper: Supabase Edge Function calling Gemini

## Runtime Architecture

### App bootstrap

[`lib/main.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/main.dart:1) mounts [`AccessPulseApp`](/abs/path/C:/Users/reyna/accesspulse/lib/app/accesspulse_app.dart:1).

[`lib/app/accesspulse_app.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/app/accesspulse_app.dart:1) does three important things:

1. Creates `InMemoryAccessPulseRepository.seeded()` as the active data store.
2. Creates `DimensionStateService` as the mutation/orchestration layer.
3. Chooses the AI implementation:
   - `GeminiServerEvidenceService` when `ACCESSPULSE_AI_FUNCTION_URL` is present
   - `MockAiEvidenceService` otherwise

The home shell is a 3-tab role switcher:

- `Public`
- `LGU`
- `Inspector`

This is a single-process demo. The Flutter app is not yet reading or writing directly to Supabase tables.

## Codebase Structure

### App and config

- [`lib/main.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/main.dart:1): app entry
- [`lib/app/accesspulse_app.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/app/accesspulse_app.dart:1): dependency wiring and role shell
- [`lib/config/ai_config.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/config/ai_config.dart:1): reads AI function URL and anon key from `dart-define`

### Domain layer

- [`lib/domain/models/accesspulse_models.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/models/accesspulse_models.dart:1): enums and immutable models
- [`lib/domain/repositories/accesspulse_repository.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/repositories/accesspulse_repository.dart:1): repository contract
- [`lib/domain/services/dimension_state_service.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/services/dimension_state_service.dart:1): main business workflow service
- [`lib/domain/services/pulse_service.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/services/pulse_service.dart:1): pulse/freshness calculation and display mapping
- [`lib/domain/services/ai_evidence_service.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/services/ai_evidence_service.dart:1): mock and server AI adapters
- [`lib/domain/services/ramp_slope_capture_service.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/domain/services/ramp_slope_capture_service.dart:1): phone-sensor incline estimation

### Data layer

- [`lib/data/accesspulse_seed_data.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/data/accesspulse_seed_data.dart:1): demo organizations, users, places, states, pulses, observations, memory
- [`lib/data/in_memory_accesspulse_repository.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/data/in_memory_accesspulse_repository.dart:1): seeded in-memory implementation of the repository

### Feature layer

- [`lib/features/public/public_flow.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/public/public_flow.dart:1): community/public experience
- [`lib/features/institution/institution_flow.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/institution/institution_flow.dart:1): LGU reviewer and inspector experience

### Backend assets

- [`supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`](/abs/path/C:/Users/reyna/accesspulse/supabase/migrations/20260629133000_accesspulse_mvp_schema.sql:1): core MVP schema
- [`supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`](/abs/path/C:/Users/reyna/accesspulse/supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql:1): ramp measurement extension
- [`supabase/seed.sql`](/abs/path/C:/Users/reyna/accesspulse/supabase/seed.sql:1): mirrored seed data
- [`supabase/functions/analyze-evidence/index.ts`](/abs/path/C:/Users/reyna/accesspulse/supabase/functions/analyze-evidence/index.ts:1): Gemini wrapper

## Domain Model

The project models accessibility as a living record around a `PlaceDimension`.

Core entities:

- `Place`: a real-world location
- `AccessibilityDimension`: currently only `mobility_access`
- `PlaceDimension`: the place/dimension pair being evaluated
- `DimensionStateRecord`: current living state
- `DimensionPulseRecord`: freshness/strength of knowledge
- `Observation`: direct community visit signal
- `Evidence`: uploaded or structured supporting material
- `RampMeasurement`: citizen sensor-based incline capture
- `BarrierSignal`: AI-structured interpretation of evidence
- `AccessCase`: institutional review object
- `Verification`: human inspector outcome
- `MemoryEvent`: append-only timeline of what happened

Important enums encode the workflow:

- `DimensionStateValue`: `unknown`, `claimedAccessible`, `reliable`, `degraded`, `officiallyVerifiedDegraded`, `underReview`, `resolved`
- `CaseStatus`: `open`, `triaging`, `inspectionRequested`, `verified`, `disputed`, `resolved`, `closed`
- `VerificationOutcome`: `confirmed`, `disputed`, `insufficientEvidence`
- `ConfidenceLevel`: `low`, `moderate`, `high`
- `EvidenceReadiness`: `draft`, `almostReady`, `institutionReady`

## Seeded Demo Data

The app starts with three places in Quezon City:

1. `Quezon City Hall Main Entrance`
   Current story: stale public accessibility claim, moderate pulse
2. `Public Hospital Main Entrance`
   Current story: recently reliable, strong pulse
3. `Transport Terminal Entrance`
   Current story: unknown, weak pulse

There is one organization and three demo users:

- community contributor
- LGU reviewer
- inspector

This setup gives the app three visible starting conditions:

- stale but plausible
- currently reliable
- not enough knowledge

## Public Flow

The public experience lives in [`lib/features/public/public_flow.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/public/public_flow.dart:1).

### Public list and place detail

The home screen lists seeded places, supports search, and shows each place's current state. Selecting a place opens a detail screen with:

- current `Mobility Access` state
- pulse/freshness explanation
- confidence label and confidence explanation
- actions for visit confirmation and evidence submission
- recent place memory

### Confirm visit flow

`ConfirmVisitScreen` collects a simple structured observation:

- entrance usable independently
- ramp usable
- needed assistance
- completed purpose
- optional note

Submitting the form calls `DimensionStateService.confirmVisit()`, which:

- creates an `Observation`
- derives an `ObservationOutcome`
- updates the state
- recalculates pulse
- appends memory events

Current state transition rules after a visit:

- positive visit can move `claimedAccessible` -> `reliable`
- negative visit can move `claimedAccessible`, `reliable`, or `unknown` -> `degraded`
- mixed signals usually preserve the existing state

### Evidence flow

`EvidenceFlowScreen` supports:

- note entry
- optional demo photo inclusion
- optional ramp slope capture
- AI analysis
- AI guidance and review packet preview
- final submission into institutional review

The UI now surfaces:

- confidence level
- confidence explanation
- evidence readiness
- recommended next step
- review packet contents before submission

### Ramp slope capture

Ramp capture is handled by `RampSlopeCaptureService`.

It listens to:

- accelerometer data
- gyroscope data

It estimates a ramp angle from device tilt and grades capture quality using:

- angle stability
- gyroscope movement
- minimum sample count

Possible statuses:

- `captured`
- `lowQuality`
- `failed`
- `fallback`
- `discarded`

For demo safety, the public flow currently offers a fallback capture path that returns a labeled sample reading:

- estimated angle: `14.8 deg`
- quality: `Moderate stability`
- source: `Demo fallback`

### AI evidence analysis

The app supports two AI modes:

1. `MockAiEvidenceService`
   Used when no Edge Function URL is configured, or as a fallback.
2. `GeminiServerEvidenceService`
   Calls the Supabase Edge Function and normalizes the JSON response.

The AI assessment produces:

- issue type
- observed features
- possible barrier
- missing evidence
- confidence and confidence level
- confidence explanation
- evidence readiness
- summary
- recommended action
- next best action
- explanation
- `institutionReady`

The current design explicitly avoids official judgments by AI. Both prompt rules and client-side sanitization prevent claims like "violation confirmed" or legal non-compliance declarations.

### Evidence submission behavior

`DimensionStateService.submitStructuredEvidence()` currently:

- creates `Evidence`
- optionally creates `RampMeasurement`
- creates `BarrierSignal`
- opens an `AccessCase`
- updates the living state toward `degraded`
- sets state source to `ai_structured_barrier_signal`
- recalculates pulse
- appends memory events for evidence, AI signal, case open, and state change

This is intentionally not official verification. It creates an actionable review case while preserving uncertainty.

## Institutional Flow

The institutional experience lives in [`lib/features/institution/institution_flow.dart`](/abs/path/C:/Users/reyna/accesspulse/lib/features/institution/institution_flow.dart:1).

### LGU dashboard

The LGU reviewer view lists non-closed cases and shows queue context for each case, including:

- place
- case status
- severity
- current state
- pulse
- priority explanation

Case details show:

- current state and pulse
- confidence and explanation
- "Why this matters"
- "Why now"
- suggested next action
- structured AI signal
- evidence bundle
- ramp measurement, when available
- place memory

Available reviewer actions:

- mark triaging
- request inspection
- close case

### Inspector dashboard

The inspector view filters to cases relevant for verification:

- `inspectionRequested`
- `verified`
- `disputed`
- `triaging`

Inspectors can open a verification form and submit one of:

- `confirmed`
- `disputed`
- `insufficientEvidence`

### Verification authority

`DimensionStateService.submitVerification()` is the authority boundary.

Current behavior:

- `confirmed` -> state becomes `officiallyVerifiedDegraded`, case becomes `verified`
- `disputed` -> state remains as-is, case becomes `disputed`
- `insufficientEvidence` -> case returns to `triaging`

Verification also:

- writes a `Verification`
- updates confidence
- sets state source to `human_verification`
- recalculates pulse with verification context
- appends a verification memory event

This is the clearest implementation rule in the project:

AI can structure evidence and open a case, but only a human inspector can make a degraded state official.

## Pulse and Freshness Logic

`PulseService` serves two jobs:

1. Turn state plus pulse data into public-facing labels such as:
   - `Reliable`
   - `Reliable, aging`
   - `Unknown`
   - `Under review`
   - `Recently refreshed`
2. Recalculate pulse scores from evidence recency and supporting records

The pulse score uses:

- observation recency
- observation count
- recent human verification bonus
- contradiction penalty

Thresholds:

- `>= 0.72` -> `strong`
- `>= 0.40` -> `moderate`
- otherwise `weak`

## Repository and Persistence Status

The active app still uses `InMemoryAccessPulseRepository`.

What this means today:

- app state is reset on restart
- the Supabase schema is present but not yet connected as a runtime repository
- the backend exists mainly as:
  - future persistence scaffolding
  - schema documentation
  - AI wrapper hosting surface

The repository contract is already shaped well for a later Supabase-backed implementation.

## Supabase Schema

The SQL schema mirrors the Dart domain closely.

Main tables:

- `organizations`
- `users`
- `places`
- `accessibility_dimensions`
- `place_dimensions`
- `dimension_states`
- `dimension_pulses`
- `observations`
- `evidence`
- `barrier_signals`
- `cases`
- `verifications`
- `memory_events`
- `ramp_measurements`

Notable schema decisions:

- `memory_events` are append-only via update/delete-blocking triggers
- enum types model workflow state explicitly
- `place_dimensions` enforce one row per place/dimension pair
- `ramp_measurements` attach one measurement to one evidence item

## Gemini Edge Function

[`supabase/functions/analyze-evidence/index.ts`](/abs/path/C:/Users/reyna/accesspulse/supabase/functions/analyze-evidence/index.ts:1) is a server wrapper for Gemini.

Current behavior:

- accepts POST requests with note, optional image metadata, and optional ramp measurement
- requires `GEMINI_API_KEY` as a Supabase secret
- calls Gemini through the `v1beta/interactions` endpoint
- requests strict JSON output with a defined schema
- normalizes the returned payload before responding

Prompt constraints are carefully tuned to keep the AI within scope:

- structure evidence for review
- explain uncertainty
- never claim legal non-compliance
- never mark official verification
- never overrule a human verifier
- treat ramp readings as supporting evidence only

On the Flutter side, `GeminiServerEvidenceService` also sanitizes risky phrases if they still appear.

## Environment and Setup

### Flutter runtime defines

Optional client-side runtime values:

- `ACCESSPULSE_AI_FUNCTION_URL`
- `ACCESSPULSE_SUPABASE_ANON_KEY`

If the function URL is absent, the app uses mock AI automatically.

### Backend secrets

Supabase Edge Function secrets:

- `GEMINI_API_KEY`
- optional `GEMINI_MODEL`

Setup docs:

- [`README.md`](/abs/path/C:/Users/reyna/accesspulse/README.md:1)
- [`SETUP_DB.md`](/abs/path/C:/Users/reyna/accesspulse/SETUP_DB.md:1)
- [`SETUP_AI.md`](/abs/path/C:/Users/reyna/accesspulse/SETUP_AI.md:1)

## Test Coverage

Current tests cover both domain logic and UI flow.

### Widget tests

- [`test/widget_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/widget_test.dart:1)
  Covers:
  - seeded public state rendering
  - confirm visit flow
  - evidence flow with ramp capture
  - AI guidance
  - review packet submission

- [`test/institution_flow_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/institution_flow_test.dart:1)
  Covers:
  - LGU review path
  - request inspection
  - inspector verification
  - official degraded state transition

### Domain tests

- [`test/domain/pulse_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/pulse_service_test.dart:1)
- [`test/domain/dimension_state_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/dimension_state_service_test.dart:1)
- [`test/domain/ai_evidence_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/ai_evidence_service_test.dart:1)
- [`test/domain/ramp_slope_capture_service_test.dart`](/abs/path/C:/Users/reyna/accesspulse/test/domain/ramp_slope_capture_service_test.dart:1)

These tests validate the main implementation promises:

- pulse label behavior
- visit-driven state changes
- AI evidence opens cases but does not verify them
- ramp capture quality logic
- server AI response parsing and fallback behavior
- sanitization of unsafe compliance claims

## Current Strengths

- Clear separation between public knowledge, AI structure, and official verification
- Strong demo storytelling through seeded data and place memory
- Good repository abstraction for future persistence work
- Safety-conscious AI wrapper and client sanitization
- Solid tests around the critical workflow

## Current Gaps and Limitations

- No live Supabase-backed repository yet
- No authentication or real user/session model
- No actual image upload pipeline; image use is still demo-level metadata
- No background sync or offline storage
- Only one accessibility dimension is implemented
- Sensor capture is demo-friendly, but not yet calibrated as a production measurement workflow
- Institutional remediation and `resolved` follow-through are modeled but not fully built out in the UI

## Recommended Next Implementation Direction

If this project continues past MVP polish, the highest-leverage next step is a real Supabase repository implementation behind the existing `AccessPulseRepository` contract. That would preserve the current app architecture while turning the demo into a persistent multi-user system.
