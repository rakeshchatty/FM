---
mode: agent
description: FM Salesforce gated code review (scope -> automated -> deep review -> findings -> fixes).
---

# salesforce-fm-review

Run the gated code-review workflow for the **FM** Salesforce project.

## 0. Project detection (first)

Confirm FM, same as `salesforce-fm-develop`:
1. `sfdx-project.json` or `force-app/main/default/` exists.
2. Git remote contains `rakeshchatty/FM` (or the user confirms).
3. `.myit/instructions/salesforce-fm/` exists.

If not an SFDX project / not FM, STOP and say so. If ambiguous, ask.

Set `ARTIFACT_DIRECTORY` = `docs/artifacts`, `MR_TARGET` = `main`,
`DEV_SANDBOX_ALIAS` = ask the developer only if fixes are applied and need deploying.

## 1. Load the base workflow

Follow `.myit/workflow/review.workflow.md` gate-for-gate. Also load and obey:
- `.myit/instructions/salesforce-fm/architecture.instructions.md` — the domain checklist
  is its **Code Review Standards** section
- `.myit/instructions/salesforce-fm/guardrails.instructions.md`
- `.myit/instructions/salesforce-fm/tools.instructions.md`
- `.myit/skills/salesforce-security-review.md` (for the security portion of Gate R3)

Read-only until Gate R5. Honor every STOP.

---

## Gate R1 additions — Scope & Context

- Default target if unspecified: current branch diff vs. `main`.
- If a `<TICKET-ID>` is known, read `docs/artifacts/<TICKET-ID>/` (requirements, specs,
  worklog) for acceptance criteria and design intent.
- Classify changed files: Apex classes / triggers / LWC / Aura / metadata / tests / docs.

**STOP — human confirms scope.**

---

## Gate R2 additions — Automated Pass

Run and record (do not fix):
- `sf scanner run --target force-app/ --format table`
- `sf apex run test --target-org <sandbox> --code-coverage --result-format human`
  (only if a sandbox is already authorized and the human okays running it; otherwise note
  it as not run)
- `npx jest --coverage` if LWC changed
- Local Sonar if configured

Report blocker / critical / high items and coverage vs. targets (Apex 85%, LWC 80%).

---

## Gate R3 additions — Manual Deep Review

Apply the Code Review Standards checklist in `architecture.instructions.md` in full. Trace each changed unit end-to-end from its
entry point (trigger / REST resource / controller / LWC). FM-specific things to check
hard:
- Layered pattern respected; no fflib architecture in implementation code.
- One trigger per object; no logic in the trigger body; recursion guard in the handler.
- No SOQL/DML/async in loops; 200-record safe; SOQL centralized in a selector.
- `WITH USER_MODE` / `SECURITY_ENFORCED`; CRUD/FLS before DML; bind variables (no
  injection); `with sharing` default.
- `ExceptionService.registerException(...)` + `commitWork()`; no `System.debug` logging.
- New REST version = new `_V[N]` class; existing version untouched.
- Class names <= 36 chars; API version >= 60.0; `{Class}Test` present and updated.
- Tests: `Assert` class with messages; happy/bulk/edge/negative/regression; mocks via
  `@TestVisible private static`; no real callouts.
- Inner Error/Exception classes in Models are `virtual`.
- No hardcoded IDs.

Verify uncertain platform behavior in a sandbox or against official Salesforce docs.

---

## Gate R4 additions — Findings Report

Format each finding:
`High/Medium/Low | file:line | issue | failure scenario | suggested fix`

Grouped by area, plus a "checked and clean" list. Save to
`docs/artifacts/<TICKET-ID>/review-findings.md` (or a path the human gives).

**STOP — human decides what to fix.**

---

## Gate R5 additions — Apply Fixes (optional)

One approved finding at a time: minimal change + test update + show diff + **STOP for
approval**. Follow FM Apex rules while editing. Do not touch findings the human didn't
select. Do not commit or push.

---

## Gate R6 additions — Re-verify + Summary

- Re-run Gate R2 checks.
- If implementation code changed and the human wants it deployed: `sf org list` ->
  confirm sandbox -> announce and run
  `sf project deploy start --target-org <DEV_SANDBOX_ALIAS>` ->
  `sf apex run test --target-org <DEV_SANDBOX_ALIAS> --code-coverage`.
- Summary: findings raised / fixed / deferred (with reasons) / residual risk.

**STOP — human approves.** Any commit or PR update follows
the repository's Git workflow and only on explicit approval.
