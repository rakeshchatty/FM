<!--
Traceability
Ticket: CRMFM-6
Jira URL: https://rakeshchatty.atlassian.net/browse/CRMFM-6
Artifact: specifications.md
Gate: 3
Status: APPROVED
Last updated: 2026-09-27
-->

# Specifications — CRMFM-6

Specifications approved by developer on 2026-09-27.

## 1. Metadata specification

Create:

`force-app/main/default/objects/Recurrings__c/validationRules/RequirePriceOrDiscount.validationRule-meta.xml`

Required metadata:

- `fullName`: `RequirePriceOrDiscount`
- `active`: `true`
- `errorDisplayField`: `Discount_to_Apply__c`
- `errorMessage`: `Enter either Manual Price or Discount to Apply.`
- `errorConditionFormula`:

```text
AND(ISBLANK(ManualPrice__c), ISBLANK(TEXT(Discount_to_Apply__c)))
```

Preserve without modification:

`force-app/main/default/objects/Recurrings__c/validationRules/RestrictDiscountToApply.validationRule-meta.xml`

The existing `Discount_to_Apply__c` field metadata must retain its `Account` default.

## 2. Test specification

Update:

`force-app/main/default/classes/RecurringTest.cls`

Add focused test methods or an equivalent focused section that verifies:

| Case | ManualPrice__c | Discount_to_Apply__c | Expected |
|---|---:|---|---|
| Manual price only | `100` | blank | Insert succeeds |
| Account discount only | blank | `Account` | Insert succeeds |
| Partner discount only | blank | `Partner` | Insert succeeds |
| Both values | `100` | `Account` | Insert fails with `RestrictDiscountToApply` |
| Neither value | blank | blank | Insert fails with `RequirePriceOrDiscount` |
| Default behavior | blank | omitted | Salesforce supplies `Account` for the user-created path |

The test must use `Database.insert(record, false)` when asserting validation errors so both valid and invalid outcomes can be inspected without aborting the test transaction. Error assertions must verify the relevant validation rule or message.

Include a bulk case with at least 200 records, using `Database.insert(records, false)`, and assert the expected success/error counts. The test must not introduce production data dependencies or callouts.

## 3. Report specification

Create a non-destructive operator script or documented CLI query under `docs/artifacts/CRMFM-6/` that reports:

```sql
SELECT Id, Name, ManualPrice__c, Discount_to_Apply__c
FROM Recurrings__c
WHERE ManualPrice__c = null
AND Discount_to_Apply__c = null
ORDER BY CreatedDate ASC
```

The report must:

- target only a developer sandbox or scratch org;
- print candidate records and values;
- perform no insert, update, delete, or execute anonymous mutation;
- be suitable for pre- and post-deployment review.

## 4. Verification specification

Before implementation:

- Retrieve metadata from the named developer sandbox or scratch org after the alias is supplied.
- Confirm the local `Recurrings__c` metadata matches the target environment.

After implementation:

- Validate the XML metadata locally.
- Run the focused Apex test in the developer sandbox or scratch org.
- Verify all behavior matrix cases.
- Run the report and retain the candidate count/output as deployment evidence.
- Confirm the existing `RestrictDiscountToApply` rule remains active and unchanged.
- Confirm no production org is accessed.

## 5. Acceptance mapping

- AC1: Existing `Account` field default and default behavior test.
- AC2: `RequirePriceOrDiscount` validation rule and neither-value test.
- AC3: Existing `RestrictDiscountToApply` rule and both-values test.
- AC4: Manual-only, Account-only, and Partner-only tests.
- AC5: Read-only report and no-mutation verification.

## 6. Out-of-scope guard

Do not create a trigger, handler, Flow, data update script, destructive deployment, production deployment, commit, or pull request as part of Gate 3 implementation preparation.
