# AccessPulse Ramp Slope Capture — Updated Implementation Plan

## Purpose

Add an optional **Ramp Slope Capture** step inside the existing ramp-related reporting flow.

This feature strengthens ramp-related evidence by capturing an **estimated incline angle** from the user’s phone sensors and attaching it to the report as structured evidence.

This feature is an **evidence assist**, not a compliance verdict.

It must never claim to prove a legal violation.

---

## Product Goal

When a user reports a ramp-related issue, AccessPulse should optionally allow them to:

1. place their phone flat on the ramp
2. keep it still for a few seconds
3. capture an estimated angle
4. attach that measurement to the report
5. surface the measurement in the AI evidence summary and institutional case detail

The result should make the report stronger without changing the core user flow.

---

## Final Measurement Stack

This section is the implementation source of truth.

### Client
- **Flutter**

### Sensor Package
- **`sensors_plus`**

### Primary Measurement Signal
- **accelerometer / gravity-based tilt estimation**

### Secondary Stability Signal
- **gyroscope-based movement detection**
- **variance over the capture window**

### Data Storage
- **Supabase**

### AI Usage
- **Gemini is NOT used to compute slope**
- Gemini is used only to:
  - reference the captured measurement in the evidence summary
  - explain what the measurement supports
  - preserve uncertainty

### Fallback
- If live sensor capture is unstable, use a **mocked/dev measurement mode** so the end-to-end demo remains intact

---

## Non-Negotiable Product Rules

1. The feature must be framed as **estimated ramp slope**.
2. The system must never say **“violation confirmed.”**
3. The system must communicate uncertainty clearly.
4. The feature must remain optional.
5. The feature must strengthen the existing report flow, not replace it.
6. If measurement quality is poor, the app must say so and allow retry.
7. A photo plus lived experience plus measurement is stronger than any one input alone.
8. Gemini must never be responsible for calculating the angle.
9. The core MVP flow must remain stable even if this feature is mocked in development.

---

## User Experience Summary

### Trigger
The feature appears only when the user selects a ramp-related issue such as:
- ramp too steep
- ramp difficult to use
- ramp unsafe
- wheelchair entrance issue involving ramp

### User Flow
1. User enters report flow.
2. User selects ramp-related issue.
3. App offers optional step: **Measure ramp slope**.
4. User taps start.
5. App shows short instructions:
   - place phone flat on the ramp surface
   - align phone with the direction of travel
   - keep it still for a few seconds
6. App reads motion sensor data.
7. App checks stability.
8. If stable enough, app records:
   - estimated angle
   - quality/confidence
   - duration
   - timestamp
9. App shows result:
   - estimated incline captured
   - quality level
   - option to retry
10. User continues with normal report submission.
11. Measurement is attached to the report and visible in downstream views.

---

## UX Copy

### Entry Point
**Optional: Measure ramp slope**

Add an estimated incline reading to strengthen this report.

### Instructions
Place your phone flat on the ramp surface and point it in the direction someone would move up or down the ramp.

Hold it still for a few seconds.

### Success State
**Ramp slope captured**

Estimated angle: **{{angle}}°**

Quality: **{{quality}}**

This measurement will be attached to your report.

### Quality Labels
- High stability
- Moderate stability
- Low stability

### Low Quality Warning
We captured a reading, but the phone moved too much to trust it strongly.

You can retry for a better result.

### Failure State
We could not capture a stable ramp reading.

Please place your phone flat on the ramp and try again.

### Important Note
This is an estimated field measurement to support review. Official verification may still be required.

---

## Measurement Logic

## Goal
Estimate the tilt angle of the phone relative to gravity while the phone is resting on the ramp.

### Assumption
If the phone is placed flat on the ramp and aligned with the slope direction, the phone’s tilt relative to gravity can approximate the ramp angle.

### Sensor Inputs
Use:
- accelerometer stream
- gyroscope stream
- gravity-derived tilt estimation from accelerometer readings

### Capture Method
1. Start reading sensor streams
2. Ask user to hold device still for 3–5 seconds
3. Sample sensor values at fixed intervals
4. Compute tilt estimate from accelerometer/gravity
5. Compute movement/stability using gyroscope + variance
6. Accept reading only if stability passes threshold
7. Return:
   - estimated angle in degrees
   - quality score
   - quality label
   - capture duration
   - sample count

### Hackathon-Safe Rule
Do not build advanced calibration or multi-axis correction.

Use:
- stable sample averaging
- simple tilt estimation
- variance-based quality

This is sufficient for an evidence-assist feature.

### Suggested Output Model
- `estimated_angle_degrees`
- `quality_score` (0–100)
- `quality_label` (`high`, `moderate`, `low`)
- `capture_duration_ms`
- `sample_count`
- `measurement_status`

---

## Accuracy and Risk Model

### Known Risks
- User may place phone incorrectly
- Phone case may affect angle
- Ramp surface may be uneven
- User may align phone sideways
- Device may move during capture
- Some ramps may have non-uniform slope
- Sensor quality varies by device

### Product Response
Because of these risks:
- result must always be labeled **estimated**
- confidence must reflect stability, not legal certainty
- UI must recommend retry when unstable
- AI must treat measurement as one evidence input, not proof

### Forbidden Claims
- “This ramp violates the law.”
- “This proves non-compliance.”
- “This reading is exact.”
- “This confirms the ramp is illegal.”

### Allowed Claims
- “Estimated ramp angle captured”
- “Reading quality is moderate”
- “This strengthens the report”
- “Official review may still be required”

---

## Data Model Additions

## `ramp_measurements`
Suggested fields:
- `id`
- `report_id` or `observation_id`
- `place_id`
- `user_id`
- `estimated_angle_degrees`
- `quality_score`
- `quality_label`
- `capture_duration_ms`
- `sample_count`
- `status`
- `created_at`

Optional future fields:
- `orientation_axis`
- `raw_sensor_summary`
- `retry_count`
- `device_model`
- `notes`

### Status Values
- `captured`
- `low_quality`
- `failed`
- `discarded`

---

## API / Service Layer Changes

### Create Measurement
`POST /ramp-measurements`

Input:
- place_id
- report_id (optional until report finalization)
- angle
- quality_score
- quality_label
- capture_duration_ms
- sample_count

Output:
- stored measurement object

### Attach Measurement to Report
If report is created after measurement, allow report creation flow to reference the measurement ID.

### Read Measurement in Case Detail
Case detail should display:
- estimated angle
- quality label
- captured at
- reviewer note that this is user-field evidence

---

## AI Integration

Gemini does not calculate the slope.

It only interprets the measurement in context.

### AI Input
- user text
- ramp photo(s)
- lived experience answers
- estimated angle
- measurement quality label

### AI Output Example
Observed:
- user reported difficulty using ramp
- photo shows visible ramp
- estimated incline captured at 14.8°
- measurement quality moderate

Possible interpretation:
- reported ramp usability concern is supported by both lived experience and measured incline estimate

Missing:
- official verification
- full side-view context if image is incomplete

Recommended next step:
- mark for review / inspection

### Allowed AI Language
- “Estimated incline reading supports the reported concern.”
- “This measurement strengthens the evidence.”
- “The reading appears consistent with a steep ramp concern.”

### Forbidden AI Language
- “This confirms the ramp violates BP 344.”
- “This proves non-compliance.”

---

## Institutional View

In LGU / case view, show a compact evidence block:

### Ramp Measurement
- Estimated angle: `14.8°`
- Capture quality: `Moderate`
- Source: `Citizen field capture`
- Note: `Estimated reading provided to support review; official measurement may still be required.`

---

## Definition of Done

This feature is complete only when:

- user can trigger ramp slope capture from ramp-related report flow
- instructions are clear and short
- `sensors_plus` is wired correctly
- accelerometer/gravity tilt estimation works
- gyroscope / variance stability check works
- unstable readings are detected
- user sees estimated angle and quality label
- user can retry
- measurement attaches to report
- measurement persists in Supabase
- measurement appears in institutional case detail
- Gemini output references the measurement appropriately
- no false legal claims appear in UI or AI text
- no blocking runtime or sensor errors occur
- fallback mock mode exists if live sensor capture is unavailable

---

# DEVELOPMENT ORDER (MUST FOLLOW)

Do NOT implement everything at once.

Complete each milestone before moving to the next.

If a milestone is incomplete, do not start the next one.

---

## Milestone 1 — Planning and Codebase Review

Implement only:
- inspect repository
- identify current ramp report flow
- identify where report state is stored
- identify current AI summary integration point
- identify current case detail rendering point
- identify current Flutter plugin footprint
- decide exact file/module insertion points

Output:
- `RAMP_SLOPE_IMPLEMENTATION_NOTES.md`

Stop.

### Commit
`feat(ramp): complete milestone 1 planning`

---

## Milestone 2 — UX Shell (Mocked)

Implement only:
- optional “Measure ramp slope” entry point in ramp-related report flow
- instructions screen
- loading/capture screen
- success state
- retry state
- mocked angle result
- mocked quality label

No real sensor logic.
No persistence.
No Gemini changes.

Stop.

### Definition of Done
- flow is clickable end to end
- no sensor dependency yet
- report flow remains stable

### Commit
`feat(ramp): complete milestone 2 ux shell`

---

## Milestone 3 — Sensor Capture

Implement only:
- `sensors_plus`
- sensor permission/setup if needed
- accelerometer/gravity tilt estimation
- gyroscope-based movement detection
- capture window
- stability / variance logic
- quality label generation
- retry behavior

Do not persist yet.
Do not wire Gemini yet.
Do not change institutional flow yet.

Stop.

### Definition of Done
- angle can be measured on a real device
- unstable motion lowers quality or fails capture
- mocked values are no longer needed in normal mode
- dev fallback still exists

### Commit
`feat(ramp): complete milestone 3 sensor capture`

---

## Milestone 4 — Persistence

Implement only:
- `ramp_measurements` schema / migration
- Supabase insert logic
- association between report and measurement
- measurement retrieval for report review
- local error handling for failed writes

No institutional rendering yet.
No Gemini updates yet.

Stop.

### Definition of Done
- captured measurement saves successfully
- report references measurement correctly
- data can be read back after submission

### Commit
`feat(ramp): complete milestone 4 persistence`

---

## Milestone 5 — Institutional Visibility

Implement only:
- measurement block in case detail
- measurement display in institutional review view
- estimated angle
- quality label
- note explaining this is supporting evidence

Do not modify Gemini yet.

Stop.

### Definition of Done
- reviewer can see measurement in case view
- wording remains non-authoritative
- no broken case detail flow

### Commit
`feat(ramp): complete milestone 5 case visibility`

---

## Milestone 6 — Gemini Integration

Implement only:
- include measurement in Gemini prompt/context
- update structured AI summary to reference measurement
- preserve uncertainty language
- prevent forbidden compliance claims

Stop.

### Definition of Done
- AI response visibly includes measured incline when present
- AI language remains evidence-support only
- no legal overclaiming

### Commit
`feat(ramp): complete milestone 6 gemini integration`

---

## Milestone 7 — Polish and Demo Readiness

Implement only:
- copy refinement
- better error states
- better loading states
- smoother retry flow
- clear before/after review experience
- demo seed path if needed
- fallback mock mode toggle for unstable demo environments

Stop.

### Definition of Done
- feature is understandable in under 10 seconds
- demo can be run reliably
- no console/runtime errors in demo path
- feature strengthens story without destabilizing MVP

### Commit
`feat(ramp): complete milestone 7 polish`

---

## Hackathon Rule

If a feature depends on unfinished backend:
- mock it first

If it depends on AI:
- mock it first

If it depends on Supabase:
- seed it first

If live sensor capture becomes unstable:
- preserve the UX and flow
- use a clearly labeled internal mock/dev mode
- protect the end-to-end demo

A polished end-to-end demo is always preferred over partially completed infrastructure.

---

## Demo Script Moment

During the report flow:

1. User selects ramp issue.
2. App offers **Measure ramp slope**.
3. User places phone on ramp.
4. App captures estimated angle.
5. Result appears:
   - `Estimated angle: 14.8°`
   - `Quality: Moderate`
6. User submits report.
7. Gemini summary includes:
   - lived experience
   - photo evidence
   - measured incline
8. LGU sees stronger institution-grade evidence.

Key narration:
> “AccessPulse doesn’t just collect complaints. It helps ordinary people capture stronger accessibility evidence. Here, the user adds an estimated ramp incline directly from their phone, making the report more concrete for institutional review.”

---

## Implementation Recommendation

Add this feature only if:
- the team can implement sensor capture cleanly
- it does not destabilize the main MVP
- it remains clearly framed as supporting evidence

Do not add it if it will jeopardize the end-to-end story.

The core product thesis remains more important than this feature.

This feature is an evidence amplifier, not the product itself.
