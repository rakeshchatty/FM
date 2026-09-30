<!--
Traceability
Ticket: CRMFM-7
Artifact: requirements.md
Gate: 1
Status: APPROVED
Last updated: 2026-09-30
-->

# Requirements — CRMFM-7: Default Discount Type and enforce manual pricing rules on Recurring Orders

## Problem statement
Recurring Order records can currently be created and saved with `Discount Type` left blank
while `Manual Price` is also blank. This causes customers to be charged full price
unintentionally, since no discount is ever applied by default. Separately, there is no
enforcement preventing `Manual Price` and `Discount Type` from being populated at the same
time, which represents two conflicting pricing mechanisms being active on the same record.

This ticket introduces a consistent, enforced pricing model on Recurring Order:
- New records default to a known discount behavior (`Discount Type = Account`) instead of
  defaulting to "no discount."
- `Manual Price` and `Discount Type` are treated as mutually exclusive pricing mechanisms —
  exactly one may be populated at a time (or `Manual Price` populated with `Discount Type`
  blank).

This is treated as a **net-new, standalone change** — independent of the previously
reverted CRMFM-2 ("RestrictDiscountToApply" validation rule, merged and reverted). Per
developer direction, CRMFM-2 history is not being reused or investigated as a starting
point.

## Assumptions
- `Discount Type` is an existing picklist field on Recurring Order with a value literally
  named `Account` — to be confirmed in Gate 2 exploration.
- `Manual Price` is an existing field on Recurring Order (type to be confirmed — likely
  currency/number) that is populated when a rep manually overrides pricing.
- The default value `Account` is achievable via a declarative default (field-level default
  value formula, e.g. `IF(ISBLANK(Manual_Price__c), "Account", "")`, or a Flow) — no Apex
  is required for the defaulting behavior per developer direction.
- The mutual-exclusion enforcement (validation) is expected to be declarative (Validation
  Rule) unless Gate 2 exploration surfaces a reason it must be Apex — to be confirmed.
- "Existing Recurring Orders are not unintentionally modified" means: (a) no retroactive
  backfill of `Discount Type` on already-existing records, and (b) the new validation only
  blocks saves that actively move a record into a violating state — it does not force a fix
  on unrelated edits to already-violating legacy records.

## Open questions
- [x] How does this relate to CRMFM-2? -> answer: Unrelated — build fresh, do not reuse or
      investigate the reverted CRMFM-2 validation rule.
- [x] When `Manual Price` is blank, which `Discount Type` values are allowed? -> answer:
      Only `Account`. Any other non-blank `Discount Type` value while `Manual Price` is
      blank is invalid.
- [x] Should the rule enforce retroactively against existing violating records? -> answer:
      No — going-forward enforcement only; a save is blocked only when the save itself
      would create/keep an invalid combination is being actively introduced by that save's
      relevant field changes (exact re-save semantics to be finalized in Gate 2 design,
      since "not unintentionally modified" implies untouched legacy records must not be
      force-broken by a mass validation-rule turn-on).
- [x] Preferred mechanism for defaulting `Discount Type`? -> answer: Declarative default
      (no Apex for the default-assignment itself).
- [ ] Confirm the exact picklist API name/values for `Discount Type` and the API name for
      `Manual Price` on Recurring Order — to be confirmed in Gate 2 exploration (read-only,
      no guessing).
- [ ] Confirm whether "existing Recurring Orders are not unintentionally modified" requires
      the validation rule to be scoped to `ISNEW()` only, or to also apply to updates of
      previously-compliant records (edits that would newly introduce a violation) — default
      assumption: validation applies on insert and update, but only fires when the
      offending fields are what make the record non-compliant, never coercing/blocking
      saves of already-existing non-compliant records for unrelated field changes unless
      those changes touch `Manual Price` or `Discount Type` themselves.

## Scope
### In scope
- Default `Discount Type` to `Account` on new Recurring Order creation when `Manual Price`
  is blank.
- Validation enforcing: if `Manual Price` is populated, `Discount Type` must be blank.
- Validation enforcing: if `Manual Price` is blank, `Discount Type` must be `Account` (no
  other non-blank value permitted).
- Clear, field-specific validation error messaging indicating which field must be cleared.
- Going-forward enforcement only — no retroactive backfill/remediation of existing
  non-compliant Recurring Orders.

### Out of scope
- Reusing, reviving, or referencing the reverted CRMFM-2 `RestrictDiscountToApply`
  validation rule.
- Data remediation / bulk backfill of existing Recurring Order records.
- Changes to any other object's pricing logic (e.g., Order, Order Product, Quote).
- UI/LWC changes (this is expected to be a declarative field-default + validation-rule
  change unless Gate 2 finds otherwise).

## Acceptance criteria
1. **Given** a new Recurring Order is created with `Manual Price` blank **when** the record
   is saved without an explicit `Discount Type` **then** `Discount Type` defaults to
   `Account`.
2. **Given** a Recurring Order has `Manual Price` blank **when** it is saved with
   `Discount Type = Account` **then** the save succeeds.
3. **Given** a Recurring Order has `Manual Price` populated **when** it is saved with
   `Discount Type` also populated **then** the save is blocked with an error identifying
   that `Discount Type` must be cleared.
4. **Given** a Recurring Order has `Manual Price` populated **when** it is saved with
   `Discount Type` blank **then** the save succeeds.
5. ~~**Given** a Recurring Order has `Manual Price` blank **when** it is saved with a
   `Discount Type` value other than `Account` (and not blank) **then** the save is blocked
   with an error identifying that `Discount Type` must be `Account` or blank cleared to
   allow default.~~ **DESCOPED 2026-09-30** — per developer instruction during Gate 3, the
   validation rule that would enforce this (`BlankManualPrice_Requires_Account_DiscountType`)
   was removed from `specs.md`. A blank `Manual Price` paired with any `Discount Type`
   value (including non-`Account` values like `Partner`) is now allowed to save. See
   `specs.md` Spec 2 and the worklog decision log.
6. **Given** an existing Recurring Order already violates the new rule **when** it is saved
   again without touching `Manual Price` or `Discount Type` **then** the save is not newly
   blocked by this rule (no forced remediation of unrelated edits).
7. Validation error messages clearly state which field must be cleared/changed before the
   record can be saved.

## Non-functional requirements (Salesforce)
- **Objects affected:** Recurring Order (custom object, exact API name to confirm in Gate
  2) — no other objects.
- **Bulk / volume:** Declarative validation rules and field defaults are evaluated
  per-record on DML by the platform; no Apex trigger volume/batch concerns anticipated
  unless Gate 2 determines Apex is required.
- **Governor-limit budget:** N/A if fully declarative (0 additional SOQL/DML/CPU from
  custom Apex). To be revisited if Gate 2 concludes Apex is necessary.
- **Sharing model:** N/A (no Apex introduced under the current assumption).
- **LWC:** None anticipated.
- **Integrations:** None.
- **REST versioning:** None anticipated — no REST resource changes expected.
- **Security / compliance:** None beyond existing field-level security on `Discount Type`
  and `Manual Price`.

## Story type
- [x] Code change (declarative metadata: field default value + validation rule)
- [ ] Analysis / spike only

## Sign-off
- Requirements approved by: rakeshchatty on 2026-09-30
