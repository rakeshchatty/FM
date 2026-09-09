<!--
Traceability
Ticket: <TICKET-ID>
Artifact: pull-request.md
Base branch: main (GitHub)
Last updated: <YYYY-MM-DD>
-->

# <type>(<TICKET-ID>): <short summary>

<!-- type: feat | fix | refactor | test | docs | style | chore -->

## What & why
<What changed and the problem it solves. Link the ticket.>

## Root cause (bug fixes only)
<The actual cause, not the symptom.>

## Changes
- <bullet per meaningful change, grouped: Apex / triggers / LWC / metadata>

## Salesforce metadata touched
- Objects / fields:
- Apex classes / triggers:
- LWC / Aura:
- Permission sets:
- Custom Metadata / other:

## Testing
- [ ] Apex tests updated (happy / bulk 200 / edge / negative / regression), `Assert` with
      messages
- [ ] `sf apex run test --target-org <sandbox> --code-coverage` passed; coverage 85%+
- [ ] LWC Jest passed; coverage 80%+
- [ ] `sf scanner run` — no critical / high
- [ ] Deployed and verified in dev sandbox

## Artifacts
See `docs/artifacts/<TICKET-ID>/` for design documents and analysis.

## Commits
- `docs(<TICKET-ID>): add design artifacts`
- `feat(<TICKET-ID>): ...`
- `test(<TICKET-ID>): ...`

## Guardrails
- [ ] No production org connected or modified
- [ ] No destructive commands run
- [ ] No secrets committed
- [ ] Class names <= 36 chars; API version >= 60.0

## Review
- Base branch: `main`
- Template: `.github/pull_request_template.md` if available
- Reviewer(s): <confirm with developer / team>
