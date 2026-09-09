---
description: FM Salesforce gated development workflow (Gates 1-7, worklog, analysis flow)
argument-hint: "[ticket id or description]"
---

# /salesforce-fm-develop

Run the gated development workflow for the **FM** Salesforce project.

Ticket / request: $ARGUMENTS

## How to run this

1. **Read `.myit/prompts/salesforce-fm-develop.prompt.md`** and follow it exactly — it is
   the FM entrypoint (project detection, variables, and FM-specific gate additions).
2. It loads **`.myit/workflow/develop.workflow.md`** — follow that base workflow
   gate-for-gate.
3. Also load and obey:
   - `.myit/instructions/salesforce-fm/guardrails.instructions.md`
   - `.myit/instructions/salesforce-fm/architecture.instructions.md`
   - `.myit/instructions/salesforce-fm/tools.instructions.md`
4. Use the templates in `.myit/templates/` for every artifact (`requirements.md`,
   `exploration.md`, `technical-design.md`, `specs.md`, worklog).

## Critical

- **Honor every `STOP` marker.** Do not generate text or call tools after a STOP until the
  human responds.
- **Every gate has a precondition** — check it before entering; go back if unmet.
- Gate 1 is ticket understanding only: **no codebase access, no git, no file searches.**
- Gate 2's `exploration.md` save question is **mandatory**.
- **No branch, commit, push, or deployment** except where a gate explicitly authorizes it.
  Never touch a production org.
- Create/update the worklog at `docs/artifacts/<TICKET-ID>/<TICKET-ID>-worklog.md`; on a
  new session, read it first and resume from the recorded gate.
