# Flow Remediation Audit

## Current status behavior

- `CaseStatus` currently supports `open`, `triaging`, `inspectionRequested`, `verified`, `disputed`, `resolved`, and `closed`.
- Public AI-structured evidence opens a case as `open` and can move the place dimension toward `degraded`.
- LGU actions currently support marking a case as `triaging`, requesting inspection, and closing a case.
- `requestInspection` moves the case to `inspectionRequested`; if the place dimension was `degraded`, the dimension state becomes `underReview`.
- Inspector verification currently handles barrier verification only:
  - `confirmed` moves the case to `verified` and the place state to `officiallyVerifiedDegraded`.
  - `disputed` moves the case to `disputed` while preserving the prior place state.
  - `insufficientEvidence` moves the case back to `triaging` while preserving the prior place state.
- `verified` currently sets `closedAt`, but the case status remains `verified`; there is no remediation request or remediation verification state yet.
- `MemoryEventType.remediationVerified` already exists, but there are no memory event types for remediation requested or remediation verification requested.

## Exact files to change

- `lib/domain/models/accesspulse_models.dart`
  - Add `remediationRequested` and `remediationVerificationRequested` case statuses.
  - Add minimal memory event types for remediation request and remediation verification request.
- `lib/domain/services/dimension_state_service.dart`
  - Add LGU transitions for remediation request and remediation verification request.
  - Extend inspector verification so remediation verification can resolve a case and refresh the place state.
  - Append memory events for each new institutional step.
- `lib/features/institution/institution_flow.dart`
  - Remove `triaging` from the inspector queue filter.
  - Include remediation verification requests in the inspector queue.
  - Add LGU action buttons for remediation request and remediation verification request.
  - Reuse the existing inspector verification screen pattern for remediation confirmation.
  - Add labels/icons/colors for the new statuses and memory event labels.
- `test/domain/dimension_state_service_test.dart`
  - Cover remediation request, remediation verification request, successful remediation confirmation, and failed remediation confirmation.
- `test/institution_flow_test.dart`
  - Cover inspector queue visibility and the improved end-to-end institutional loop.
- `test/widget_test.dart`
  - Update only if visible public copy changes.

## UI cohesion plan

- Keep the existing detail screen structure and action area.
- Add LGU actions into the current `Wrap` that already contains `OutlinedButton.icon`, `FilledButton.icon`, and `TextButton.icon`.
- Use `FilledButton.icon` for the next primary institutional step, matching the current `Request inspection` action.
- Use existing icon/button density, spacing (`spacing: 12`, `runSpacing: 12`), typography, cards, and status-chip patterns.
- Reuse the current inspector verification screen layout, segmented control, note field, and submit button for remediation confirmation with copy adjusted to the case status.
