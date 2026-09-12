---
applyTo: "force-app/**"
description: FM (FirstMile) Salesforce architecture, patterns, standards, and review guidelines.
---

# Salesforce Architecture — FirstMile (FM)

Architecture, enterprise patterns, coding standards, and review guidelines for the
FirstMile Salesforce **Sales Cloud** platform.

> **Source of truth is the repo code.** Where an item below is marked _(target)_ it is a
> standard to move toward — it may not be fully present in `force-app/` yet. Verify
> against existing classes before enforcing on old code, and flag divergence rather than
> silently "fixing" working code.

---

## Critical Rules

### Production safety
**NEVER commit, push, deploy, or make changes targeting any PRODUCTION org or branch.**
- If an action could impact production (direct deploy, merge to a release/production
  branch), STOP and warn immediately.
- Never run destructive commands (`DELETE`, `TRUNCATE`, mass data manipulation) against
  production data.
- If you detect production credentials, endpoints, or org IDs in context, flag it
  immediately and do not use them.
- Always confirm the target environment before any deployment-related action.
- Production org access is forbidden — refuse and highlight if ever attempted.

### Zero-regression policy
**Every fix or feature MUST NOT break existing functionality.**
- Analyze blast radius first — identify all callers, dependents, and downstream consumers
  of the code being modified.
- If a method signature, return type, or behavior changes, trace every reference.
- Shared utilities, services, selectors, and trigger handlers are high-risk — changes
  cascade across the org.
- Tests must cover the new/changed logic **and** verify existing behavior is preserved
  (regression tests).
- When in doubt, add defensive checks rather than assuming callers adapt.

---

## Project Overview

- **Platform:** Salesforce Sales Cloud
- **Product:** FirstMile (FM)
- **UI:** Lightning Web Components for all new frontend; Aura is legacy
- **Metadata format:** Salesforce DX source (`force-app/main/default/`)
- **Repository:** `github.com/rakeshchatty/FM` — single repo, default branch `main`,
  GitHub Pull Requests
- **Scale:** design for high record volume — assume bulk (200+ in trigger context) and
  large data operations; confirm concrete volumes per feature.

---

## Repository & VCS

| Item | Value |
|---|---|
| Repo | `FM` (`github.com/rakeshchatty/FM`) |
| Source format | SFDX (`force-app/main/default/`) |
| Default branch | `main` |
| Branch/PR flow | `feature|bugfix/<TICKET-ID>-<desc>` → PR into `main` |
| CI/CD | _(target)_ not yet configured in-repo; deploy via `sf` CLI to sandboxes only |

There is no `package.json` checked in. The repository uses `sfdx-project.json` to describe
the `force-app` source directory. `fflib-apex-mocks` and `sfdx-lwc-jest` are _(target)_
dependencies for the test tooling; they are not installed yet.

---

## Technology Stack

| Category | Technology |
|---|---|
| Platform | Salesforce Sales Cloud |
| Language | Apex |
| UI | Lightning Web Components (new); Aura (legacy) |
| Metadata | SFDX source format |
| CLI | Salesforce CLI (`sf`) |
| Query | SOQL / SOSL |
| Config | Custom Metadata Types, Custom Settings, Custom Labels |
| Async | Batch / Queueable / Scheduled Apex, Platform Events |
| Integration | Named Credentials, Connected Apps |
| Test tooling _(target)_ | `fflib-apex-mocks` (mocks only), `@salesforce/sfdx-lwc-jest`, PMD, Salesforce Code Analyzer |

---

## Project Structure

```text
FM/
├── force-app/main/default/
│   ├── classes/           # Apex classes and test classes
│   ├── triggers/          # Apex triggers (one per object)
│   ├── lwc/               # Lightning Web Components
│   ├── aura/              # Aura components (legacy)
│   ├── objects/           # Custom objects, fields, record types
│   ├── flexipages/ layouts/ flows/ quickActions/ tabs/
│   ├── permissionsets/    # Access control (never edit as a side effect)
│   ├── customMetadata/    # Configuration records
│   ├── labels/ globalValueSets/ staticresources/ contentassets/
│   └── applications/ reportTypes/
├── config/                # scratch org definition (currently empty)
├── manifest/              # package.xml manifests
└── .myit/  .github/  .vscode/   # agentic framework (this setup)
```

---

## Architecture Overview

FM follows a **pragmatic layered architecture**. It does **not** adopt fflib enterprise
base classes, interfaces, or the `Application` factory in implementation code.
`fflib-apex-mocks` is used **only in test classes** for mocking and isolation.

### What the codebase uses (or should — _target_ where noted)

- **REST Resources** (`{Domain}RestResource`, `{Domain}RestResource_V{N}`) — Apex REST
  endpoints are the entry points for external integrations. Parse/validate the request and
  delegate; no business logic inline.
- **Versioning by class suffix** — new API/model versions are **new classes** with `_V2`,
  `_V8`, … suffixes. Never mutate an existing versioned class.
- **Models** (`{Domain}Model`) — plain Apex DTOs for request/response payloads and internal
  transfer. Inner `Error` / `Exception` classes inside models are declared **`virtual`**
  for Salesforce serialization.
- **Builders** (`{Domain}Builder`, `{Domain}ModelBuilder`) — fluent builders that
  construct SObjects and Model DTOs.
- **Trigger Handlers** (`{Object}TriggerHandler`) — one trigger per object delegates here.
  Plain Apex classes; do not extend `fflib_SObjectDomain`. FM's existing
  `*TriggerHandler` / `*TriggerHelper` classes are the reference.
- **Utils** (`{Domain}Util`) — stateless helpers holding logic extracted from REST
  resources and handlers.
- **SOQL access** — colocated with the handler/util/builder that needs it, or extracted to
  a `{Domain}Selector` _(target)_. No `fflib_SObjectSelector`, no shared selector base
  class.
- **Transactions/DML** — standard Apex DML directly. No fflib Unit of Work.
- **Mock injection for tests** — via `@TestVisible private static` fields on the class
  under test, not constructor injection or interface substitution.
- **Error logging** — `ExceptionService.registerException(ex, 'ClassName.methodName')` +
  `ExceptionService.commitWork()` _(target: introduce `ExceptionService` if not present;
  until then, propagate typed exceptions — never `System.debug` for logging)_.

### Do NOT introduce

- `Application.Service.newInstance(...)` factory calls
- `fflib_SObjectDomain`, `fflib_SObjectSelector`, `fflib_SObjectUnitOfWork`
- Dependency injection via an `Application` class or service locator
- In-place mutation of an existing versioned (`_V[N]`) class — add a new `_V[N]` instead
- fflib architectural conventions (interfaces, base classes, factory, UoW) in
  implementation code — `fflib-apex-mocks` is permitted **only** in test classes

### Separation of concerns

```
Lightning Web Components  (UI / presentation)
        |  wire / imperative Apex
        v
Apex Controllers          (thin — validation + delegation only)
        |
        v
Apex Services / Utils      (business logic)
        |
        v
Apex Domain / Trigger Handlers  (record-level rules)
        |
        v
Selectors / DAL            (data access)
```

- Controllers NEVER contain business logic — validate input, delegate.
- Services/Utils NEVER query directly where a selector exists — use it _(target)_.
- Triggers NEVER contain logic — delegate to the handler.
- Business logic lives in Services/Utils or Domain/Handler classes only.

### Trigger architecture

```
Trigger (1 per object)
  -> TriggerHandler (dispatches by context)
     -> Domain/Helper (record-level rules)
        -> Service/Util (business logic)
           -> Selector / DAL (data access)
```

Recursion control lives in the handler (static `@TestVisible` guard), not the trigger.
The **Triggers** subsection under Apex Best Practices has the full rule set.

---

## Integration & Async Patterns

| Pattern | When to use |
|---|---|
| Named Credentials | Outbound REST/SOAP callouts (auth handled by the platform) |
| Platform Events | Async, decoupled, cross-system communication |
| Apex REST / SOAP | Inbound API endpoints (`{Domain}RestResource`) |
| Batch Apex | Large data volumes (10k+); `Database.Stateful` only when tracking state |
| Queueable Apex | Chained async work or callouts needing context passing |
| Scheduled Apex | Recurring jobs; put schedule config in Custom Metadata |

---

## Configuration

- Use Custom Metadata Types extensively for configuration-driven behavior.
- Prefer **Custom Metadata over Custom Settings** for anything that must be deployable.
- No hardcoded IDs — record type IDs, profile IDs, org-specific IDs come from Custom
  Metadata, Custom Settings, or Custom Labels.

---

## Key Entities & Data Model

FM is a waste / recycling collection and delivery-logistics business on Sales Cloud
(~90 custom objects, ~40 triggers). Generated from `force-app/main/default/objects/` —
re-verify against the repo when a field/relationship matters.

### Customer & commercial

| Entity | Purpose | Key relationships |
|---|---|---|
| `Account` | Central identity. Record types: **Account**, **Location Partner**, **Prospect**. An Account also represents a **service location** — many operational objects reference it as `Location__c`. | `Contact`, `AccountContactRelation`, `Opportunity`, `Order` |
| `Opportunity` | Sales pipeline; parent of `Collection__c` (master-detail). | `Collection__c`, `Account` |
| `Order` / `OrderItem` | Commercial order lines that feed invoicing, delivery, and compliance. | `Account`, `Product2`, `Invoice_Line__c`, `DeliveryOrder__c` |
| `Product2` / `Pricebook2` / `PricebookEntry` | Standard product & pricing. | `Schedule__c`, `Supplier_Product__c`, `Recurrings__c` |
| `Account_Discount__c` | Negotiated discount applied to collections. | `Account`, `Collection_Waypoints__c` |
| `Subscribed_Products__c` / `Recurrings__c` | Recurring / subscribed product agreements per account. | `Account`, `Product2`, `Suppliers__c`, `Supplier_Product__c` |
| `Competitor__c` | Competitive-intel records. | `Account` |

### Scheduling & collection operations

| Entity | Purpose | Key relationships |
|---|---|---|
| `Schedule__c` | Core collection schedule (largest object, ~72 fields). Master-detail to `Account` (`Location__c`). | `Round__c`, `Suppliers__c`, `Supplier_Product__c`, `Product2`, `Pricebook2`, `CollectionAggregator__c` |
| `Collection_Waypoints__c` | An individual scheduled stop / visit. | `Account` (`Location__c`), `Schedule__c`, `DailyDispatch__c`, `Round__c`, `Case`, `Suppliers__c`, `Account_Discount__c` |
| `Round__c` | A collection route. | `Driver__c` (default + 2nd), `Vehicle__c` |
| `DailyDispatch__c` | A day's execution of a round. | `Round__c`, `Driver__c` (+2nd), `Vehicle__c` |
| `Waypoint__c` / `ReceivedWaypoint__c` / `ReceivedWaypointGroup__c` | Route waypoints and inbound waypoint batches (via `ReceivedWaypointGroupEvent__e` platform event). | `Round__c` |
| `Missed_Collection__c` | Logged missed / failed collection. | `Case`, `Schedule__c`, `DailyDispatch__c`, `Round__c` |
| `Driver__c` / `Vehicle__c` / `Depot__c` / `DispatchLocation__c` / `DriverPIN__c` | Fleet & depot master data. | — |
| `Region__c` / `Cities_Data__c` | Geographic routing / coverage. | `Suppliers__c` (supplier + clearance supplier) |
| `CollectionException__c` + `CollectionExceptionSetting__c` + `CollectionServiceTimeSetting__c` | Service exceptions / non-collection days (also `CollectionExceptions__mdt`). | — |
| `QR_Codes_from_Detrack__c` / `Qr_code__c` / `DeliveryPackageQrCode__c` | Detrack driver-app QR integration (`SplitQRCodesIntoNewRecords` trigger). | — |

### Weighing & waste compliance

| Entity | Purpose | Key relationships |
|---|---|---|
| `Tonnage__c` | Weighbridge tonnage per dispatch (master-detail to `DailyDispatch__c`). | `DailyDispatch__c` |
| `Weight__c` / `BinWeight__c` | Recorded weights per collection / bin (`WeightCategoryToFieldMapping__mdt`, `WeightTrigger`). | — |
| `Waste_Category__c` / `WTN_Waste_Category__c` | Waste classification (EWC-style). | — |
| `SeasonTicketWTN__c` / `SeasonTicketWTNProduct__c` | Season-ticket Waste Transfer Notes. | `Product2` |
| `Compliance_Doc__c` / `CP_Doc_URL__c` | Duty-of-care / waste-transfer compliance documents (~48 fields). | `Account`, `Suppliers__c` (`Contractor__c`), `Order`, `Product2` |

### Delivery logistics

| Entity | Purpose | Key relationships |
|---|---|---|
| `DeliveryOrderGroup__c` → `DeliveryOrder__c` → `DeliiveryLine__c` | Delivery order hierarchy (master-detail chain; note the misspelled `DeliiveryLine__c`). | `DeliveryRoute__c`, `Order` |
| `DeliveryRouteGroup__c` → `DeliveryRoute__c` | Delivery route hierarchy (master-detail). | — |
| `DeliveryPackage__c` + `DeliveryPackageTrackingEvent__c` + `DeliveryPackageTrackingFile__c` | Package + tracking scan events / files. | `Order` |
| `Container_Type__c` / `Equipment__c` | Bin / container / equipment catalogue. | — |

### Billing & finance

| Entity | Purpose | Key relationships |
|---|---|---|
| `Invoice_Header__c` → `Invoice_Line__c` | Custom invoicing (master-detail; header MD to `Account`; self-lookup for credit notes). | `Order`, `OrderItem`, `Product2`, `Bank_Statement__c` |
| `Payment__c` / `PaymentAllocation__c` | Payments and their allocation to invoices / bank statements. | `Account`, `Bank_Statement__c` (MD), `Invoice_Header__c` (MD) |
| `Bank_Statement__c` | Imported bank statement lines (~33 fields; `OnBankStatement` trigger). | `PaymentAllocation__c`, `SageExtract__c` |
| `Cash_Allocation__c` / `VATCorrection__c` / `TheVat__c` | Cash matching and VAT adjustments. | — |
| `SageExtract__c` / `SageExtractFile__c` | Export feed to Sage accounting. | `Bank_Statement__c`, `Invoice_Line__c` |
| `ScheduleAdvanceInvoiceHistory__c` / `ReportPercentEachMonth__c` / `ResultReportSent__c` | Advance-invoice and reporting history. | `Schedule__c` |

### Suppliers / procurement

| Entity | Purpose | Key relationships |
|---|---|---|
| `Suppliers__c` | Waste contractors / haulier partners (~36 fields). | `Supplier_Product__c`, `Region__c` |
| `Supplier_Product__c` | Product offered by a supplier, with pricing (`SuppProdTrigger`). | `Suppliers__c`, `Product2` |
| `Product_Category__c` / `Product_Skin__c` / `Suggested_Product__c` | Product taxonomy & recommendations. | — |

### Service & field sales

| Entity | Purpose | Key relationships |
|---|---|---|
| `Case` | Service/support. Record types include `Missed_Collection`, `Billing_Pricing_Query`, `Credit_Note_Request`, `Delivery_Query`, `Extra_Job`, `Health_Safety`, `Retention_Call`, `Council_Fine`. | `Account`, `Collection_Waypoints__c`, `Missed_Collection__c` |
| `Feedback__c` | Customer feedback / NPS. | `Case`, `Account` |
| `Field_Sales_Visit__c` + `Field_Sales_App_Setting__c` | Field-sales visit logging. | `Account` |
| `Email_Activity__c` / `Send_Email__c` / `SendInvoiceEmail__c` | Outbound email orchestration via **SendGrid** (`SendGridEvent__e`, `SendGridSetting__c` / `Sendgrid_Setting__c`, `SendGridRequestLog__c`). | — |

### Integration, logging & configuration

| Entity | Purpose |
|---|---|
| `NoTriggers__c` | **Hierarchy custom setting (`Flag__c`) — per-user trigger bypass.** Trigger handlers must check `NoTriggers__c.getInstance(UserInfo.getUserId()).Flag__c` and skip when set (used by Enqix import batches). |
| `Log__c` / `Integration_Error__c` | Logging / integration-error records. Existing exception types: `GeneralException`, `EnquixImportException`. The target `ExceptionService` should persist here. |
| `Enqix_Import__c` / `Enqix_Id_automation__c` / `EnqixImportCSVParameters__c` / `EnquixImportMappings__c` | "Enqix" CSV/data-import framework (Account & Order import batches). |
| `ParcelforceSetting__c` | Parcelforce carrier integration config. |
| `GlobalParameter__mdt` | Global configuration parameters. |
| `CollectionExceptions__mdt` / `WeightCategoryToFieldMapping__mdt` | Rules for collection exceptions and weight-category field mapping. |
| Platform events | `ReceivedWaypointGroupEvent__e` (inbound route waypoints), `SendGridEvent__e` (email delivery events). |

> **Naming caution:** the repo contains real misspellings that are part of the API name —
> `DeliiveryLine__c`, `Regionsuppler_association__c`, `EnquixImportMappings__c` vs
> `EnqixImportCSVParameters__c`. Use the exact API name from the repo; do not "correct" it.

---

## Code Organization — Naming Conventions

### Apex

| File type | Convention | Example |
|---|---|---|
| REST Resource | `{Domain}RestResource` | `AccountSearchRestResource` |
| Versioned REST / Model | `{Domain}RestResource_V{N}` / `{Domain}ModelV{N}` | `AccountSearchRestResource_V2` |
| Model (DTO) | `{Domain}Model` | `AccountModel` |
| Builder (SObject) | `{Domain}Builder` | `AccountBuilder` |
| Model Builder | `{Domain}ModelBuilder` | `AccountModelBuilder` |
| Util (helper) | `{Domain}Util` | `AccountSearchUtil` |
| Trigger | `{Object}Trigger` | `AccountTrigger` |
| Trigger Handler | `{Object}TriggerHandler` | `AccountTriggerHandler` |
| Selector _(target)_ | `{Domain}Selector` | `AccountSelector` |
| Test class | `{ClassName}Test` | `AccountTriggerHandlerTest` |
| Custom Metadata Type | `{Feature}__mdt` | — |
| Platform Event | `{Domain}__e` | — |

FM's repo currently also uses `*TriggerHelper` and `*Manager` / `*Controller` — keep using
those where they already exist; use the table above for **new** code.

### Class name length limit

- Apex class names **must not exceed 36 characters** — leaves a 4-char buffer for the
  `Test` suffix (Salesforce max is 40).
- Every production class has a dedicated `{ClassName}Test`.
- Plan the name with this limit in mind.

### Variables & methods

| Element | Convention | Example |
|---|---|---|
| Classes | PascalCase | `AccountTriggerHandler` |
| Test classes | PascalCase + `Test` | `AccountTriggerHandlerTest` |
| Methods | camelCase | `buildAccount`, `handleBeforeInsert` |
| Instance vars | camelCase | `accountModel`, `channelsByAccountId` |
| Collections | descriptive noun, no Hungarian | `accounts`, `usersById` |
| Constants | UPPER_SNAKE_CASE | `DEFAULT_RECORD_TYPE`, `MAX_RETRY_COUNT` |
| Inner VO classes | PascalCase (`virtual` for Model errors) | `AccountModel.Error` |

No Hungarian notation: `lstAccounts` → `accounts`, `mapUsers` → `usersById`.

### API version

- New Apex classes: use a current API version and keep it **consistent with sibling files
  in the same folder**. The repo currently spans 29.0–62.0; target **>= 60.0** for new
  code. Do not bulk-bump existing files as a side effect.

### LWC

| Element | Convention |
|---|---|
| Component folder / JS / HTML / CSS | camelCase (`applicantChannels/`, `applicantChannels.js`) |
| Meta file | `<name>.js-meta.xml` |
| Test file | `__tests__/<name>.test.js` |
| Public property | `@api` |
| Wire adapter | `@wire(getRecord, …)` |
| Event name | kebab-case (`channel-updated`) |
| Apex import | camelCase from `@salesforce/apex/...` |
| Custom label | `@salesforce/label/c.LabelName` |

---

## Apex Best Practices

- **Bulkify everything** — handle collections, assume 200+ in trigger context.
- **No SOQL/DML inside loops** — query/commit outside loops (instant reject in review).
- **Governor-limit awareness** — monitor with the `Limits` class in complex operations.
- **One trigger per object** — handler pattern for dispatch (see Trigger architecture).
- **Separation of concerns** — no logic in controllers or triggers.
- **Keep classes cohesive** — one responsibility per class; aim for < ~400 lines.
- **No hardcoded IDs** — Custom Metadata / Settings / Labels.
- **`with sharing` by default** — document any `without sharing`; `inherited sharing` for
  utilities that should run in the caller's context.
- **Security enforcement** — `WITH USER_MODE` (API 60+) or `WITH SECURITY_ENFORCED`;
  `Security.stripInaccessible()` for FLS before DML on user data.
- **Dynamic SOQL** — bind variables only; never string-concatenate user input
  (`String.escapeSingleQuotes()` as a fallback for identifiers).
- **`Set<String>` for membership checks** — `Set.contains()` over chained `||`.
- **Constants for repeated string sets** — `private static final` collections, not inline
  literals repeated across conditionals.

### Triggers

- **One trigger per SObject.** If one already exists, extend its handler — never add a
  second trigger.
- Trigger body = context routing only: no SOQL, DML, or conditionals beyond dispatch.
  Delegate every context to `{Object}TriggerHandler`.
- Handle all relevant contexts explicitly: `before insert/update/delete`,
  `after insert/update/delete/undelete`.
- Pass `Trigger.new` / `old` / `newMap` / `oldMap` into the handler; don't reach into
  `Trigger.*` deep in helper code.
- Recursion guard: static `@TestVisible Boolean` in the handler, not the trigger.
- **Honor the `NoTriggers__c` bypass** (see Key Entities → Integration/logging/config): the
  handler early-returns when
  `NoTriggers__c.getInstance(UserInfo.getUserId())?.Flag__c == true`. Match the existing
  handlers in the repo.

Template:

```apex
trigger OrderTrigger on Order (before insert, before update, after insert, after update) {
    new OrderTriggerHandler().run();   // or explicit context routing, matching sibling triggers
}

public with sharing class OrderTriggerHandler {
    @TestVisible private static Boolean hasRun = false;

    public void run() {
        if (hasRun) { return; }
        if (NoTriggers__c.getInstance(UserInfo.getUserId())?.Flag__c == true) { return; }
        hasRun = true;

        if (Trigger.isBefore && Trigger.isInsert) { onBeforeInsert(Trigger.new); }
        // ... one method per relevant context; gather ids, one bulk SOQL, mutate/DML in bulk
    }
}
```

Checklist: one trigger per object · every context delegated · no SOQL/DML in loops
(filter by `Set<Id>`) · recursion guard · `NoTriggers__c` honored · handler test covers each
context + a 200-record bulk case.

### Error logging

- Standard API _(target)_: `ExceptionService.registerException(ex, 'ClassName.methodName')`
  then `ExceptionService.commitWork()`.
- Context string is always `ClassName.methodName` so logs trace to origin.
- **Never `System.debug` for error logging.**
- Commit **once at the boundary** (REST resource, trigger handler, batch `execute`) — not
  inside loops or nested helpers.
- Every `catch` logs meaningfully or rethrows a typed exception (e.g. an inner `virtual`
  `Error`/`Exception` class on the relevant Model). No silent swallowing.
- REST resources on `catch`: register via `ExceptionService`, never leak raw messages or
  stack traces to API consumers.
- Preserve the original exception's message/cause when rethrowing.

### Code structure & readability

- Early returns over mutable accumulator variables.
- Extract reusable helpers (`containsAnyIgnoreCase()`), name them for intent.
- Reduce cognitive complexity — pull large nested blocks into named helpers
  (`populateBaseFields`, `applySpecialKeyRules`).
- Inner `Error`/`Exception` classes in Models must be `virtual`.
- Fields holding mock references: `@TestVisible private static`, not `public`.

---

## LWC Development Standards

Key rules:

- All new UI is LWC — no new Aura.
- **Composition:** smart parent orchestrates; dumb children render and emit `CustomEvent`.
  `@api` down, events up. Lightning Message Service for cross-DOM; avoid ad-hoc pubsub.
- **Data:**
  - Reads via `@wire` (`getRecord`, `getObjectInfo`, `getPicklistValues`, or an
    `@AuraEnabled(cacheable=true)` Apex method). Handle `{ data, error }` for every wire.
  - Writes via imperative non-cacheable Apex, then `refreshApex` /
    `notifyRecordUpdateAvailable`.
  - No SOQL/DML decisions in JS.
- Handle loading, error, and empty states in every component; on a failed callout, set the
  empty/`No_Results` state in the `catch`. Normalize errors with a shared `reduceErrors`.
- Custom labels for all user-facing strings (i18n ready).
- Single responsibility — one component, one purpose.
- SLDS + base components; **no inline styles**; no raw `document` / `window` DOM work.
- Use base components (`lightning-formatted-date-time`, `lightning-formatted-number`) —
  not custom JS formatting or `window.location` for resources.
- Don't add Aura/SLDS input classes to base components (`slds-input` on `lightning-input`
  causes double borders) — use `variant` / `label` attributes.
- Normalize non-standard API date formats via a `parseDateTime()` helper.
- Module-level `const` maps over static class properties; lookup maps over if/else chains.
- `@track` only for deep object/array reactivity. Remove dead code and unused imports.
- **Accessibility:** labelled inputs, semantic markup, keyboard operable, `aria-*` as
  needed.
- `js-meta.xml`: expose only the targets actually used.
- Tests: Jest under `__tests__/`, mock Apex + wire adapters; cover render, `@api` changes,
  interactions, wire success/error, empty & loading states. Coverage 80%+.

### Legacy Aura

- Do **not** build new Aura components — build LWC.
- When a change to an Aura component is unavoidable: keep it minimal and localized; don't
  refactor the whole bundle. Push non-trivial logic to an Apex controller or a child LWC
  (via `lightning:...` interop) rather than growing the JS controller/helper. Preserve
  existing `aura:attribute` names and events — other components may depend on them.
- Flag simple, self-contained components as migration candidates in your summary.

### Aura → LWC migration

- Use the existing Aura component as a **functional reference only** — not a pattern to
  copy.
- Feature-parity checklist before "done": pagination, filtering, sorting, empty states,
  error states, popovers, tooltips, every user interaction.
- Preserve API contracts: `@api` props, events, payload shape, method semantics.
- Keep template semantics and accessibility intact.
- Add/update Jest tests for key logic and edge cases.

---

## Testing Approach

Key testing rules:

- **Framework:** Apex Test Framework + `fflib-apex-mocks` _(target)_ for mocking/isolation.
- **Test class naming:** `{ClassName}Test`, one dedicated class per production class — never
  combine.
- **Test method naming:** snake_case with a `should_` prefix —
  `should_<behavior>[_when_<condition>]`. Examples: `should_verify_account`,
  `should_return_error_when_payload_invalid`, `should_handle_before_insert_bulk`. **Do
  not** use `testDoPost...` or camelCase BDD names. (FM's repo has a mix of `*Test` and
  `*_Test`; match the sibling file when editing, use `{ClassName}Test` + `should_` for new.)
- **Coverage:** 75% Salesforce minimum; **quality gate 85%**; aim 95%+.
- `@TestSetup` for shared data; `Test.startTest()/stopTest()` around the exercised call.
- **No `SeeAllData=true`** — build test data explicitly (data factory preferred).
- Every assertion uses the `Assert` class with a **mandatory descriptive message** as the
  last parameter.
- Test negative paths, boundaries, permission failures, and **bulk (200+)**.
- Mock all external dependencies — no real callouts.
- Mock-injection fields: `@TestVisible private static`; mock variables lowercase `mocks`.
- Test data must match production transformations exactly (e.g. a `substring(0, len-4)`
  method needs test input that accounts for it).

### LWC (Jest) — coverage target 80%+
Wire-adapter mocking, imperative Apex mocking, DOM event simulation, lifecycle, navigation
and toast verification, empty & loading states.

---

## CI/CD & Deployment

| Environment | Purpose | How |
|---|---|---|
| Dev sandbox | Feature development | `sf project deploy start -d force-app --target-org <alias>` |
| QA / UAT sandbox | Validation / UAT | pipeline _(target)_ or manual `sf` deploy |
| Production | Live | **protected — manual approval, pipeline only; agents never deploy here** |

- Always **validate before deploying**:
  `sf project deploy validate --source-dir <paths> --test-level RunLocalTests --target-org <sandbox>`.
- Deploy only to sandboxes, only when asked. Retrieve latest from the dev sandbox before
  starting implementation.
- Quality gates: Apex tests all pass @ 85%+; LWC Jest all pass @ 80%+; Code Analyzer no
  critical/high; Sonar (run locally) no blocker/critical; deploy validation succeeds.

---

## Security & Governance

- `with sharing` by default; `without sharing` only when required (service/system context)
  and documented; `inherited sharing` for utilities.
- FLS: `Security.stripInaccessible()` or `WITH USER_MODE` / `WITH SECURITY_ENFORCED`.
- No hardcoded credentials/IDs; secrets via Named Credentials / Protected Custom Metadata.

### Governor limits to watch

| Limit | Sync max | Mitigation |
|---|---|---|
| SOQL / transaction | 100 | bulkify, collections |
| DML / transaction | 150 | bulkify, batch DML |
| Heap | 6 MB | stream/paginate |
| CPU time | 10,000 ms | offload to async |
| Callouts / transaction | 100 | batch, Platform Events |
| `@future` / transaction | 50 | use Queueable for chaining |

---

## Metadata

- Treat metadata XML as generated: keep Salesforce's element ordering and formatting;
  change only the intended nodes.
- **Do not hand-edit** `profiles/`, `permissionsets/`, `namedCredentials/`,
  `customMetadata/`, or `settings/` as a side effect of tooling / framework / doc work.
  Functional changes need an explicit request and should be **retrieved from a sandbox**,
  not hand-authored.
- Grant new object/field access via **permission sets**, not profiles.
- Keep `<apiVersion>` consistent within a metadata type/folder (Apex/triggers >= 60.0 for
  new files).
- Never commit secrets, endpoints with embedded tokens, or real-org ids in metadata.
- Object/field changes: update the `-meta.xml` **and** dependent permission sets in the
  same change — only when explicitly asked.

---

## Code Review Standards

Applies to any diff under `force-app/`. Report findings as
`severity | file:line | issue | suggested fix` and block on any **High**.

### Priority order

1. **Correctness** — solves the problem; breaks nothing (zero-regression).
2. **Governor limits & performance** — SOQL/DML in loops, unbounded queries, missing
   `LIMIT`, CPU concerns.
3. **Security** — FLS/CRUD, sharing, injection, hardcoded credentials/IDs.
4. **Architecture & separation of concerns** — right layer for the logic.
5. **Bulkification** — survives 200-record trigger context.
6. **Test quality** — meaningful assertions and edge cases, not just coverage %.
7. **Code clarity** — readability, naming, unnecessary complexity.

### Instant-reject / high-severity red flags

- SOQL/DML inside loops
- Hardcoded record type / profile / org-specific IDs
- Missing null checks on collections/maps before access
- `without sharing` without justification
- Business logic in a controller or trigger
- Test classes using `SeeAllData=true`; missing `@TestSetup` / data factory
- Overly broad try/catch that swallows exceptions silently
- New code duplicating existing functionality
- LWC `@wire` without error handling
- New Aura component where LWC should be used
- In-place edit of an existing `_V[N]` class instead of a new version

### Review comment format (esp. migrations)

Per finding: **what is wrong** (specific, localized) · **why it matters** (risk /
performance / maintainability) · **exact fix** (copy-paste ready where possible).

### Full checklist

**Architecture & patterns**
- [ ] Layered pattern respected: Trigger → Handler → Util → Builder/Model; controllers and
      REST resources are thin.
- [ ] No fflib architecture in implementation code (factory / UoW / base classes /
      interfaces). `fflib-apex-mocks` only in tests.
- [ ] One trigger per object; no logic in the trigger body; `NoTriggers__c` bypass honored.
- [ ] SOQL centralized in a selector/util, not duplicated inline across handlers.
- [ ] New REST version = new `_V{N}` class; existing versioned class not mutated.
- [ ] Inner exception/error classes in models are `virtual`.

**Bulkification**
- [ ] No SOQL / DML / async enqueue inside loops.
- [ ] Queries filtered by `Set<Id>` / collections; `Map` lookups used.
- [ ] Handles 200-record context.

**Security**
- [ ] Queries use `WITH USER_MODE` or `WITH SECURITY_ENFORCED`.
- [ ] CRUD/FLS checked before DML on user data (`Security.stripInaccessible` / `Schema`
      describe).
- [ ] No SOQL/SOSL injection — bind variables, not string concatenation.
- [ ] `with sharing` by default; any `without sharing` justified in a comment.
- [ ] No hardcoded IDs; secrets via Named Credential / Custom Metadata / Custom Label.

**Error handling**
- [ ] `ExceptionService.registerException(ex, 'Class.method')` + `commitWork()` at the
      boundary; no `System.debug` for logging.
- [ ] Specific exception types caught; no empty / over-broad `catch`.

**Naming & versioning**
- [ ] Class names <= 36 chars; one `{Class}Test` per production class.
- [ ] Test methods `should_<behavior>[_when_<condition>]` (snake_case).
- [ ] API version >= 60.0, consistent with siblings.

**Tests**
- [ ] Dedicated test class present and updated.
- [ ] Happy path + bulk (200) + edge + negative + regression scenarios.
- [ ] `Assert` class (not legacy `System.assert*`) with a descriptive message on every
      assertion.
- [ ] `@TestSetup` or a data factory; `SeeAllData=false`; no reliance on org data.
- [ ] Mock injection via `@TestVisible private static` fields; external callouts mocked.
- [ ] Coverage: 85%+ (aim 95%); LWC Jest 80%+.

**LWC**
- [ ] `@wire` for reads; imperative Apex only for writes; `{ data, error }` handled.
- [ ] Loading & error states rendered; errors normalized via `reduceErrors`.
- [ ] SLDS + base components; no raw DOM manipulation; accessible markup.
- [ ] Jest specs cover render, `@api` changes, interactions, wire success/error, empty
      states.

**Cross-cutting**
- [ ] Zero-regression: callers / dependents traced.
- [ ] Sonar run locally — no blocker/critical.
- [ ] No new code duplicating existing functionality.

---

## Development Philosophy

- **Simplicity first** — minimum complexity; don't over-engineer.
- **Configuration over code** — Custom Metadata / Settings / Labels for values that change.
- **Reuse existing patterns** — check for similar functionality before writing new code.
- **Think in bulk** — assume large batches; design accordingly.
- **Fail fast, fail loud** — explicit errors over silent failure; log via `ExceptionService`.
- **Backward compatibility** — consider integrations and downstream consumers before
  changing interfaces.

## Scale & Performance

- Design for high volume — assume large record counts.
- Consider governor limits in every implementation.
- Batch / Queueable / Scheduled Apex for large data operations.
- Prefer async for anything that doesn't need a synchronous response.
- Monitor heap and CPU for complex operations; use `LIMIT` and pagination for large sets.
