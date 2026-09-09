# Skill: Tooling & MCP Guidance

Guidance for tools and Model Context Protocol (MCP) servers used with this project. No
`.vscode/mcp.json` is committed yet — add one only when the user asks.

## Salesforce CLI (`sf`)
Allowed, non-destructive, sandbox / scratch org only:
- `sf project retrieve start --metadata <Type:Name>`
- `sf project deploy validate --source-dir <path> --test-level RunLocalTests --target-org <sandbox>`
- `sf apex run test -l RunLocalTests --target-org <sandbox>`
- `sf org display`, `sf project deploy report`, `sf data query` (read-only)

**Forbidden:** any deploy / push to production, `sf org delete`, `sf data delete`,
`sf project delete`, `--forceoverwrite` on a shared org, `sf org login` with production
credentials.

## Git
Read / status / diff freely. **No** `commit`, `push`, `branch`, `checkout -b`,
`reset --hard`, or history rewrite without an explicit user instruction.

## MCP servers (when the user adds `.vscode/mcp.json`)
- Keep server definitions minimal; store secrets as `${input:...}` prompts or env vars,
  never inline.
- Reasonable candidates for this project:
  - **GitHub MCP** — issue / PR context (read-oriented).
  - **Filesystem MCP** — scoped to the repo root only.
  - **Atlassian / Jira MCP** — if stories live in Jira; auth via input prompt, never a
    committed `.jira-token`.
- Review each server's tool permissions before enabling; disable write / destructive tools
  you do not need.
- Never point an MCP server at production Salesforce credentials.

## General
- Prefer the dedicated editor / file tools over shell for reading and editing.
- Batch independent read-only commands; stop and ask before anything outward-facing or hard
  to reverse.
