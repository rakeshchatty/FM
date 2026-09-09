# FM — Copilot / Agent Instructions

Always-on entrypoint. The full agentic framework lives in **`.myit/`** (registered for
Copilot Chat in `.vscode/settings.json`). Read `.myit/CAPABILITIES.yaml` for the map.

## What this repository is
- **FM** — a Salesforce project in **SFDX source format**. Metadata: `force-app/main/default/`.
- Git remote `github.com/rakeshchatty/FM`; default branch `main`.
- No `sfdx-project.json` / `package.json` is checked in — do not add them unless asked.

## Load these
- Guardrails (always): `.myit/instructions/salesforce-fm/guardrails.instructions.md`
- Architecture (Apex, triggers, LWC, Aura, metadata, naming, testing, CI/CD, code-review
  standards + FM data model): `.myit/instructions/salesforce-fm/architecture.instructions.md`
- Tools & MCP: `.myit/instructions/salesforce-fm/tools.instructions.md`
- Path-scoped instruction files apply automatically via their `applyTo` globs.

## Slash commands (Copilot Chat)
- `/salesforce-fm-develop` — gated development workflow (Gates 1-7, worklog, analysis flow).
  Base: `.myit/workflow/develop.workflow.md`.
- `/salesforce-fm-review` — gated code review. Base: `.myit/workflow/review.workflow.md`.

## Non-negotiable guardrails
- Never connect to / deploy to / modify a **production** org. Sandbox or scratch only, on request.
- Never run destructive `sf` or git commands. No commit / push / branch except when a
  workflow gate authorizes it.
- Do not edit `force-app/**` Apex/LWC/trigger/permission-set/profile/Named Credential/
  Custom Metadata as a side effect of framework or tooling work.
- Never read, print, copy, or commit secrets (`.jira-token`, `.sfdx/`, `.sf/`, auth files).
- Honor every `STOP` marker and gate precondition.
- Every Apex change ships with tests — 85%+ coverage (aim 95%), meaningful assertions.

## Working style
Small, focused edits. Match surrounding patterns. The repo code is the source of truth —
read it, don't assume from tickets. Validate every file you touch. When a step is
outward-facing, hard to reverse, or touches production, stop and ask.
