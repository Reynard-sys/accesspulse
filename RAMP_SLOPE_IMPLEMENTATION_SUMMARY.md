# Ramp Slope Implementation Summary

This document summarizes the ramp slope feature implemented from
`accesspulse-ramp-slope-implementation-plan-v2.md`.

## What Was Implemented

AccessPulse now supports an optional ramp slope capture inside the public
evidence flow. The feature lets a community user attach an estimated ramp angle
to a mobility-access evidence report, sends that measurement into the AI
evidence summary, persists it with the evidence, and exposes it to LGU and
inspector review screens.

The implementation preserves the key product rule: ramp slope readings are
supporting evidence only. They do not prove legal non-compliance, do not mark a
place officially verified, and do not replace human review.

## Milestone Summary

### Milestone 1 - Planning

- Reviewed the existing public evidence flow, AI service, repository, and LGU
  case detail flow.
- Created `RAMP_SLOPE_IMPLEMENTATION_NOTES.md` with insertion points and safety
  rules.
- Identified `EvidenceFlowScreen` as the primary public-user integration point.

Commit:

```text
154a721 feat(ramp): complete milestone 1 planning
```

### Milestone 2 - UX Shell

- Added an optional ramp slope capture panel to the public evidence flow.
- The panel appears when the evidence note contains ramp-related terms such as
  `ramp`, `steep`, `incline`, `slope`, `unsafe`, or `wheelchair entrance`.
- Added initial states for entry, capture, success, failure, and retry.
- Kept the feature optional so users can still analyze and submit evidence
  without a ramp measurement.

Commit:

```text
b9057e8 feat(ramp): complete milestone 2 ux shell
```

### Milestone 3 - Sensor Capture

- Added `sensors_plus` to `pubspec.yaml`.
- Added `lib/domain/services/ramp_slope_capture_service.dart`.
- Implemented accelerometer/gyroscope sample capture and tilt estimation.
- Added quality scoring and statuses:
  - `captured`
  - `lowQuality`
  - `failed`
  - `fallback`
  - `discarded`
- Added a demo fallback measurement for web or environments without live motion
  sensors.
- Added unit tests for stable samples, unstable samples, and fallback behavior.

Commit:

```text
6299bd7 feat(ramp): complete milestone 3 sensor capture
```

### Milestone 4 - Persistence

- Added the domain model `RampMeasurement`.
- Added repository methods:
  - `addRampMeasurement`
  - `getRampMeasurementForEvidence`
  - `listRampMeasurements`
- Added in-memory storage for ramp measurements.
- Updated `DimensionStateService.submitStructuredEvidence` to persist a ramp
  measurement when one is submitted with evidence.
- Added ramp measurement metadata to the associated `Evidence`.
- Added Supabase migration:
  - `supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`
- The migration creates:
  - `public.ramp_measurement_status`
  - `public.ramp_measurements`
  - indexes for evidence and place-dimension lookup

Commit:

```text
b7799d0 feat(ramp): complete milestone 4 persistence
```

### Milestone 5 - Case Visibility

- Updated the institution flow to fetch the ramp measurement linked to the
  evidence in a case.
- Added a compact ramp measurement block to the case detail screen.
- LGU reviewers and inspectors can see:
  - estimated angle
  - quality
  - source
  - capture duration
  - sample count
  - captured date
  - uncertainty language
- Added widget coverage for the LGU reviewer and inspector case flow.

Commit:

```text
1ca8d35 feat(ramp): complete milestone 5 case visibility
```

### Milestone 6 - Gemini Integration

- Extended `AiEvidenceService.analyzeMobilityEvidence` to accept an optional
  `RampSlopeMeasurement`.
- Updated the public evidence flow to pass the captured ramp measurement into
  AI analysis.
- Updated `GeminiServerEvidenceService` to send `rampMeasurement` in the request
  payload.
- Updated Supabase Edge Function:
  - `supabase/functions/analyze-evidence/index.ts`
- The Gemini prompt now includes a formatted ramp slope field measurement when
  present.
- Added prompt rules that Gemini must:
  - treat the reading as an estimated supporting signal
  - use only the provided angle
  - not calculate slope itself
  - not say violation confirmed
  - not say the reading proves non-compliance
  - not say the ramp is illegal
  - not say the reading is exact
- Added response text safety normalization in Dart for forbidden overclaiming
  phrases.
- Added tests for Gemini payload structure, mock AI output, and compliance-claim
  filtering.

Commit:

```text
13754b2 feat(ramp): complete milestone 6 gemini integration
```

### Milestone 7 - Polish And Demo Readiness

- Added a visible `Demo-safe capture` toggle to the public evidence flow.
- Demo-safe mode defaults on and uses the seeded `14.8 deg` fallback reading for
  reliable demos.
- Added clearer loading copy for demo-safe capture and live sensor capture.
- Added retry flow polish.
- Added safer analysis and submission error states.
- Reframed submission as a `review packet`.
- Added a `Review packet` panel that shows:
  - before review state
  - after submission outcome
  - included note/photo/ramp reading chips
- Updated the final success copy to explain that the note, optional photo,
  measured incline, and AI summary move into LGU review.
- Updated widget tests for the polished demo path.

Commit:

```text
70d0752 feat(ramp): complete milestone 7 polish
```

## Current Demo Flow

1. Open the Public tab.
2. Select `Quezon City Hall Main Entrance`.
3. Choose `Add evidence`.
4. Keep the default ramp-related note or write a ramp-related note.
5. Confirm `Demo-safe capture` is on.
6. Click `Start slope capture`.
7. The app shows:
   - `Estimated angle: 14.8 deg`
   - `Quality: Moderate stability`
   - `Source: Demo fallback`
8. Click `Analyze evidence`.
9. AI evidence structure includes the estimated ramp angle as supporting
   evidence.
10. The review packet shows that the note and ramp reading are ready for the LGU
    queue.
11. Click `Submit review packet`.
12. The result screen shows the state transition from `Claimed accessible` to
    `Degraded` and the pulse transition from `Moderate` to `Weak`.
13. Switch to LGU or Inspector to review the case and see the ramp measurement
    in the case detail.

## Key Files

### Public UI

- `lib/features/public/public_flow.dart`
  - Ramp slope capture panel
  - Demo-safe capture toggle
  - AI analysis call with ramp measurement
  - Review packet panel
  - Submit review packet flow

### Sensor And Measurement Logic

- `lib/domain/services/ramp_slope_capture_service.dart`
  - `RampSlopeCaptureService`
  - `RampSlopeMeasurement`
  - accelerometer and gyroscope sample handling
  - tilt estimation
  - quality scoring
  - demo fallback measurement

### Domain And Persistence

- `lib/domain/models/accesspulse_models.dart`
  - `RampMeasurementStatus`
  - `RampMeasurement`
- `lib/domain/repositories/accesspulse_repository.dart`
  - repository contract for ramp measurements
- `lib/data/in_memory_accesspulse_repository.dart`
  - in-memory ramp measurement storage
- `lib/domain/services/dimension_state_service.dart`
  - persists ramp measurements with submitted evidence
  - returns ramp measurement in `EvidenceSignalResult`

### Institution Review

- `lib/features/institution/institution_flow.dart`
  - loads ramp measurement for case-linked evidence
  - displays ramp measurement details in case detail screens

### Gemini And AI

- `lib/domain/services/ai_evidence_service.dart`
  - sends ramp measurement to the server wrapper
  - mock AI references measured incline with uncertainty
  - filters forbidden legal-overclaiming phrases
- `supabase/functions/analyze-evidence/index.ts`
  - accepts `rampMeasurement`
  - formats it in the Gemini prompt
  - instructs Gemini to treat it as supporting evidence only

### Supabase

- `supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`
  - creates ramp measurement enum, table, and indexes
- `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`
  - base MVP schema
- `supabase/seed.sql`
  - seeded public service buildings and demo data

### Tests

- `test/domain/ramp_slope_capture_service_test.dart`
  - sensor math and fallback behavior
- `test/domain/dimension_state_service_test.dart`
  - persistence and evidence linkage
- `test/domain/ai_evidence_service_test.dart`
  - AI payload, summary behavior, and forbidden-claim filtering
- `test/institution_flow_test.dart`
  - LGU/inspector case visibility
- `test/widget_test.dart`
  - public demo flow, review packet, and submission result

## Safety Rules Implemented

- The angle is always described as estimated.
- Demo fallback is clearly labeled as `Demo fallback`.
- The reading is supporting evidence only.
- The AI summary cannot claim official verification.
- The AI summary cannot make legal conclusions.
- Forbidden phrases are blocked or rewritten, including:
  - `violation confirmed`
  - `proves non-compliance`
  - `ramp is illegal`
  - `confirms legal non-compliance`
- Official verification remains reserved for the inspector workflow.

## Verification Performed

The following checks passed after milestone 7:

```powershell
flutter analyze
flutter test
flutter build web
```

Browser verification was also run against the built web app. The tested path
covered:

- public place selection
- evidence flow
- demo-safe ramp capture
- AI evidence summary
- review packet
- submit review packet
- final state update screen

No page errors, console errors, or framework error overlays were observed during
browser verification.

## Setup Notes

For local app setup, use:

- `README.md`
- `SETUP_DB.md`
- `SETUP_AI.md`
- `.env.example`

For Supabase SQL Editor setup, run the migrations in order:

1. `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`
2. `supabase/migrations/20260630041000_accesspulse_ramp_measurements.sql`
3. `supabase/seed.sql`

For Gemini-backed analysis, configure the Edge Function as described in
`SETUP_AI.md`. The local Flutter app can still run with mock AI when the server
wrapper is not configured.

## Current Known Boundaries

- Demo-safe mode is enabled by default to protect the hackathon demo.
- Live sensor capture is still available by turning demo-safe mode off.
- Web and emulator environments may not expose motion sensors, so fallback mode
  is expected and intentionally visible.
- Ramp slope evidence updates the living accessibility state and opens review
  context, but official verification still requires the inspector path.
