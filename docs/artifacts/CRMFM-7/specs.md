<!--
Traceability
Ticket: CRMFM-7
Artifact: specs.md
Gate: 3
Status: APPROVED
Requirements: ./requirements.md
Design: ./technical-design.md
Last updated: 2026-09-30
-->

# Specifications — CRMFM-7: Default Discount Type and enforce manual pricing rules on Recurring Orders

Specs are ordered by dependency. Each is independently implementable. Per
`technical-design.md`, the "Validation Rule" concept is implemented here as a single
validation rule enforcing only the Manual Price -> blank Discount Type direction. Per
developer instruction on 2026-09-30, the `BlankManualPrice_Requires_Account_DiscountType`
rule (which would have blocked a blank `ManualPrice__c` paired with a non-`Account`,
non-blank `Discount_to_Apply__c`) has been **removed from scope**. This means requirement
AC5 in `requirements.md` is **no longer enforced** by this ticket — see the open item at
the end of this document.

---

## Spec 1: Before-Save Flow — default Discount Type

**Satisfies:** AC1, AC4
**FM layer / order position:** Metadata — Automation (Before-Save Flow)

### Revision note (post Gate-6 discovery, 2026-09-30)
Gate 6 testing in the `fm-ai` sandbox revealed that `Discount_to_Apply__c`'s existing
picklist-level `<default>true</default>` on `Account` **is applied by the platform on every
Apex/API insert that omits the field** (verified empirically — it is not UI-only, contrary
to the `exploration.md` assumption). Because platform field defaults are substituted
*before* Before-Save flows run, a record inserted with `ManualPrice__c` populated and
`Discount_to_Apply__c` omitted arrives at our flow already showing
`Discount_to_Apply__c = 'Account'`, which then tripped Spec 2's validation rule and blocked
the save — a regression against AC4. The flow below is revised to also counteract that
platform default. Only the literal `'Account'` value is treated as "possibly
platform-injected, not a deliberate choice" — an explicit `Partner` value alongside a
populated `ManualPrice__c` is left alone so it still hits the Spec 2 validation rule
(AC3 is preserved).

### Acceptance criteria
- [ ] A new `Recurrings__c` record with `ManualPrice__c` blank and `Discount_to_Apply__c`
      blank saves with `Discount_to_Apply__c = 'Account'`.
- [ ] A new record with `Discount_to_Apply__c` already explicitly set to `Partner` is left
      unchanged by this flow, regardless of `ManualPrice__c`.
- [ ] A new record with `ManualPrice__c` populated and `Discount_to_Apply__c` arriving as
      `Account` (whether platform-defaulted or explicitly set) has `Discount_to_Apply__c`
      cleared to blank by this flow, so the save succeeds (AC4).
- [ ] A new record with `ManualPrice__c` populated and `Discount_to_Apply__c` already blank
      is left unchanged by this flow.
- [ ] Updates to existing records where both fields are already non-blank do not trigger
      any field change from this flow (field defaults only apply on insert, not update).

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/flows/RecurringOrderDefaultDiscountType.flow-meta.xml` | new | Before-Save Record-Triggered Flow defaulting/clearing `Discount_to_Apply__c` |

### Flow design contract
- Object: `Recurrings__c`
- `processType`: `AutoLaunchedFlow`; `start.triggerType`: `RecordBeforeSave`;
  `start.recordTriggerType`: `CreateAndUpdate` (matches `OrderProductBeforeSave` precedent).
- No start-level entry filter (two distinct branches are needed, so filtering moved into a
  Decision element).
- Decision `IsManualPricePopulatedWithDefaultDiscountType` (evaluated first):
  - Condition (AND): `ManualPrice__c` Is Null = `false`; `Discount_to_Apply__c` Equals
    `'Account'`.
  - Outcome: Assignment sets `$Record.Discount_to_Apply__c` = `vBlankDiscountType` (a
    String flow variable with no default value, i.e. null — the standard Flow mechanism for
    clearing a field value; `$GlobalConstant.EmptyString` does not exist and was rejected
    at deploy time during implementation) — clears the platform-injected/default value so
    the mutual-exclusion rule doesn't false-positive.
- Decision `IsManualPriceAndDiscountTypeBlank` (default path when the above doesn't match):
  - Condition (AND): `ManualPrice__c` Is Null = `true`; `Discount_to_Apply__c` Is Null =
    `true`.
  - Outcome: Assignment sets `$Record.Discount_to_Apply__c` = `'Account'`.
- Otherwise: no action.
- Errors: none — this flow only assigns field values, never blocks a save.

### Governor-limit budget
SOQL 0 / DML 0 / CPU negligible / callouts 0

### Test scenarios
- Happy path: insert with both fields blank -> `Discount_to_Apply__c` = `Account` after save.
- Happy path: insert with `ManualPrice__c` populated and `Discount_to_Apply__c` omitted ->
  flow clears the platform-defaulted `Account` back to blank -> save succeeds (AC4).
- Bulk (200): insert 200 records with both fields blank -> all 200 default correctly in one
  transaction.
- Edge: insert with `Discount_to_Apply__c = 'Partner'`, `ManualPrice__c` blank -> value stays
  `Partner` (flow does not override an explicit choice).
- Edge: insert with `ManualPrice__c` populated, `Discount_to_Apply__c` explicitly `'Partner'`
  -> flow leaves it as `Partner` (not `'Account'`, so the clearing branch doesn't match) ->
  Spec 2's validation rule blocks the save (AC3 preserved).
- Negative: N/A (flow never errors).
- Regression: update an existing compliant record's unrelated field (e.g. `First_Date__c`)
  -> `Discount_to_Apply__c` / `ManualPrice__c` unchanged by this flow.

---

## Spec 2: Validation Rule — Manual Price requires blank Discount Type

**Satisfies:** AC3, AC4, AC6, AC7 (AC5 descoped — see note above)
**FM layer / order position:** Metadata — Validation Rule

### Acceptance criteria
- [ ] Save blocked when `ManualPrice__c` populated and `Discount_to_Apply__c` populated.
- [ ] Save allowed when `ManualPrice__c` populated and `Discount_to_Apply__c` blank.
- [ ] Save allowed when `ManualPrice__c` blank, regardless of `Discount_to_Apply__c` value
      (including `Account`, `Partner`, or blank) — no rule constrains this combination now
      that `BlankManualPrice_Requires_Account_DiscountType` is out of scope.
- [ ] Save of a pre-existing non-compliant record is **not** newly blocked when neither
      `ManualPrice__c` nor `Discount_to_Apply__c` is part of the edit.
- [ ] Each blocked save produces a clear, field-specific error message.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/objects/Recurrings__c/validationRules/ManualPrice_Requires_Blank_DiscountType.validationRule-meta.xml` | new | Blocks save when both `ManualPrice__c` and `Discount_to_Apply__c` are populated |

### Validation rule contract

**`ManualPrice_Requires_Blank_DiscountType`**
- `active`: `true`
- `errorConditionFormula`:
  ```
  AND(
    OR(ISNEW(), ISCHANGED(ManualPrice__c), ISCHANGED(Discount_to_Apply__c)),
    NOT(ISBLANK(ManualPrice__c)),
    NOT(ISPICKVAL(Discount_to_Apply__c, ''))
  )
  ```
- `errorDisplayField`: `Discount_to_Apply__c`
- `errorMessage`: "Discount Type must be blank when Manual Price is populated. Clear Discount Type before saving."

The `OR(ISNEW(), ISCHANGED(ManualPrice__c), ISCHANGED(Discount_to_Apply__c))` guard is
always true on insert and, on update, restricts (re-)evaluation to saves that actually
touch one of the two relevant fields — satisfying AC6.

### Governor-limit budget
SOQL 0 / DML 0 / CPU negligible / callouts 0

### Test scenarios
- Happy path: `ManualPrice__c` blank, `Discount_to_Apply__c = 'Account'` -> save succeeds.
- Happy path: `ManualPrice__c` populated, `Discount_to_Apply__c` blank -> save succeeds.
- Bulk (200): insert 200 valid records (mix of the two happy-path shapes) -> all succeed.
- Edge: `ManualPrice__c = 0.00` (explicit zero, not blank) with `Discount_to_Apply__c`
  populated -> blocked (zero is not blank).
- Edge: `ManualPrice__c` blank with `Discount_to_Apply__c = 'Partner'` -> save succeeds
  (no longer blocked, since AC5 enforcement is descoped).
- Negative: `ManualPrice__c` populated and `Discount_to_Apply__c = 'Partner'` -> `DmlException`
  with `ManualPrice_Requires_Blank_DiscountType`'s message.
- Regression: an unrelated field update on an existing record does not trigger
  re-validation of this rule — see Spec 3 for the practical test approach.

---

## Spec 3: Apex test coverage for the new declarative logic

**Satisfies:** AC1, AC2, AC3, AC4, AC6, AC7 (automated regression evidence; AC5 descoped)
**FM layer / order position:** Apex test classes

### Acceptance criteria
- [ ] All Spec 1 and Spec 2 scenarios above are covered by passing, meaningfully-asserted
      Apex tests.
- [ ] Bulk (200-record) coverage included for both the flow default and the validation
      rules.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/classes/RecurringDiscountTypeTest.cls` | new | Test class covering the Before-Save Flow default/clear logic and the Validation Rule (renamed from the originally-planned `RecurringOrderDiscountTypeValidationTest` — 40 chars exceeded FM's 36-char class-name limit) |
| `force-app/main/default/classes/RecurringDiscountTypeTest.cls-meta.xml` | new | Test class metadata |

### Method contracts
- `should_default_discount_type_to_account_when_both_fields_blank()` — inserts a Recurring
  Order via `TestDataHelper.insertRecurring(...)` with `ManualPrice__c` and
  `Discount_to_Apply__c` left unset, re-queries, asserts `Discount_to_Apply__c == 'Account'`.
- `should_not_override_explicit_discount_type_when_manual_price_blank()` — inserts with
  `Discount_to_Apply__c = 'Partner'` explicitly, `ManualPrice__c` blank, asserts value stays
  `Partner` and the save succeeds (AC5's stricter enforcement of this combination is
  descoped, so this is now a valid, unblocked state).
- `should_clear_platform_default_when_manual_price_populated()` — inserts with
  `ManualPrice__c = 50` and `Discount_to_Apply__c` omitted (letting the platform's native
  picklist default and our flow both run), asserts `Discount_to_Apply__c` is blank after
  save and the insert does not throw (covers the Gate 6 regression fix). The paired
  negative case — `ManualPrice__c` populated with `Discount_to_Apply__c` explicitly
  `'Partner'` still being blocked (proving the clearing branch only swallows the
  platform-default `Account` case, not a genuine conflict) — is already covered by
  `should_block_save_when_manual_price_and_discount_type_both_populated()` below, which
  uses `Discount_to_Apply__c = 'Partner'`.
- `should_default_discount_type_in_bulk_200_records()` — builds and inserts 200 Recurring
  Orders with both fields blank, asserts all 200 come back with `Discount_to_Apply__c ==
  'Account'`.
- `should_block_save_when_manual_price_and_discount_type_both_populated()` — attempts
  insert with both populated, wraps in try/catch, asserts a `DmlException` is thrown whose
  message contains "Discount Type must be blank when Manual Price is populated.".
- `should_allow_save_when_manual_price_populated_and_discount_type_blank()` — asserts
  successful insert, no exception.
- `should_allow_save_when_manual_price_blank_and_discount_type_not_account()` — inserts with
  `ManualPrice__c` blank and `Discount_to_Apply__c = 'Partner'`, asserts the save succeeds
  (documents the descoped AC5 behavior so a future change to this rule is a visible,
  intentional test update rather than a silent regression).
- `should_not_reblock_existing_noncompliant_record_on_unrelated_update()` — since a
  genuinely non-compliant record cannot be created through normal DML (the VR always fires
  on insert), this scenario is validated by asserting: (a) inserting a compliant record,
  (b) updating an unrelated field (`First_Date__c`) succeeds without touching
  `ManualPrice__c` / `Discount_to_Apply__c`, confirming the `ISCHANGED()` guard does not
  cause false-positive re-validation on unrelated edits (positive proof of the guard's
  intended behavior, which is the practically testable half of AC6 — true legacy bad data
  can only exist via a data load that predates the rule's activation, which is outside the
  reach of an Apex test).

### Governor-limit budget
SOQL 1 per assertion re-query / DML 1 per test insert (batched for the 200-bulk test) / CPU
well within limits / callouts 0

### Test scenarios
- Happy path: see method contracts above (defaulting + both valid combinations).
- Bulk (200): `should_default_discount_type_in_bulk_200_records()`.
- Edge: explicit non-default `Discount_to_Apply__c` with blank `ManualPrice__c` is a
  deliberately invalid state per AC5 — covered by the negative test above, not a separate
  edge case.
- Negative: both mutual-exclusion violations, each asserted with a specific error-message
  substring (`Assert.isTrue(e.getMessage().contains(...), 'descriptive message')`).
- Regression: unrelated-field update does not trigger re-validation — see method contract
  above.

---

## Implementation order (this ticket)
1. Spec 2 — Validation Rule (deploy first so the safety net exists before the flow can
   write to the field)
2. Spec 1 — Before-Save Flow
3. Spec 3 — Apex test coverage

## Open item — platform default vs. validation rule (resolved 2026-09-30)
See the Spec 1 revision note above. Root cause: `Discount_to_Apply__c`'s picklist-level
default is applied by the platform on every insert that omits the field, not just via the
UI as originally assumed in `exploration.md`. Resolved by having the Before-Save Flow
clear the platform-injected `'Account'` value whenever `ManualPrice__c` is populated,
before the Validation Rule evaluates.

## Open item — requirements traceability impact
Removing `BlankManualPrice_Requires_Account_DiscountType` means AC5 in `requirements.md`
("A Recurring Order with Manual Price populated can be saved only when Discount Type is
blank" — note: AC5's actual text concerns the *other* direction, a blank Manual Price with
a non-Account Discount Type) is no longer enforced by this ticket. `requirements.md` was
already approved with AC5 in scope. Recommend marking AC5 as explicitly descoped in
`requirements.md` for traceability before Gate 4, rather than leaving an approved
requirement silently unimplemented.

## Sign-off
Specs approved by: rakeshchatty on 2026-09-30
