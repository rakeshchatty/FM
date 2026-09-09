---
description: FM Salesforce gated code review (scope -> automated -> deep review -> findings -> fixes)
argument-hint: "[branch | PR # | paths — defaults to current branch vs main]"
---

# /salesforce-fm-review

Run the gated code-review workflow for the **FM** Salesforce project.

Review target: $ARGUMENTS  (default: current branch diff vs `main`)

## How to run this

1. **Read `.myit/prompts/salesforce-fm-review.prompt.md`** and follow it exactly — it is
   the FM entrypoint (project detection + FM-specific gate additions).
2. It loads **`.myit/workflow/review.workflow.md`** — follow that base workflow
   gate-for-gate (R1 scope → R2 automated → R3 deep review → R4 findings → R5 fixes →
   R6 re-verify).
3. Also load and obey:
   - `.myit/instructions/salesforce-fm/architecture.instructions.md` — the domain checklist
     is its **Code Review Standards** section
   - `.myit/instructions/salesforce-fm/guardrails.instructions.md`
   - `.myit/instructions/salesforce-fm/tools.instructions.md`
   - `.myit/skills/salesforce-security-review.md` (security portion of Gate R3)

## Critical

- **Read-only until Gate R5.** Gates R1–R4 do not modify files.
- **Honor every `STOP` marker.**
- Trace each changed unit end-to-end from its entry point — the repo code is the source of
  truth, not the diff summary or the ticket.
- Findings format: `severity | file:line | issue | failure scenario | suggested fix`;
  block on any High. Save to `docs/artifacts/<TICKET-ID>/review-findings.md`.
- In Gate R5, fix only the findings the human selected, one at a time with approval. No
  commit or push.
