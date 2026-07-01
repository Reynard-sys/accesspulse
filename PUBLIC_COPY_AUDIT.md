# Public Copy Audit

Milestone 1 mapping decision:

- Public place detail, nearby cards, and list tiles currently derive state copy from the private `DimensionStateValue.label` extension in `lib/features/public/public_flow.dart`.
- Institutional screens use their own private labels in `lib/features/institution/institution_flow.dart`; public copy changes should stay in the public feature layer so institutional workflow wording remains unchanged.
- Public remediation wording can be derived deterministically from the current `DimensionStateRecord` plus the latest `AccessCase` for the place dimension.
- Public issue summary should use the latest case's `barrierSignalId` when available, then fall back to case/state lifecycle copy and the existing memory chain.
