<!--
Traceability
Ticket: CRMFM-7
Artifact: exploration.md
Gate: 2
Status: SAVED
Last updated: 2026-09-30
-->

# Exploration — CRMFM-7

## What was explored
- Recurring Order object identity — `force-app/main/default/objects/Recurrings__c/` —
  confirmed "Recurring Order" in the ticket = `Recurrings__c` custom object.
- `Discount_to_Apply__c` field metadata — confirmed "Discount Type" = this picklist
  (`Account` / `Partner`, restricted). **CORRECTION (2026-09-30, post Gate-6 testing):** the
  `<default>true</default>` on `Account` was initially assumed to be UI-layout-only, but
  empirical testing in the `fm-ai` sandbox proved it is actually applied by the platform on
  every Apex/API insert that omits the field — not just via the UI. See `specs.md` Spec 1's
  revision note for the resulting design fix.
- `ManualPrice__c` field metadata — confirmed "Manual Price" = this Currency field.
- `git log` on `Discount_to_Apply__c.field-meta.xml` — confirmed the existing picklist
  default predates this ticket and was untouched by the reverted CRMFM-2 work, so it alone
  has never solved the reported bug.
- `RecurringTrigger.trigger` + `RecurringTriggerHelper.cls` — confirmed the FM
  trigger-handler pattern is present for this object (before insert/before update,
  delegates to helper, uses `rec.addError(...)` for an existing validation).
- `force-app/main/default/objects/Recurrings__c/validationRules/*.xml` — confirmed the
  house style for declarative validation rules (simple `errorConditionFormula` +
  `errorDisplayField` + `errorMessage`, e.g. `RequireActiveProduct`).
- `force-app/main/default/flows/OrderProductBeforeSave.flow-meta.xml` — confirmed an
  existing precedent: a Before-Save Record-Triggered Flow (`RecordBeforeSave`,
  `CreateAndUpdate`) on `OrderItem` that already branches on the analogous
  `Discount_to_Apply__c` field.
- `RecurringBatch.cls` — confirmed it bulk-updates `Recurrings__c` via `Database.update`
  but never touches `ManualPrice__c` / `Discount_to_Apply__c`, so scoping the new
  validation rule with `ISCHANGED()` on those two fields will not affect this batch.
- `TestDataHelper.insertRecurring(...)` — confirmed an existing reusable test-data factory
  for `Recurrings__c`.
- Checked for any Apex/batch code that inserts `Recurrings__c` directly (bulk import paths
  that might need a `NoTriggers__c`-style bypass) — none found outside test classes.

## Existing components relevant to this work
| Component | Path | Role | Reuse / extend / reference |
|---|---|---|---|
| `Recurrings__c.Discount_to_Apply__c` | `force-app/main/default/objects/Recurrings__c/fields/Discount_to_Apply__c.field-meta.xml` | "Discount Type" picklist (`Account`/`Partner`) | Target field for new default + validation logic |
| `Recurrings__c.ManualPrice__c` | `force-app/main/default/objects/Recurrings__c/fields/ManualPrice__c.field-meta.xml` | "Manual Price" currency field | Condition field for new default + validation logic |
| `RecurringTrigger` / `RecurringTriggerHelper` | `force-app/main/default/triggers/RecurringTrigger.trigger`, `force-app/main/default/classes/RecurringTriggerHelper.cls` | Existing before insert/update trigger handler for this object | Reference only — not modified (declarative approach chosen instead) |
| `Recurrings__c` validation rules | `force-app/main/default/objects/Recurrings__c/validationRules/` | Existing declarative validation style | Style reference for new Validation Rule |
| `OrderProductBeforeSave` flow | `force-app/main/default/flows/OrderProductBeforeSave.flow-meta.xml` | Existing Before-Save Record-Triggered Flow on OrderItem branching on `Discount_to_Apply__c` | Direct structural pattern to mirror for the new Recurrings__c flow |
| `RecurringBatch` | `force-app/main/default/classes/RecurringBatch.cls` | Scheduled bulk updater of `Recurrings__c` | Confirms new validation rule's `ISCHANGED()` scoping won't break it |
| `TestDataHelper.insertRecurring` | `force-app/main/default/classes/TestDataHelper.cls` | Existing Recurrings__c test-data factory | Reuse in new Apex test coverage for the validation rule (DML exception tests) |

## Existing patterns observed
- Layering: For this object, Salesforce declarative metadata (Flow + Validation Rule) is
  used side-by-side with a legacy Apex trigger/handler; new field-behavior logic is not
  required to go through Apex when the platform-native mechanism suffices. FM's
  `RestResource -> Util/Handler -> Builder/Model` layering applies to Apex/REST work, not to
  this pure-declarative field-behavior change.
- Versioning: No `_V[N]` REST classes involved — not applicable to this ticket.
- Test approach: Apex tests exercise validation rules indirectly by asserting a
  `DmlException` is thrown on `insert`/`update` with the expected error message substring;
  `TestDataHelper.insertRecurring` is the existing factory to build a baseline valid record
  before mutating fields for negative-path assertions.

## Configuration
- Custom Metadata Types: none relevant.
- Custom Settings: none relevant (`NoTriggers__c` bypass is Apex-trigger-only and not
  applicable to declarative Flow/Validation Rule logic; confirmed no bulk Apex path inserts
  `Recurrings__c` that would need a bypass).
- Named Credentials: none relevant.
- Permission Sets: none relevant (no new fields/objects requiring FLS grants).

## Solution alternatives considered
### Option A: Before-Save Flow (default) + Validation Rule (enforcement) — declarative, no Apex
Description: A new Record-Triggered Before-Save Flow on `Recurrings__c` (mirroring
`OrderProductBeforeSave`) sets `Discount_to_Apply__c = 'Account'` when both it and
`ManualPrice__c` are blank. A new Validation Rule blocks saves where `ManualPrice__c` and
`Discount_to_Apply__c` are both populated, or where `ManualPrice__c` is blank and
`Discount_to_Apply__c` is populated with anything other than `Account`. The rule is scoped
with `(ISNEW() || ISCHANGED(ManualPrice__c) || ISCHANGED(Discount_to_Apply__c))` so
unrelated edits to already-existing non-compliant records are not newly blocked.
- Pros: No Apex; matches an existing proven pattern in this exact codebase; works
  regardless of record-creation path (UI, API, data load); fully satisfies all 7 ACs; zero
  governor-limit footprint.
- Cons: Two metadata artifacts to maintain instead of one.
- Risk: Low.
- Effort: S.

### Option B: Apex Trigger Handler (extend `RecurringTriggerHelper`)
Description: Add defaulting and `addError(...)`-based validation logic directly into
`RecurringTriggerHelper`, invoked from the existing `RecurringTrigger`.
- Pros: Single code location; easy to unit-test with existing Apex conventions.
- Cons: Contradicts the developer's stated preference for a declarative default; adds Apex
  and 85%-coverage test burden for logic that is a simple field comparison; less
  discoverable to Salesforce admins than a Validation Rule.
- Risk: Low technically, but scope-mismatch risk against stated direction.
- Effort: M.

### Option C: Rely on the existing picklist default + Validation Rule only (no Flow)
Description: Keep the pre-existing `<default>true</default>` on the `Account` picklist
value as the sole defaulting mechanism; add only the Validation Rule from Option A.
- Pros: Smallest footprint; reuses metadata already present.
- Cons: Does not satisfy AC1 for any record created outside the standard UI layout (API,
  data load, integration) — this is the literal root cause the ticket describes. Not a
  complete fix.
- Risk: High (fails acceptance criteria).
- Effort: XS.

### Comparison matrix
| Criterion | Option A | Option B | Option C |
|---|---|---|---|
| Effort | S | M | XS |
| Governor-limit impact | None (0 SOQL/DML) | None (0 SOQL/DML, before-insert only) | None |
| Bulkification complexity | Low (Flow/VR natively bulk-safe) | Low (existing bulk-safe handler) | Low |
| Versioning impact | None | None | None |
| Aligns with FM patterns | Yes — mirrors `OrderProductBeforeSave` | Partial — valid pattern, not requested | Partial |
| Reuses existing code | Reuses proven Flow pattern + VR style | Reuses `RecurringTriggerHelper` | Reuses field default only |
| Satisfies all ACs | Yes | Yes | No (fails AC1) |

## Recommendation
Option A — declarative Before-Save Flow for defaulting + a Validation Rule for
enforcement. It matches the developer's stated preference for a declarative default,
directly reuses a proven pattern already present in this codebase
(`OrderProductBeforeSave`), requires no Apex or associated test-coverage burden, and is the
only option (besides B) that fully satisfies every acceptance criterion.

## Chosen approach
Option A, selected by rakeshchatty on 2026-09-30.
