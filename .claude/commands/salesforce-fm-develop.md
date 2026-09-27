---
agent: agent
description: FM Salesforce gated development workflow with read-only Jira ticket retrieval (Gates 1-9, worklog, analysis flow).
argument-hint: "[Jira issue key or browse URL, for example CRMFM-1]"
---

# /salesforce-fm-develop

Run the gated development workflow for the **FM** Salesforce project.

Ticket / request: $ARGUMENTS

## How to run this

1. **Read `.myit/prompts/salesforce-fm-develop.prompt.md` and follow it exactly — it is
   the master FM entrypoint.** This command file is only a pointer to it; if anything here
   appears to conflict with the master prompt, the master prompt wins.
2. It loads **`.myit/workflow/develop.workflow.md`** — follow that base workflow
   gate-for-gate. The master prompt layers FM-specific additions onto each gate.
3. The master prompt also covers, in full:
   - **Section 0** — project detection (SFDX / `force-app`, git remote, `.myit/` presence)
     and project variables (`ARTIFACT_DIRECTORY`, `DEV_SANDBOX_ALIAS`, `PR_BASE`).
   - **Section 2** — session start: worklog-first resume, then `requirements.md`, then
     read-only Jira retrieval via `.myit/tools/Get-JiraIssue.ps1` only if both are missing.
   - **Gate 1–9 additions** — FM NFRs, exploration/design focus, spec/implementation
     order, branch naming, sandbox retrieve, implementation + test rules, the Pre-Gate 6
     manifest step, dev-sandbox deploy/verify, commit + PR, the Gate 8 release-document
     update, and the Gate 9 Jira/business-communication step.
4. Also load and obey:
   - `.myit/instructions/salesforce-fm/guardrails.instructions.md`
   - `.myit/instructions/salesforce-fm/architecture.instructions.md`
   - `.myit/instructions/salesforce-fm/tools.instructions.md`
5. Use the templates in `.myit/templates/` for every artifact (`requirements.md`,
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
