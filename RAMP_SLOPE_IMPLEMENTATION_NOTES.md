# Ramp Slope Capture Implementation Notes

Milestone 1 planning review for `accesspulse-ramp-slope-implementation-plan-v2.md`.

## Current Ramp Report Flow

- Public report entry is in `lib/features/public/public_flow.dart`.
- Ramp-related lived-experience confirmation is already represented in `ConfirmVisitScreen` through `_rampUsable`.
- The stronger evidence/report flow is `EvidenceFlowScreen`.
- `EvidenceFlowScreen` already defaults its note to a ramp-related concern: `The entrance has steps and the ramp required assistance.`
- The practical Milestone 2 insertion point is inside `EvidenceFlowScreen`, after the note/photo card and before AI analysis.
- Trigger logic should be local and conservative at first:
  - show the optional slope capture affordance when the note contains ramp-related terms such as `ramp`, `steep`, `incline`, `slope`, `unsafe`, or `wheelchair entrance`
  - keep it optional and never block analysis or submission

## Current Report State Storage

- Domain models live in `lib/domain/models/accesspulse_models.dart`.
- Current report evidence is stored as `Evidence`.
- `Evidence.metadata` is already a `Map<String, Object?>`, which is the best short-term attachment point for a captured ramp measurement before the dedicated Supabase persistence milestone.
- `BarrierSignal.aiExplanation` is also available for AI-side structured context, but the source measurement should remain attached to `Evidence.metadata`.
- `DimensionStateService.submitStructuredEvidence` in `lib/domain/services/dimension_state_service.dart` creates:
  - `Evidence`
  - `BarrierSignal`
  - `AccessCase`
  - memory events
- Milestone 4 should add a first-class `RampMeasurement` model and repository methods, then connect it to the evidence/report submission path.

## Current AI Summary Integration Point

- AI abstraction: `lib/domain/services/ai_evidence_service.dart`.
- Client call site: `_EvidenceFlowScreenState._analyze` in `lib/features/public/public_flow.dart`.
- Server wrapper: `supabase/functions/analyze-evidence/index.ts`.
- Current Gemini wrapper receives `dimension`, `note`, and `imagePath`.
- Milestone 6 should extend the AI request with an optional measurement payload.
- Gemini must only interpret the measurement as supporting evidence. Angle calculation must remain client-side and must not be delegated to Gemini.
- The prompt already includes non-overclaiming rules; Milestone 6 should add explicit forbidden language for compliance/violation claims involving ramp slope.

## Current Case Detail Rendering Point

- Institution case detail is in `lib/features/institution/institution_flow.dart`.
- `_CaseDetailScreenState._loadDetail` already fetches the `BarrierSignal` and linked `Evidence`.
- `_SignalPanel` renders the evidence bundle and receives both `signal` and `evidence`.
- Milestone 5 insertion point:
  - read a ramp measurement from the linked evidence or repository result
  - render a compact `Ramp Measurement` block inside `_SignalPanel`
  - include estimated angle, quality label, source, captured timestamp, and the non-authoritative note

## Current Repository and Persistence Footprint

- Repository contract: `lib/domain/repositories/accesspulse_repository.dart`.
- In-memory implementation: `lib/data/in_memory_accesspulse_repository.dart`.
- Supabase schema: `supabase/migrations/20260629133000_accesspulse_mvp_schema.sql`.
- Existing database tables support observations, evidence, barrier signals, cases, verifications, and memory events.
- There is no `ramp_measurements` table yet.
- Milestone 4 should add:
  - `RampMeasurement` model
  - repository methods such as `addRampMeasurement`, `getRampMeasurement`, and possibly `getRampMeasurementForEvidence`
  - in-memory storage
  - Supabase migration for `public.ramp_measurements`
  - an association to report/evidence; `evidence_id` is the best current link because this MVP report flow creates evidence before the case

## Current Flutter Plugin Footprint

- `pubspec.yaml` currently has Flutter, `cupertino_icons`, and `http`.
- No sensor plugin is currently installed.
- Milestone 3 should add `sensors_plus`.
- Sensor capture should be isolated outside the large public flow file, likely in:
  - `lib/domain/models/ramp_measurement.dart` or the existing accesspulse model file for MVP simplicity
  - `lib/domain/services/ramp_slope_capture_service.dart`
  - `lib/features/public/widgets/ramp_slope_capture.dart` or a small feature file if the public flow grows too large
- Keep a dev/mock fallback service available so web/demo flows remain stable when device sensors are unavailable.

## Recommended Milestone Insertion Points

1. Milestone 2 UX shell:
   - `lib/features/public/public_flow.dart`
   - Add a small optional capture panel to `EvidenceFlowScreen`.
   - Use a local mocked measurement object held in `_EvidenceFlowScreenState`.
   - Do not add dependencies or persistence yet.

2. Milestone 3 sensor capture:
   - `pubspec.yaml`
   - new ramp capture service file
   - optional UI state updates in `EvidenceFlowScreen`
   - fallback mock mode for web/unsupported devices

3. Milestone 4 persistence:
   - `lib/domain/models/accesspulse_models.dart`
   - `lib/domain/repositories/accesspulse_repository.dart`
   - `lib/data/in_memory_accesspulse_repository.dart`
   - `lib/domain/services/dimension_state_service.dart`
   - new Supabase migration for `ramp_measurements`

4. Milestone 5 case visibility:
   - `lib/features/institution/institution_flow.dart`
   - render the compact measurement block inside `_SignalPanel`

5. Milestone 6 Gemini integration:
   - `lib/domain/services/ai_evidence_service.dart`
   - `supabase/functions/analyze-evidence/index.ts`
   - related tests in `test/domain/ai_evidence_service_test.dart`

6. Milestone 7 polish:
   - public capture UX copy and retry states
   - README/setup notes if needed
   - browser/demo verification

## Safety Rules to Preserve

- Always label the angle as estimated.
- Never say violation confirmed, illegal, exact, or proven non-compliant.
- Low-quality readings must remain usable as weak supporting context, with retry available.
- Measurement must strengthen evidence, not replace lived experience or human review.
- Main MVP flow must continue to work without sensors.
