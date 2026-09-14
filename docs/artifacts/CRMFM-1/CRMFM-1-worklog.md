<!--
Traceability
Ticket: CRMFM-1
Artifact: CRMFM-1-worklog.md
Purpose: context persistence across sessions — read this FIRST on resume.
Last updated: 2026-09-13 00:00
-->

# Worklog — CRMFM-1: Create Invoice Dashboard LWC with Date, Customer, and CSV Export Filters

## Current state
- **Active gate:** Gate 6 — Verification (environment setup blocked)
- **Next action:** Install/configure local Jest tooling and authorize the approved non-production sandbox alias fm-ai, then rerun verification.
- **Blocked on:** nothing (proceeding with exploration)

## Story type
- [x] Code change  [ ] Analysis / spike only

## Key facts (do not re-derive)
- Chosen approach: Option A — service-backed dashboard DTO with thin controller, reusable util,
  lazy invoice-line loading, and client-side CSV export
- Dev sandbox alias: not yet provided (asked at Pre-Gate 5)
- Branch: not yet created
- Artifact directory: `docs/artifacts/CRMFM-1/`
- Ticket fetched from Jira via `.myit/tools/Get-JiraIssue.ps1` on 2026-09-13 (issue status:
  "To Do", type: Task).

## Gate log
| Gate | Status | Date | Notes / decisions |
|---|---|---|---|
| 1 Requirements | APPROVED | 2026-09-13 | requirements.md created from Jira CRMFM-1; 5 open questions accepted with stated assumptions |
| 2 Exploration + Design | APPROVED | 2026-09-13 | Option A selected; exploration.md and technical-design.md approved |
| 3 Specs | APPROVED | 2026-09-13 | specs.md approved |
| 4 Branch | APPROVED | 2026-09-13 | Created and switched to feature/CRMFM-1-invoice-dashboard |
| Pre-5 Retrieve | APPROVED | 2026-09-13 | Developer confirmed successful retrieve against fm-ai |
| 5 Implementation | APPROVED | 2026-09-13 | Step 5 LWC implemented and approved |
| 5/6 Tests | APPROVED | 2026-09-13 | LWC diagnostics pass; Jest tooling missing; Apex execution pending deployment |
| 6 Verification | BLOCKED | 2026-09-13 | Jest cannot parse LWC imports without Salesforce Jest/Babel configuration; fm-ai absent from authorized org list; deployment not attempted |
| 7 Commit + PR | | | artifacts committed: no |

## Implementation steps
| # | Component | Implemented | Tested | Approved |
|---|---|---|---|---|
| 1 | Dashboard metadata and access | Yes | Yes | Yes |
| 2 | Invoice dashboard DTO model | Yes | No | No |
| 3 | Invoice dashboard query and date utility | Yes | No | No |
| 4 | Apex dashboard controller and exception adapter | Yes | No | No |
| 5 | Invoice Dashboard LWC and CSV export | Yes | No | No |

## Decisions & rationale
- 2026-09-13 — Fetched CRMFM-1 from Jira since neither worklog nor requirements.md existed
  locally — per session-start rules in the develop prompt.
- 2026-09-13 — Gate 2 exploration completed; Option A selected and exploration.md saved.
- 2026-09-13 — Technical design drafted for Option A; pending developer approval.
- 2026-09-13 — Technical design approved; Gate 3 specs.md drafted with implementation contracts and test scenarios.
- 2026-09-13 — Gate 3 specs approved; proposed branch feature/CRMFM-1-invoice-dashboard.
- 2026-09-13 — Gate 4 branch approved; created and switched to feature/CRMFM-1-invoice-dashboard.
- 2026-09-13 — Pre-Gate 5 retrieve confirmed complete against dev sandbox fm-ai; Gate 5 started.
- 2026-09-13 — Step 1 metadata/access implemented: custom permission, permission set, and LWC exposure metadata; focused diagnostics passed.
- 2026-09-13 — Step 1 approved; metadata diagnostics recorded as its applicable validation; Step 2 DTO model proposed.
- 2026-09-13 — Step 2 DTO model and tests implemented; production diagnostics pass. Apex test execution is pending deployment; test naming lint conflicts with the workflow-required snake_case convention.
- 2026-09-13 — Step 3 utility and tests implemented; production utility diagnostics pass. Test naming lint conflict remains per workflow-required snake_case convention; Apex execution is pending deployment.
- 2026-09-13 — Step 4 controller and ExceptionService adapter implemented with tests; production diagnostics pass. Apex execution is pending deployment.
- 2026-09-13 — Step 5 LWC, CSV export, and Jest tests implemented; focused LWC diagnostics pass. Jest execution is pending project test tooling.
- 2026-09-13 — Gate 6 checks attempted: Jest unavailable without installation; authorized org list contained no fm-ai entry. Deployment and Apex tests were not attempted.
- 2026-09-13 — Gate 6 retry: Jest reached the dashboard test but failed on `import` parsing because LWC Jest/Babel configuration is absent; `sf org list` again returned no authorized orgs. Deployment remained unattempted.

## Deviations from design
- None yet.

## Open questions / follow-ups
- [ ] Default "current reporting period" definition (see requirements.md open questions)
- [ ] CSV export mechanism: client-side vs. Apex-generated
- [ ] Expected invoice/line data volume for governor-limit sizing
- [ ] Target Lightning App/navigation for the new tab
- [ ] Eager vs. lazy loading of invoice-line detail
