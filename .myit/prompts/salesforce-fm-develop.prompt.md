---
agent: agent
description: FM Salesforce gated development workflow with Jira retrieval, release-document update, and automated Jira-comment posting (Gates 1-9, worklog, analysis flow).
argument-hint: "[Jira issue key or browse URL, for example CRMFM-1]"
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

The ticket argument may be a Jira key such as `CRMFM-1` or a browse URL such as
`https://rakeshchatty.atlassian.net/browse/CRMFM-1`.

1. Normalize the argument to the Jira issue key. If no ticket key or browse URL was
  provided, ask the developer for one before continuing.
2. First check the local worklog:

```powershell
Test-Path docs/artifacts/<TICKET-ID>/worklog.md
```

3. If the worklog exists, read it first and resume from the recorded gate. Do not
  re-run completed gates and do not fetch Jira details again for this session.
4. If the worklog is not found, check whether `docs/artifacts/<TICKET-ID>/requirements.md`
  exists. If it exists, read it as the local source of truth and do not fetch Jira.
5. If neither the worklog nor `requirements.md` exists, fetch the ticket from Jira before
  Gate 1. From the repository root, run the existing read-only helper:

```powershell
pwsh -NoProfile -File .myit/tools/Get-JiraIssue.ps1 -IssueKey <ISSUE-KEY-OR-BROWSE-URL>
```

If `pwsh` is unavailable, use `powershell -NoProfile` with the same arguments.
The helper derives the Jira email from Git `user.email`, reads `.jira-token` only at
runtime, validates and normalizes the issue input, and performs a GET request only.
Never open, print, echo, copy, or paste the token.
6. Use returned Jira details as the sole source for Gate 1 ticket understanding. Record
  the issue key, summary, acceptance criteria, constraints, and explicit out-of-scope
  items in `requirements.md`.
7. If the helper reports a 404, stop and report that the issue is missing or not visible
  to the configured Jira account. Do not proceed with guessed requirements. For other
  errors, stop and report the configuration or request error without exposing secrets.

Jira retrieval is external ticket reading, not codebase exploration. Gate 1 still forbids
repository code access, file searches, and Git operations until the human approves the
requirements.

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
13. LWC Jest tests (if LWC is implemented)

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

At the start of Gate 5, create the directory `manifest/<TICKET-ID>/` and create
`manifest/<TICKET-ID>/package.xml` inside it. Keep this ticket-scoped package file current
as each metadata component is added or changed:
- Include every metadata member that will be deployed for the ticket; use explicit members
  rather than a catch-all wildcard where practical.
- Update the manifest after every implementation and test step.
- Add a valid XML comment block with detailed, ticket-specific pre-deployment and
  post-deployment instructions, including ordering, manual setup, data preparation,
  permissions, and verification. If no pre- or post-deployment action is required, record
  that explicitly in the comment block.

FM Apex rules to enforce while coding (see `architecture.instructions.md`):
- Class names <= 36 chars; API version targets latest (67.0 as of 2026-09).
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

1. Optional local check: when LWC changes are included, run `npx jest --coverage`.
2. Confirm `manifest/<TICKET-ID>/package.xml` is present and current. Run `sf org list` to
  confirm the sandbox, follow the manifest's pre-deployment instructions, then tell the
  developer:
   > Deploying to dev sandbox now. Running:
  > `sf project deploy start --manifest manifest/<TICKET-ID>/package.xml --target-org <DEV_SANDBOX_ALIAS>`
3. `sf apex run test --target-org <DEV_SANDBOX_ALIAS> --code-coverage --result-format human`
4. Follow the manifest's post-deployment instructions, then verify the feature in the org
  against the acceptance criteria.
5. Fix, redeploy, re-verify.

**Pass criteria**

| Gate | Criteria |
|---|---|
| Apex tests | all pass, 85%+ coverage |
| LWC tests, when applicable | all pass, 80%+ coverage |
| Class naming | all names <= 36 chars |
| Deploy to dev | successful |
| Org verification | feature works as expected |

If you did not deploy to the dev sandbox, you cannot proceed. **STOP — human approves.**

---

## Gate 7 additions — Commit + Pull Request

### Part A: single commit per branch (automatic — do not ask)

FM branches carry **exactly one commit**. Never stack separate `docs`/`feat`/`test`
commits on the same branch.

- **First commit on the branch:** stage everything for this unit of work (artifacts,
  implementation, tests) and create one commit:
  ```
  ls docs/artifacts/<TICKET-ID>/
  git add docs/artifacts/<TICKET-ID>/ force-app/ <other changed paths>
  git commit -m "feat(<TICKET-ID>): <summary>"
  ```
  Analysis-only work: `git commit -m "docs(<TICKET-ID>): add analysis findings"` is the
  sole deliverable.
- **Any subsequent change on the same branch** (fixes from review, additional test
  coverage, more artifacts, etc.): stage the new changes and **amend** the existing
  commit instead of creating a new one:
  ```
  git add <changed paths>
  git commit --amend --no-edit
  ```
  Update the commit message with `git commit --amend -m "<type>(<TICKET-ID>): <summary>"`
  only if the summary needs to change to still describe the full contents.
- If the branch was already pushed, amending rewrites history — this requires a
  force-push (`git push --force-with-lease`). Amending/force-pushing a branch you are
  actively developing is authorized by this workflow gate; **never** amend or
  force-push a branch once someone else may have based work on it, and never touch
  `main`.

**SELF-CHECK:** `git log --oneline` must show exactly **one** commit ahead of `main`. If
it shows more than one, amend them down to one before proceeding.

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

---

## Gate 8 additions — Release Document

After Gate 7 is approved, this mandatory update must be performed for every ticket or
subsequent implementation change. Update the existing Word document at
`docs/Release document.docx`. Preserve existing entries, insert a page break, and place
the new entry at the beginning of the document so the newest entry is always on the first
page. Do not append new entries to the end. Add one entry containing:

- **Ticket Number:** `<TICKET-ID>`
- **Title:** `<ticket or implementation title>`
- **Short description:** `<concise implementation summary>`
- A table with exactly these columns: `File name`, `File type`, `New/Modified`.

Add one row for every changed or newly created implementation, test, metadata, and
deployment-manifest file, including `manifest/<TICKET-ID>/package.xml`. Verify the table
against the final diff, confirm the new entry is on the first page, save the document, and
confirm it opens successfully. If the file cannot be opened or is not a valid Word
document, stop and request approval before converting or replacing it.

Amend the existing single branch commit to include the release document; do not create a
second commit. If the PR is already open, update it after the amend. **STOP — human
approves the release-document update.**

---

## Gate 9 additions — Jira Implementation Comment

After Gate 8 approval, compose the detailed implementation comment in memory containing:

- Ticket number, title, and summary of what changed and why.
- Implementation details, including layers, classes, triggers, LWCs, metadata, and key
  behavior.
- Changed files with each file marked `New` or `Modified`.
- Deployment manifest path: `manifest/<TICKET-ID>/package.xml`.
- Pre-deployment and post-deployment instructions, or an explicit `None required`.
- Apex test results, optional LWC Jest results when applicable, sandbox verification, and
  known limitations or follow-up items.

Post the comment automatically after it is composed:

```powershell
$implementationComment = @'
<implementation details from the template above>
'@
pwsh -NoProfile -File .myit/tools/Add-JiraComment.ps1 `
  -IssueKey <TICKET-ID> `
  -CommentText $implementationComment
```

Use `powershell -NoProfile` if `pwsh` is unavailable. The helper reads `.jira-token` only
at runtime and returns the issue key, comment ID, and URL. Never print or expose the token.
The `.myit/tools/Get-JiraIssue.ps1` helper is read-only and must not be used to post
comments. Record the returned comment URL or ID in the worklog. Do not create a comment file
or a second commit for the comment. Gate 9 completes only after the Jira post succeeds.
