# AccessPulse MVP Implementation Plan

## Milestone 1 status

This repository is a fresh Flutter application scaffold. The MVP implementation should reuse Flutter and Dart as the client stack, keep Material 3, and add the AccessPulse domain in small layers instead of replacing the project structure wholesale.

Current baseline:

- Flutter app with default counter UI in `lib/main.dart`
- Default widget test in `test/widget_test.dart`
- No existing domain, data, persistence, navigation, or feature modules
- No Supabase, storage, AI, or backend wrapper configuration yet
- `flutter analyze` passes on the starting scaffold

## SSOT concepts to preserve

The founder handbook defines AccessPulse as a living accessibility knowledge system, not a complaint app or static directory. The implementation must preserve these concepts:

- A place has an accessibility profile composed of dimension-specific living states.
- The MVP dimension is `mobility_access`, focused on public service building entrance/ramp usability for independent wheelchair access.
- State, Pulse, and Memory are distinct:
  - State is the current best belief for a place and dimension.
  - Pulse is how alive, fresh, and trustworthy that belief is.
  - Memory is the append-only event history explaining how the state changed.
- Users update public accessibility knowledge by confirming visits and contributing evidence.
- AI acts as an accessibility evidence copilot and knowledge steward, never as a legal compliance judge.
- Human verification remains authoritative for official outcomes.
- Unknown is a valid state when the system does not know enough.
- The demo must visibly prove that a user interaction changes a place, changes pulse, creates an actionable case, and updates memory.

## MVP scope

Implement only the hackathon MVP from `accesspulse-codex-implementation-prompt-v2.md`.

In scope:

- Place type: public service buildings
- Accessibility dimension: Mobility Access
- Scenario: entrance/ramp usability for independent wheelchair access
- Roles: community user, LGU reviewer, inspector/verifier
- Role handling: lightweight demo role switcher, no production auth
- Seeded demo places:
  - Quezon City Hall Main Entrance
  - Public Hospital Main Entrance
  - Transport Terminal Entrance
- Demo loop:
  - User opens a stale claimed-accessible place.
  - User confirms a failed mobility-access visit.
  - User adds evidence.
  - AI mock structures the issue with uncertainty.
  - Place state updates to `degraded`.
  - LGU dashboard shows a case.
  - Inspector verifies it.
  - Place updates to `officially_verified_degraded`.
  - Place memory shows the chain.

Out of scope for the MVP:

- Full authentication or RBAC
- Production government integration
- Map-heavy functionality
- Advanced computer vision measurements
- Multi-dimension UX beyond a dimension-aware data model
- Direct client-side Gemini calls

## Target architecture

Use a layered Flutter structure that can start with seeded/local repositories and later swap in Supabase.

Proposed `lib/` layout:

```txt
lib/
  main.dart
  app/
    accesspulse_app.dart
    app_state.dart
    app_theme.dart
  domain/
    models/
    repositories/
    services/
  data/
    seed_data.dart
    in_memory_accesspulse_repository.dart
    mock_ai_evidence_service.dart
  features/
    public/
    institution/
    shared/
```

Domain objects:

- `Place`
- `AccessibilityDimension`
- `PlaceDimension`
- `DimensionState`
- `DimensionPulse`
- `MemoryEvent`
- `Observation`
- `Evidence`
- `BarrierSignal`
- `AccessCase`
- `Verification`

Enums:

- Dimension states: `unknown`, `claimed_accessible`, `reliable`, `degraded`, `officially_verified_degraded`, `under_review`, `resolved`
- Pulse levels: `weak`, `moderate`, `strong`
- Case states: `open`, `triaging`, `inspection_requested`, `verified`, `disputed`, `resolved`, `closed`
- Roles: community user, LGU reviewer, inspector

Services:

- `AccessPulseRepository`: canonical API for places, states, observations, evidence, cases, verifications, and memory.
- `DimensionStateService`: transition rules and memory logging.
- `PulseService`: pulse/freshness scoring separate from state.
- `AiEvidenceService`: mock first, Gemini wrapper later.

## Milestone plan

### Milestone 2 - Database and seed data

Because the prompt prioritizes a working demo and says to mock unfinished backend dependencies, start with canonical schema artifacts plus seeded in-memory data for the app.

Deliverables:

- Add `supabase/migrations/` SQL schema for the required tables.
- Add `supabase/seed.sql` with the three demo places and initial mobility state/pulse/memory.
- Add Dart seed models matching the schema so the UI can run before Supabase is wired.
- Keep cases attached to `place + dimension`, not only `place`.
- Keep memory append-only.

Verification:

- `flutter analyze`
- `flutter test`

### Milestone 3 - Domain layer

Deliverables:

- Implement domain models and enums.
- Implement in-memory repository.
- Implement state transition service:
  - `unknown` and seeded states as valid starts
  - positive observations can move `claimed_accessible` to `reliable`
  - negative evidence can move `claimed_accessible` or `reliable` to `degraded`
  - reviewer action can move `degraded` to `under_review`
  - inspector confirmation can move `under_review` to `officially_verified_degraded`
  - verified remediation can move degraded states to `resolved`
- Implement pulse logic from recency, supporting observations, verification, and contradictions.
- Log memory events for every state-changing action.
- Add focused unit tests for transitions, pulse calculation, and memory append behavior.

Verification:

- `flutter analyze`
- `flutter test`

### Milestone 4 - Public flow

Deliverables:

- Replace counter scaffold with the public AccessPulse app.
- Home/Search screen with seeded places and Mobility Access chip.
- Place Detail screen with state, confidence, pulse, last confirmed, explanation, and memory.
- Confirm Visit flow with MVP questions and optional note.
- Evidence flow with image placeholder/upload affordance, note, AI analysis panel, missing evidence guidance, and final structured signal.
- Submission Result screen with visible state and pulse transition summary.
- Ensure the language says users are helping update place knowledge, not filing complaints.

Verification:

- `flutter analyze`
- `flutter test`
- Manual run on at least one mobile-sized viewport

### Milestone 5 - Institution flow

Deliverables:

- Role switcher for community user, LGU reviewer, and inspector.
- LGU Dashboard with actionable cases and state/severity/confidence/pulse/status.
- Case Detail with place info, evidence bundle, AI explanation, current state, and memory.
- Reviewer actions for triage, request inspection, and close where appropriate.
- Inspector Verification screen with confirm, dispute, insufficient evidence, note, and submit.
- Verification updates case, dimension state, pulse, and memory.

Verification:

- `flutter analyze`
- `flutter test`
- Manual happy-path demo from public submission to inspector verification

### Milestone 6 - AI integration

Deliverables:

- Replace mock AI service with a secure server-side Gemini wrapper.
- Keep the client talking to `AiEvidenceService`, not Gemini directly.
- Preserve structured output:
  - dimension
  - issue type
  - observed features
  - possible barrier
  - missing evidence
  - confidence
  - summary
  - recommended action
- Preserve uncertainty and avoid legal compliance conclusions.
- Add fallback behavior if AI is unavailable so the demo remains usable.

Verification:

- `flutter analyze`
- `flutter test`
- Manual weak-evidence and useful-evidence checks

### Milestone 7 - Polish and demo

Deliverables:

- Improve state badges, pulse visuals, memory timeline, and transition feedback.
- Add accessible labels, semantic groupings, sufficient contrast, and keyboard-friendly controls where applicable.
- Add concise demo data labels that make the five-minute story obvious.
- Verify responsive layout for mobile and desktop/web.
- Update README with demo steps and setup notes.

Verification:

- `flutter analyze`
- `flutter test`
- `flutter build web`
- Manual end-to-end demo path

## Commit sequence

Use the required commit messages:

- `feat(mvp): complete milestone 1 project setup`
- `feat(mvp): complete milestone 2 database`
- `feat(mvp): complete milestone 3 domain layer`
- `feat(mvp): complete milestone 4 public flow`
- `feat(mvp): complete milestone 5 institution flow`
- `feat(mvp): complete milestone 6 ai integration`
- `feat(mvp): complete milestone 7 polish and demo`

## Milestone 1 stop point

Per the v2 implementation prompt, work stops after this plan is created, verified, and committed. Milestone 2 should begin in the next implementation pass.
