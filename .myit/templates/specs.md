<!--
Traceability
Ticket: <TICKET-ID>
Artifact: specs.md
Gate: 3
Status: DRAFT | APPROVED
Requirements: ./requirements.md
Design: ./technical-design.md
Last updated: <YYYY-MM-DD>
-->

# Specifications — <TICKET-ID>: <title>

Specs are ordered by dependency. Each is independently implementable.

---

## Spec 1: <name>

**Satisfies:** Req #<n>, #<n>
**FM layer / order position:** <e.g. 6. Apex Utils>

### Acceptance criteria
- [ ] <testable condition>

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/classes/<Name>.cls` | new | |
| `force-app/main/default/classes/<Name>Test.cls` | new | |

### Method contracts
- `<returnType> <Class>.<method>(<params>)`
  - Behavior: <...>
  - Returns: <...>
  - Errors: <exception> when <condition>

### Governor-limit budget
SOQL <n> / DML <n> / CPU <ms> / callouts <n>

### Test scenarios
- Happy path: <...>
- Bulk (200): <...>
- Edge: <...>
- Negative: <...>
- Regression: <...>

---

## Spec 2: <name>
<same structure>

---

## Implementation order (this ticket)
1. Spec <n> — <name>
2. Spec <n> — <name>

## Sign-off
Specs approved by: <name> on <date>
