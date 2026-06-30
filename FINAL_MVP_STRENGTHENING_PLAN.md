# AccessPulse Final MVP Strengthening Plan

## Milestone 1 Audit Summary

This plan implements only the approved final-mile improvements from
`accesspulse-final-mvp-strengthening-implementation-prompt.md`.

The current repository is a Flutter MVP backed by an in-memory repository for
the demo path. The public flow, institutional flow, state transitions, pulse
calculation, AI wrapper, seeded data, and tests are already present. The final
strengthening work should preserve that architecture and make the existing demo
clearer rather than broader.

Key audited sources:

- `accesspulse-founders-handbook-final(2).md`
- `ACCESSPULSE_IMPLEMENTATION_SUMMARY.md`
- `lib/domain/models/accesspulse_models.dart`
- `lib/domain/services/pulse_service.dart`
- `lib/domain/services/dimension_state_service.dart`
- `lib/domain/services/ai_evidence_service.dart`
- `lib/data/accesspulse_seed_data.dart`
- `lib/data/in_memory_accesspulse_repository.dart`
- `lib/features/public/public_flow.dart`
- `lib/features/institution/institution_flow.dart`
- `test/widget_test.dart`
- `test/institution_flow_test.dart`
- `test/domain/dimension_state_service_test.dart`
- `test/domain/ai_evidence_service_test.dart`

## Current Flow Findings

### Public Flow

`lib/features/public/public_flow.dart` contains:

- Public place list and place detail.
- `_StateCard`, which currently shows Mobility Access state, pulse level,
  numeric confidence percentage, last confirmed date, state explanation, and
  pulse explanation.
- `ConfirmVisitScreen`, which updates state and pulse immediately after a visit.
- `EvidenceFlowScreen`, which currently asks the user to press
  `Analyze evidence`, then shows `_AiResultPanel`, `_ReviewPacketPanel`, and
  `Submit review packet`.
- `SubmissionResultScreen`, which shows before/after state and pulse.

The public flow already supports the full demo loop, but pulse is still shown as
raw `Weak/Moderate/Strong pulse` language, and confidence is shown as a
percentage.

### Institution Flow

`lib/features/institution/institution_flow.dart` contains:

- LGU dashboard queue via `_CaseQueueTile`.
- Case detail via `_CaseDetailScreen`.
- `_InstitutionStateCard`, which currently shows state, pulse, case status,
  severity, and numeric confidence percentages.
- `_SignalPanel`, which shows AI evidence bundle, observed features, missing
  context, and recommended action.
- Inspector verification flow.

The institution flow already has enough data for a minimal priority explanation.
It needs a visible "Why This Case Matters" block and label-based confidence.

### AI Integration

`lib/domain/services/ai_evidence_service.dart` contains:

- `MockAiEvidenceService`, used by default and as fallback.
- `GeminiServerEvidenceService`, which calls the Supabase Edge Function and
  falls back to mock output.

`AiEvidenceAssessment` currently contains structured fields but not evidence
readiness, confidence labels, or guidance-card-specific fields.

### State, Pulse, and Memory

`lib/domain/services/dimension_state_service.dart` already:

- Creates observations from visit confirmations.
- Creates evidence, barrier signals, and access cases.
- Moves place state to degraded or under review.
- Recalculates pulse through `PulseService`.
- Appends memory events.

`PulseService` currently returns `DimensionPulseLevel` and an explanation. It
has enough source information for user-facing freshness labels, but no
dedicated public pulse status.

## Exact Target Files

### Domain and Services

- `lib/domain/models/accesspulse_models.dart`
  - Add `EvidenceReadiness`.
  - Add `ConfidenceLevel`.
  - Add `PlacePulseStatus` or equivalent display state.
  - Extend `AiEvidenceAssessment` with readiness and confidence explanation.
  - Add a small `AiEvidenceGuidance` model only if the assessment shape becomes
    too crowded.
  - Add optional `PriorityExplanation` model if reused by UI/tests.

- `lib/domain/services/pulse_service.dart`
  - Add deterministic helper logic for public pulse status if it belongs near
    pulse calculation.
  - Keep existing `DimensionPulseLevel` and score calculation intact.

- `lib/domain/services/ai_evidence_service.dart`
  - Preserve the existing `AiEvidenceService` contract unless a narrow optional
    evidence-count/context parameter is needed for coaching.
  - Update mock output to return readiness, confidence label, confidence
    explanation, observed, missing, and one next-best action.
  - Keep Gemini fallback behavior intact.

- `lib/domain/services/dimension_state_service.dart`
  - Persist readiness/confidence language into `BarrierSignal.aiExplanation`
    metadata or direct fields if added to `BarrierSignal`.
  - Keep numeric confidence internally for existing severity/state math.
  - Avoid changing state transition rules except where submission result needs
    a clearer pulse label.

- `supabase/functions/analyze-evidence/index.ts`
  - Update JSON schema/prompt parsing only after the Flutter mock path works.
  - Keep server wrapper optional and fallback-safe.

### Data

- `lib/data/accesspulse_seed_data.dart`
  - Adjust seed dates or explanations only as needed to demonstrate:
    `Reliable`, `Reliable, aging`, `Unknown`, `Under review`, and
    `Recently refreshed`.
  - Do not add new places unless absolutely necessary; prefer deriving labels
    from current three-place seeds and flow transitions.

- `lib/data/in_memory_accesspulse_repository.dart`
  - No expected structural change unless new persisted fields require it.

### Public UI

- `lib/features/public/public_flow.dart`
  - `_PlaceListTile`: show state plus user-facing pulse/freshness label.
  - `_StateCard`: show dimension label, current state, pulse/freshness label,
    last confirmed date, short explanation, and verification context when
    available.
  - `EvidenceFlowScreen`: add AI Guidance Card inside the existing flow.
  - `_AiResultPanel`: replace confidence percentage with label and explanation.
  - `_ReviewPacketPanel`: include evidence readiness.
  - `SubmissionResultScreen`: show state transition and pulse/freshness update.
  - Add small private UI helpers if they stay local to this file.

### Institutional UI

- `lib/features/institution/institution_flow.dart`
  - `_CaseQueueTile`: add a short priority reason if safe.
  - `_InstitutionStateCard`: replace confidence percentages with labels and
    explanations.
  - `_CaseDetailScreen`: insert "Why This Case Matters" before evidence bundle.
  - `_SignalPanel`: show evidence readiness and label-based confidence.
  - Add a small private priority explanation builder if not shared.

### Tests

- `test/widget_test.dart`
  - Cover public pulse/freshness labels.
  - Cover confidence label rendering.
  - Cover evidence readiness in AI result/review packet.
  - Cover AI guidance card visibility and continue/skip/add-another controls.
  - Cover submission result pulse/freshness wording.

- `test/institution_flow_test.dart`
  - Cover LGU priority explanation block.
  - Cover case card priority reason if added.
  - Cover label-based confidence in case detail.

- `test/domain/dimension_state_service_test.dart`
  - Update constructors for new model fields.
  - Cover readiness metadata propagation if stored in signals/cases.

- `test/domain/ai_evidence_service_test.dart`
  - Cover mock readiness transitions.
  - Cover confidence label/explanation.
  - Cover Gemini wrapper parsing/fallback for added fields.

- `test/domain/pulse_service_test.dart` (new if needed)
  - Cover mapping from state/pulse/last-confirmed/case activity to public
    pulse labels.

## Implementation Sequence

### Milestone 2 - Place Pulse Visibility

Scope:

- Implement only user-facing pulse/freshness labels.
- Keep existing flow and AI behavior unchanged.
- Keep internal pulse score and level intact.

Steps:

1. Add a small pulse display mapper:
   - Inputs: `DimensionStateRecord`, `DimensionPulseRecord`, optional active
     case/recent update context if already available.
   - Outputs: `Reliable`, `Reliable, aging`, `Unknown`, `Under review`, or
     `Recently refreshed`, plus short explanation.
2. Update public place list and `_StateCard`.
3. Update `SubmissionResultScreen` to show before/after pulse display labels.
4. Update case detail summary only where data is already loaded.
5. Add/update tests for seeded reliable, aging, unknown, and post-submit
   under-review/recently-refreshed states.
6. Run `flutter analyze`, `flutter test`, and `flutter build web`.
7. Commit: `feat(final-mvp): add pulse visibility`.

Rollback-safe notes:

- This milestone should be mostly display logic. If labels behave incorrectly,
  revert the mapper and UI copy without touching state transitions.

### Milestone 3 - Institutional Priority Explanation

Scope:

- Implement only minimal case explanation.
- Do not add scoring engines, dashboards, roles, or new workflows.

Steps:

1. Add a deterministic priority explanation builder using existing data:
   - Place type.
   - Current state.
   - Case status/severity.
   - Signal observed features and missing evidence.
   - Assistance/ramp/entrance language in signal/evidence note.
   - Pulse/freshness label.
2. Render a "Why This Case Matters" block on LGU case detail with:
   - Why this matters.
   - Why now.
   - Suggested next action.
3. Add a one-line summary in `_CaseQueueTile` only if it remains readable.
4. Add tests for the block and expected demo copy.
5. Run `flutter analyze`, `flutter test`, and `flutter build web`.
6. Commit: `feat(final-mvp): add institutional priority explanation`.

Rollback-safe notes:

- Keep the builder pure and deterministic so copy can be adjusted without
  altering case status logic.

### Milestone 4 - Evidence Readiness + Confidence Labels

Scope:

- Add shared evidence assessment language before dynamic coaching.
- Do not change the evidence flow yet beyond rendering the new labels.

Steps:

1. Add `EvidenceReadiness` enum:
   - `draft`
   - `almostReady`
   - `institutionReady`
2. Add `ConfidenceLevel` enum:
   - `low`
   - `moderate`
   - `high`
3. Add helper mapping from internal double confidence to labels:
   - Low for incomplete/weak evidence.
   - Moderate for plausible but missing context.
   - High for strongly aligned evidence.
4. Extend `AiEvidenceAssessment` with:
   - `confidenceLevel`
   - `confidenceExplanation`
   - `evidenceReadiness`
   - optional `institutionReady`
5. Update mock AI and Gemini parsing with safe defaults.
6. Update public AI result/review packet/submission copy.
7. Update institutional signal panel to stop rendering confidence percentages.
8. Update constructor usages in tests.
9. Run `flutter analyze`, `flutter test`, and `flutter build web`.
10. Commit:
    `feat(final-mvp): complete milestone 1 implementation plan` is reserved
    for this plan commit; use
    `feat(final-mvp): add evidence readiness and confidence labels` for this
    milestone unless the user requests the exact prompt list only.

Rollback-safe notes:

- Keep numeric confidence fields for domain math and severity. Only display
  label/explanation publicly.

### Milestone 5 - AI Evidence Coaching

Scope:

- Implement the collaborative guidance loop inside existing Add Evidence.
- Start deterministic; connect Gemini only if stable.

Steps:

1. Add guidance fields using either `AiEvidenceAssessment` or a small
   `AiEvidenceGuidance` model:
   - Observed.
   - Missing.
   - Confidence.
   - Evidence Readiness.
   - Recommended Next Step.
2. Update `EvidenceFlowScreen` so guidance appears after initial evidence is
   provided/analyzed.
3. Add controls:
   - Add another photo.
   - Continue anyway.
   - Skip AI guidance.
4. Track simple local evidence iteration state:
   - No photo/weak note -> Draft.
   - Photo or useful note -> Almost Ready.
   - Photo plus ramp/clear note or explicit continue -> Institution Ready when
     sufficient.
5. Ensure the AI asks for only one next-best improvement at a time.
6. Update `_ReviewPacketPanel` to reflect final readiness and missing context.
7. If stable, update `supabase/functions/analyze-evidence/index.ts` to request
   and parse the new guidance fields; keep fallback deterministic.
8. Add widget tests for the guidance card and actions.
9. Run `flutter analyze`, `flutter test`, and `flutter build web`.
10. Commit: `feat(final-mvp): add ai evidence coaching`.

Rollback-safe notes:

- The deterministic guidance loop should remain functional even if Gemini
  output is unavailable or invalid.

### Milestone 6 - Final Integration and Demo Polish

Scope:

- Polish only approved improvements.
- Do not add flows, maps, auth, gamification, notifications, or dashboards.

Steps:

1. Sweep public flow for:
   - State plus pulse clarity.
   - Label-based confidence only.
   - Evidence readiness visibility.
   - AI guidance copy that sounds like an accessibility field copilot.
2. Sweep LGU flow for:
   - Clear priority explanation.
   - Pulse/freshness context.
   - Suggested next action.
3. Add accessibility semantics where new badges/buttons need clearer names.
4. Verify responsive behavior through Flutter widget constraints and, if a dev
   server is started, browser visual verification.
5. Run `flutter analyze`, `flutter test`, and `flutter build web`.
6. Commit: `feat(final-mvp): polish final mvp demo flow`.

Rollback-safe notes:

- Polish should be UI-only. Avoid changing domain transitions in this milestone.

## Data Model Changes

Planned minimal additions:

```dart
enum EvidenceReadiness { draft, almostReady, institutionReady }

enum ConfidenceLevel { low, moderate, high }

enum PlacePulseStatus {
  reliable,
  reliableAging,
  unknown,
  underReview,
  recentlyRefreshed,
}
```

Potential `AiEvidenceAssessment` extension:

```dart
final ConfidenceLevel confidenceLevel;
final String confidenceExplanation;
final EvidenceReadiness evidenceReadiness;
final bool institutionReady;
```

Potential guidance model if needed:

```dart
class AiEvidenceGuidance {
  final List<String> observed;
  final List<String> missing;
  final ConfidenceLevel confidenceLevel;
  final String confidenceExplanation;
  final EvidenceReadiness evidenceReadiness;
  final String nextBestAction;
  final bool institutionReady;
}
```

Potential priority model if shared outside the UI:

```dart
class PriorityExplanation {
  final List<String> whyThisMatters;
  final List<String> whyNow;
  final String suggestedNextAction;
}
```

Internal numeric confidence should remain in `DimensionStateRecord`,
`BarrierSignal`, and `AccessCase` for severity/state math. Public-facing UI
must render only Low, Moderate, or High with a short explanation.

## UI Component Changes

Public:

- `_PlaceListTile`: state plus public pulse label.
- `_StateCard`: dimension, current state, pulse/freshness, last confirmed,
  short explanation, verification context.
- `EvidenceFlowScreen`: AI Guidance Card and actions.
- `_AiResultPanel`: label confidence, readiness, observed, missing, next step.
- `_ReviewPacketPanel`: readiness and institution-ready status.
- `SubmissionResultScreen`: before/after state and pulse status.

Institution:

- `_CaseQueueTile`: optional short priority reason.
- `_InstitutionStateCard`: state/pulse/confidence label summary.
- New `_PriorityExplanationPanel` or similar private widget.
- `_SignalPanel`: readiness and label confidence.

## AI Service Changes

Mock first:

- Keep `MockAiEvidenceService` deterministic and demo-stable.
- Use evidence note/photo/ramp measurement to determine observed features,
  missing evidence, confidence label, confidence explanation, readiness, and one
  next-best action.

Gemini wrapper second:

- Update Supabase Edge Function schema only after mock-based Flutter flow passes.
- Parse missing fields with safe defaults.
- Continue sanitizing compliance/adjudication language.
- Continue falling back to mock output on failure.

## Test Plan

Run after every implementation milestone:

```powershell
flutter analyze
flutter test
flutter build web
```

Targeted assertions:

- Pulse labels:
  - Reliable.
  - Reliable, aging.
  - Unknown.
  - Under review.
  - Recently refreshed.
- No public-facing confidence percentages remain in public MVP screens.
- Confidence labels always have short explanation text.
- Evidence readiness appears in Add Evidence, AI Result/Review Packet, and
  relevant submission/institution views.
- AI Guidance Card appears after first evidence analysis.
- AI Guidance Card asks for only one next-best improvement.
- Add another photo, continue anyway, and skip AI guidance controls are visible
  and accessible.
- LGU case detail shows why this matters, why now, and suggested next action.
- Existing public-to-institution demo path still passes.

## Rollback and Safety Notes

- Keep changes milestone-scoped and commit after each milestone.
- Do not migrate to a Supabase-backed repository during this sprint.
- Do not add auth, maps, notifications, gamification, leaderboards, new roles,
  or new product areas.
- Prefer seeded/demo-safe data and deterministic helpers over incomplete
  infrastructure.
- Preserve existing state transition and memory behavior unless a later
  milestone explicitly requires display metadata.
- Treat AI as advisory evidence coaching only. Do not introduce legal
  compliance adjudication or official AI verification language.
- If a later milestone becomes risky, stop with the previous committed
  milestone intact.
