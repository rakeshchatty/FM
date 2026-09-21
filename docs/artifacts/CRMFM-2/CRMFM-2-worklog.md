<!--
Traceability
Ticket: CRMFM-2
Artifact: CRMFM-2-worklog.md
Purpose: context persistence across sessions — read this FIRST on resume.
Last updated: 2026-09-21
-->

# Worklog — CRMFM-2: Recurring Order - Default "Discount to Apply" to Account & enforce mutual-exclusivity validation with Manual Price

## Current state
- **Active gate:** Gate 6 — Verification
- **Next action:** Confirm acceptance criteria met against approved requirements, then proceed to Gate 7 (commit + PR)
- **Blocked on:** nothing

## Story type
- [x] Code change  [ ] Analysis / spike only

## Key facts (do not re-derive)
- Chosen approach: Option A — declarative only: rely on existing `Discount_to_Apply__c` picklist default (`Account`) + a merged validation rule on `Recurrings__c` blocking both-blank and both-populated. **Accepted risk:** does not guarantee defaulting for records inserted via the `OrderHaulageTonnageOrLiftPriceService` screen flow, API, or other integrations that submit `Discount_to_Apply__c` explicitly as blank — confirmed and accepted by developer 2026-09-21.
- Dev sandbox alias: `fm-ai`
- Branch: `bugfix/CRMFM-2-recurring-order-discount-type-default` (created: yes)
- Artifact directory: `docs/artifacts/CRMFM-2/`
- Object: `Recurrings__c` (Recurring Order)
- Fields: `ManualPrice__c` (Manual Price), `Discount_to_Apply__c` (Discount to Apply / "Discount Type", picklist `Account`/`Partner`)
- Existing validation rule: `RestrictDiscountToApply` (blocks both-populated only) at
  `force-app/main/default/objects/Recurrings__c/validationRules/RestrictDiscountToApply.validationRule-meta.xml`
- `Discount_to_Apply__c` field metadata already has `<default>true</default>` on the `Account` value — root cause of "not pre-populated" is that this only applies to manual UI record creation, not API/Flow-submitted records (e.g. `OrderHaulageTonnageOrLiftPriceService` flow explicitly assigns `Recurring.Discount_to_Apply__c`, bypassing the field default when left blank).
- Analogous existing pattern on `Schedule__c`: `Discount_Type__c` + `Enqix_Price__c` with `Discount_or_Manual_Price` validation rule — same gap exists there too (out of scope for this ticket).
- `RecurringTrigger.trigger` (before insert/update) -> `RecurringTriggerHelper.populateDates()` already defaults other fields (`Active__c`, `isSalesforce__c`) on insert — this is the pattern Option B would have extended.

## Gate log
| Gate | Status | Date | Notes / decisions |
|---|---|---|---|
| 1 Requirements | APPROVED | 2026-09-21 | requirements.md approved by developer |
| 2 Exploration + Design | APPROVED | 2026-09-21 | exploration.md saved: yes (Option A chosen); technical-design.md approved |
| 3 Specs | APPROVED | 2026-09-21 | specs.md approved (2 specs: validation rule merge, data-fix script) |
| 4 Branch | APPROVED | 2026-09-21 | branch `bugfix/CRMFM-2-recurring-order-discount-type-default` created |
| Pre-5 Retrieve | CONFIRMED | 2026-09-21 | confirmed by developer: yes (sandbox alias `fm-ai`) |
| 5 Implementation | DONE | 2026-09-21 | steps done: 2/2 |
| 5/6 Tests | PASSED | 2026-09-21 | 7/7 `RecurringTest` methods pass (100%); bulk (200) scenario verified |
| 6 Verification | PASSED | 2026-09-21 | Deployed to `fm-ai` via `manifest/CRMFM-2-package.xml`; tests 7/7 pass; data-fix script run — 0 records needed fixing in this sandbox |
| 7 Commit + PR | | | artifacts committed: yes/no |

## Implementation steps
| # | Component | Implemented | Tested | Approved |
|---|---|---|---|---|
| 1 | `RestrictDiscountToApply` validation rule (merged formula) | Yes | Yes (`RecurringTest.cls` new methods) | Yes |
| 2 | Post-deployment data-fix script (`manifest/CRMFM-2-datafix-discount-to-apply.apex`) | Yes | Executed against `fm-ai` — 0 records matched (none needed fixing in this sandbox) | Yes |

## Decisions & rationale
- 2026-09-21 — Fetched ticket via Get-JiraIssue.ps1; confirmed CRMFM-2 matches the pricing/discount-type description previously drafted for this repo.
- 2026-09-21 — Confirmed object is `Recurrings__c`; default must apply to all creation paths (UI/API/Flow/integration), so a pure picklist default is insufficient — automation needed too; new validation will replace/merge `RestrictDiscountToApply` into a single rule.
- 2026-09-21 — Data-fix for existing bad records (both fields blank) is included as a **post-deployment step** (e.g. anonymous Apex, referenced under `manifest/`) delivered with this ticket, not a separate story and not built into the validation rule/trigger logic itself.
- 2026-09-21 — Presented Options A/B/C for Gate 2. Recommended Option B (Apex trigger helper) to cover all creation paths. Developer explicitly chose **Option A** (declarative only) after being shown the gap — accepted as a known risk/limitation rather than a design oversight.
- 2026-09-21 — **Important finding during test-writing/deploy:** the `Discount_to_Apply__c` picklist default (`Account`) DOES apply even on plain Apex `insert` statements, but only when the field is entirely omitted from the record (not explicitly set to null). This was proven by a deploy failure where a bulk-test record left the field untouched and got auto-defaulted, causing a both-populated validation block. This refines (but does not eliminate) the accepted Option A risk: the real gap is specifically when a client (e.g. the `OrderHaulageTonnageOrLiftPriceService` flow) explicitly assigns the field as blank rather than omitting it — an explicit null bypasses the default.
- 2026-09-21 — Deployed to `fm-ai` dev sandbox via scoped manifest `manifest/CRMFM-2-package.xml`; all 7 `RecurringTest` methods pass; data-fix script run — 0 existing records needed fixing in this sandbox.

## Deviations from design
- none yet

## Open questions / follow-ups
- [x] Confirm `Recurrings__c` is the correct object — Yes.
- [x] Confirm whether default must apply to API/Flow-created records, not just UI — Yes, all paths.
- [x] Confirm whether new validation replaces or complements `RestrictDiscountToApply` — Replace/merge into one rule.
- [x] Confirm data-fix for existing bad records is out of scope — Included as a post-deployment step referenced under `manifest/`, delivered with this ticket.
