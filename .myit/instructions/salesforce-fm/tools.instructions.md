---
applyTo: "**"
description: FM tool & MCP guidance — sf CLI, git, retrieval, MCP servers.
---

# FM — Tools & MCP

## Salesforce CLI (`sf`)
Allowed (non-destructive, sandbox / scratch only):
- `sf org list` — check authorized orgs before any deploy
- `sf org display --target-org <sandbox>`
- `sf project retrieve start --target-org <sandbox>` — **run before implementation**
- `sf project deploy validate --source-dir <path> --test-level RunLocalTests --target-org <sandbox>`
- `sf project deploy start --target-org <sandbox>` — only inside Gate 6 of the develop workflow
- `sf apex run test --target-org <sandbox> --code-coverage --result-format human`
- `sf data query --target-org <sandbox> --query "..."` — read-only
- `sf scanner run --target force-app/ --format table` — static analysis

Forbidden: anything against production; `sf org delete`; `sf data delete`;
`sf project delete`; `--forceoverwrite` on a shared org; `sf org login` with prod creds.

## Retrieve-before-implement
Before writing implementation code (Pre-Gate 5 in `salesforce-fm-develop`), ask the
developer to run `sf project retrieve start --target-org <dev-sandbox>` and confirm it
completed cleanly, so local metadata matches what is deployed.

## Git
Read / `status` / `diff` / `log` freely. `add` / `commit` only when a workflow gate
authorizes it. Never `push`, branch, or rewrite history without explicit approval.

## Static analysis / quality
- `sf scanner run` (PMD/ESLint) — fix critical & high before proceeding.
- Local SonarQube if configured — fix blocker / critical / major.
- `npx jest --coverage` for LWC.

## MCP servers (`.vscode/mcp.json` — not committed yet)
- Add only when needed. Secrets as `${input:...}` prompts or env vars, never inline.
- Candidates: GitHub MCP (issue/PR context), Filesystem MCP (repo root only),
  Atlassian/Jira MCP (ticket context; auth via input prompt, never a committed
  `.jira-token`).
- Review each server's tool list; disable write/destructive tools you do not need.
- Never point an MCP server at production Salesforce credentials.
