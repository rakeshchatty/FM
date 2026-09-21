<!--
Traceability
Ticket: CRMFM-2
Artifact: requirements.md
Gate: 1
Status: APPROVED
Last updated: 2026-09-21
-->

# Requirements — CRMFM-2: Recurring Order - Default "Discount to Apply" to Account & enforce mutual-exclusivity validation with Manual Price

## Problem statement
Following the recent change to `Recurrings__c` (Recurring Order) to support manual pricing
/ manual supplier pricing, the `Discount_to_Apply__c` ("Discount to Apply" / "Discount
Type") field is not being pre-populated when a Recurring Order is created. As a result,
many Recurring Orders have been saved with **Manual Price blank** and **Discount to Apply
blank**, meaning no discount and no manual price is applied — customers are being charged
full list price in error.

Existing validation rule `RestrictDiscountToApply` on `Recurrings__c` only blocks records
where *both* `ManualPrice__c` and `Discount_to_Apply__c` are populated. It does not catch
the case where *both are blank*, which is the actual root cause of the pricing defect.

## Assumptions
- "Recurring Order" refers to the `Recurrings__c` custom object — **confirmed**.
- "Discount Type" in the ticket title/description refers to the `Discount_to_Apply__c` picklist field (label "Discount to Apply", values `Account`/`Partner`) — confirmed by context.
- The default must apply consistently across **all** creation paths (UI, API, Flow, integration users) — the picklist field's `<default>true</default>` alone is not sufficient, since it is not guaranteed to apply to API-inserted records; automation (e.g. before-insert Flow or trigger) will likely be required in addition to the field default.
- Existing bad records (both fields blank) are **not** part of the field/validation-rule deliverable, but a data-fix for them will be delivered as a **post-deployment step** documented alongside this ticket's deployment (e.g. an anonymous Apex script or data-fix instructions referenced from `manifest/`), not as a separate story.

## Open questions
- [x] Is `Recurrings__c` definitely the correct object? -> **Yes, confirmed.**
- [x] Does the default need to apply only to manual UI record creation, or also to records created via API / Flow / integration? -> **Yes, must work for all creation paths (UI, API, Flow, integration).**
- [x] Should the new validation rule replace `RestrictDiscountToApply`, or should it be added as a second, complementary rule? -> **Replace/merge into a single validation rule covering both conditions (both-blank and both-populated).**
- [x] Is a data-fix for existing bad records wanted as part of this ticket, or strictly a follow-up story? -> **Not a schema/validation deliverable, but include a post-deployment data-fix step (referenced in `manifest/`) as part of this ticket's rollout.**

## Scope
### In scope
- Default `Discount_to_Apply__c` to `Account` on new `Recurrings__c` records, for **all** creation paths (manual UI, API, Flow, integration users).
- A single validation rule (replacing/merging `RestrictDiscountToApply`) to block save unless exactly one of `ManualPrice__c` / `Discount_to_Apply__c` is populated (both blank -> blocked; both populated -> blocked).
- A post-deployment data-fix step (e.g. anonymous Apex, run once against existing bad records) to set `Discount_to_Apply__c` = `Account` on existing `Recurrings__c` records where both `ManualPrice__c` and `Discount_to_Apply__c` are blank, so they pass the new validation going forward. Documented/referenced under `manifest/` as part of this ticket's deployment, not built into the validation rule/trigger itself.

### Out of scope
- Changes to other objects with similar Discount Type / Manual Price pairs (e.g. `Schedule__c`, `Collection_Waypoints__c`) unless requested.
- Any data-fix beyond the specific blank/blank `Recurrings__c` scenario (e.g. records with invalid/mismatched values) — to be raised separately if discovered.

## Acceptance criteria
1. **Given** a new Recurring Order with no value entered for Discount to Apply, **when** the record is created, **then** Discount to Apply defaults to "Account".
2. **Given** a Recurring Order where Manual Price is blank and Discount to Apply is blank, **when** the user attempts to save, **then** the save is blocked with a clear validation error.
3. **Given** a Recurring Order where Manual Price is populated and Discount to Apply is populated, **when** the user attempts to save, **then** the save is blocked (existing behavior retained).
4. **Given** a Recurring Order where exactly one of Manual Price / Discount to Apply is populated, **when** the user attempts to save, **then** the save succeeds.
5. **Given** a Recurring Order created via an automated path (API/Flow/integration) without an explicit Discount to Apply value, **when** the record is saved, **then** Discount to Apply is still defaulted/validated consistently with criterion 1.
6. **Given** the post-deployment data-fix step has run, **when** existing `Recurrings__c` records with both `ManualPrice__c` and `Discount_to_Apply__c` blank are checked, **then** those records now have `Discount_to_Apply__c` = `Account` and pass the new validation rule.

## Non-functional requirements (Salesforce)
- **Objects affected:** Custom — `Recurrings__c` (Recurring Order).
- **Bulk / volume:** Recurring Orders can be created in bulk (import/integration); validation and default logic must be bulk-safe (no per-row SOQL/DML).
- **Governor-limit budget:** SOQL 0, DML 0 (declarative default + validation rule expected), CPU negligible; to be confirmed after Gate 2 exploration if an Apex/Flow path is required instead of a pure picklist default.
- **Sharing model:** N/A for a validation rule / field default; no new Apex context created unless automation is needed.
- **LWC:** Not expected — no UI changes anticipated.
- **Integrations:** Must confirm behavior for records created via API/integration users, since picklist field defaults are only guaranteed to apply for UI-created records, not API-inserted records.
- **REST versioning:** N/A.
- **Security / compliance:** No PII/FLS impact — pricing fields only, no schema visibility changes.

## Story type
- [x] Code change (declarative: field default + validation rule; possible automation if picklist default doesn't cover API-created records)
- [ ] Analysis / spike only

## Sign-off
- Requirements approved by: developer on 2026-09-21
- Open questions resolved: 2026-09-21 (object confirmed, all-creation-paths default required, single merged validation rule, data-fix delivered as a post-deployment step referenced under `manifest/`)
