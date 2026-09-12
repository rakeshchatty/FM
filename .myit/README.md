# .myit — Agentic Workflow Framework

Reusable agentic setup for this workspace, shared by **GitHub Copilot Chat** and
**Claude Code**. One folder holds project-specific and common instructions, gated prompts,
workflows, skills, and document templates. Both tools use the same command names
(`/salesforce-fm-develop`, `/salesforce-fm-review`) and the same `.myit/` source of truth.

| | Copilot Chat | Claude Code |
|---|---|---|
| Always-on entrypoint | `.github/copilot-instructions.md` | `CLAUDE.md` |
| Command definitions | `.myit/prompts/*.prompt.md` (registered via `.vscode/settings.json`) | `.claude/commands/*.md` (wrappers that load the `.myit/` prompt) |
| Instructions | `.myit/instructions/**` auto-applied by `applyTo` glob | `.myit/instructions/**` — read the ones matching the files you touch |

## Layout

```
.myit/
├── CAPABILITIES.yaml                 registry of everything below
├── instructions/
│   ├── salesforce-fm/                project-specific — 3 files:
│   │                                 architecture (Apex/triggers/LWC/Aura/metadata/naming/
│   │                                 testing/CI-CD/review + FM data model), guardrails, tools
│   └── common/                       project-agnostic (general, code-quality, css, git,
│                                     testing, troubleshoot)
├── prompts/
│   ├── salesforce-fm-develop.prompt.md   gated dev workflow (Gates 1-7)
│   └── salesforce-fm-review.prompt.md    gated code review
├── workflow/
│   ├── develop.workflow.md           base gated dev workflow (project-agnostic)
│   ├── review.workflow.md            base gated review workflow (project-agnostic)
│   ├── bugfix.md                     lightweight playbook
│   └── metadata-change.md            lightweight playbook
└── templates/                        requirements, exploration, technical-design, specs,
                                      worklog, test-plan, pull-request
```

## How Copilot Chat consumes it

`.myit/` is not one of Copilot's default auto-discovered locations, so it is registered in
[`.vscode/settings.json`](../.vscode/settings.json):

```jsonc
{
  "chat.instructionsFilesLocations": { ".myit/instructions": true },
  "chat.promptFilesLocations":       { ".myit/prompts": true }
}
```

- **Instructions** (`*.instructions.md`) apply automatically when a request touches files
  matching their `applyTo` glob.
- **Prompts** (`*.prompt.md`) are run on demand: type `/salesforce-fm-develop` or
  `/salesforce-fm-review` in the Copilot Chat box.
- `.github/copilot-instructions.md` stays as a thin always-on pointer to this folder
  (Copilot only auto-loads that one at `.github/`).

Reload the VS Code window after changing `settings.json` so the locations are picked up.

## How Claude Code consumes it

- **`CLAUDE.md`** at the repo root is auto-loaded every session — it points here and
  restates the guardrails.
- **`.claude/commands/salesforce-fm-develop.md`** and **`.claude/commands/salesforce-fm-review.md`**
  provide the slash commands. They are thin wrappers: each tells Claude to read the
  matching `.myit/prompts/*.prompt.md` and follow the base workflow in `.myit/workflow/`.
- Claude Code has no `applyTo` auto-apply — `CLAUDE.md` instructs it to open the relevant
  `.myit/instructions/**` file for the area being changed (always `guardrails`, plus
  `architecture` for anything under `force-app/`).
- No settings change or window reload needed; `.claude/` and `CLAUDE.md` are picked up
  automatically and are committed normally (not git-ignored).

> **Note:** `.vscode/settings.json` is git-ignored in this repo (`.gitignore` line 2426),
> so it works locally but is not shared on clone. The committed, shareable copy is
> [`.vscode/settings.json.example`](../.vscode/settings.json.example) — new contributors
> copy it to `.vscode/settings.json`. To track the real file instead, add
> `!.vscode/settings.json` to `.gitignore` (a `.gitignore` change — get it approved
> first).

## Adding another project

1. `mkdir .myit/instructions/<project-id>` and add `architecture`, `guardrails`, `tools`
   instruction files (copy `salesforce-fm/` as a starting point).
2. Add `.myit/prompts/<project-id>-develop.prompt.md` / `-review.prompt.md` that detect the
   project and load the base workflow in `.myit/workflow/`.
3. Add matching `.claude/commands/<project-id>-develop.md` / `-review.md` wrappers (copy the
   `salesforce-fm-*` ones and swap the prompt path).
4. Register the project and its commands in `CAPABILITIES.yaml`.
5. `common/` is shared as-is.

## Guardrails (summary)

No production org. No destructive `sf`/git commands. No commit/push/branch outside an
authorized workflow gate. No secrets in code or output. No side-effect edits to
`force-app/**` functional metadata. Full list in
[`instructions/salesforce-fm/guardrails.instructions.md`](instructions/salesforce-fm/guardrails.instructions.md).
