---
agent: agent
description: FM Salesforce gated code review (scope -> automated -> deep review -> findings -> fixes), with FM-specific standards and blocker checklist.
argument-hint: "[branch | PR # | paths — defaults to current branch vs main]"
---

# /salesforce-fm-review

Run the gated code-review workflow for the **FM** Salesforce project.

Review target: $ARGUMENTS (default: current branch diff vs `main`)

## How to run this

1. **Read `.myit/prompts/salesforce-fm-review.prompt.md` and follow it exactly — it is the
   master FM entrypoint.** This command file is only a pointer to it; if anything here
   appears to conflict with the master prompt, the master prompt wins.
2. It loads **`.myit/workflow/review.workflow.md`** — follow that base workflow
   phase-for-phase (Pre-Gate → Phase 1 Change Understanding → Phase 2 Standards →
   Phase 3 Business Logic → Phase 4 Security & Performance → Phase 5 Test Adequacy →
   Phase 6 Present Review → Phase 7 Post Comments).
3. The master prompt also covers, in full:
   - **Section 0** — project configuration values (`BASE_BRANCH`, `PR_CLI`, `TICKET_TRACKER`, etc.)
   - **Section 1** — FM diff guidance: SFDX source-path detection, file classification
     (Apex / LWC / Aura / metadata / test), and what to inspect when reading full files.
   - **Section 2** — FM-specific review guidance: Apex standards, LWC, Aura (existing
     components only), metadata, security & performance, test adequacy, and naming.
   - **Section 3** — the FM anti-pattern / blocker table (Critical / Major / Minor), and
     the severity mapping onto the base workflow's Blocker/Major/Minor/Nit/Praise levels.
   - **Section 4** — the mandatory review summary output: file, location, and required
     contents.
4. Also load and obey:
   - `.myit/instructions/salesforce-fm/guardrails.instructions.md`
   - `.myit/instructions/salesforce-fm/architecture.instructions.md`
   - `.myit/instructions/salesforce-fm/tools.instructions.md`
   (Phase 4's security pass uses the Security & Performance items in the master prompt.)

## Critical

- **Read-only until Phase 7.** Phases 1–6 do not modify files or post anywhere.
- **Honor every `STOP` marker.** Do not generate text or call tools after a STOP until the
  human responds.
- **Human approval is mandatory before posting.** Phase 7 (posting PR comments) only runs
  if the human explicitly chose "Post to PR" in Phase 6.
- **No commit, push, or branch changes** as part of a review.
- Trace each changed unit end-to-end from its entry point — the repo code is the source of
  truth, not the diff summary or the ticket.
- Always generate the mandatory review summary file per the master prompt's Section 4:
  `docs/artifacts/<TICKET-ID>/<TICKET-ID>-review-summary.md`.
