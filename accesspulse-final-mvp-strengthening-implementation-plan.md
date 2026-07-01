# AccessPulse Final MVP Strengthening — Implementation Plan

## Purpose

This document defines the implementation plan for the **final MVP strengthening sprint** for AccessPulse.

It does **not** redesign the product.

It only implements the three approved improvements from the final design review:

1. **AI Evidence Coaching**
2. **Truth Freshness / Place Pulse Visibility**
3. **Institutional Priority Explanation**

It also incorporates two additional accepted refinements:

4. **Evidence Readiness**
5. **Confidence as Low / Moderate / High, never percentages**

These improvements exist to strengthen the bridge between:

**lived accessibility experience**  
and  
**trusted institutional action**

---

## Success Criteria

After this sprint, judges should leave with three impressions:

### 1. This information is alive.
The platform honestly shows freshness, aging, uncertainty, and active review.

### 2. The AI genuinely helps ordinary people create institution-grade evidence.
The AI does not just summarize after submission. It collaborates before review.

### 3. Institutions immediately know what deserves attention and why.
The system surfaces not just cases, but actionable, prioritized, explainable public intelligence.

---

# Scope

## In Scope

### A. AI Evidence Coaching
Add a guided evidence quality loop inside the existing public evidence flow.

The AI should:
- inspect the first submitted evidence
- identify what is visible
- identify what is missing
- ask for one better next piece of evidence
- re-evaluate after new evidence is added
- produce an institution-ready packet only when evidence is sufficient

### B. Evidence Readiness
Introduce a simple evidence readiness state that is easier to understand than confidence alone.

Allowed states:

- `Draft`
- `Almost Ready`
- `Institution Ready`

### C. Confidence Language
Replace any percentage confidence in the user-facing MVP with:

- `Low`
- `Moderate`
- `High`

Each confidence state must always include a short explanation.

### D. Place Pulse Visibility
Make pulse and freshness visible in the public experience so users can distinguish between:

- Reliable
- Reliable, aging
- Unknown
- Under review
- Recently refreshed

### E. Institutional Priority Explanation
Add a minimal priority explanation block in the LGU case experience that answers:

- Why does this matter?
- Why now?
- What should happen next?

---

## Out of Scope

Do **not** add:
- new roles
- gamification
- leaderboards
- notifications
- map layer
- social feed
- remediation portal
- network health dashboard
- full multidimensional UX
- additional issue categories
- auth / RBAC
- production Supabase repository migration if it risks demo stability

---

# Design Intent

## A. AI Evidence Coaching should feel collaborative
The AI should feel like an accessibility field copilot.

It should never sound like:
- a legal authority
- a compliance adjudicator
- a vague assistant
- a generic summarizer

It should sound like:
- a calm accessibility reviewer
- a knowledgeable evidence coach
- a collaborator helping the user produce stronger evidence

### Example tone
- “I can see the doorway, but not enough of the route leading to it.”
- “A side photo of the ramp would make this much stronger for review.”
- “The entrance and ramp are visible, but the landing area is not.”
- “This is now strong enough for LGU review.”

## B. Pulse must reinforce the philosophy
Pulse is not a technical metric. It is the visible expression of living public truth.

Users should immediately understand:
- what we know
- how recent it is
- whether it is aging
- whether the truth is in motion

## C. Institutional priority must reduce cognitive load
The LGU should not read a raw report and decide from scratch.

The system should already explain:
- why the case has public importance
- what evidence supports it
- why it deserves review now
- what next action is recommended

---

# Product Changes

# 1. AI Evidence Coaching

## Existing Flow
Place Detail  
→ Confirm Visit  
→ Add Evidence  
→ AI Result  
→ Review Packet  
→ Submission Result

## New Flow
Place Detail  
→ Confirm Visit  
→ Add Evidence  
→ **AI Guidance Card appears immediately**  
→ User optionally adds better evidence  
→ AI re-evaluates  
→ Evidence Readiness updates  
→ AI Result becomes institution-ready  
→ Review Packet  
→ Submission Result

## New Interaction Rules
- AI should respond after the first note/photo is provided
- AI should request only **one next-best evidence improvement at a time**
- AI should allow the user to:
  - add another photo
  - continue anyway
  - skip AI guidance
- AI should visibly improve confidence and readiness when evidence improves
- AI should explicitly state when the evidence is sufficient for institutional review

## AI Guidance Card Fields
- Observed
- Missing
- Confidence
- Evidence Readiness
- Recommended Next Step

## AI Guidance Card Example
### Example 1
**Observed**  
Entrance and doorway visible.

**Missing**  
The full route leading to the entrance is not visible.

**Confidence**  
Low — I cannot tell whether the entrance is independently usable from this angle.

**Evidence Readiness**  
Draft — needs one more photo.

**Recommended Next Step**  
Take a wider photo that shows the full path from sidewalk to entrance.

### Example 2
**Observed**  
Entrance and ramp visible.

**Missing**  
The landing area at the top of the ramp is unclear.

**Confidence**  
Moderate — the ramp is visible, but I cannot fully assess usability yet.

**Evidence Readiness**  
Almost Ready — one more angle would improve this for review.

**Recommended Next Step**  
Take a side photo of the ramp showing the full slope and top landing.

### Example 3
**Observed**  
Entrance path, ramp, and access difficulty are clearly supported.

**Missing**  
No major missing evidence.

**Confidence**  
High — the visual evidence and visit confirmation align.

**Evidence Readiness**  
Institution Ready — sufficient evidence collected for LGU review.

**Recommended Next Step**  
Submit for review.

---

# 2. Evidence Readiness

## Purpose
Help users understand whether their contribution is useful enough to help institutions act.

## States
### Draft
Meaning:
- evidence is incomplete
- another piece of evidence is needed before strong institutional review

### Almost Ready
Meaning:
- evidence is useful
- one missing detail would improve review quality

### Institution Ready
Meaning:
- sufficient evidence has been collected for institutional review

## Rules
- Evidence Readiness must be shown in the public evidence flow
- Evidence Readiness must change as evidence improves
- Evidence Readiness must appear in the review packet
- Evidence Readiness must never be confused with legal validity or official verification

---

# 3. Confidence Language

## Rule
Do not use confidence percentages anywhere in the public MVP.

## Allowed values
- Low
- Moderate
- High

## Requirement
Every confidence label must be accompanied by a short explanation.

### Example
**Confidence: Moderate**  
The entrance and ramp are visible, but the landing area is not.

---

# 4. Place Pulse Visibility

## Goal
Make freshness and place pulse visible at the point of decision.

## Public-facing pulse states
- Reliable
- Reliable, aging
- Under review
- Unknown
- Recently refreshed

## Required UX
The Place State Card should show:
- Dimension label: `Mobility Access`
- Current state
- Freshness / pulse label
- Last confirmed date
- Short explanation
- Verification context where applicable

## Example Copy
### Reliable
Recently confirmed as independently usable.

### Reliable, aging
Previously reliable, but not confirmed recently.

### Unknown
We do not currently have enough recent evidence for this place.

### Under review
Recent evidence may change this place’s current state.

### Recently refreshed
Updated today based on a new visit confirmation.

## Pulse Display Rules
- Pulse should appear on Place Detail
- Pulse should appear on Submission Result when the state changes
- Pulse / freshness context should appear in Case Detail summary
- Pulse should reinforce honesty, not just visual polish

---

# 5. Institutional Priority Explanation

## Goal
Help LGU reviewers quickly decide what deserves scarce attention.

## Minimal priority model
Each case should explicitly show:

### A. Why this matters
Examples:
- Public service building
- Main entrance affected
- Mobility access affected
- Assistance required
- Visit purpose not completed

### B. Why now
Examples:
- Recent evidence
- State just degraded
- Active review needed
- High-confidence evidence
- New evidence contradicts prior assumption

### C. Suggested next action
Examples:
- Request inspection
- Review alternate entrance
- Request more evidence
- Close if out of scope

## Required UI Block
### Why This Case Matters
- Public service entrance affected
- Assistance required during visit
- Recent evidence updated place state
- AI confidence: Moderate
- Suggested action: Request inspection

---

# Component-Level Plan

# Public Flow

## Screen: Place Detail
### Add / strengthen
- pulse label
- freshness wording
- clearer distinction between state and pulse
- “recently refreshed” or “reliable, aging” where appropriate

## Screen: Add Evidence
### Add
- AI Guidance Card
- Evidence Readiness card
- Confidence explanation block
- “Add another photo” action
- “Continue anyway” action

## Screen: AI Result / Review Packet
### Update
- institution-ready summary
- evidence readiness
- confidence explanation
- missing evidence summary if still partial

## Screen: Submission Result
### Update
- show before/after place state
- show pulse update
- show that the evidence is now in review / institution-ready
- reinforce that the user updated the place’s living knowledge

# Institutional Flow

## Screen: LGU Dashboard
### Add / strengthen
- clearer priority badge
- better ordering by institutional relevance if already possible
- summary explaining why a case is important

## Screen: Case Detail
### Add
- “Why This Case Matters” block
- evidence readiness
- confidence explanation
- pulse / freshness context
- suggested next action

---

# Data / Domain Changes

## Domain additions
These are conceptual additions only; implementation can be minimal.

### EvidenceReadiness enum
- draft
- almostReady
- institutionReady

### ConfidenceLevel enum
- low
- moderate
- high

### AIGuidance model
Suggested structure:
- observed: list[string]
- missing: list[string]
- confidenceLevel
- confidenceExplanation
- evidenceReadiness
- nextBestAction
- institutionReady: bool

### PriorityExplanation model
Suggested structure:
- whyThisMatters: list[string]
- whyNow: list[string]
- suggestedNextAction: string

---

# Acceptance Criteria

## AI Evidence Coaching
- After user adds initial evidence, AI provides guidance before submission
- AI requests a single next-best evidence improvement
- User can add more evidence and see updated output
- Confidence updates visibly
- Evidence Readiness updates visibly
- AI can mark evidence as institution-ready

## Place Pulse Visibility
- Place Detail clearly distinguishes state from freshness / pulse
- Aging knowledge is visually different from reliable current knowledge
- Unknown is clearly represented
- Recently refreshed and under review are clearly represented in the demo path

## Institutional Priority Explanation
- Every case shown in the demo includes a visible explanation of why it matters
- LGU can quickly understand urgency, public impact, and next action
- Case detail feels like decision support, not just report review

---

# Implementation Notes

## For hackathon discipline
- Prefer simple deterministic rules over complex scoring
- Prefer visible behavior over internal sophistication
- Prefer demo clarity over technical perfection
- Mock AI coaching first if necessary, then connect Gemini
- Reuse existing domain models where possible
- Avoid rewriting stable flows

## Suggested readiness rules
### Draft
- no photo and weak note
- or photo present but major evidence missing

### Almost Ready
- core issue visible
- at least one key missing context remains

### Institution Ready
- evidence plus user confirmation sufficiently support the issue for review

## Suggested confidence rules
### Low
- issue may exist but current evidence is incomplete

### Moderate
- issue is plausible and supported, but key uncertainty remains

### High
- evidence and lived experience strongly align

---

# Sprint Priority

## Priority 1
Place Pulse Visibility

## Priority 2
Institutional Priority Explanation

## Priority 3
AI Evidence Coaching + Evidence Readiness + Confidence labels

Reason:
- pulse visibility is lowest risk and highest product-clarity gain
- institutional priority explanation is high-value and low complexity
- AI coaching is the most differentiated, but slightly more complex, so it should build on the strengthened UI and data framing

---

# Final Outcome

After this sprint, AccessPulse should feel like:
- a system where accessibility truth is alive
- a platform where AI helps people build evidence institutions can use
- a civic tool that helps institutions know what deserves attention and why

That is the goal of this implementation plan.
