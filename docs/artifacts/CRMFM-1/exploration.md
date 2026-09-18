<!--
Traceability
Ticket: CRMFM-1
Artifact: exploration.md
Gate: 2
Status: APPROVED APPROACH - DESIGN PENDING
Last updated: 2026-09-13
-->

# Gate 2 Exploration — CRMFM-1

## Selected approach

**Option A: Service-backed dashboard DTO.**

The implementation will use a thin `InvoiceDashboardController` as the LWC entry point,
reusable invoice dashboard query and validation logic in `InvoiceDashboardUtil`, DTOs for
summary/rows/lines, and a new `invoiceDashboard` LWC. Invoice-line records will load lazily
when a row is expanded. CSV export will be client-side from the filtered rows already returned
to the LWC.

## Repository findings

### Invoice data model

- `Invoice_Header__c` is an existing deployed custom object with sharing enabled and
  `ControlledByParent` external sharing.
- `Invoice_Line__c` is an existing deployed custom object with sharing enabled and
  `ControlledByParent` external sharing.
- `Invoice_Header__c.Account__c` is a master-detail relationship to `Account`.
- `Invoice_Line__c.Invoice_HeaderId__c` is a master-detail relationship to
  `Invoice_Header__c`, with child relationship `Invoice_Lines`.
- `Invoiced_Date__c` is a formula `Date` field. It uses `CreatedDate` for `Per Order`
  invoices and `DueDate__c` otherwise.
- Existing header fields cover the dashboard summary and row requirements, including
  `InvoiceNo__c`, `Invoiced_Date__c`, `DueDate__c`, `Status__c`, `AmountExclVAT__c`,
  `VAT__c`, `AmountInclVAT__c`, and `AmountOutstanding__c`.
- Existing line fields cover detail and line totals, including `Product_Name__c`,
  `Description__c`, `Qty__c`, `UnitPrice__c`, `Total_Price__c`, and `VAT__c`.

### Existing Apex patterns

- Invoice processing is implemented by existing helpers and handlers such as
  `InvoiceHeaderTriggerHelper`, `InvoiceChangeEventTriggerHandler`, and `Invoicing`.
  These are processing paths and should not be modified for this read-only dashboard.
- `TestDataHelper` provides `insertInvoice` and `insertInvoiceLine`, so dashboard tests can
  reuse existing invoice test data setup.
- Existing LWC-facing Apex controllers use `@AuraEnabled` methods and DTO-style inner
  classes. `OrderController` is the closest reusable DTO/controller pattern.
- Existing controller implementations are inconsistent about sharing and query security.
  New code will follow the FM target standard: `with sharing` and explicit object/field
  security enforcement.
- No invoice-specific LWC exists. The current LWC source tree contains `fileUploader`,
  `orderEntry`, `putOutTimes`, and `supplierProductSearch` only.
- No REST resource or API versioning is required because this feature is an LWC controller,
  not an external REST surface.

### Metadata and access

- No `tabs`, `permissionsets`, or `applications` directory currently exists under
  `force-app/main/default`.
- The dedicated dashboard tab and System Administrator-only access therefore require new
  metadata decisions and must be included explicitly in the technical design.
- No schema changes are anticipated.

## Design constraints

- Initial dashboard load should use a filtered header query and a line aggregate query for
  line quantity/amount summary values.
- Expanded line detail should be lazy-loaded with a separate query for the selected invoice.
- No SOQL or DML belongs in loops; the feature performs no DML and no callouts.
- Client-side CSV export is appropriate for the bounded loaded result set assumed by the
  approved requirements. A high-volume export would require a separate server-side design.
- Date filtering must use `Invoiced_Date__c`, including Monday-Sunday weekly ranges and
  inclusive custom ranges.
- Invalid custom ranges must be rejected before querying.
- The default period remains the current calendar month unless the open requirement is
  changed before specification.

## Alternatives considered

| Criterion | Option A: service-backed DTO | Option B: controller-only | Option C: paginated reporting service |
|---|---|---|---|
| Effort | Medium | Small | Large |
| Governor-limit impact | Two initial queries, one query per expanded invoice | Similar, but less structured | Lowest per request |
| Bulkification complexity | Low/Medium | Medium | High |
| Versioning impact | No REST versioning | No REST versioning | No REST versioning |
| Aligns with FM patterns | Yes | Partial | Yes |
| Reuses existing code | TestDataHelper, invoice schema, LWC conventions | Same | Same plus reusable reporting service |

## Decision rationale

Option A is the smallest design that preserves FM separation of concerns, keeps invoice query
logic independently testable, supports lazy line loading, and remains within the approved
starting governor-limit budget without prematurely introducing pagination or an export job.
