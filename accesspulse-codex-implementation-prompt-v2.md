# AccessPulse MVP — Codex Implementation Prompt

## DEVELOPMENT ORDER (MUST FOLLOW)

Do **not** implement everything at once.

Complete each milestone before moving to the next.

If a milestone is incomplete, do not start the next one.

After completing each milestone:
1. Verify everything builds.
2. Fix lint errors.
3. Fix type errors.
4. Commit the milestone.

Commit format:
- `feat(mvp): complete milestone 1 project setup`
- `feat(mvp): complete milestone 2 database`
- `feat(mvp): complete milestone 3 domain layer`
- `feat(mvp): complete milestone 4 public flow`
- `feat(mvp): complete milestone 5 institution flow`
- `feat(mvp): complete milestone 6 ai integration`
- `feat(mvp): complete milestone 7 polish and demo`

### Hackathon Rule

If a feature depends on an unfinished backend:
- **mock it first**

If it depends on AI:
- **mock it first**

If it depends on Supabase:
- **seed it first**

A polished end-to-end demo is always preferred over partially completed production infrastructure.

### Milestone 1 — Project setup

Implement only:
- inspect repository
- understand architecture
- identify existing stack
- create implementation plan

Output:
- `IMPLEMENTATION_PLAN.md`

Stop after this milestone.

### Milestone 2 — Database

Implement only:
- schema
- migrations
- seed data

No frontend.

Stop after this milestone.

### Milestone 3 — Domain Layer

Implement only:
- repositories
- services
- state machine
- pulse logic
- memory logging

No UI.

Stop after this milestone.

### Milestone 4 — Public Flow

Implement only:
- Home
- Place Detail
- Confirm Visit
- Evidence Upload
- AI Result
- State Update

Do not build dashboards yet.

Stop after this milestone.

### Milestone 5 — Institution Flow

Implement only:
- LGU Dashboard
- Case Detail
- Verification
- State Update

Stop after this milestone.

### Milestone 6 — AI Integration

Implement only:
- replace AI mocks with Gemini through a secure server-side wrapper
- preserve visible AI explanations and uncertainty handling

Stop after this milestone.

### Milestone 7 — Animations, polish, demo

Implement only:
- animations
- polish
- demo flow
- accessibility improvements

Stop after this milestone.

---

You are implementing the **AccessPulse hackathon MVP**.

The repository root contains the final conceptual SSOT handbook for this product. Treat that handbook as the **single source of truth** for product philosophy, ontology, terminology, system boundaries, and MVP scope.

Your job is to **build the MVP**, not revisit product discovery.

---

## 0. First rule

Before changing code, **read the SSOT in the repo root** and extract the implementation-relevant concepts into your plan.

Assume the handbook is final.

Do **not**:
- redesign the product,
- replace the ontology,
- simplify the system into a generic reporting app,
- collapse the place-state model into static labels,
- remove AI,
- invent alternative product directions.

Do:
- implement the narrowest possible version that clearly demonstrates the product thesis,
- preserve terminology from the handbook,
- make implementation decisions that are faithful to the SSOT,
- optimize for demo clarity, technical feasibility, and future expandability.

---

## 1. Product to build

Build the **AccessPulse MVP** that proves this loop:

1. A user checks a place.
2. The place shows a current living accessibility state for the MVP dimension.
3. The user confirms a visit or reports a failed access experience.
4. AI helps structure the evidence into institution-ready accessibility intelligence.
5. The place state updates.
6. An institutional reviewer sees an actionable case.
7. A human verifier confirms or disputes it.
8. The place memory updates.

This MVP must feel like:
- **a living place-state system**, not a complaint form,
- **a reliability layer**, not a static accessibility directory,
- **human + AI collaboration**, not AI auto-judgment.

---

## 2. MVP scope (frozen)

Implement only the minimum scope necessary to demonstrate the thesis.

### 2.1 Domain scope
- **Place type:** public service buildings
- **Primary accessibility dimension:** **Mobility Access**
- **Primary scenario:** entrance/ramp usability for independent wheelchair access

### 2.2 User roles for the MVP
- **Community user / PWD / citizen**
- **LGU reviewer**
- **Inspector / verifier**

Use a simple role switcher for demo if necessary.

### 2.3 Product objects that must exist
At minimum, the system must represent:
- **Place**
- **Accessibility Dimension** (for MVP: Mobility Access)
- **Dimension State**
- **Dimension Pulse**
- **Dimension Memory**
- **Observation**
- **Evidence**
- **Barrier Signal**
- **Case**
- **Verification**

### 2.4 States to support in MVP
For the **Mobility Access** dimension, implement a reduced but faithful state model:
- `unknown`
- `claimed_accessible`
- `reliable`
- `degraded`
- `officially_verified_degraded`
- `under_review`
- `resolved`

For **Pulse**, implement a reduced model:
- `weak`
- `moderate`
- `strong`

For **Case**, implement a reduced model:
- `open`
- `triaging`
- `inspection_requested`
- `verified`
- `disputed`
- `resolved`
- `closed`

---

## 3. Non-negotiable conceptual rules

These are product rules, not suggestions.

### 3.1 The user is not filing a complaint
The community-side flow must be framed as:
- confirming a place state,
- updating public accessibility knowledge,
- contributing evidence,
not “submitting a complaint.”

### 3.2 AI is not a compliance judge
AI may:
- structure evidence,
- classify likely issue type,
- estimate confidence,
- identify missing context,
- coach stronger evidence capture,
- suggest likely next action.

AI may **not**:
- declare legal non-compliance,
- mark a place officially verified,
- overrule human verification,
- silently rewrite state without trace.

### 3.3 State, Pulse, and Memory must be distinct
Do not collapse them.

- **State** = current best belief about the accessibility condition of a dimension
- **Pulse** = how alive / recent / trustworthy the current knowledge is
- **Memory** = the event history explaining how the state evolved

### 3.4 Unknown is valid
Do not force certainty.

If a place lacks enough evidence, show `unknown` rather than overclaiming reliability.

### 3.5 Human verification remains authoritative
Only the human verifier can move a case into an official verification outcome.

---

## 4. UX principles for implementation

These principles must be reflected in the UI and flows.

### 4.1 Emotional center
The magical moment is:

> “I answered a few simple questions, and the place changed.”

The user must visibly see that their interaction updates the living accessibility state.

### 4.2 Public-facing language
Use product language consistent with the handbook:
- “living accessibility state”
- “place memory”
- “help update this place”
- “current accessibility state”
- “confidence”
- “last confirmed”
- “under review”

Avoid generic bug-tracker language.

### 4.3 Layered simplicity
Keep the public UI simple:
- place name
- current state for the MVP dimension
- confidence
- pulse / freshness signal
- last confirmation
- CTA to confirm visit
- CTA to add evidence

Keep deeper details in reviewer and verifier views.

---

## 5. Preferred technical approach

### 5.1 Use the existing stack if the repo already has one
First inspect the repo and adapt to the existing stack.

### 5.2 If greenfield or architecture is missing, default to:
- **Flutter** for the client application
- **Dart** as the application language
- **Material 3** with strong accessibility defaults and semantic labels
- **Supabase Postgres** for persistence
- **Supabase Storage** for uploaded images
- **Supabase Auth** only if needed; otherwise use a lightweight demo role switcher for hackathon speed
- **Supabase Edge Functions** (preferred) or another minimal secure server-side layer for Gemini proxy calls
- **Gemini** for multimodal evidence analysis, evidence coaching, and structured signal generation

### 5.3 Build for expandability
Even if the MVP only supports one dimension, structure the code so future dimensions can be added without rewriting the whole system.

That means:
- dimension-aware models
- place-state logic isolated in services/repositories
- event-driven state history
- explicit case and verification entities
- AI access isolated behind a dedicated Gemini service layer
- Supabase access isolated behind repositories or data sources rather than scattered direct calls

### 5.4 Preferred implementation split
Use this implementation boundary unless the repo already imposes a cleaner one:
- **Flutter app:** all user-facing screens, role switcher, forms, local state, and presentation logic
- **Supabase Postgres:** canonical persistence for places, states, observations, signals, cases, verifications, and memory events
- **Supabase Storage:** image upload and retrieval
- **Supabase Edge Functions / secure backend wrapper:** Gemini requests, structured evidence analysis, and any privileged server-side logic

Do not call Gemini directly from the client with an exposed API key.

---

## 6. Required screens

Implement these screens at minimum.

### Public/User side
1. **Home / Search**
   - search or select seeded places
   - optional accessibility-need chip for demo (default to Mobility Access)

2. **Place Detail**
   - place name
   - current dimension state badge
   - confidence
   - pulse indicator
   - last confirmed time
   - short explanation
   - recent memory events
   - CTA: `I visited this place`
   - CTA: `Add evidence`

3. **Confirm Visit**
   - Was the entrance usable independently?
   - Was the ramp usable?
   - Did you need assistance?
   - Were you able to complete your purpose for visiting?
   - optional note

4. **Evidence / Barrier Flow**
   - upload image
   - optional text note
   - AI analysis panel
   - missing evidence guidance
   - submit final structured signal

5. **Submission Result**
   - state transition summary
   - “your visit updated this place” message

### Institutional side
6. **LGU Dashboard**
   - queue of open/actionable cases
   - state, severity, confidence, pulse, status

7. **Case Detail**
   - place info
   - evidence bundle
   - AI explanation
   - current state and memory
   - CTA: request inspection / triage / close

8. **Inspector Verification**
   - review case
   - confirm / dispute / insufficient evidence
   - add note
   - submit verification

---

## 7. Required data model

Design the data model around the ontology below.

### 7.1 Core entities
Implement at minimum:
- `users`
- `organizations` (optional in MVP, but leave room)
- `places`
- `place_dimensions`
- `dimension_states`
- `dimension_pulses`
- `memory_events`
- `observations`
- `evidence`
- `barrier_signals`
- `cases`
- `verifications`

### 7.2 Modeling notes
- A **Place** can have many **Dimensions**.
- For MVP, seed one dimension: `mobility_access`.
- Each `place + dimension` pair has:
  - one current state,
  - one current pulse,
  - many memory events.
- Observations and evidence should attach to a specific `place + dimension`.
- Cases should attach to a specific `place + dimension`, not just a place.
- Memory events must be append-only.

---

## 8. State machine requirements

### 8.1 Dimension state transition rules (MVP)
Example simplified rules:
- New place starts at `unknown`
- Seeded place may start at `claimed_accessible`
- Positive confirmed observations can move `claimed_accessible` → `reliable`
- Negative evidence can move `claimed_accessible` or `reliable` → `degraded`
- Reviewer action can move `degraded` → `under_review`
- Inspector confirmation can move `under_review` → `officially_verified_degraded`
- Verified remediation can move degraded states → `resolved`

These transitions must be logged into memory events.

### 8.2 Pulse logic (MVP)
Implement a simple pulse model using:
- last confirmed time
- number of supporting observations
- presence of recent verification
- contradiction flag

You do **not** need a full probabilistic system for the hackathon.
But the code should clearly reflect that Pulse is separate from State.

---

## 9. AI requirements

The AI must be materially useful. Do not reduce it to a generic summary box.

### 9.1 Minimum AI responsibilities in MVP
For an uploaded entrance/ramp photo and note, AI should:
- identify likely relevant visible features
- classify likely issue category within the MVP scope
- explain what it can and cannot determine
- generate a structured summary for institutional review
- surface missing evidence or uncertainty
- return a confidence estimate
- recommend a next step

### 9.2 Example AI output shape
For the MVP, a structured JSON response like this is enough:

```json
{
  "dimension": "mobility_access",
  "issueType": "entrance_ramp_usability",
  "observedFeatures": ["entrance", "steps", "partial ramp"],
  "possibleBarrier": "independent wheelchair access may be unreliable",
  "missingEvidence": ["full side view of ramp", "landing visibility"],
  "confidence": 0.82,
  "summary": "The visible entrance suggests mobility access may require assistance.",
  "recommendedAction": "lgu_review"
}
```

### 9.3 Important AI constraints
- Never state legal non-compliance.
- Never mark official verification.
- Never hide uncertainty.
- If the image is weak, say so.
- If another image is needed, say why.

---

## 10. Demo-first requirements

The implementation must support a clean, credible 5-minute demo.

### 10.1 Seed at least 3 places
Example seeded places:
- Quezon City Hall Main Entrance
- Public Hospital Main Entrance
- Transport Terminal Entrance

At least one place should start as:
- `claimed_accessible`
- moderate pulse
- old confirmation date

### 10.2 Demo scenario
At least one scripted demo path must work reliably:
1. User opens a place that appears accessible but stale.
2. User confirms a failed mobility-access experience.
3. User uploads a photo.
4. AI structures the issue and highlights uncertainty.
5. Place state updates to degraded.
6. LGU dashboard shows a new actionable case.
7. Inspector verifies it.
8. Place updates to officially verified degraded.
9. Place memory reflects the full chain.

### 10.3 Visual proof of the thesis
The UI must visibly show:
- the place changed,
- the pulse changed,
- the case appeared,
- memory updated.

If that chain is not obvious, the MVP is not done.

---

## 11. Implementation guidance for Codex

When implementing, follow this order.

### Phase 1 — Repo inspection and plan
- Inspect current repo structure.
- Read the SSOT in the root folder.
- Write a short implementation plan before editing major files.
- Reuse existing components and stack wherever possible.

### Phase 2 — Domain model and persistence
- Create/extend schema for places, dimensions, states, pulse, memory, observations, evidence, signals, cases, verifications.
- Seed demo data.

### Phase 3 — Public user flow
- Build search/home.
- Build place detail.
- Build visit confirmation.
- Build evidence upload and AI analysis.
- Build state update result.

### Phase 4 — Institutional flow
- Build LGU dashboard.
- Build case detail.
- Build inspector verification.
- Build official state update and memory logging.

### Phase 5 — Demo polish
- Improve labels and state badges.
- Make transitions visible.
- Make AI explanation readable.
- Ensure the happy path never breaks.

---

## 12. Acceptance criteria

The MVP is complete only if all of the following are true.

### Product acceptance
- A user can search and open a place.
- The place shows a living state for the MVP dimension.
- The place also shows pulse/freshness information.
- A user can confirm a visit.
- A user can add evidence.
- AI returns a structured, uncertainty-aware assessment.
- The place state updates visibly.
- A case appears for institutional review.
- A human verifier can confirm or dispute the issue.
- Place memory shows the chain of change.

### Conceptual acceptance
- The product does not read like a generic reporting app.
- The ontology reflects `place × dimension` rather than a single place label.
- State, pulse, and memory are visibly distinct.
- AI acts as an evidence copilot, not a compliance judge.

### Demo acceptance
- The core narrative can be shown in under 5 minutes.
- There is a clear magical moment where user input changes a place.
- Judges can immediately understand why the product is different from maps, complaints, or audits.

---

## 13. Things to avoid

Do not waste hackathon time on these unless already trivial in the repo:
- full authentication
- production-grade RBAC
- robust file upload infrastructure beyond what is needed for demo
- complex multi-dimension UI beyond the MVP dimension
- map-heavy functionality
- real government integration
- advanced CV measurement estimation
- generalized workflow engines
- complete policy/rules engine

This is a thesis demo, not a national rollout.

---

## 14. Final instruction

Build the smallest implementation that makes this sentence feel true:

> **AccessPulse helps people and institutions know whether places are truly accessible right now.**

And make the architecture strong enough that future work can grow naturally into the full **Living Accessibility Network**.

## 15. Definition of Done

A feature is not complete until all of the following are true:

- ✓ UI works
- ✓ Backend works
- ✓ Database updates correctly
- ✓ State updates correctly
- ✓ Memory updates correctly
- ✓ AI response is visible where relevant
- ✓ No console/runtime errors
- ✓ Mobile responsiveness is verified
- ✓ Accessibility semantics are added

If a dependency is unfinished, use a mock or seeded path so the end-to-end experience still works.

The MVP is judged by the strength of the working flow, not by how much incomplete infrastructure exists.
