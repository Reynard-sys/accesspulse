# AccessPulse Implementation Summary

This document summarizes the current AccessPulse implementation in this
repository. It covers the original MVP and the later ramp slope extension.

## Product Summary

AccessPulse is a Flutter MVP for living accessibility intelligence. The demo
focuses on Mobility Access for public service buildings, especially entrance and
ramp usability for independent wheelchair access.

The product is built around three ideas:

- **State**: the current best belief about a place and accessibility dimension.
- **Pulse**: how fresh, trustworthy, and alive that belief is.
- **Memory**: append-only event history explaining how the state changed.

AccessPulse is not implemented as a static directory or complaint app. Users,
AI, LGU reviewers, and inspectors all contribute to a living accessibility
record, while official verification remains a human inspector action.

## Current Scope

Implemented scope:

- Flutter app with Material 3 UI.
- Public service building demo places.
- One accessibility dimension: `mobility_access`.
- Community/public user flow.
- LGU reviewer flow.
- Inspector/verifier flow.
- In-memory repository for runnable demo behavior.
- Supabase schema and seed SQL for backend setup.
- Gemini-backed Supabase Edge Function wrapper with mock fallback.
- Ramp slope measurement extension with demo-safe fallback.
- Tests for domain logic, public UI, institution workflow, AI integration, and
  ramp slope behavior.

Explicitly not implemented as production scope:

- Full authentication or RBAC.
- Production government integrations.
- Full map experience.
- Multi-dimension UI beyond dimension-aware models.
- Legal compliance adjudication by AI.
- Direct client-side Gemini calls.

## Demo Places

The seeded demo places are:

- `Quezon City Hall Main Entrance`
- `Public Hospital Main Entrance`
- `Transport Terminal Entrance`

The main story path usually starts from `Quezon City Hall Main Entrance`, which
begins as a stale `Claimed accessible` place with `Moderate` pulse.

## High-Level Demo Flow

1. Public user opens a seeded place.
2. Public user confirms a failed mobility-access visit.
3. The place state and pulse visibly change.
4. Public user adds structured evidence.
5. Optional ramp slope measurement can be captured and attached.
6. AI structures the evidence while preserving uncertainty.
7. The app opens an LGU review case.
8. LGU reviewer reviews the case and requests inspection.
9. Inspector submits a verification outcome.
10. Place state, pulse, and memory update to reflect the official outcome.

## Architecture

The app uses a layered Flutter structure:

```text
lib/
  main.dart
  app/
  config/
  data/
  domain/
    models/
    repositories/
    services/
  features/
    public/
    institution/
```

The code is intentionally demo-friendly: the UI runs against seeded in-memory
data, while SQL artifacts and Edge Functions exist for Supabase-backed setup.

## Key Files

### App Shell And Configuration

- `lib/main.dart`
  - Flutter entry point.
- `lib/app/accesspulse_app.dart`
  - App shell, theme, seeded repository setup, and role navigation.
- `lib/config/ai_config.dart`
  - Reads `ACCESSPULSE_AI_FUNCTION_URL` and
    `ACCESSPULSE_SUPABASE_ANON_KEY` from `--dart-define`.
  - Uses mock AI if no server wrapper URL is configured.

### Domain Layer

- `lib/domain/accesspulse_domain.dart`
  - Barrel export for domain models, repositories, and services.
- `lib/domain/models/accesspulse_models.dart`
  - Core domain entities and enums.
- `lib/domain/repositories/accesspulse_repository.dart`
  - Repository contract used by services and UI.
- `lib/domain/services/pulse_service.dart`
  - Pulse/freshness scoring.
- `lib/domain/services/dimension_state_service.dart`
  - State transitions, evidence submission, case actions, verification, and
    memory logging.
- `lib/domain/services/ai_evidence_service.dart`
  - Mock AI and Gemini server-wrapper client.
- `lib/domain/services/ramp_slope_capture_service.dart`
  - Ramp slope sampling, quality scoring, and demo fallback measurement.

### Data Layer

- `lib/data/accesspulse_seed_data.dart`
  - Seeded places, dimensions, states, pulses, observations, and memory events.
- `lib/data/in_memory_accesspulse_repository.dart`
  - In-memory implementation of `AccessPulseRepository`.
  - Stores places, states, pulses, observations, evidence, barrier signals,
    cases, verifications, memory events, and ramp measurements.

### Public UI

- `lib/features/public/public_flow.dart`
  - Public place list.
  - Place detail state/pulse/memory view.
  - Confirm visit flow.
  - Add evidence flow.
  - Ramp slope capture panel.
  - AI evidence structure panel.
  - Review packet panel.
  - Submission result screen.

### Institution UI

- `lib/features/institution/institution_flow.dart`
  - LGU dashboard.
  - Inspector dashboard.
  - Case summaries.
  - Case detail screen.
  - Evidence bundle.
  - Ramp measurement visibility.
  - Reviewer triage/request/close actions.
  - Inspector verification submission.

### Supabase

- `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`
  - Base MVP schema.
- `supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`
  - Ramp measurement schema extension.
- `supabase/seed.sql`
  - Seed data for demo places, users, organizations, dimension state, pulse,
    observations, and memory.
- `supabase/functions/analyze-evidence/index.ts`
  - Gemini-backed Edge Function wrapper for structured evidence analysis.
- `supabase/functions/analyze-evidence/.env.example`
  - Local Edge Function secret placeholders.

### Setup Docs

- `README.md`
  - Local app setup and demo flow.
- `SETUP_DB.md`
  - Manual Supabase SQL Editor setup for base schema and seed.
- `SETUP_AI.md`
  - Gemini/Supabase Edge Function setup.
- `.env.example`
  - Flutter client-side placeholders for `--dart-define` values.

### Ramp-Specific Docs

- `RAMP_SLOPE_IMPLEMENTATION_NOTES.md`
  - Planning and insertion notes for ramp slope milestones.
- `RAMP_SLOPE_IMPLEMENTATION_SUMMARY.md`
  - Ramp slope feature summary.

## Domain Model Summary

Core entities:

- `Place`
- `AccessibilityDimension`
- `PlaceDimension`
- `DimensionStateRecord`
- `DimensionPulseRecord`
- `MemoryEvent`
- `Observation`
- `Evidence`
- `AiEvidenceAssessment`
- `BarrierSignal`
- `AccessCase`
- `Verification`
- `RampMeasurement`

Important enums:

- `DimensionStateValue`
  - `unknown`
  - `claimedAccessible`
  - `reliable`
  - `degraded`
  - `officiallyVerifiedDegraded`
  - `underReview`
  - `resolved`
- `DimensionPulseLevel`
  - `weak`
  - `moderate`
  - `strong`
- `CaseStatus`
  - `open`
  - `triaging`
  - `inspectionRequested`
  - `verified`
  - `disputed`
  - `resolved`
  - `closed`
- `VerificationOutcome`
  - `confirmedBarrier`
  - `disputed`
  - `insufficientEvidence`
  - `remediationVerified`
- `RampMeasurementStatus`
  - `captured`
  - `lowQuality`
  - `failed`
  - `fallback`
  - `discarded`

## State And Pulse Behavior

`DimensionStateService` owns the MVP transition rules.

Implemented public/user behavior:

- Positive visit confirmations can strengthen stale or claimed state.
- Negative visit confirmations can degrade a claimed/reliable state.
- Evidence submission creates structured evidence and barrier signal records.
- Evidence submission opens an actionable access case for institutional review.
- Every state-changing action logs memory.

Implemented institution behavior:

- LGU reviewer can triage cases.
- LGU reviewer can request inspection.
- LGU reviewer can close a case.
- Inspector can submit verification.
- Inspector-confirmed barriers can move state to
  `officiallyVerifiedDegraded`.
- Remediation verification can move state toward `resolved`.

Pulse remains separate from state and is recalculated from the latest context,
including freshness, evidence, verification, contradictions, and case activity.

## Public Flow Implementation

The Public tab includes:

- Searchable seeded place list.
- Mobility Access and Public Service Building chips.
- Place detail card with:
  - current state
  - pulse
  - confidence
  - last confirmed date
  - explanation
  - recent memory
- Confirm visit flow:
  - entrance usable independently
  - ramp usable
  - needed assistance
  - completed purpose
  - optional note
- Add evidence flow:
  - optional demo photo
  - evidence note
  - optional ramp slope measurement
  - AI evidence analysis
  - review packet
  - submission result

The public copy is framed around updating living place knowledge, not filing a
complaint.

## Institution Flow Implementation

The role switcher exposes:

- `Public`
- `LGU`
- `Inspector`

The LGU and Inspector dashboards show actionable cases from the same in-memory
repository.

Case detail includes:

- place and case context
- current state and pulse
- AI barrier signal
- evidence note/photo reference
- ramp measurement block when available
- memory history
- role-appropriate actions

Inspector verification updates the case, state, pulse, and memory chain.

## AI Implementation

AI is accessed through `AiEvidenceService`.

Implemented modes:

- `MockAiEvidenceService`
  - Used when no server wrapper URL is configured.
  - Used as fallback when the Edge Function fails.
  - Returns structured evidence with uncertainty language.
- `GeminiServerEvidenceService`
  - Sends evidence to a Supabase Edge Function.
  - Passes Supabase anon key headers when configured.
  - Parses structured JSON response.
  - Falls back to mock on failed/invalid responses.

The Flutter app never calls Gemini directly.

The Edge Function:

- accepts evidence context
- accepts optional ramp measurement context
- calls Gemini server-side
- requests JSON output
- normalizes output into the app's evidence assessment shape

AI output includes:

- dimension
- issue type
- observed features
- possible barrier
- missing evidence
- confidence
- summary
- recommended action
- explanation

AI safety rules:

- AI does not determine legal compliance.
- AI does not officially verify places.
- AI does not overrule human verifiers.
- AI keeps uncertainty visible.
- AI treats ramp measurements as supporting evidence only.

## Ramp Slope Extension

Ramp slope capture is implemented inside the public evidence flow.

Implemented behavior:

- Ramp capture is optional.
- Capture is shown only for ramp-related evidence notes.
- Live sensor capture uses accelerometer and gyroscope events through
  `sensors_plus`.
- Captured samples are converted into an estimated tilt angle.
- Quality is scored from sample stability and motion.
- Low-quality captures remain visible but weak.
- Failed captures prompt retry.
- Demo-safe mode defaults on for reliable hackathon/demo runs.
- Demo-safe mode uses a clearly labeled `14.8 deg` fallback reading.

Ramp measurement is persisted with evidence and visible in institution case
review.

Ramp measurement is sent into AI analysis, where it is referenced as supporting
field evidence only.

## Supabase Database Implementation

The base migration creates:

- users
- organizations
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
- enum types and indexes
- append-only protection for memory events

The ramp migration creates:

- `public.ramp_measurement_status`
- `public.ramp_measurements`
- indexes for evidence and place-dimension lookup

Manual setup should run:

1. `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`
2. `supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`
3. `supabase/seed.sql`

Note: `SETUP_DB.md` currently describes the base MVP schema and seed flow. For
the full current repo, include the ramp measurement migration between the base
schema and seed steps.

## Environment And Secrets

Flutter client values:

```text
ACCESSPULSE_AI_FUNCTION_URL
ACCESSPULSE_SUPABASE_ANON_KEY
```

These are configured through `--dart-define` and represented as placeholders in
`.env.example`.

Server-side Gemini secrets:

```text
GEMINI_API_KEY
GEMINI_MODEL
```

These belong in Supabase Edge Function secrets only. The Gemini API key should
not be committed to Flutter files, `.env.example`, or any public/client code.

## Tests Implemented

Test files:

- `test/domain/dimension_state_service_test.dart`
  - seeded repository behavior
  - positive/negative visit state transitions
  - AI evidence case creation
  - ramp measurement persistence
  - inspector verification authority
- `test/domain/ai_evidence_service_test.dart`
  - Gemini wrapper request payload
  - mock AI summary behavior
  - ramp measurement AI context
  - forbidden compliance-claim filtering
  - fallback behavior
- `test/domain/ramp_slope_capture_service_test.dart`
  - stable sample angle estimation
  - unstable sample failure
  - fallback measurement labeling
- `test/widget_test.dart`
  - public place list
  - confirm visit state update
  - evidence flow
  - ramp demo-safe capture
  - AI panel
  - review packet
  - submit result
- `test/institution_flow_test.dart`
  - LGU reviewer case actions
  - inspector verification flow
  - ramp measurement visibility in case detail

## Verification Status

The project has been verified with:

```powershell
flutter analyze
flutter test
flutter build web
```

Browser verification was also run against the built web app after the ramp
polish milestone. The checked path covered:

- public place selection
- add evidence
- demo-safe ramp capture
- AI evidence summary
- review packet
- submit review packet
- final state update screen

No page errors, console errors, or framework error overlays were observed in the
verified browser path.

## Commit History By Milestone

MVP:

```text
0aca883 feat(mvp): complete milestone 1 project setup
b03a186 feat(mvp): complete milestone 2 database
e664dd9 feat(mvp): complete milestone 3 domain layer
8470f0c feat(mvp): complete milestone 4 public flow
0f7c1a1 feat(mvp): complete milestone 5 institution flow
74978d1 feat(mvp): complete milestone 6 ai integration
a5a8a4f feat(mvp): complete milestone 7 polish and demo
```

Ramp slope extension:

```text
154a721 feat(ramp): complete milestone 1 planning
b9057e8 feat(ramp): complete milestone 2 ux shell
6299bd7 feat(ramp): complete milestone 3 sensor capture
b7799d0 feat(ramp): complete milestone 4 persistence
1ca8d35 feat(ramp): complete milestone 5 case visibility
13754b2 feat(ramp): complete milestone 6 gemini integration
70d0752 feat(ramp): complete milestone 7 polish
```

## Current Run Instructions

Install dependencies:

```powershell
flutter pub get
```

Run with mock AI fallback:

```powershell
flutter run -d chrome
```

Run with server AI enabled:

```powershell
flutter run -d chrome `
  --dart-define=ACCESSPULSE_AI_FUNCTION_URL=$env:ACCESSPULSE_AI_FUNCTION_URL `
  --dart-define=ACCESSPULSE_SUPABASE_ANON_KEY=$env:ACCESSPULSE_SUPABASE_ANON_KEY
```

Build web:

```powershell
flutter build web
```

## Current Known Boundaries

- The runnable app uses the in-memory repository.
- Supabase schema and seed files exist, but a Supabase-backed repository is not
  implemented yet.
- Role switching is a demo role switcher, not production auth.
- Demo-safe ramp capture is enabled by default to protect demos on web and
  sensorless environments.
- AI is advisory and evidence-structuring only.
- Inspector verification remains the official authority path.
- The app currently focuses on `mobility_access`; the model can support more
  dimensions later, but the UI is intentionally scoped to the MVP.
