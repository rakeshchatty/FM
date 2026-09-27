<!--
Traceability
Ticket: CRMFM-6
Jira URL: https://rakeshchatty.atlassian.net/browse/CRMFM-6
Artifact: technical-design.md
Gate: 2
Status: APPROVED
Last updated: 2026-09-27
-->

# Technical Design — CRMFM-6

Design approved by developer on 2026-09-27.

## Decision

Implement CRMFM-6 with Salesforce declarative metadata only:

- Retain the existing default value `Account` on `Discount_to_Apply__c` for user-created Recurring Orders.
- Retain the active `RestrictDiscountToApply` validation rule that blocks both Manual Price and Discount to Apply from being populated.
- Add a second validation rule on `Recurrings__c` that blocks both fields from being blank.
- Add focused Apex tests to `RecurringTest.cls` for the validation matrix and bulk behavior.
- Provide a read-only post-deployment candidate-reporting script for existing invalid records.

No trigger, handler, Flow, SOQL, DML, callout, permission, sharing, integration, or REST changes are required.

## Metadata changes

### New validation rule

Path:

`force-app/main/default/objects/Recurrings__c/validationRules/RequirePriceOrDiscount.validationRule-meta.xml`

Formula:

```text
AND(
  ISBLANK(ManualPrice__c),
  ISBLANK(TEXT(Discount_to_Apply__c))
)
```

Proposed error message:

`Enter either Manual Price or Discount to Apply.`

Error display field:

`Discount_to_Apply__c`

The existing `RestrictDiscountToApply` rule remains unchanged. Together, the two rules enforce that exactly one of the two fields is populated for saved records.

## Behavior matrix

| Manual Price | Discount to Apply | Expected result |
|---|---|---|
| Blank | Blank | Rejected by `RequirePriceOrDiscount` |
| Blank | `Account` or `Partner` | Accepted |
| Populated | Blank | Accepted |
| Populated | `Account` or `Partner` | Rejected by `RestrictDiscountToApply` |

For a user-created record where Discount to Apply is not entered, the field default supplies `Account` before validation. The design does not add defaulting logic to integration, Flow, or batch paths.

## Test design

Extend `force-app/main/default/classes/RecurringTest.cls` with focused assertions for:

1. A Recurring Order with Manual Price only saves.
2. A Recurring Order with Discount to Apply only saves.
3. A Recurring Order with both fields populated fails with the existing validation message.
4. A Recurring Order with both fields blank fails with the new validation message.
5. A user-created Recurring Order with the field omitted receives the `Account` default where Salesforce defaulting applies.
6. A bulk list containing valid and invalid combinations produces the expected per-record save results without additional database work from the implementation.

The test data must include only the minimum fields required by the current object metadata and existing test helpers. Assertions should inspect `Database.SaveResult` errors rather than relying on unhandled DML exceptions for mixed bulk input.

## Post-deployment report

Provide a read-only script under the CRMFM-6 artifact directory for execution by an operator in a developer sandbox or scratch org. It should query:

```text
SELECT Id, Name, ManualPrice__c, Discount_to_Apply__c
FROM Recurrings__c
WHERE ManualPrice__c = null
AND Discount_to_Apply__c = null
ORDER BY CreatedDate ASC
```

The script must print candidate record identifiers and values only. It must not perform `update`, `delete`, or any other mutation. Any remediation requires a separate explicit approval and workflow gate.

## Deployment and verification

- Change-scoped manifest must include the new validation rule, the retained/related Recurring Order metadata required by the implementation, the updated test class, and the post-deployment report artifact as applicable to the repository's deployment convention.
- Pre-deployment manual step: identify and review records returned by the read-only report in the target developer sandbox or scratch org.
- Post-deployment manual step: run the report again, verify the new validation error in the UI/API test path, and confirm no existing records were mutated by the report.
- Deployment and tests must target only a developer sandbox or scratch org after the required retrieval gate.

## Risks and mitigations

- Existing records with both fields blank may be unable to update after deployment if they remain invalid. The read-only report identifies candidates before deployment so they can be reviewed separately.
- Flow or integration-created records that intentionally omit Discount to Apply may be affected by the new validation rule. This is accepted because the approved requirement limits defaulting to user-created records; affected automation paths must be identified during specification and sandbox verification.
- The current field default may not apply to every API creation path. No Apex or Flow defaulting is added without a separate approved requirement.
