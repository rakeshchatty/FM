---
applyTo: "**"
description: FM hard guardrails — orgs, destructive actions, secrets, scope.
---

# FM — Guardrails (always enforce)

## Orgs & deployment
- **Never connect to, authenticate against, deploy to, or modify a PRODUCTION org.**
- Deploy / retrieve / test only against a **developer sandbox or scratch org**, and only
  when the user asks.
- Refuse any org alias that looks like production. If org intent is ambiguous, stop and ask.

## Destructive actions
- Never run: `sf org delete`, `sf data delete`, `sf project delete ...`, mass record
  DML from a script, `--forceoverwrite` / `--ignore-conflicts` against a shared org,
  metadata destructive deploys.
- Never `git push`, `git commit`, `git reset --hard`, branch creation, or history rewrite
  **unless a gate in the active workflow explicitly authorizes it** or the user directly
  instructs it.

## Scope protection
- Do **not** edit `force-app/**` Apex / LWC / trigger / permission-set / profile /
  Named Credential / Custom Metadata files as a side effect of framework, tooling, or
  documentation work. Functional changes require an explicit request and a workflow gate.
- Preserve unrelated user changes. Small, focused edits only.

## Secrets
- Never read, print, copy, commit, or paste into output: `.jira-token`, `.sfdx/`, `.sf/`,
  auth files, tokens, passwords, API keys, private keys, session ids, org ids tied to a
  real org.
- Secrets in code come from Named Credentials / Protected Custom Metadata / Custom
  Settings — never hardcoded.

## Workflow discipline
- When running `salesforce-fm-develop` or `salesforce-fm-review`, honor every `STOP`
  marker and gate precondition. STOP means STOP — no further text or tool calls until the
  human responds.
- Tests ship with every Apex change. Coverage target **85%+ (aim 95%)** with meaningful
  assertions, not coverage padding.
