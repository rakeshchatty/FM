<!--
Traceability
Ticket: CRMFM-2
Artifact: specs.md
Gate: 3
Status: DRAFT
Requirements: ./requirements.md
Design: ./technical-design.md
Status: APPROVED
Last updated: 2026-09-21
-->

# Specifications — CRMFM-2: Recurring Order - Default "Discount to Apply" to Account & enforce mutual-exclusivity validation with Manual Price

Specs are ordered by dependency. Each is independently implementable.

---

## Spec 1: Merge validation rule to block both-blank and both-populated

**Satisfies:** AC2, AC3, AC4
**FM layer / order position:** 1. Custom Objects / Fields (schema/validation metadata)

### Acceptance criteria
- [ ] Given `ManualPrice__c` blank and `Discount_to_Apply__c` blank, saving the record is blocked with the rule's error message.
- [ ] Given `ManualPrice__c` populated and `Discount_to_Apply__c` populated, saving the record is blocked with the rule's error message.
- [ ] Given exactly one of `ManualPrice__c` / `Discount_to_Apply__c` populated, the record saves successfully.
- [ ] Error is displayed on the `Discount_to_Apply__c` field.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/objects/Recurrings__c/validationRules/RestrictDiscountToApply.validationRule-meta.xml` | modified | Merge both-blank condition into existing both-populated rule |
| `force-app/main/default/classes/RecurringTest.cls` | modified | Add/extend test methods asserting new validation behavior |

### Method contracts
N/A — declarative validation rule, no Apex method signature. Formula:
```
OR(
  AND(NOT(ISBLANK(ManualPrice__c)), NOT(ISBLANK(TEXT(Discount_to_Apply__c)))),
  AND(ISBLANK(ManualPrice__c), ISBLANK(TEXT(Discount_to_Apply__c)))
)
```
Error message: `"A Recurring Order must have either a Manual Price or a Discount to Apply, but not both and not neither."`

### Governor-limit budget
SOQL 0 / DML 0 / CPU negligible / callouts 0 (declarative, evaluated by the platform at save time)

### Test scenarios
- Happy path: insert with `Discount_to_Apply__c = 'Account'`, `ManualPrice__c = null` -> succeeds.
- Happy path: insert with `ManualPrice__c = 10`, `Discount_to_Apply__c = null` -> succeeds.
- Negative: insert with both null -> `DmlException` with expected error message.
- Negative: insert with both populated -> `DmlException` with expected error message.
- Edge: update an existing record clearing both fields -> blocked.
- Bulk (200): insert 200 valid `Recurrings__c` records (one field populated each) in one DML -> all succeed, no per-row governor issues (declarative rule, no additional SOQL/DML from this change).
- Regression: existing `RecurringTest.cls` scenarios (date population, supplier-product validation) continue to pass.

---

## Spec 2: Post-deployment data-fix script for existing bad records

**Satisfies:** AC6
**FM layer / order position:** N/A — one-off anonymous Apex, not deployed metadata; depends on Spec 1 being deployed first (records must pass the new rule once fixed)

### Acceptance criteria
- [ ] Script queries all `Recurrings__c` where `ManualPrice__c = null AND Discount_to_Apply__c = null`.
- [ ] Script sets `Discount_to_Apply__c = 'Account'` on each and performs a single bulk `update`.
- [ ] Script is idempotent — re-running after a successful fix updates 0 records.
- [ ] Script logs the count of records updated.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `manifest/CRMFM-2-datafix-discount-to-apply.apex` | new | One-off anonymous Apex data-fix script, run manually via `sf apex run --file` against the target org after Spec 1 is deployed |

### Method contracts
N/A — anonymous Apex script, not a class/method. Logic:
```apex
List<Recurrings__c> toFix = [
    SELECT Id, Discount_to_Apply__c, ManualPrice__c
    FROM Recurrings__c
    WHERE ManualPrice__c = null AND Discount_to_Apply__c = null
];
for (Recurrings__c r : toFix) {
    r.Discount_to_Apply__c = 'Account';
}
if (!toFix.isEmpty()) {
    update toFix;
}
System.debug('CRMFM-2 data fix: updated ' + toFix.size() + ' Recurrings__c records.');
```

### Governor-limit budget
SOQL 1 / DML 1 / CPU proportional to record count / callouts 0.
**Note:** if the query in the target org returns more than ~10,000 records, this single
anonymous script may need to be converted to a batch class before running — record count
to be confirmed in the dev sandbox during Gate 6 before execution.

### Test scenarios
This is a one-off operational script, not covered by an Apex test class. Verification is
manual in Gate 6: run in the dev sandbox, query before/after to confirm the count of
blank/blank records drops to 0 and no unrelated records were changed.

---

## Implementation order (this ticket)
1. Spec 1 — Merge validation rule (+ tests)
2. Spec 2 — Post-deployment data-fix script (created now, executed manually in Gate 6 after Spec 1 is deployed)

## Sign-off
Specs approved by: developer on 2026-09-21
