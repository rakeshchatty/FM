# develop.workflow.md — Base Gated Development Workflow

Project-agnostic. A project prompt (e.g. `salesforce-fm-develop.prompt.md`) loads this
file and layers project-specific gate additions on top.

## Gate flow

```
Instructions received
    |
    v
Gate 1: Requirements & Scope        (NO codebase access)
    | -> saves requirements.md
    | HUMAN APPROVES
    v
Gate 2: Codebase Exploration + Solution Alternatives
    | -> presents 2-3 options with a comparison matrix
    | HUMAN PICKS APPROACH
    | -> MANDATORY: ask whether to save exploration.md
    | -> saves technical-design.md
    | HUMAN APPROVES DESIGN
    v
Gate 3: Technical Specifications
    | -> saves specs.md
    | HUMAN APPROVES SPECS
    v
Gate 4: Git Branch Creation
    | HUMAN APPROVES BRANCH
    v
Pre-Gate 5: Retrieve latest code from dev sandbox
    | HUMAN CONFIRMS RETRIEVAL DONE
    v
Gate 5: Step-by-step Implementation (platform dependency order)
    | HUMAN APPROVES EACH STEP
    v
Gate 5/6: Tests for the step (immediately, not batched)
    | HUMAN APPROVES
    v
Gate 6: Verification (quality gates + deploy to dev sandbox)
    | HUMAN APPROVES
    v
Gate 7: Commit (artifacts FIRST) + Pull / Merge Request
  | HUMAN APPROVES
  v
Gate 8: Release Document Update
  | HUMAN APPROVES
  v
Gate 9: Jira Implementation Comment
  | AUTOMATIC POST
    v
Done
```

## Core rules

- **Gate 1 is pure ticket understanding** — NO codebase access, NO git commands, NO file
  searches. Only the ticket and clarifying questions.
- **Gate 2 unlocks codebase access** — only after requirements are approved.
- **STOP means STOP.** Do not generate text or call tools after a STOP marker until the
  human responds.
- **Every gate has a PRECONDITION.** Check it before entering. If unmet, go back.
- **The exploration.md save question in Gate 2 is MANDATORY** — always ask before design.
- **Source of truth is ALWAYS the repo code.** Never infer behavior from ticket
  descriptions — read the actual classes, verify logic in the codebase (and in a sandbox
  where relevant).
- **Never hallucinate.** If unsure, say so and verify in code / sandbox / official docs.

---

## Worklog file (MANDATORY — context persistence)

Path: `<ARTIFACT_DIRECTORY>/<TICKET-ID>/worklog.md`
Example: `docs/artifacts/CRME-1234/worklog.md`

- **Create** immediately after Gate 1 approval (once the ticket ID is known), from
  `.myit/templates/worklog.md`.
- **Update** at the end of every gate and after every significant decision.
- **Read first** at the start of every session:
  `ls <ARTIFACT_DIRECTORY>/<TICKET-ID>/worklog.md` — if found, it is the
  primary context source. Do NOT re-ask questions or re-run exploration it already
  documents.

---

## Gate 1 — Requirements & Scope

**Precondition:** a ticket / request exists. No codebase access yet.

- Restate the problem in your own words. List assumptions.
- Ask clarifying questions until scope is unambiguous. Do NOT guess.
- Define acceptance criteria as testable Given/When/Then.
- Capture NFRs (project prompt adds domain-specific ones).
- List explicit out-of-scope items.

Output: save to `<ARTIFACT_DIRECTORY>/<TICKET-ID>/requirements.md` (template:
`.myit/templates/requirements.md`). This file WILL be committed in Gate 7.

Create the worklog file now. **STOP — human approves requirements.**

### Analysis / investigation stories
Not every ticket needs code. For spikes / analysis:
- Use Gates 1-3 to produce the analysis deliverables. Do NOT skip exploration — read the
  code, trace the logic end-to-end, verify assumptions against the repo.
- Verify in the dev sandbox — run SOQL, check metadata, test hypotheses. Do a POC in the
  sandbox to back findings; if something must be deployed/configured to validate, ASK the
  developer first.
- For platform features, cite official docs (developer.salesforce.com,
  help.salesforce.com) — not memory.
- Analysis artifacts follow the same templates and traceability headers as design/spec
  docs. They are first-class deliverables.
- After Gate 3, the human decides: **Done (analysis only)** or **proceed to Gates 4-7**.

---

## Gate 2 — Codebase Exploration + Design

**Precondition:** `requirements.md` approved.

### Part A: Exploration
- Read `project-context.md` / project prompt first if present.
- Explore only what's relevant: existing entry points and handlers for the domain, reusable
  utils/builders/models, Custom Metadata / Custom Settings, Named Credentials, reusable
  LWC, test-data factories, existing versioned classes (`_V[N]`).
- Follow existing patterns — do not import a different architecture.

### Part B: Solution Alternatives
Present 2-3 approaches. For each: Description / Architecture / Pros / Cons / Risk / Effort.
Then a comparison matrix (project prompt defines the columns; include Effort, platform-limit
impact, complexity, versioning impact, alignment with existing patterns, code reuse).
End with **RECOMMENDATION: Option X — rationale.**

Present and invite discussion. **STOP — human picks approach.**

### Part B-2: exploration.md save decision — MANDATORY
After the human picks an approach, ask verbatim:

> Would you like me to save the exploration findings as `exploration.md`?
> 1. Yes — save `exploration.md` before proceeding to design
> 2. No — skip, proceed directly to the design document

**STOP. Wait for response.**

### Part C: Technical Design
Produce using `.myit/templates/technical-design.md`. Include architecture / sequence /
component diagrams (Mermaid), platform-limit analysis, dependencies, and the implementation
order (project prompt specifies the exact order).

Output: `<ARTIFACT_DIRECTORY>/<TICKET-ID>/technical-design.md`.
Invite discussion -> **STOP** -> iterate -> save -> **STOP — human approves design.**

---

## Gate 3 — Technical Specifications

**Precondition:** `technical-design.md` approved.

Break the design into independently implementable specs, ordered by dependency. For each:
- Summary + which requirements it satisfies
- Acceptance criteria (testable)
- Components affected (exact file paths — new or modified)
- Method contracts (signature, params, returns, behavior, errors)
- Platform-limit budget (SOQL / DML / CPU for this spec)
- Test scenarios (positive, negative, bulk, edge)

Output: `<ARTIFACT_DIRECTORY>/<TICKET-ID>/specs.md` (template: `.myit/templates/specs.md`).
Invite discussion -> **STOP** -> iterate -> save -> **STOP — human approves specs.**

---

## Gate 4 — Git Branch Creation

**Precondition:** `specs.md` approved.

Propose the branch name using the repository's feature/bugfix branch convention.
**STOP — human approves branch.** Only then create it.

---

## Pre-Gate 5 — Retrieve latest code from dev sandbox (MANDATORY)

**Precondition:** branch created.

Prompt the developer:

> ### RETRIEVE LATEST CODE
> Before I start implementation, please retrieve the latest metadata from your development
> sandbox so local code matches what's deployed:
> ```
> sf project retrieve start --target-org <dev-sandbox-alias>
> ```
> Confirm when the retrieve is complete and successful.

**STOP.** Do NOT proceed to Gate 5 until the developer confirms. If there are
conflicts, help resolve them first.

---

## Gate 5 — Step-by-step Implementation

**Precondition:** retrieval confirmed.

Before the first implementation step, create the directory `manifest/<TICKET-ID>/` and
create `manifest/<TICKET-ID>/package.xml` inside it. Maintain this ticket-scoped manifest
throughout Gate 5:
- Add every changed or newly created Salesforce metadata member to `package.xml` as the
  implementation progresses; do not use the root catch-all manifest for ticket deploys.
- Keep the manifest synchronized after each implementation and test step.
- Add a valid XML comment block in `package.xml` with ticket-specific instructions for
  any required pre-deployment and post-deployment actions. If none are required, state
  that explicitly in the comment block. Keep instructions detailed enough to execute,
  including ordering, manual setup, data preparation, permissions, and verification.

Follow the implementation order from the specs (project prompt defines the platform order).
For each step:
1. Implement following the project's existing patterns.
2. **STOP — human approves the implementation.**
3. Immediately write the tests for that step (next section). Not optional.

---

## Gate 5/6 — Tests per step (MANDATORY)

Every implementation step has a corresponding test class, written **immediately** after the
step is approved — never batched at the end.

For each unit, produce:

> TEST FOR: `<ClassName>`
> File: `<test file path>`
> Testing: `<behaviors covered>`
> Coverage target: `<project target>`
> Scenarios: happy path / bulk (200) / edge / negative / regression

Follow the testing standards in `.myit/instructions/salesforce-fm/architecture.instructions.md`.
**STOP — human approves tests** before the next step or Gate 6.

---

## Gate 6 — Verification (quality gates + deploy)

**Precondition:** all steps + tests approved.

1. **Optional local check:** when LWC changes are included, run LWC Jest
  (`npx jest --coverage`).
2. **Deploy to dev sandbox (mandatory — do not skip).** Confirm that
  `manifest/<TICKET-ID>/package.xml` exists and is current. First `sf org list` to confirm
  the sandbox is connected, then follow the manifest's pre-deployment instructions and
  tell the developer explicitly:
   > Deploying to dev sandbox now. Running:
  > `sf project deploy start --manifest manifest/<TICKET-ID>/package.xml --target-org <alias>`
3. **Run Apex tests in the sandbox:**
   `sf apex run test --target-org <alias> --code-coverage --result-format human`
4. **Complete post-deployment instructions and verify in the org:** follow the manifest's
  post-deployment instructions, then manually test against the acceptance criteria.
5. **Fix issues found, redeploy, re-verify.**

You cannot proceed to Gate 7 without a successful dev-sandbox deployment + verification.
**STOP — human approves verification.**

---

## Gate 7 — Commit (single commit per branch) + Pull / Merge Request

**Precondition:** verification approved.

### Part A: one commit per branch (mandatory, automatic — do not ask whether to)

A branch carries **exactly one commit** for the whole unit of work (artifacts +
implementation + tests together), not a separate commit per file group.

1. `ls <ARTIFACT_DIRECTORY>/<TICKET-ID>/`
2. First commit on the branch — stage everything (artifacts, implementation, tests) and
   commit once: `git add <ARTIFACT_DIRECTORY>/<TICKET-ID>/ <implementation paths> && git
   commit -m "feat(<TICKET-ID>): <desc>"`
   (artifacts include whichever of `requirements.md`, `exploration.md`,
   `technical-design.md`, `specs.md`, worklog exist)
3. Any later change on the same branch (fixes, more tests, more artifacts): stage it and
   **amend** the existing commit rather than adding a new one — `git add <paths> && git
   commit --amend --no-edit` (or `--amend -m "..."` if the summary needs updating). If the
   branch is already pushed, this requires `git push --force-with-lease` on that branch.

For analysis-only stories the single commit is `docs(<TICKET-ID>): add analysis
findings`.

**SELF-CHECK — STOP AND VERIFY:** run `git log --oneline` and confirm the branch has
exactly **one** commit ahead of the base branch. If there's more than one, amend them
down to one now. This is the #1 most commonly missed step. No "later", no waiting to be
asked.

### Part B: Pull / Merge Request
Present the PR/MR title, branch, description (what / why / testing / artifacts), and commit
list.
The description MUST include:

```
## Artifacts
See `<ARTIFACT_DIRECTORY>/<TICKET-ID>/` for design documents and analysis.
```

**STOP — human approves the PR/MR.** (The project prompt defines the VCS platform, base
branch, template, and reviewers.) Continue to Gate 8 only after approval.

---

## Gate 8 — Release Document Update

**Precondition:** Gate 7 commit and PR/MR preparation approved.

This update is mandatory for every completed ticket or subsequent implementation change.
Update the existing release document at `docs/Release document.docx` using a
Word-compatible editor. Preserve all existing release entries and formatting. Insert a
page break before the new entry and place it at the beginning of the document, above all
previous release entries. Never append a new release entry to the end of the document.
Add one release entry containing:

- **Ticket Number:** `<TICKET-ID>`
- **Title:** `<ticket or implementation title>`
- **Short description:** `<concise implementation summary>`
- A table with one row for every changed or newly created implementation, test, metadata,
  and deployment-manifest file, using exactly these columns:

  | File name | File type | New/Modified |
  |---|---|---|
  | `<path>` | `<Apex/LWC/Metadata/Test/Manifest/etc.>` | `<New/Modified>` |

Include `manifest/<TICKET-ID>/package.xml` in the table. Check that the table matches the
final diff, that the new entry is on the first page, and that the document saves and opens
successfully. Every later ticket or implementation change must receive its own new page
at the beginning of the document. If the existing file cannot be opened or is not a valid
Word document, stop and ask for approval before converting or replacing it; do not silently
overwrite it.

Because the release document is part of the same unit of work, add it to the existing
branch commit by amending that commit. Do not create a second commit. If a PR/MR already
exists, update it after the amend. **STOP — human approves the release-document update.**

---

## Gate 9 — Jira Implementation Comment

**Precondition:** Gate 8 release-document update approved.

Compose the implementation comment in memory containing:

```text
Implementation details

Ticket: <TICKET-ID>
Title: <title>
Summary: <what changed and why>
Implementation: <layers, classes, triggers, LWCs, metadata, and key behavior>
Files: <changed files and whether each is new or modified>
Deployment: manifest/<TICKET-ID>/package.xml
Pre-deployment: <steps, or None required>
Post-deployment: <steps, verification, or None required>
Testing: <Apex results and optional LWC Jest results>
Verification: <sandbox verification outcome>
Known limitations / follow-up: <items, or None>
```

Post the comment automatically after it is composed:

```powershell
$implementationComment = @'
<implementation details from the template above>
'@
pwsh -NoProfile -File .myit/tools/Add-JiraComment.ps1 `
  -IssueKey <TICKET-ID> `
  -CommentText $implementationComment
```

If `pwsh` is unavailable, use `powershell -NoProfile` with the same arguments. The helper
reads `.jira-token` only at runtime and returns the issue key, comment ID, and comment URL;
it must never print or expose the token. Do not use the read-only
`.myit/tools/Get-JiraIssue.ps1` helper to post comments. Record the returned comment URL or
ID in the worklog. Do not create a comment file or a second commit for the comment. Gate 9
completes after a successful Jira post.
