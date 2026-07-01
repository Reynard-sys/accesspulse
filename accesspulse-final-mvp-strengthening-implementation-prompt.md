# AccessPulse Final MVP Strengthening — Codex Implementation Prompt

You are implementing the **final MVP strengthening sprint** for AccessPulse.

Read the repository first.

Read the SSOT / Founder’s Handbook first.

Read the current implementation summary first.

Do not redesign the product.
Do not expand the MVP.
Do not add unrelated features.

Your job is to implement only the already-approved final-mile improvements that strengthen the bridge between lived accessibility experience and institutional action.

---

# PRIMARY OBJECTIVE

Strengthen the existing AccessPulse MVP so judges leave with three clear impressions:

1. **This information is alive.**
2. **The AI genuinely helps ordinary people create institution-grade evidence.**
3. **Institutions immediately know what deserves attention and why.**

---

# APPROVED IMPROVEMENTS ONLY

Implement only these improvements:

## 1. AI Evidence Coaching
Evolve the AI from post-submission analysis into a collaborative Accessibility Copilot that helps users improve evidence before submission.

## 2. Place Pulse Visibility
Make freshness and pulse visible enough that stale, aging, unknown, under-review, and recently refreshed truth are obvious.

## 3. Institutional Priority Explanation
Make every institutional case immediately answer:
- Why does this matter?
- Why now?
- What should happen next?

## 4. Evidence Readiness
Add:
- Draft
- Almost Ready
- Institution Ready

## 5. Confidence Labels
Replace any percentage confidence in the public MVP with:
- Low
- Moderate
- High

Always paired with a short explanation.

---

# NON-NEGOTIABLE RULES

- Do not redesign architecture.
- Do not replace existing flows.
- Do not add new product areas.
- Do not add maps.
- Do not add auth.
- Do not add gamification.
- Do not add dashboards beyond what is needed for the approved improvements.
- Do not add generic chatbot features.
- Do not add AI compliance adjudication.
- Do not expand beyond current MVP scope.

Protect the MVP from feature creep.

---

# HACKATHON RULE

A polished end-to-end demo is more important than partial infrastructure.

If a dependency is unfinished:
- mock it first
- make the demo path work
- only replace mocks when safe

If AI coaching is hard to implement fully:
- build a deterministic first version that feels native to the AI Guidance Card
- then connect to Gemini through the existing server wrapper

If a backend dependency is incomplete:
- prefer seeded or mocked data over a half-working broken flow

---

# DEVELOPMENT ORDER (MUST FOLLOW)

Do NOT implement everything at once.

Complete each milestone before moving to the next.

If a milestone is incomplete, do not start the next one.

After each milestone:
1. verify the app builds
2. fix analysis / lint issues
3. fix test failures
4. commit

Commit format:
- `feat(final-mvp): complete milestone 1 implementation plan`
- `feat(final-mvp): add pulse visibility`
- `feat(final-mvp): add institutional priority explanation`
- `feat(final-mvp): add ai evidence coaching`

---

## Milestone 1 — Audit and Plan

Inspect repository and current implementation.

Understand:
- existing public flow
- existing institution flow
- current AI integration
- current state/pulse/memory behavior
- current place detail card
- current evidence submission flow
- current case detail screen

Then create:

`FINAL_MVP_STRENGTHENING_PLAN.md`

This file must contain:
- exact target files
- implementation sequence
- data model changes
- UI component changes
- AI service changes
- test plan
- rollback-safe notes

Stop after creating the plan.

---

## Milestone 2 — Place Pulse Visibility

Implement only pulse / freshness visibility.

### Required behavior
Public place detail must clearly show:
- state
- pulse/freshness
- last confirmed
- short explanation

Support these user-facing states:
- Reliable
- Reliable, aging
- Unknown
- Under review
- Recently refreshed

### Required screens
- Place Detail
- Submission Result
- Case Detail summary if relevant

### Rules
- no confidence percentages
- do not change core flow yet
- do not implement AI coaching yet

Stop.

Commit.

---

## Milestone 3 — Institutional Priority Explanation

Implement only institutional prioritization explanation.

### Required behavior
LGU case detail must clearly show:
- Why this case matters
- Why now
- Suggested next action

### Use only minimal logic
Derive from existing case data such as:
- public service building
- main entrance affected
- assistance required
- recent evidence
- state degraded / under review
- confidence level if available

### Required screens
- LGU case detail
- case card summary if easy and safe

Do not build complex scoring systems.

Stop.

Commit.

---

## Milestone 4 — Evidence Readiness + Confidence Labels

Implement the shared public evidence assessment language before full AI coaching.

### Add
- EvidenceReadiness enum / state
  - Draft
  - Almost Ready
  - Institution Ready
- Confidence labels
  - Low
  - Moderate
  - High
- Confidence explanation text

### Required screens
- Add Evidence
- AI Result / Review Packet
- Submission Result if useful

Do not implement dynamic coaching yet.
Use current AI or deterministic fallback to populate the structure.

Stop.

Commit.

---

## Milestone 5 — AI Evidence Coaching

Implement the collaborative AI Guidance Card inside the existing Add Evidence flow.

### Required behavior
After the user adds initial evidence:
- AI evaluates what is visible
- AI identifies what is missing
- AI recommends one next-best improvement
- user can add more evidence
- AI re-evaluates
- confidence and readiness update visibly
- once sufficient, evidence can become Institution Ready

### Required user actions
- add another photo
- continue anyway
- skip AI guidance

### Required outputs
- Observed
- Missing
- Confidence
- Evidence Readiness
- Recommended Next Step

### Important
AI should feel like a field accessibility copilot, not a summarizer.

If full Gemini-based iterative coaching is too risky:
- first implement a deterministic coaching loop based on existing evidence fields
- then connect to Gemini through the existing Edge Function wrapper only if stable

Stop.

Commit.

---

## Milestone 6 — Final Integration and Demo Polish

Polish only the approved improvements.

### Required checks
- place state + pulse are visually understandable
- evidence readiness is legible
- confidence is Low / Moderate / High only
- AI guidance feels collaborative
- LGU case immediately explains why it matters
- demo flow is clear from public user to institutional action

### Add only safe polish
- spacing
- hierarchy
- badges
- explanatory text
- accessibility semantics
- screen-reader friendly labels
- transition clarity

Do not add new flows.

Stop.

Commit.

---

# DEFINITION OF DONE

A change is not complete until:

- [ ] UI works
- [ ] backend/service logic works
- [ ] state updates correctly
- [ ] pulse/freshness displays correctly
- [ ] memory remains intact
- [ ] AI response or AI-guidance output is visible
- [ ] evidence readiness is visible
- [ ] confidence is label-based, not percentage-based
- [ ] no analyzer errors
- [ ] tests pass or are updated appropriately
- [ ] no console/runtime errors in demo flow
- [ ] mobile responsiveness verified
- [ ] accessibility semantics added where relevant

---

# IMPLEMENTATION DETAILS

## 1. AI Evidence Coaching

### Must implement
Inside existing Add Evidence flow, add an AI Guidance Card that shows:
- observed
- missing
- confidence (Low / Moderate / High)
- evidence readiness
- next best action

### Interaction rules
- only request one next-best improvement at a time
- keep language short and plain
- preserve user control
- allow “continue anyway”

### Example guidance
- “I can see the doorway, but not enough of the route leading to it.”
- “A side photo of the ramp would make this much stronger for review.”
- “The entrance and ramp are visible, but the landing area is not.”

---

## 2. Evidence Readiness

### Must implement
Evidence Readiness state with:
- Draft
- Almost Ready
- Institution Ready

### Purpose
This is separate from confidence.

Confidence = how sure the AI currently is.  
Evidence Readiness = whether the evidence is useful enough for review.

---

## 3. Confidence

### Must implement
Replace public-facing percentage confidence with:
- Low
- Moderate
- High

Always include a short explanation.

Examples:
- “Low — I cannot see enough of the entrance path.”
- “Moderate — The ramp is visible, but the landing area is not.”
- “High — The entrance path, ramp, and access difficulty are clearly supported.”

---

## 4. Place Pulse Visibility

### Must implement
Public-facing pulse/freshness wording that distinguishes:
- Reliable
- Reliable, aging
- Unknown
- Under review
- Recently refreshed

Do not expose raw internal scoring if unnecessary.

---

## 5. Institutional Priority Explanation

### Must implement
On LGU case detail, add a block:
- Why this case matters
- Why now
- Suggested next action

Use current data only.
Do not create a full scoring engine.

---

# FILE TARGETING GUIDANCE

Inspect repo first, but likely target areas include:
- public place detail UI
- public add evidence flow
- AI result / review packet UI
- shared domain models / enums
- AI service response shapes
- institution case detail UI
- any seeded/mock data needed to support the demo path
- tests covering new states and copy

Do not refactor broadly unless required for the approved changes.

---

# TESTING EXPECTATIONS

Add or update tests for:
- pulse/freshness labels
- evidence readiness transitions
- confidence label rendering
- AI guidance card visibility
- LGU priority explanation rendering
- end-to-end public → institution demo path

---

# ACCESSIBILITY EXPECTATIONS

Because AccessPulse is an accessibility product:
- all new labels must be screen-reader friendly
- readiness and confidence must not rely on color alone
- chips/badges must have text
- interaction copy must stay short and understandable
- buttons must remain accessible on mobile

---

# OUTPUT STYLE

Work milestone by milestone.

At the end of each milestone:
- summarize what changed
- list touched files
- report test/build status
- commit

Do not skip milestones.
Do not work ahead.
Do not redesign anything outside the approved scope.

Your goal is not to make the codebase broader.

Your goal is to make the current MVP much clearer, more truthful, and more compelling as a demonstration of how AI transforms lived accessibility experience into trusted institutional intelligence.
