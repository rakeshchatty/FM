<!--
Traceability
Ticket: CRMFM-6
Artifact: CRMFM-6-worklog.md
Purpose: context persistence across sessions — read this FIRST on resume.
Last updated: 2026-09-27
-->

# Worklog — CRMFM-6: Recurring Order discount validation and defaulting

## Current state
- **Active gate:** Gate 8 — Release Document
- **Next action:** Update the maintained release Word document and obtain approval before Gate 9 communications.
- **Blocked on:** None; developer confirmed manual deployment and acceptance verification in `fm-ai`.

## Story type
- [x] Code change  [ ] Analysis / spike only

## Key facts (do not re-derive)
- Jira URL: https://rakeshchatty.atlassian.net/browse/CRMFM-6
- Chosen approach: Option A — existing field default plus declarative validation rule
- Dev sandbox alias: `fm-ai`
- Branch: `feature/CRMFM-6-recurring-discount-validation`
- Artifact directory: `docs/artifacts/CRMFM-6/`
- Gate 1 requirements: Approved by developer on 2026-09-27

## Gate log
| Gate | Status | Date | Notes / decisions |
|---|---|---|---|
| 1 Requirements | APPROVED | 2026-09-27 | Jira description used as summary; user-created defaulting; no integrations or REST changes; post-deployment candidate-reporting script required |
| 2 Exploration + Design | APPROVED | 2026-09-27 | Option A selected; exploration.md saved; technical-design.md approved by developer |
| 3 Specs | APPROVED | 2026-09-27 | Specifications approved by developer |
| 4 Branch | APPROVED | 2026-09-27 | Created and switched to `feature/CRMFM-6-recurring-discount-validation` |
| Pre-5 Retrieve | COMPLETE | 2026-09-27 | Developer confirmed successful retrieve from `fm-ai` |
| 5 Implementation | APPROVED | 2026-09-27 | Added validation rule, focused tests, and read-only candidate report |
| 5/6 Tests | APPROVED | 2026-09-27 | Local metadata/consistency checks passed; sandbox test pending |
| 6 Verification | APPROVED | 2026-09-27 | Developer manually deployed and checked acceptance criteria in `fm-ai`; scanner step removed from workflow |
| 7 Commit + PR | APPROVED | 2026-09-27 | PR [#3](https://github.com/rakeshchatty/FM/pull/3); artifacts `4e98b8e`; implementation `c4c9b16`; tests `098852b`; cleanup `e7cdf0c` |
| 8 Release Document | IN PROGRESS | 2026-09-27 | |
| 9 Jira + Business Communication | | | |

## Implementation steps
| # | Component | Implemented | Tested | Approved |
|---|---|---|---|---|
| 1 | Gate 2 exploration and selected Option A | Complete | Pending | Complete |
| 2 | `RequirePriceOrDiscount` validation rule | Complete | Metadata parse passed | Complete |
| 3 | Recurring validation/default/bulk tests | Complete | Sandbox test pending | Complete |
| 4 | Read-only post-deployment candidate report | Complete | Not applicable | Complete |
| 5 | `manifest/CRMFM-6-package.xml` | Complete | XML validation passed | Complete |

## Decisions & rationale
- 2026-09-27 — Gate 1 approved — requirements are sufficiently defined to inspect the existing Recurring Order implementation.
- 2026-09-27 — Gate 2 approach selected — use the existing `Discount_to_Apply__c` default and add a declarative both-blank validation rule; retain `RestrictDiscountToApply`.
- 2026-09-27 — Gate 2 design approved — proceed to executable specifications for Option A.
- 2026-09-27 — Canonical Gate 2 artifact filename confirmed as `technical-design.md`.
- 2026-09-27 — Gate 3 specifications approved — proceed to Gate 4 branch approval.
- 2026-09-27 — Gate 4 branch approved — created and switched to `feature/CRMFM-6-recurring-discount-validation`.
- 2026-09-27 — Pre-Gate 5 retrieve confirmed — latest metadata retrieved from developer sandbox `fm-ai`.
- 2026-09-27 — Gate 5 implementation — added the both-blank declarative validation rule; retained the existing both-populated rule.
- 2026-09-27 — Gate 5 implementation — added single-value, defaulting, invalid-combination, and 200-record bulk test coverage.
- 2026-09-27 — Gate 5 implementation — added `post-deployment-report.md` with a read-only candidate query; no remediation is included.
- 2026-09-27 — Gate 5 and Gate 5/6 approvals received — proceed to Gate 6 manifest review.
- 2026-09-27 — Pre-Gate 6 — generated a source-scoped manifest containing only `RecurringTest` and `Recurrings__c.RequirePriceOrDiscount`.
- 2026-09-27 — Gate 6 verification approved — developer confirmed manual deployment and acceptance-criteria verification in `fm-ai`.
- 2026-09-27 — Gate 7 approved — committed artifacts (`4e98b8e`), implementation (`c4c9b16`), and tests (`098852b`).
- 2026-09-27 — Gate 7 PR opened — [FM pull request #3](https://github.com/rakeshchatty/FM/pull/3) targets `main`.

## Deviations from design
- None yet.

## Open questions / follow-ups
- [x] Confirm exact Recurring Order object API name: `Recurrings__c`.
- [x] Save Gate 2 exploration artifact as `exploration.md`.
- [x] Select the Gate 2 implementation approach: Option A.
- [ ] Confirm whether a separate data-fix story is required; deliver a read-only candidate-reporting script, not automatic remediation.
- [x] Confirm concrete bulk volume during Gate 2/3.
- [x] Confirm exact validation error wording during Gate 2.
- [x] Obtain dev sandbox alias at Pre-Gate 5.
