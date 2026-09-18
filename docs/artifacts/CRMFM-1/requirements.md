<!--
Traceability
Ticket: CRMFM-1
Artifact: requirements.md
Gate: 1
Status: APPROVED
Last updated: 2026-09-13
-->

# Requirements — CRMFM-1: Create Invoice Dashboard LWC with Date, Customer, and CSV Export Filters

## Problem statement
System Administrators currently have no consolidated, filterable view of invoice data inside
Salesforce. They need a dedicated dashboard to report on invoices by period (yearly / monthly /
weekly / custom range) and by customer, see summary totals, drill into invoice-line detail, and
export the filtered result set as CSV — all using the existing `Invoice_Header__c` /
`Invoice_Line__c` data model without any changes to how invoices are created or processed.

## Assumptions
- "Current reporting period" defaulted on load means the current calendar month, using
  `Invoiced_Date__c` — to be confirmed with the developer/reporter (Rakesh) since the ticket does
  not explicitly define which period type is the default beyond "current reporting period."
- "System Administrator profile" access is enforced via a Permission Set or profile-based tab
  visibility; exact mechanism to be decided at Gate 2 (technical design), consistent with FM's
  sharing/security patterns.
- CSV export runs client-side (LWC) or via an `@AuraEnabled` Apex method against the already
  filtered/loaded result set — no separate large-data export/batch mechanism is implied by the
  ticket (dataset scope is invoices, not high-volume transactional data).
- No currency conversion is required; all amounts are assumed to already be stored/displayed in
  GBP given "Amount excluding VAT," etc. fields — display formatting only, not conversion.
- `Location_Id__c` and `Order__c` on `Invoice_Line__c` are informational/display fields, not
  additional filter dimensions (ticket only calls out Date and Customer as filters).

## Open questions
- [ ] What does "current reporting period" default to exactly (current month? current week? a
      custom fiscal period)? -> answer: _pending confirmation_
- [ ] Should the CSV export be generated client-side in the LWC, or via an Apex
      `@AuraEnabled` method returning a file/Blob? -> answer: _pending confirmation_
- [ ] Expected data volume (max invoices per customer/period) to size pagination, governor-limit
      budget, and whether aggregate SOQL (`GROUP BY`) is required for summary metrics? -> answer:
      _pending confirmation_
- [ ] Is there an existing Lightning App / navigation menu the new tab should be added to, or is
      a new app also in scope? -> answer: _pending confirmation_
- [ ] Should invoice-line detail be loaded eagerly per invoice row or lazily on
      expand/select (governor-limit implication)? -> answer: _pending confirmation_

## Scope
### In scope
- New LWC-based Invoice Dashboard, exposed as its own Salesforce tab.
- Date filters: Yearly, Monthly, Weekly (Monday–Sunday), Custom Date Range — all against
  `Invoiced_Date__c`.
- Customer filter via `Invoice_Header__c.Account__c`.
- Summary metrics: total invoice count, total amount excl. VAT, total VAT, total amount incl.
  VAT, total outstanding amount, total quantity/line amount (from `Invoice_Line__c`) where
  applicable.
- Invoice detail list/table (invoice number, customer, invoice date, billing period, status, due
  date, totals) with expand/select to view related `Invoice_Line__c` records.
- CSV export of the currently filtered invoice result set, capturing the active date range and
  customer filter context.
- Loading, empty-result, validation, and error UI states; filter changes refresh data without a
  full page reload.
- Apex controller/service with `@AuraEnabled` methods for filtered query + aggregation.
- Apex and LWC test coverage for all filter modes, GBP formatting, CSV export, empty results,
  invalid date ranges, and query/error handling.
- Access restricted to System Administrator profile initially.

### Out of scope
- Creating or editing invoice records.
- Changes to existing invoice-generation, invoice-line, or credit-note processes/triggers.
- Payment processing.
- Access for non-System Administrator profiles.
- Additional currencies beyond GBP display.

## Acceptance criteria
1. **Given** the dashboard is opened, **when** no filters have been changed, **then** the current
   reporting period is selected by default.
2. **Given** Yearly mode is selected, **when** a year is chosen, **then** invoices with an
   `Invoiced_Date__c` in that year are displayed.
3. **Given** Monthly mode is selected, **when** a year and month are selected, **then** invoices
   for that month are displayed.
4. **Given** Weekly mode is selected, **when** a week is selected, **then** invoices from Monday
   through Sunday of that week are displayed.
5. **Given** Custom Date Range mode is selected, **when** valid start and end dates are entered,
   **then** invoices within the inclusive date range are displayed.
6. **Given** a customer is selected, **when** the filter is applied, **then** only invoices
   related to that customer through `Account__c` are displayed.
7. **Given** one or more filters are applied, **when** results load, **then** all summary values
   and invoice details reflect those filters.
8. **Given** invoice amounts are displayed, **when** the dashboard loads, **then** monetary
   values are shown in pounds sterling (GBP).
9. **Given** an invoice is selected, **when** its details are expanded, **then** related
   `Invoice_Line__c` records are displayed.
10. **Given** the user selects Export CSV, **when** filtered results are available, **then** a
    CSV file containing the displayed invoice data is downloaded.
11. **Given** no records match the filters, **when** the query completes, **then** a clear
    empty-state message and zero-value summaries are displayed.
12. **Given** the custom end date is earlier than the start date, **when** the user applies the
    filter, **then** validation prevents the search and displays an error message.
13. **Given** the data query fails, **when** the error is returned, **then** a user-friendly
    error message is displayed.
14. **Given** the user has System Administrator access, **when** they open the dedicated
    dashboard tab, **then** the dashboard is available to them.

## Non-functional requirements (Salesforce)
- **Objects affected:** custom — `Invoice_Header__c` (primary, read-only query), `Invoice_Line__c`
  (child, read-only query via `Invoice_HeaderId__c`). No schema changes anticipated.
- **Bulk / volume:** UI-triggered query flow (no trigger context). Volume TBD — see open question
  on expected invoice counts per customer/period; governor-limit budget below is a starting
  estimate pending that answer.
- **Governor-limit budget (per filter action):** SOQL ≤ 3 (header query + aggregate summary query
  + line query on expand), DML 0 (read-only feature), CPU time within standard synchronous Apex
  limit, callouts 0.
- **Sharing model:** `with sharing` — dashboard must respect record-level access; no justification
  for `without sharing` identified by the ticket.
- **LWC:** Yes — one primary dashboard LWC (filters + summary + invoice list), likely a child LWC
  or expandable row for invoice-line detail.
- **Integrations:** None — no Named Credentials, Platform Events, or external callouts required.
- **REST versioning:** Not applicable — feature is Apex controller + LWC only, no REST API
  surface identified in the ticket.
- **Security / compliance:** Enforce object/field-level security (`WITH SECURITY_ENFORCED` or
  equivalent) and sharing rules on all queries; restrict tab/dashboard visibility to System
  Administrator profile via permission set or profile-based tab settings.

## Story type
- [x] Code change  [ ] Analysis / spike only

## Sign-off
- Requirements approved by: rakeshchatty on 2026-09-13 (open questions accepted with stated
  assumptions; to be revisited if they change design)
