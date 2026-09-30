<!--
Traceability
Ticket: CRMFM-7
Artifact: worklog.md
Purpose: context persistence across sessions — read this FIRST on resume.
Last updated: 2026-09-30
-->

# Worklog — CRMFM-7: Default Discount Type and enforce manual pricing rules on Recurring Orders

## Current state
- **Active gate:** Gate 7 — Commit + Pull Request
- **Next action:** Create the single commit, then propose PR for human approval.
- **Blocked on:** nothing — committing now.

## Gate 2 exploration findings (do not re-derive)
- Recurring Order = `Recurrings__c` custom object.
- `Discount_to_Apply__c` (picklist, values `Account`/`Partner`) = "Discount Type" from the
  ticket. It already has `<default>true</default>` on `Account` in field metadata — but
  this is a UI-layout-only default; it does NOT apply to records created via API/Flow/data
  load, which is the actual root cause of the bug (confirmed: field unchanged since initial
  commit, so this pre-existing default alone does not solve the ticket).
- `ManualPrice__c` (Currency) = "Manual Price" from the ticket.
- Existing trigger: `RecurringTrigger` (before insert, before update) delegates to
  `RecurringTriggerHelper` — FM TriggerHandler pattern confirmed present for this object.
- Existing validation rules live at
  `force-app/main/default/objects/Recurrings__c/validationRules/` — simple
  `errorConditionFormula` + `errorDisplayField` + `errorMessage` style (e.g.
  `RequireActiveProduct`).
- Strong precedent for the declarative approach: `OrderProductBeforeSave.flow-meta.xml` is
  an existing **RecordBeforeSave** flow (`recordTriggerType: CreateAndUpdate`) on OrderItem
  that already branches on the analogous `Discount_to_Apply__c` field — same pattern
  reusable for Recurrings__c.
- `RecurringBatch.cls` bulk-updates `Recurrings__c` (`Database.update`) but does not touch
  `ManualPrice__c`/`Discount_to_Apply__c` — confirms a validation rule scoped with
  `ISCHANGED()` on those two fields will not break this batch or other unrelated updates
  (supports the "existing records not unintentionally modified" AC).
- No Apex/batch code inserts `Recurrings__c` directly except tests — `NoTriggers__c`
  bypass (Apex-trigger-only) is not a relevant risk here since nothing bulk-inserts this
  object outside the UI/API paths our new logic must cover anyway.
- Existing test factory: `TestDataHelper.insertRecurring(accountId, productId, supplierId)`
  — reusable in new test coverage.

## Story type
- [x] Code change  [ ] Analysis / spike only

## Key facts (do not re-derive)
- Chosen approach: not yet decided (Gate 2 not started).
- Dev sandbox alias: fm-ai
- Branch: `bugfix/CRMFM-7-recurring-order-discount-type-default` (created: yes)
- Artifact directory: `docs/artifacts/CRMFM-7/`
- Clarified with developer during Gate 1:
  - CRMFM-7 is unrelated to CRMFM-2 (reverted "RestrictDiscountToApply" validation rule) —
    build fresh, do not reuse/investigate that history.
  - When `Manual Price` is blank, only `Discount Type = Account` is valid (no other
    non-blank value).
  - No retroactive enforcement against existing non-compliant records — going-forward only.
  - Default-value mechanism preference: declarative (no Apex for the default itself).

## Gate log
| Gate | Status | Date | Notes / decisions |
|---|---|---|---|
| 1 Requirements | APPROVED | 2026-09-30 | requirements.md saved; 4 clarifying questions answered by developer |
| 2 Exploration + Design | APPROVED | 2026-09-30 | exploration.md saved: yes; Option A chosen; technical-design.md approved |
| 3 Specs | APPROVED | 2026-09-30 | specs.md revised: dropped BlankManualPrice_Requires_Account_DiscountType per developer instruction; requirements.md AC5 marked DESCOPED for traceability |
| 4 Branch | APPROVED | 2026-09-30 | Branch created: bugfix/CRMFM-7-recurring-order-discount-type-default |
| Pre-5 Retrieve | DONE | 2026-09-30 | confirmed by developer: yes (fm-ai sandbox, no conflicts) |
| 5 Implementation | | | steps done: 0/n |
| 5/6 Tests | APPROVED | 2026-09-30 | RecurringDiscountTypeTest.cls approved |
| 6 Verification | APPROVED | 2026-09-30 | Deployed to fm-ai (2 rounds — 2nd fixed a Gate-6 design gap); 8/8 Apex tests pass; static analysis explicitly skipped per developer instruction |
| 7 Commit + PR | | | artifacts committed: no |

## Implementation steps
| # | Component | Implemented | Tested | Approved |
|---|---|---|---|---|
| 1 | ManualPrice_Requires_Blank_DiscountType.validationRule-meta.xml | yes | yes | yes |
| 2 | RecurringOrderDefaultDiscountType.flow-meta.xml (revised in Gate 6 with a second Decision branch to clear the platform-injected default) | yes | yes | yes |
| 3 | RecurringDiscountTypeTest.cls (renamed from RecurringOrderDiscountTypeValidationTest.cls — 40 chars exceeded FM's 36-char class-name limit; revised in Gate 6 to fix wrong Account record type + bulk-test SOQL limit + add platform-default regression test) | yes | n/a | yes |
| — | manifest/CRMFM-7.xml (package manifest for the 3 new components) | yes | n/a | yes |

## Decisions & rationale
- 2026-09-30 — Approach chosen: Option A — Before-Save Record-Triggered Flow (default
  `Discount_to_Apply__c = 'Account'` when both it and `ManualPrice__c` are blank) +
  Validation Rule (mutual-exclusion enforcement, `ISCHANGED()`-scoped). Fully declarative,
  no Apex, mirrors existing `OrderProductBeforeSave` flow pattern.
- 2026-09-30 — Gate 6 testing in fm-ai revealed `Discount_to_Apply__c`'s picklist
  `<default>true</default>` on `Account` is applied by the platform on every Apex/API
  insert that omits the field (not UI-only, as `exploration.md` originally assumed). This
  broke AC4 (Manual Price populated + Discount Type blank) because the platform-injected
  `Account` value tripped the new validation rule. Fixed by adding a second Decision branch
  to the flow: when `ManualPrice__c` is populated and `Discount_to_Apply__c` arrives as
  `Account`, clear it (via a null-default String flow variable — `$GlobalConstant.EmptyString`
  does not exist and was rejected at deploy time). An explicit `Partner` value is left
  alone so genuine conflicts still hit the validation rule. `exploration.md` and `specs.md`
  updated to record the correction. Also fixed two real test bugs found during this cycle:
  wrong Account record type (`Account__c` requires `Location`, not `Account`/Parent) and a
  101-SOQL-query bulk-test failure (was re-querying inside a 200-iteration loop).
- 2026-09-30 — Developer instructed removal of `BlankManualPrice_Requires_Account_DiscountType`
  from specs.md. Effect: AC5 (blocking a blank Manual Price paired with a non-Account,
  non-blank Discount Type) is no longer enforced by this ticket. Only one validation rule
  remains: `ManualPrice_Requires_Blank_DiscountType`. Flagged as an open item in specs.md —
  requirements.md AC5 not yet formally updated to reflect the descope, pending developer
  confirmation.
- 2026-09-30 — Treat CRMFM-7 as standalone/unrelated to CRMFM-2 — explicit developer
  direction, do not reuse reverted validation rule.
- 2026-09-30 — Discount Type must be exactly `Account` (not just non-blank) when Manual
  Price is blank — explicit developer direction, narrows AC #5.
- 2026-09-30 — Enforcement is going-forward only, no backfill/remediation of legacy data —
  explicit developer direction.
- 2026-09-30 — Prefer declarative implementation (field default + validation rule) over
  Apex for the defaulting behavior — explicit developer direction; final mechanism for
  enforcement (validation rule vs Apex) still to be confirmed in Gate 2.

## Deviations from design
- None yet (Gate 2 not started).

## Open questions / follow-ups
- [ ] Confirm exact API names for `Discount Type` (picklist) and `Manual Price` fields on
      Recurring Order during Gate 2 exploration.
- [ ] Confirm exact validation-rule scoping semantics so legacy non-compliant records are
      not newly blocked on unrelated edits (ISNEW() vs field-change-aware condition).
