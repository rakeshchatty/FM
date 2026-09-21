<!--
Traceability
Ticket: CRMFM-2
Artifact: exploration.md
Gate: 2
Status: SAVED
Last updated: 2026-09-21
-->

# Exploration — CRMFM-2

## What was explored
- `Recurrings__c` object metadata — `force-app/main/default/objects/Recurrings__c/Recurrings__c.object-meta.xml` — standard custom object, no record types, `sharingModel: ReadWrite`.
- Existing validation rules on `Recurrings__c` — `force-app/main/default/objects/Recurrings__c/validationRules/` — `RestrictDiscountToApply` only blocks both `ManualPrice__c` and `Discount_to_Apply__c` populated at once; does not block both-blank.
- `Discount_to_Apply__c` field — `force-app/main/default/objects/Recurrings__c/fields/Discount_to_Apply__c.field-meta.xml` — picklist (`Account`/`Partner`), already has `<default>true</default>` on `Account`.
- `ManualPrice__c` field — `force-app/main/default/objects/Recurrings__c/fields/ManualPrice__c.field-meta.xml` — Currency, not required.
- Trigger automation — `force-app/main/default/triggers/RecurringTrigger.trigger` (before insert/update) delegates to `RecurringTriggerHelper.cls`, which already sets `Active__c` / `isSalesforce__c` defaults on insert — an existing pattern for object-wide defaulting that fires on every insert regardless of origin (UI/API/Bulk/Flow/integration).
- Manual pricing entry point — `force-app/main/default/flows/OrderHaulageTonnageOrLiftPriceService.flow-meta.xml` — assigns `Recurring.ManualPrice__c`, `Recurring.Supplier_Unit_Price__c`, and `Recurring.Discount_to_Apply__c` from screen inputs. This is the flow introduced by the "recent change to allow manual pricing/manual supplier pricing" referenced in the ticket; if the discount field is left blank on this screen, the flow submits it as an explicit blank, bypassing the field-level picklist default.
- Downstream consumers — `OrderTriggerHelper.cls` reads `RecurringId__r.Discount_to_Apply__c` / `ManualPrice__c` directly when building `OrderItem`s; no other transformation layer, so fixing the source field is sufficient.
- Analogous pattern — `Schedule__c.Discount_Type__c` / `Enqix_Price__c` with `Discount_or_Manual_Price` validation rule has the identical both-blank gap. Confirmed out of scope for this ticket.
- Test coverage — `RecurringTest.cls`, `TestDataHelper.insertRecurring()` — existing test data factory for `Recurrings__c`.

## Existing components relevant to this work
| Component | Path | Role | Reuse / extend / reference |
|---|---|---|---|
| `Discount_to_Apply__c` field | `force-app/main/default/objects/Recurrings__c/fields/Discount_to_Apply__c.field-meta.xml` | Picklist, default value `Account` | Rely on existing `<default>true</default>` — no change needed (Option A) |
| `RestrictDiscountToApply` | `force-app/main/default/objects/Recurrings__c/validationRules/RestrictDiscountToApply.validationRule-meta.xml` | Blocks both-populated | Extend/merge to also block both-blank |
| `RecurringTriggerHelper.cls` | `force-app/main/default/classes/RecurringTriggerHelper.cls` | Defaults `Active__c`/`isSalesforce__c` on insert | Not used in Option A (would have been extended under Option B) |
| `RecurringTest.cls` / `TestDataHelper.insertRecurring` | `force-app/main/default/classes/` | Existing test data factory for `Recurrings__c` | Reuse for new validation-rule test scenarios |
| `OrderHaulageTonnageOrLiftPriceService.flow-meta.xml` | `force-app/main/default/flows/` | Screen flow that sets manual pricing / discount fields | Root-cause entry point; **not modified** under Option A (accepted risk) |

## Existing patterns observed
- Layering: `Recurrings__c` automation lives in a single trigger -> helper class pattern (`RecurringTrigger` -> `RecurringTriggerHelper`), not fflib/RestResource layering (this object predates the FM REST layered pattern).
- Versioning: N/A — no `_V[N]` classes on this object.
- Test approach: Plain `@isTest` classes with inline test data plus a shared `TestDataHelper` factory method; no `fflib-apex-mocks` used for this object's tests.

## Configuration
- Custom Metadata Types: none relevant.
- Custom Settings: none relevant.
- Named Credentials: none relevant.
- Permission Sets: none relevant (no FLS/visibility changes).

## Solution alternatives considered
### Option A: Declarative only (chosen)
Rely on the existing `Discount_to_Apply__c` picklist default (`Account`) and update `RestrictDiscountToApply` into a single merged validation rule blocking both-blank and both-populated.
- Pros: no Apex change, minimal effort, zero governor-limit footprint.
- Cons: does not fix defaulting for records inserted via `OrderHaulageTonnageOrLiftPriceService` flow, API, or integration users that explicitly submit a blank `Discount_to_Apply__c` — the picklist default only applies when the field is omitted from manual UI entry. This is the actual root cause described in the ticket.
- Risk: **Accepted by developer** on 2026-09-21 after this gap was explicitly raised.
- Effort: S.

### Option B: Apex trigger helper defaulting (recommended, not chosen)
Extend `RecurringTriggerHelper.populateDates()` (before-insert branch) to default `Discount_to_Apply__c = 'Account'` when both it and `ManualPrice__c` are blank, plus the same merged validation rule.
- Pros: fires on every insert regardless of origin (UI/API/Bulk/Flow/integration); matches existing codebase pattern (helper already defaults other fields); before-insert trigger runs before validation rules so no false blocks.
- Cons: requires Apex change + test update.
- Risk: Low.
- Effort: S.

### Option C: New record-triggered Flow (not chosen)
Add a new before-save Flow to default the field, alongside the merged validation rule.
- Pros: no Apex change.
- Cons: introduces a second automation layer alongside the existing trigger/helper, unclear execution-order interplay, diverges from this object's established pattern.
- Risk: Medium.
- Effort: S/M.

### Comparison matrix
| Criterion | Option A | Option B | Option C |
|---|---|---|---|
| Effort | S | S | S/M |
| Governor-limit impact | None | None | None |
| Bulkification complexity | N/A | Low (existing loop) | Low, unproven on this object |
| Versioning impact | N/A | Modifies existing method | New metadata component |
| Aligns with FM patterns | Partial | Yes | No |
| Reuses existing code | Validation rule only | `RecurringTriggerHelper`, `RecurringTest`, `TestDataHelper` | None |
| Fixes root cause (all creation paths) | No | Yes | Yes |

## Recommendation
Option B — Apex trigger helper defaulting — was recommended because it is the only option that reliably covers all creation paths, matching the approved NFR. It was presented and explained to the developer.

## Chosen approach
Option A (declarative only), selected by developer on 2026-09-21, with the all-creation-paths gap explicitly raised and accepted as a known risk/limitation of this ticket's scope.
