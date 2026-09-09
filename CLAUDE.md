# FM — Claude Code Instructions

Always-on entrypoint for Claude Code. This mirrors `.github/copilot-instructions.md` so
Claude and GitHub Copilot follow the **same** rules and commands. The full framework lives
in **`.myit/`**; `.myit/CAPABILITIES.yaml` is the map.

## What this repository is
- **FM (FirstMile)** — a Salesforce **Sales Cloud** project (waste / recycling collection
  and delivery logistics) in **SFDX source format**. Metadata: `force-app/main/default/`.
- Git remote `github.com/rakeshchatty/FM`; default branch `main`; GitHub Pull Requests.
- No `sfdx-project.json` / `package.json` is checked in — do not add them unless asked.

## Read these before working
Load the relevant files under `.myit/instructions/` — they are the source of truth:

| Scope | File |
|---|---|
| Guardrails (always) | `.myit/instructions/salesforce-fm/guardrails.instructions.md` |
| Architecture, Apex, triggers, LWC, Aura, metadata, naming, testing, CI/CD, code-review standards, FM data model | `.myit/instructions/salesforce-fm/architecture.instructions.md` |
| Tools & MCP (`sf` CLI, git, retrieval) | `.myit/instructions/salesforce-fm/tools.instructions.md` |

Claude Code does not auto-apply these by path glob — open the ones that match the files you
are touching (e.g. read `architecture.instructions.md` before editing anything under
`force-app/`).

## Slash commands
Same names as Copilot Chat. Defined in `.claude/commands/`, backed by `.myit/`:

- **`/salesforce-fm-develop`** — gated development workflow (Gates 1–7, worklog, analysis
  flow). Prompt: `.myit/prompts/salesforce-fm-develop.prompt.md`; base:
  `.myit/workflow/develop.workflow.md`.
- **`/salesforce-fm-review`** — gated code review (scope → automated → deep review →
  findings → fixes). Prompt: `.myit/prompts/salesforce-fm-review.prompt.md`; base:
  `.myit/workflow/review.workflow.md`.

Lightweight playbooks: `.myit/workflow/bugfix.md`, `.myit/workflow/metadata-change.md`.
Skills: `.myit/skills/`. Document templates: `.myit/templates/`.

## Non-negotiable guardrails
- Never connect to / deploy to / modify a **production** org. Sandbox or scratch only, on
  explicit request. Refuse any org alias that looks like production.
- Never run destructive `sf` or git commands. **No commit / push / branch / history
  rewrite** except when a workflow gate explicitly authorizes it or the user directly
  instructs it.
- Do not edit `force-app/**` Apex / LWC / trigger / permission-set / profile / Named
  Credential / Custom Metadata files as a side effect of framework, tooling, or doc work.
- Never read, print, copy, or commit secrets (`.jira-token`, `.sfdx/`, `.sf/`, auth files,
  tokens, keys).
- Honor every `STOP` marker and gate precondition in the workflows. STOP means STOP.
- Every Apex change ships with tests — 75% floor, **85% gate**, aim 95%, meaningful
  `Assert` messages.
- `NoTriggers__c` per-user bypass must be honored in trigger handlers.

## Working style
Small, focused edits. Match surrounding patterns. The repo code is the source of truth —
read it, don't assume from tickets. Validate every file you touch. When a step is
outward-facing, hard to reverse, or touches production, stop and ask.
