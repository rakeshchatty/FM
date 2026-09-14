<!--
Traceability
Ticket: CRMFM-1
Artifact: specs.md
Gate: 3
Status: APPROVED
Requirements: ./requirements.md
Design: ./technical-design.md
Last updated: 2026-09-13
-->

# Specifications — CRMFM-1: Invoice Dashboard LWC

Specs are ordered by dependency and follow the FM implementation order.

---

## Spec 1: Dashboard metadata and access

**Satisfies:** Req #14
**FM layer / order position:** 1. Metadata

### Acceptance criteria
- [ ] The dashboard is exposed as a dedicated Lightning tab or equivalent navigation target.
- [ ] The dashboard is available to System Administrators.
- [ ] No invoice object or field schema is changed.
- [ ] Access metadata does not grant the dashboard to non-administrator users.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/tabs/Invoice_Dashboard.tab-meta.xml` | new, if tab metadata is selected | Dedicated dashboard tab |
| `force-app/main/default/permissionsets/Invoice_Dashboard_Access.permissionset-meta.xml` | new, if permission-set access is selected | Deployable access control |
| `force-app/main/default/customPermissions/Invoice_Dashboard.customPermission-meta.xml` | new, if custom-permission access is selected | Optional explicit feature permission |
| `force-app/main/default/applications/<existing-app>.app-meta.xml` | modified only if required | Add dashboard to an existing app navigation menu |

### Method contracts
- No Apex method contract.
- The exact access artifact must be selected before implementation based on the target org’s
  existing navigation and profile/access conventions.

### Governor-limit budget
SOQL 0 / DML 0 / CPU negligible / callouts 0

### Test scenarios
- Happy path: System Administrator can open the dashboard target.
- Bulk (200): Not applicable; metadata-only.
- Edge: Existing app/navigation metadata is absent and a standalone target is required.
- Negative: Non-administrator access is not granted.
- Regression: Existing invoice tabs and applications remain unchanged unless explicitly updated.

---

## Spec 2: Invoice dashboard DTO model

**Satisfies:** Req #5, #6, #7, #9, #11, #12
**FM layer / order position:** 4. Apex Models / DTOs

### Acceptance criteria
- [ ] The model serializes filter input, summary values, invoice rows, and invoice lines for LWC.
- [ ] Monetary and quantity values are nullable-safe and default to zero in empty summaries.
- [ ] Filter mode supports yearly, monthly, weekly, and custom date range values.
- [ ] Model error types are `virtual` where used for serialization.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/classes/InvoiceDashboardModel.cls` | new | Aura-enabled filter/result/summary/row/line DTOs |
| `force-app/main/default/classes/InvoiceDashboardModel.cls-meta.xml` | new | Apex API version metadata |
| `force-app/main/default/classes/InvoiceDashboardModelTest.cls` | new | DTO defaults and serialization contract tests |
| `force-app/main/default/classes/InvoiceDashboardModelTest.cls-meta.xml` | new | Apex test metadata |

### Method contracts
- `InvoiceDashboardModel.Filter(String mode, Integer year, Integer month, Date weekStart, Date startDate, Date endDate, Id accountId)`
  stores filter input without querying or mutating data.
- `InvoiceDashboardModel.DashboardResult()`
  initializes an empty row list and zero-valued summary.
- `InvoiceDashboardModel.Summary()`
  exposes invoice count, header totals, line quantity, and line amount.
- `InvoiceDashboardModel.InvoiceRow(Invoice_Header__c header)`
  maps the selected header fields into an Aura-enabled row DTO.
- `InvoiceDashboardModel.InvoiceLine(Invoice_Line__c line)`
  maps selected child fields into an Aura-enabled line DTO.

### Governor-limit budget
SOQL 0 / DML 0 / CPU < 10 ms typical / callouts 0

### Test scenarios
- Happy path: DTOs expose expected filter, header, summary, and line values.
- Bulk (200): Construct 200 row/line DTOs without queries or DML.
- Edge: Null monetary, quantity, and date values map safely.
- Negative: Unsupported mode is rejected by utility/controller validation rather than silently queried.
- Regression: No existing model or public class contracts change.

---

## Spec 3: Invoice dashboard query and date utility

**Satisfies:** Req #1-#9, #11-#13
**FM layer / order position:** 6. Apex Utils

### Acceptance criteria
- [ ] Yearly range is January 1 through December 31 of the selected year.
- [ ] Monthly range covers the selected calendar month inclusively.
- [ ] Weekly range is Monday through Sunday inclusively.
- [ ] Custom range requires both dates and rejects an end date before the start date.
- [ ] Optional `Account__c` filtering is applied without changing the date semantics.
- [ ] Header rows are mapped from visible invoice records only.
- [ ] Line quantity and amount summaries are aggregated without SOQL in loops.
- [ ] Child line retrieval is limited to the requested invoice and uses stable ordering.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/classes/InvoiceDashboardUtil.cls` | new | Date construction, validation, queries, aggregation, and mapping |
| `force-app/main/default/classes/InvoiceDashboardUtil.cls-meta.xml` | new | Apex API version metadata |
| `force-app/main/default/classes/InvoiceDashboardUtilTest.cls` | new | Utility behavior and query contract tests |
| `force-app/main/default/classes/InvoiceDashboardUtilTest.cls-meta.xml` | new | Apex test metadata |
| `force-app/main/default/classes/ExceptionService.cls` | new only if approved logging abstraction is absent | Centralized unexpected-error logging |
| `force-app/main/default/classes/ExceptionService.cls-meta.xml` | new only if required | Apex API version metadata |
| `force-app/main/default/classes/ExceptionServiceTest.cls` | new only if `ExceptionService` is added | Logging service tests |
| `force-app/main/default/classes/ExceptionServiceTest.cls-meta.xml` | new only if required | Apex test metadata |

### Method contracts
- `DateRange InvoiceDashboardUtil.buildDateRange(InvoiceDashboardModel.Filter filter)`
  returns an inclusive start/end date pair or throws a validation exception for malformed input.
- `InvoiceDashboardModel.DashboardResult InvoiceDashboardUtil.buildDashboard(InvoiceDashboardModel.Filter filter)`
  queries filtered headers, aggregates child line values for returned headers, and maps the
  result into DTOs. It returns an empty result for no matches.
- `List<InvoiceDashboardModel.InvoiceLine> InvoiceDashboardUtil.getInvoiceLines(Id invoiceId)`
  returns visible child lines ordered by `InvoiceDate__c`, `Name`, and `Id` or the final approved
  stable ordering available from the metadata.
- `void ExceptionService.registerException(Exception exception, String source)` and
  `void ExceptionService.commitWork()`
  record unexpected errors using the repository-approved logging object if the service is added.

### Governor-limit budget
SOQL 2 / DML 0 / CPU within synchronous limit / callouts 0 for dashboard load; SOQL 1 / DML 0
for line expansion. No queries or DML in loops. Use `WITH USER_MODE` where supported, otherwise
use the approved security-enforcement fallback and sanitize returned fields.

### Test scenarios
- Happy path: Year, month, week, custom range, and account filtering return only matching headers.
- Bulk (200): 200 headers and child lines map using bounded query counts.
- Edge: Month/year boundaries, leap year, Monday/Sunday boundaries, no matching records, and
  null optional fields.
- Negative: Unsupported mode, missing custom dates, reversed dates, invalid account ID, and
  query/security errors return safe handled failures.
- Regression: Existing invoice creation, trigger, and processing classes remain untouched.

---

## Spec 4: Apex dashboard controller

**Satisfies:** Req #5-#7, #9, #11-#13
**FM layer / order position:** 10. Apex Controllers

### Acceptance criteria
- [ ] The controller is `with sharing` and contains validation/delegation only.
- [ ] Dashboard calls return the DTO contract expected by the LWC.
- [ ] Invalid input is rejected before any SOQL executes.
- [ ] Unexpected errors are logged through the approved exception pattern and returned as a safe
      user-facing error.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/classes/InvoiceDashboardController.cls` | new | LWC-facing Apex methods |
| `force-app/main/default/classes/InvoiceDashboardController.cls-meta.xml` | new | Apex API version metadata |
| `force-app/main/default/classes/InvoiceDashboardControllerTest.cls` | new | Controller contract/error tests |
| `force-app/main/default/classes/InvoiceDashboardControllerTest.cls-meta.xml` | new | Apex test metadata |

### Method contracts
- `@AuraEnabled public static InvoiceDashboardModel.DashboardResult getDashboard(InvoiceDashboardModel.Filter filter)`
  validates and delegates to `InvoiceDashboardUtil.buildDashboard`; returns empty summaries for
  no matches; throws `AuraHandledException` with a safe message for invalid/query failures.
- `@AuraEnabled public static List<InvoiceDashboardModel.InvoiceLine> getInvoiceLines(Id invoiceId)`
  validates the ID and delegates to `InvoiceDashboardUtil.getInvoiceLines`; returns an empty list
  when no child lines exist.

### Governor-limit budget
SOQL 2 / DML 0 / CPU within synchronous limit / callouts 0 for `getDashboard`; SOQL 1 / DML 0
for `getInvoiceLines`. The controller itself performs no direct SOQL.

### Test scenarios
- Happy path: Controller returns filtered result and lazy line DTOs.
- Bulk (200): Controller supports 200 returned rows without per-row queries.
- Edge: Empty result and an invoice with no lines.
- Negative: Reversed custom dates, null filter, null invoice ID, and utility exceptions produce
  safe errors.
- Regression: Existing controller contracts remain unchanged.

---

## Spec 5: Invoice Dashboard LWC and CSV export

**Satisfies:** Req #1-#14
**FM layer / order position:** 11. Lightning Web Components

### Acceptance criteria
- [ ] The component defaults to the current calendar month.
- [ ] Users can select yearly, monthly, weekly, and custom date-range modes.
- [ ] Customer selection filters results by `Account__c`.
- [ ] Summary cards and invoice rows update after a valid filter action.
- [ ] GBP formatting is used for all monetary values.
- [ ] Expanding a row loads and displays invoice lines lazily.
- [ ] CSV export downloads the currently displayed filtered invoice rows.
- [ ] Loading, empty, validation, and server-error states are visible and do not reload the page.
- [ ] Invalid custom ranges do not call Apex.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/lwc/invoiceDashboard/invoiceDashboard.js` | new | State, Apex calls, filtering, row expansion, CSV export |
| `force-app/main/default/lwc/invoiceDashboard/invoiceDashboard.html` | new | Dashboard layout and states |
| `force-app/main/default/lwc/invoiceDashboard/invoiceDashboard.css` | new | Scoped dashboard styling |
| `force-app/main/default/lwc/invoiceDashboard/invoiceDashboard.js-meta.xml` | new | Lightning page/tab exposure |
| `force-app/main/default/lwc/invoiceDashboard/__tests__/invoiceDashboard.test.js` | new | Jest interaction and state tests |

### Method contracts
- `connectedCallback()` initializes current-month filter state.
- `handleFilterChange(event)` updates mode/date/account state and clears stale validation errors.
- `handleApply()` validates client-side, invokes `getDashboard`, and updates loading/error/result state.
- `handleRowToggle(event)` invokes `getInvoiceLines` once per expanded invoice and caches the result.
- `handleExportCsv()` serializes displayed invoice rows with escaped CSV values and starts a browser download.

### Governor-limit budget
Apex invocation: same as Spec 4; browser-side CSV work has no Salesforce governor usage.

### Test scenarios
- Happy path: Render, apply each filter mode, display summaries/rows, expand lines, and export CSV.
- Bulk (200): Render a large mocked result set without duplicate Apex calls or layout failure.
- Edge: Empty results, zero summaries, null optional fields, and repeated row expansion.
- Negative: Invalid dates, mocked Apex rejection, and CSV values containing commas, quotes, or newlines.
- Regression: Loading state clears on success/failure and filter changes do not require page reload.

---

## Spec 6: Apex and LWC test coverage

**Satisfies:** Req #1-#14
**FM layer / order position:** 13. Apex test classes and LWC Jest tests

### Acceptance criteria
- [ ] Each new production Apex class has a dedicated test class.
- [ ] Apex coverage is at least 85% with meaningful assertions.
- [ ] LWC Jest coverage is at least 80% for the dashboard bundle.
- [ ] Tests cover happy path, 200-record mapping, edge cases, negative validation, errors, and
      regression boundaries.
- [ ] No test performs real callouts or depends on unrelated existing org data.

### Components affected
| Path | New / modified | Purpose |
|---|---|---|
| `force-app/main/default/classes/InvoiceDashboardModelTest.cls` | new | Model tests |
| `force-app/main/default/classes/InvoiceDashboardUtilTest.cls` | new | Utility tests |
| `force-app/main/default/classes/InvoiceDashboardControllerTest.cls` | new | Controller tests |
| `force-app/main/default/lwc/invoiceDashboard/__tests__/invoiceDashboard.test.js` | new | LWC Jest tests |
| Existing `force-app/main/default/classes/TestDataHelper.cls` | modified only if fixture gaps block tests | Reusable invoice test data |

### Method contracts
- Test methods use the repository’s supported Apex assertion style and descriptive assertion
  messages; new tests should use `should_<behavior>[_when_<condition>]` names where compatible.
- LWC tests mock imperative Apex methods and cover success/error/loading states.

### Governor-limit budget
Test methods must assert bounded query behavior where practical; DML is test setup only and
must not occur in production paths. No callouts.

### Test scenarios
- Happy path: All four date modes, customer filter, summaries, details, GBP display, CSV export.
- Bulk (200): 200 invoice headers and associated lines.
- Edge: Date boundaries, empty results, null fields, no child lines, and CSV escaping.
- Negative: Reversed range, invalid input, FLS/query error, and Apex rejection.
- Regression: Existing invoice processing tests remain unaffected and no existing source class is
  modified outside an explicitly approved fixture change.

---

## Governor-limit budget summary

| Path | SOQL | DML | CPU | Callouts |
|---|---:|---:|---|---:|
| Apply dashboard filter | <= 2 | 0 | Standard synchronous | 0 |
| Expand one invoice | <= 1 | 0 | Standard synchronous | 0 |
| Invalid filter | 0 | 0 | Minimal | 0 |
| CSV export | 0 | 0 | Browser only | 0 |

## Implementation order (this ticket)

1. Spec 1 — Dashboard metadata and access
2. Spec 2 — Invoice dashboard DTO model
3. Spec 3 — Invoice dashboard query and date utility
4. Spec 4 — Apex dashboard controller
5. Spec 5 — Invoice Dashboard LWC and CSV export
6. Spec 6 — Apex and LWC test coverage

## Sign-off

Specs approved by: rakeshchatty on 2026-09-13
