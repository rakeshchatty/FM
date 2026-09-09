---
mode: agent
description: FM Salesforce gated development workflow (Gates 1-7, worklog, analysis flow).
---

# salesforce-fm-develop

Run the gated development workflow for the **FM** Salesforce project.

## 0. Project detection (do this first, before Gate 1)

Confirm you are in the FM project. Check, in order:
1. `sfdx-project.json` or a `force-app/` directory with `main/default/` exists.
2. Git remote contains `rakeshchatty/FM` (or the user confirms this is FM).
3. `.myit/instructions/salesforce-fm/` exists.

If this is **not** an SFDX project or not FM, STOP and tell the user this prompt is
FM-specific. If detection is ambiguous, ask the user to confirm before proceeding.

Set:
- `ARTIFACT_DIRECTORY` = `docs/artifacts`
- `DEV_SANDBOX_ALIAS` = ask the developer for their FM dev sandbox alias at Pre-Gate 5
  (do not assume one).
- `PR_BASE` = `main` (GitHub — `github.com/rakeshchatty/FM`)

## 1. Load the base workflow

Follow `.myit/workflow/develop.workflow.md` gate-for-gate. Everything in it applies. The
sections below are **FM additions** layered onto the matching gates. Also load and obey:
- `.myit/instructions/salesforce-fm/guardrails.instructions.md`
- `.myit/instructions/salesforce-fm/architecture.instructions.md`
- `.myit/instructions/salesforce-fm/tools.instructions.md`

## 2. Session start

`ls docs/artifacts/<TICKET-ID>/<TICKET-ID>-worklog.md`. If it exists, read it first and
resume from the recorded gate — do not re-run completed gates.

---

## Gate 1 additions — Requirements & Scope

Capture these FM NFRs in `requirements.md`:
- Salesforce objects affected (standard vs custom).
- Bulk requirements: trigger context, batch size, expected volume.
- Governor-limit budget: max SOQL, DML, CPU time, callouts.
- Sharing model: `with sharing` vs `without sharing` (+ justification).
- LWC requirements (if UI changes).
- External integration needs: Named Credentials, Platform Events, callouts.
- REST API versioning considerations (existing `_V2`, `_V8`, `_V[N]` patterns).

Reminder: Gate 1 = ticket understanding only. NO codebase access, NO git, NO file
searches. Save to `docs/artifacts/<TICKET-ID>/requirements.md`. **STOP.**

---

## Gate 2 additions — Exploration + Design

### Exploration focus
1. Existing REST resources / handlers / triggers for the affected domain — read the
   actual classes.
2. Existing utils, builders, models for the domain (pragmatic layered pattern).
3. Custom Metadata Types & Custom Settings relevant to the feature.
4. Named Credentials for any callout requirement.
5. Reusable / extensible LWC components.
6. Test-data factories and testing patterns for the affected objects.
7. Existing `_V[N]` classes — understand the versioning approach.

**Architecture note:** FM uses `RestResource -> Util/Handler -> Builder/Model`. Do NOT
introduce fflib conventions (interfaces, base classes, Application factory, Unit of Work)
into implementation code. `fflib-apex-mocks` is used **only in test classes**.

### Comparison matrix columns
| Criterion | Option A | Option B |
|---|---|---|
| Effort | S/M/L | S/M/L |
| Governor-limit impact | SOQL/DML count | ... |
| Bulkification complexity | Low/Med/High | ... |
| Versioning impact | New `_V[N]` / modify existing | ... |
| Aligns with FM patterns | Yes/Partial/No | ... |
| Reuses existing code | what | ... |

### Technical design additions
Include: Governor Limit Analysis, Bulk Operation Strategy, Sharing Model Impact, Metadata
Dependencies, REST API Versioning Strategy. Mermaid diagrams: architecture, sequence, LWC
component hierarchy. Error logging pattern: `ExceptionService.registerException` +
`ExceptionService.commitWork()`.

**Implementation order:**
`Metadata -> Models/Builders -> Utils -> TriggerHandlers -> RestResources -> Controllers -> LWC -> Tests`

Do not forget the MANDATORY exploration.md save question. **STOP at each marker.**

---

## Gate 3 additions — Specifications

Per spec, also define: governor-limit budget (SOQL/DML/CPU) and the FM implementation
order below. Save to `docs/artifacts/<TICKET-ID>/specs.md`. **STOP.**

### FM implementation order per spec
1. Custom Objects / Fields (schema)
2. Custom Metadata Types (configuration)
3. Permission Sets (access)
4. Apex Models / DTOs (`{Domain}Model`, versioned `{Domain}ModelV{N}`; inner
   error/exception classes `virtual`)
5. Apex Builders (`{Domain}Builder`, `{Domain}ModelBuilder`)
6. Apex Utils (`{Domain}Util` — reusable business logic)
7. Apex Trigger Handlers (`{Object}TriggerHandler`)
8. Apex Triggers (one per object, delegates to handler)
9. Apex REST Resources (`{Domain}RestResource`, versioned `{Domain}RestResource_V{N}`)
10. Apex Controllers (thin, for LWC)
11. Lightning Web Components
12. Apex test classes (one per production class, `{Class}Test`)
13. LWC Jest tests

---

## Gate 4 additions — Branch

Branch name: `feature/<TICKET-ID>-<short-description>` (or `bugfix/...`). **STOP — human
approves.**

---

## Pre-Gate 5 additions — Retrieve

Ask the developer for `DEV_SANDBOX_ALIAS`, then prompt:

> ### RETRIEVE LATEST CODE
> ```
> sf project retrieve start --target-org <DEV_SANDBOX_ALIAS>
> ```
> Confirm when the retrieve is complete and successful.

**STOP** until confirmed. Help resolve conflicts before continuing.

---

## Gate 5 additions — Implementation

Follow the FM implementation order. FM pragmatic layered patterns only
(`RestResource -> Util/Handler -> Builder/Model`, versioning via `_V[N]`). No fflib base
classes / interfaces / Application factory / UoW in implementation code. Approve each
step, then write its tests immediately.

FM Apex rules to enforce while coding (see `architecture.instructions.md`):
- Class names <= 36 chars; API version >= 60.0.
- `with sharing` by default; document any `without sharing`.
- Bulkify; no SOQL/DML in loops; no hardcoded IDs (use Custom Metadata / Labels).
- Error logging via `ExceptionService.registerException(ex, 'Class.method')` +
  `ExceptionService.commitWork()` — never `System.debug`.
- New REST version = new `_V[N]` class; never mutate an existing version.
- Inner Error/Exception classes in Models must be `virtual`.

---

## Gate 5/6 additions — Tests per step

Per unit:

> TEST FOR: `<ClassName>`
> File: `force-app/main/default/classes/<ClassName>Test.cls`
> Testing: `<behaviors>`
> Coverage target: 85%+ (aim 95%)
> Scenarios: happy path / bulk (200) / edge / negative / regression

Apex test rules:
- `fflib-apex-mocks` for dependency isolation; mock injection via `@TestVisible private
  static` fields; mock vars lowercase `mocks`.
- Method naming `should_<behavior>[_when_<condition>]` (snake_case).
- `Assert` class with a descriptive message on **every** assertion.
- `@TestSetup` / data factory; realistic field values; bulk (200+) in trigger context.
- Mock all external services — no real callouts.

LWC Jest (if LWC implemented): render, `@api` changes, interactions, wire success + error,
empty & loading states, mocked imperative Apex. Coverage 80%+.

**STOP — human approves tests** before the next step.

---

## Gate 6 additions — Verification (deploy to FM dev sandbox — mandatory)

1. Local: `npx jest --coverage`; `sf scanner run --target force-app/ --format table`;
   local Sonar.
2. `sf org list` -> confirm sandbox. Then tell the developer:
   > Deploying to dev sandbox now. Running:
   > `sf project deploy start --target-org <DEV_SANDBOX_ALIAS>`
3. `sf apex run test --target-org <DEV_SANDBOX_ALIAS> --code-coverage --result-format human`
4. Verify the feature in the org against the acceptance criteria; ask about manual setup.
5. Fix, redeploy, re-verify.

**Pass criteria**

| Gate | Criteria |
|---|---|
| Apex tests | all pass, 85%+ coverage |
| LWC tests | all pass, 80%+ coverage |
| Static analysis | no critical / high |
| Sonar (local) | no blocker / critical |
| Class naming | all names <= 36 chars |
| Deploy to dev | successful |
| Org verification | feature works as expected |

If you did not deploy to the dev sandbox, you cannot proceed. **STOP — human approves.**

---

## Gate 7 additions — Commit + Pull Request

### Part A: artifacts FIRST (automatic — do not ask)
```
ls docs/artifacts/<TICKET-ID>/
git add docs/artifacts/<TICKET-ID>/
git commit -m "docs(<TICKET-ID>): add design artifacts"
```
Then implementation (`feat(<TICKET-ID>): ...`), then tests (`test(<TICKET-ID>): ...`).
Analysis-only: `git commit -m "docs(<TICKET-ID>): add analysis findings"` is the sole
deliverable.

**SELF-CHECK:** `git log --oneline -5` must show `docs(<TICKET-ID>): add design
artifacts`. If not, commit now.

### Part B: Pull Request (GitHub)
- Title: `<type>(<TICKET-ID>): <summary>`
- Base branch: `main`
- Description: what / why / testing / commit list, plus:
  ```
  ## Artifacts
  See `docs/artifacts/<TICKET-ID>/` for design documents and analysis.
  ```
- Use `.github/pull_request_template.md` if present.
- Reviewer(s): confirm with the developer / team.
- Open with `gh pr create` only after the human approves; never push without approval.

Commit type examples:
`feat(CRME-1234): add applicant channel controller` /
`fix(CRME-1234): resolve null pointer in ApplicantUtil` /
`docs(CRME-1234): add design artifacts` /
`test(CRME-1234): add bulk tests for CreatorTriggerHandler`

**STOP — human approves the PR.** Do not push or open the PR without approval.
