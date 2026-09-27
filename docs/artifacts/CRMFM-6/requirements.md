<!--
Traceability
Ticket: CRMFM-6
Jira URL: https://rakeshchatty.atlassian.net/browse/CRMFM-6
Artifact: requirements.md
Gate: 1
Status: APPROVED
Last updated: 2026-09-27
-->

# Requirements — CRMFM-6: Recurring Order discount validation and defaulting

## Problem statement
Ensure a Recurring Order cannot be saved with an invalid combination of Manual Price and Discount to Apply, while retaining the existing protection against both values being populated. User-created Recurring Orders should default Discount to Apply to Account when no value is entered.

## Assumptions
- The affected record is the Salesforce Recurring Order object `Recurrings__c`.
- `ManualPrice__c` represents Manual Price and `Discount_to_Apply__c` represents Discount to Apply / Discount Type — sourced from Jira.
- The existing `RestrictDiscountToApply` validation rule remains in place.
- The default and validation use the existing declarative FM pattern.

## Open questions
- [x] What is the Jira issue title? The Jira description is the working summary -> answer: Recurring Order discount validation and defaulting.
- [x] What is the exact Salesforce object API name for Recurring Order? -> answer: `Recurrings__c`.
- [x] Should the default Account be implemented as a field default, validation/automation, Flow, trigger handler, or another existing FM pattern? -> answer: Keep the existing `Discount_to_Apply__c` field default and add a declarative validation rule.
- [x] What exact validation error message and error location should users receive when both fields are blank? -> answer: Use a clear validation error displayed on `Discount_to_Apply__c`; exact wording will be finalized in the design/specification.
- [x] Must the default be enforced for API, Flow, and integration-created records, or only user-created records? Jira indicates API/Flow/integration paths require confirmation -> answer: User-created records only.
- [ ] What batch size and expected volume must bulk operations support? -> answer:
- [x] What are the approved SOQL, DML, CPU, and callout budgets? -> answer: No additional budget is required; validation/defaulting should use no SOQL, DML, or callouts.
- [x] Are any permission, sharing, Named Credential, Platform Event, or REST versioning changes required? -> answer: No.
- [ ] Is a separate data-fix story required for existing records with both fields blank? Jira identifies this as follow-up scope -> answer:

## Scope
### In scope
- Default Discount to Apply to Account for a user-created Recurring Order when no value is entered.
- Block save when Manual Price is blank and Discount to Apply is blank, with a clear validation error.
- Retain the existing behavior that blocks save when both Manual Price and Discount to Apply are populated.
- Allow save when exactly one of Manual Price or Discount to Apply is populated.
- Verify the field and validation behavior against the actual Salesforce metadata and existing FM patterns.
- Generate a non-destructive post-deployment script for the approved data-fix process, if the final design confirms existing records require remediation.

### Out of scope
- Executing data remediation for existing records with both Manual Price and Discount Type blank; provide the script, but keep execution as a separate post-deployment/manual activity unless separately approved.
- Unrelated Recurring Order pricing, discount, or lifecycle behavior.
- Production-org deployment or modification.

## Acceptance criteria
1. **Given** a new Recurring Order with no value entered for Discount to Apply **when** the record is created **then** Discount to Apply defaults to `Account`.
2. **Given** a Recurring Order where Manual Price is blank and Discount to Apply is blank **when** the user attempts to save **then** the save is blocked with a clear validation error.
3. **Given** a Recurring Order where Manual Price is populated and Discount to Apply is populated **when** the user attempts to save **then** the save is blocked, retaining existing behavior.
4. **Given** a Recurring Order where exactly one of Manual Price or Discount to Apply is populated **when** the user attempts to save **then** the save succeeds.
5. **Given** the approved post-deployment data-fix script is run in a non-production environment **when** it encounters existing records with both fields blank **then** it reports the candidate records and makes no changes unless explicit execution approval is provided.

## Non-functional requirements (Salesforce)
- **Objects affected:** Custom object `Recurrings__c`; fields `ManualPrice__c` and `Discount_to_Apply__c`.
- **Bulk / volume:** Trigger context, batch size, and expected record counts are not specified in Jira; must support the project's standard bulk test expectation once the owning automation is identified.
- **Governor-limit budget:** No additional SOQL, DML, or callouts; validation/defaulting should use declarative behavior or the existing FM pattern without introducing database work. Confirm CPU impact during Gate 2/3.
- **Sharing model:** No Apex is required; declarative metadata preserves the existing sharing model.
- **LWC:** No LWC requirement identified; confirm whether any UI surface needs a custom error presentation.
- **Integrations:** No Named Credential, Platform Event, or external callout requirement.
- **REST versioning:** No REST resource or versioning requirement identified; confirm whether existing `_V[N]` resources participate in Recurring Order creation.
- **Post-deployment data script:** Provide a read-only candidate-reporting script for existing records with both fields blank; execution requires explicit approval and must target a developer sandbox or scratch org, never production.
- **Security / compliance:** Preserve existing field-level security and validation behavior; no PII or permission-set change identified.

## Story type
- [x] Code change  [ ] Analysis / spike only

## Sign-off
- Requirements approved by: developer on 2026-09-27
