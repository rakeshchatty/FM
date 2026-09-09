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

Path: `<ARTIFACT_DIRECTORY>/<TICKET-ID>/<TICKET-ID>-worklog.md`
Example: `docs/artifacts/CRME-1234/CRME-1234-worklog.md`

- **Create** immediately after Gate 1 approval (once the ticket ID is known), from
  `.myit/templates/worklog.md`.
- **Update** at the end of every gate and after every significant decision.
- **Read first** at the start of every session:
  `ls <ARTIFACT_DIRECTORY>/<TICKET-ID>/<TICKET-ID>-worklog.md` — if found, it is the
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

1. **Local checks:** LWC Jest (`npx jest --coverage`), static analysis
   (`sf scanner run --target force-app/ --format table`), local Sonar.
2. **Deploy to dev sandbox (mandatory — do not skip).** First `sf org list` to confirm the
   sandbox is connected, then tell the developer explicitly:
   > Deploying to dev sandbox now. Running:
   > `sf project deploy start --target-org <alias>`
3. **Run Apex tests in the sandbox:**
   `sf apex run test --target-org <alias> --code-coverage --result-format human`
4. **Verify in the org:** manually test against the acceptance criteria; ask the developer
   if any manual setup/config is needed first.
5. **Fix issues found, redeploy, re-verify.**

You cannot proceed to Gate 7 without a successful dev-sandbox deployment + verification.
**STOP — human approves verification.**

---

## Gate 7 — Commit (artifacts FIRST) + Pull / Merge Request

**Precondition:** verification approved.

### Part A: Commit artifacts FIRST (mandatory, automatic — do not ask whether to)
1. `ls <ARTIFACT_DIRECTORY>/<TICKET-ID>/`
2. `git add <ARTIFACT_DIRECTORY>/<TICKET-ID>/ && git commit -m "docs(<TICKET-ID>): add design artifacts"`
   (includes whichever of `requirements.md`, `exploration.md`, `technical-design.md`,
   `specs.md`, worklog exist)
3. Commit implementation — one commit per logical unit: `feat(<TICKET-ID>): <desc>`
4. Commit tests if separate: `test(<TICKET-ID>): <desc>`

For analysis-only stories the artifacts commit is the only deliverable:
`git commit -m "docs(<TICKET-ID>): add analysis findings"`.

**SELF-CHECK — STOP AND VERIFY:** run `git log --oneline -5` and confirm you see
`docs(<TICKET-ID>): add design artifacts`. If not, commit them NOW. This is the #1 most
commonly missed step. No "later", no waiting to be asked.

### Part B: Pull / Merge Request
Present the PR/MR title, branch, description (what / why / testing / artifacts), and commit
list.
The description MUST include:

```
## Artifacts
See `<ARTIFACT_DIRECTORY>/<TICKET-ID>/` for design documents and analysis.
```

**STOP — human approves the PR/MR.** (The project prompt defines the VCS platform, base
branch, template, and reviewers.)
