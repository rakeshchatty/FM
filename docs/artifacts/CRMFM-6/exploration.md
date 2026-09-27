<!--
Traceability
Ticket: CRMFM-6
Jira URL: https://rakeshchatty.atlassian.net/browse/CRMFM-6
Artifact: exploration.md
Gate: 2
Status: COMPLETE
Last updated: 2026-09-27
-->

# Exploration — CRMFM-6

## Confirmed implementation surface

The Recurring Order object is the custom Salesforce object `Recurrings__c`.

Relevant metadata:

- `ManualPrice__c` is an optional Currency field.
- `Discount_to_Apply__c` is an optional restricted picklist with values `Account` and `Partner`.
- `Discount_to_Apply__c` currently defaults to `Account`.
- `RestrictDiscountToApply` is active and blocks both `ManualPrice__c` and `Discount_to_Apply__c` from being populated together.
- Existing Recurring Order creation paths include Apex tests/batch behavior and Flow-based creation. The requirement limits defaulting behavior to user-created records.

## Existing validation

Current rule: `RestrictDiscountToApply`

```text
AND(
  NOT(ISBLANK(ManualPrice__c)),
  NOT(ISBLANK(TEXT(Discount_to_Apply__c)))
)
```

Current error: `You can have a "Manual Price" or Discount but not both.`

## Solution alternatives

| Criterion | Option A: Validation Rule | Option B: Before-save Flow | Option C: Apex Trigger/Handler |
|---|---|---|---|
| Effort | Small | Medium | Large |
| Governor-limit impact | None | None | Potential CPU impact |
| Bulkification complexity | None | Low | High |
| Versioning impact | None | Flow metadata versioning | Apex and test versioning |
| Alignment with FM patterns | Strong for declarative validation | Partial; adds automation for a field default | Weak; over-engineered for this requirement |
| Reuse | Reuses the existing field default and validation rule | Reuses Flow conventions | Limited reuse |

### Option A — selected

Keep the existing field default and validation rule, and add a second validation rule that blocks both fields from being blank:

```text
AND(
  ISBLANK(ManualPrice__c),
  ISBLANK(TEXT(Discount_to_Apply__c))
)
```

Extend the relevant test coverage for the four combinations and bulk behavior. Provide a read-only post-deployment candidate-reporting script for existing invalid records. The script must not mutate records by default.

### Option B — not selected

A before-save Flow could explicitly set `Discount_to_Apply__c` to `Account` and enforce the blank-value condition. This is unnecessary because the field already has the required default and would introduce additional automation to the save path.

### Option C — not selected

An Apex trigger/handler could perform the defaulting and validation, but this would add code, tests, CPU/governor-limit considerations, and maintenance cost without providing required behavior beyond the declarative solution.

## Decision

The developer selected **Option A** on 2026-09-27.

## Constraints carried into design

- Defaulting applies to user-created Recurring Orders only.
- Existing both-populated validation behavior must remain unchanged.
- Exactly one populated field must save successfully.
- Both blank must be blocked with a clear validation error.
- No SOQL, DML, or callouts are required for the validation/defaulting change.
- Existing invalid records must be reported by a non-destructive post-deployment script; automatic remediation is out of scope.
- No production access or deployment is permitted.
