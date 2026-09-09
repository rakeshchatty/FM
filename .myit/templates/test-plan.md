<!--
Traceability
Ticket: <TICKET-ID>
Artifact: test-plan.md
Specs: ./specs.md
Last updated: <YYYY-MM-DD>
-->

# Test Plan — <TICKET-ID>

## Scope
<What is verified. Link to specs.>

## Apex tests
| Test class | Method (`should_...`) | Scenario | Type | Asserts (with message) |
|---|---|---|---|---|
| `<Class>Test` | `should_<behavior>` | given/when/then | positive | |
| `<Class>Test` | `should_<behavior>_when_bulk` | 200 records | bulk | no limit errors |
| `<Class>Test` | `should_throw_<x>_when_<y>` | invalid input | negative | expected exception |
| `<Class>Test` | `should_preserve_<behavior>` | existing path | regression | unchanged |

- Data: `@TestSetup` / factory. `SeeAllData=false`.
- Mocks: `fflib-apex-mocks` via `@TestVisible private static` fields.
- Coverage target: 85%+ (aim 95%); `<Class>` line >= 90%.

## LWC / Jest
| Spec | State / action | Assertion |
|---|---|---|
| renders | loading | spinner shown |
| renders | data resolved | fields rendered |
| renders | wire error | error message shown |
| interaction | click / input | handler called / event dispatched with `detail` |
| empty state | no data | empty message shown |

Coverage target: 80%+.

## Dev sandbox verification
- [ ] Deploy succeeds: `sf project deploy start --target-org <alias>`
- [ ] `sf apex run test --target-org <alias> --code-coverage` — all pass, targets met
- [ ] Manual check against each acceptance criterion
- [ ] Manual setup/config needed first: <list or none>

## Regression surface
- Related triggers / flows / components to re-check: <list>

## Exit criteria
- [ ] All automated tests green
- [ ] Coverage targets met
- [ ] Static analysis: no critical / high
- [ ] Security checklist passed
- [ ] Dev sandbox verification passed
