# review.workflow.md — Base Gated Code-Review Workflow

Project-agnostic. A project prompt (e.g. `salesforce-fm-review.prompt.md`) loads this file
and layers project-specific checklist additions on top.

## Gate flow

```
Review requested
    |
    v
Gate R1: Scope & Context        (identify target; gather ticket + acceptance criteria)
    | HUMAN CONFIRMS SCOPE
    v
Gate R2: Automated Pass         (static analysis, unit tests, coverage, Sonar)
    | -> record results
    v
Gate R3: Manual Deep Review     (read the actual code, trace logic end-to-end)
    v
Gate R4: Findings Report        (severity-ranked; file:line; fix) -> saved to artifact
    | HUMAN REVIEWS FINDINGS, DECIDES WHAT TO FIX
    v
Gate R5: Apply Fixes            (optional; one finding at a time)
    | HUMAN APPROVES EACH FIX
    v
Gate R6: Re-verify + Summary    (re-run checks; deploy to dev sandbox if code changed)
    | HUMAN APPROVES
    v
Done
```

## Core rules

- **Read-only until Gate R5.** Gates R1-R4 do not modify files.
- **STOP means STOP.** No text or tool calls after a STOP marker until the human responds.
- **Source of truth is the repo code.** Trace each change end-to-end from its entry point;
  verify behavior in a sandbox where it matters. Never assume from the ticket or the diff
  summary alone.
- **Never hallucinate.** Unsure how something behaves? Say so; verify in code, sandbox, or
  official docs.
- **No nitpick dumps.** Rank by severity; every finding names a concrete failure scenario
  and a suggested fix.

## Worklog (optional but recommended for multi-session reviews)

`<ARTIFACT_DIRECTORY>/<TICKET-ID>/<TICKET-ID>-review-worklog.md` — create after R1, update
per gate, read first on session resume.

---

## Gate R1 — Scope & Context

**Precondition:** a review target is identifiable.

- Determine the target: working-tree diff / a branch vs. `main` / a PR number / explicit
  paths. Confirm with the human.
- Gather the ticket ID, requirements, and acceptance criteria (from
  `<ARTIFACT_DIRECTORY>/<TICKET-ID>/` if artifacts exist).
- Enumerate changed files by area (Apex / triggers / LWC / metadata / tests / docs).
- State what is in and out of review scope.

**STOP — human confirms scope.**

---

## Gate R2 — Automated Pass

**Precondition:** scope confirmed.

Run and record (do not fix yet):
- Static analysis (PMD / ESLint via the project scanner).
- Unit tests + coverage (Apex and/or LWC Jest).
- Sonar (local) if configured.
- Build / compile / deploy-validate if cheap and available.

Summarize pass/fail and any blocker/critical/high items.

---

## Gate R3 — Manual Deep Review

**Precondition:** automated pass recorded.

For each changed unit, read the actual code and trace the logic end-to-end from its entry
point. Apply the review checklist (project prompt supplies the domain checklist). Look for:
- Correctness: wrong logic, off-by-one, null/empty handling, race conditions, order of
  execution.
- Bulk / scale behavior.
- Security: access control, injection, data exposure, secrets.
- Error handling and logging.
- Test adequacy: do the tests actually assert the new behavior and its failure modes?
- Simplification / reuse / dead code.
- Adherence to project architecture and naming/versioning rules.

Verify uncertain behavior in a sandbox (read-only queries, metadata checks) or cite
official docs — do not guess.

---

## Gate R4 — Findings Report

**Precondition:** manual review complete.

Produce a severity-ranked report. For each finding:

`severity (High/Medium/Low) | file:line | issue | concrete failure scenario | suggested fix`

Group by area. Note explicitly what you checked and found clean. Save to
`<ARTIFACT_DIRECTORY>/<TICKET-ID>/review-findings.md` (or a path the human gives).

**STOP — human reviews findings and decides which to fix (if any).**

---

## Gate R5 — Apply Fixes (optional)

**Precondition:** human selected findings to fix.

For each approved finding, one at a time:
1. Make the minimal change.
2. Update or add the corresponding test.
3. Show the diff.
4. **STOP — human approves the fix.**

Do not batch. Do not fix findings the human did not select.

---

## Gate R6 — Re-verify + Summary

**Precondition:** approved fixes applied.

- Re-run the Gate R2 automated pass.
- If implementation code changed, deploy to the dev sandbox and re-verify (per the
  project's deploy rules).
- Summarize: findings raised, fixed, deferred (with reasons), and residual risk.

**STOP — human approves.** Commits / PR updates follow the project's git rules — only on
explicit approval.
