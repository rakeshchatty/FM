# Salesforce FM — Code Review

This prompt performs a structured code review of a FirstMile (FM) Salesforce pull request
against established team standards and best practices.

## Workflow

Follow the workflow defined in: `review.workflow.md`

## Instructions

- `.myit/instructions/salesforce-fm/guardrails.instructions.md`
- `.myit/instructions/salesforce-fm/architecture.instructions.md`
- `.myit/instructions/salesforce-fm/tools.instructions.md`

## 0. Project Configuration Values

| Configuration Item | Salesforce Value |
|---|---|
| `PROJECT_CONTEXT` | `project-context.md` (read if present) |
| `BASE_BRANCH` | `main` |
| `PR_CLI` | `gh` (GitHub) |
| `TICKET_TRACKER` | Jira — ticket IDs referenced from the branch name / PR title (e.g. `FM-002`) |
| `CLASS_PREFIX` | None — FM does not enforce a custom class-name prefix |
| `ERROR_LOGGING` | `ExceptionService.registerException` + `ExceptionService.commitWork()` (target — see `architecture.instructions.md`) |

## 1. Pre-Gate: FM-Specific Diff Guidance

When reading the diff for the FM Salesforce project:

**Source path**
- The FM repo uses SFDX source format with `force-app/main/default/` as the source directory.
- Check `sfdx-project.json` → `packageDirectories[0].path` to confirm.

**File classification**
- Apex code = `.cls` files in `classes/` (e.g. `force-app/main/default/classes/`)
- Apex triggers = `.trigger` files in `triggers/`
- LWC code = files under `lwc/` (`.js`, `.html`, `.css`) — check the parent folder is `lwc/`, not `aura/`
- Aura code = files under `aura/` (`.cmp`, `.app`, `.evt`, `.js`, `.css`, `.helper`, `.controller`) — legacy, no new components allowed
- Distinguish by path, not extension: `.js` and `.css` exist in both LWC and Aura — check the parent folder (`lwc/` vs `aura/`)
- Metadata = `.xml` files (object definitions, fields, permissions, layouts)
- Configuration = `sfdx-project.json`, `config/project-scratch-def.json`
- Test code = `*Test.cls` files (FM's repo also has a legacy `*_Test.cls` pattern — match the sibling file); `__tests__/*.test.js` files
- Skip = `.sfdx/`, `.sf/`, `node_modules/`, generated metadata timestamps

**When reading full files for context, pay attention to:**
- Sharing model — `with sharing` vs `without sharing` vs `inherited sharing`
- Layer classification — RestResource / Util / Handler / Builder / Model
- Governor limit patterns — SOQL/DML in loops, unbounded queries
- Bulkification — code must handle collections, not single records
- Versioning — check for `_V2`, `_VN` suffixed classes; never mutate existing versioned classes
- Error logging — must use `ExceptionService.registerException` + `ExceptionService.commitWork()`, not `System.debug`
- `NoTriggers__c` bypass — trigger handlers must honor the per-user `NoTriggers__c.Flag__c` bypass

## 2. FM-Specific Review Guidance

The workflow defines the general review phases. Below is FM-specific guidance for what to
focus on.

### Standards Review — FM Focus

- **Pragmatic layered architecture** — this codebase does not use fflib enterprise base
  classes in implementation code. It uses `RestResource → Util/Handler → Builder/Model`.
  `fflib-apex-mocks` is only in test classes.
- **Separation of concerns** — triggers must only delegate to handler classes; business
  logic belongs in utils/services, not triggers or controllers.
- **Bulkification** — all Apex code must handle bulk operations (200+ records); no
  single-record assumptions.
- **SOQL/DML in loops** — this is a critical blocker. Query and DML operations must be
  outside loops.
- **Hardcoded IDs** — record IDs, profile IDs, or org IDs in code are a critical blocker.
  Use Custom Metadata or Custom Labels.
- **`SeeAllData=true`** — using this in test classes is a critical blocker. Always create
  test data explicitly.
- **Sharing declarations** — every Apex class must have an explicit sharing declaration
  (`with sharing` / `without sharing` / `inherited sharing`). `without sharing` requires
  documented business justification.
- **REST API versioning** — new API versions must be new classes with `_VN` suffix.
  Existing versioned classes must NOT be mutated — create a new version instead.
- **Error logging** — must use:
  ```apex
  ExceptionService.registerException(ex, 'ClassName.methodName')
  ExceptionService.commitWork()
  ```
  Never use `System.debug` for error logging. (This is a target pattern — see
  `architecture.instructions.md`; until `ExceptionService` exists in the repo, flag
  divergence rather than blocking on it.)
- **Inner Error/Exception classes** — must be `virtual` for Salesforce serialization.
- **API version** — new Apex classes should use API version `>= 60.0`, consistent with
  sibling files in the same folder. Do not bulk-bump existing files as a side effect.

### LWC Review — FM Focus

- **Component patterns** — no new Aura; all new UI must be LWC. If the PR adds a new Aura
  component, it is a blocker.
- **SLDS compliance** — use SLDS utility classes, not custom CSS for standard patterns.
  Don't mix Aura CSS with LWC base components (e.g. don't add `slds-input` to
  `lightning-input` — causes double borders; use `variant` and `label` attributes instead).
- **Use native Lightning components for formatting** — dates → `lightning-formatted-date-time`,
  numbers → `lightning-formatted-number`. Don't use custom JS formatting or `window.Util.*`
  from static resources.
- **`@api` properties** — public properties must be documented and validated.
- **Wire vs imperative** — prefer `@wire` for read operations; imperative calls only for
  mutations or conditional fetching.
- **Handle non-standard API date formats** — external APIs may return malformed ISO
  timestamps; write a `parseDateTime()` normalizer.
- **State & reactivity** — no unnecessary `@track` (plain class properties are reactive by
  default in modern LWC; `@track` is only needed for deep object/array observation). Remove
  unused properties and imports.
- **Module-level constants over static class properties** — for lookup maps and fixed
  configuration, use `const` at module level.
- **JavaScript quality** — replace repetitive if/else chains with lookup maps (plain object
  map). No `console.log` in production code. No dead code — unused variables, methods, and
  CSS selectors must be removed.
- **Error & empty states** — all Apex calls must handle errors (`lightning-toast` or inline
  error messaging). Always set the empty state in `catch` blocks. Every component must
  handle loading, error, and empty states explicitly.
- **Accessibility** — ARIA labels on interactive elements; verify keyboard navigation
  support. Lightning input accessibility: use `variant="label-hidden"` with `label="..."`.

### Aura Migration Reviews

If this is a migration PR, verify feature parity: pagination, filtering, sorting, empty
states, error states, popovers, tooltips, and all user interactions from the source Aura
component. Use the source Aura component as a functional reference only — don't copy poor
patterns.

### Aura Review — FM Focus (Existing Components Only)

No new Aura components allowed. These rules apply only to modifications of existing Aura
code:

- Don't add new features to Aura — if the change is significant, it should be an LWC
  migration instead.
- Helper over controller — business logic belongs in the helper.
- No direct DOM manipulation — use Aura patterns.
- No jQuery or external JS libraries.

### Metadata Review — FM Focus

When the PR includes metadata changes (`.xml` files):

**Custom Objects & Fields**
- Field-level security — new fields must have FLS configured in relevant permission sets.
- Data type appropriateness — is the chosen field type correct?
- Field descriptions — custom fields should have a description.
- Required vs optional — verify required flag is intentional.
- Relationship fields — verify `deleteConstraint`, relationship name, child relationship name.
- **Naming caution** — FM's data model contains real misspellings that are part of the live
  API name (e.g. `DeliiveryLine__c`, `Regionsuppler_association__c`). Use the exact API name
  from the repo — do not "correct" it in a diff.

**Permission Sets & Profiles**
- No profile modifications — prefer Permission Sets over Profile changes.
- Least privilege — new permissions should be minimal.
- Check for accidental removals — metadata diffs can accidentally remove existing
  permissions.

**Flows & Process Builders**
- No new Process Builders — use Flow for all new automation (Process Builder is deprecated).
- Flow bulkification — verify the flow handles bulk records.
- Flow error handling — fault paths must be defined for all DML and callout elements.

**Custom Metadata Types**
- Read-only in code — Custom Metadata should be queried, never modified via DML in
  production code.
- No hardcoded values — if a value is in Custom Metadata, don't also hardcode it in Apex.

**Custom Labels**
- No hardcoded user-facing strings — all user-facing text should use Custom Labels for
  i18n readiness.
- Check for duplicates — search existing labels before creating new ones.

**Validation Rules**
- Bypass mechanism — complex validation rules should have a bypass via Custom Permission or
  Custom Metadata.
- Error messages — must be user-friendly and actionable.

### Security & Performance — FM Focus

- **FLS enforcement** — SOQL queries must use `WITH USER_MODE` (API 60+, preferred),
  `WITH SECURITY_ENFORCED`, or `Security.stripInaccessible()` for user-facing data.
- **CRUD checks** — DML operations must verify object-level and field-level access where
  applicable.
- **Unbounded queries** — `SELECT` without `LIMIT` or `WHERE` on large objects is a major
  concern.
- **Governor limits** — check `Limits` class usage for operations near limits.
- **Named Credentials** — external callouts must use Named Credentials; never hardcode
  URLs/credentials.

### Test Adequacy — FM Focus

- **Coverage target** — 85%+ line coverage for new Apex code (Salesforce minimum is 75%);
  aim for 95%+.
- **Bulk tests** — at least one test per trigger handler that processes 200+ records.
- **Negative tests** — exception paths and permission failures must be tested.
- **Test data isolation** — all test data must be created via `@TestSetup` or inline factory
  methods; no `SeeAllData`.
- **Assert quality** — every test must have meaningful assertions with descriptive failure
  messages, using the `Assert` class (not legacy `System.assert*`).
- **Test method naming** — `should_<behavior>[_when_<condition>]`, snake_case, not
  camelCase.
- **LWC test coverage** — 80%+ for new LWC components with wire mocking and event
  simulation.
- **Missing tests** — new production code without corresponding test changes is always a
  Major finding.
- **Separate test classes** — every production class must have its own dedicated test class
  (FM's repo has a mix of `{ClassName}Test` and `{ClassName}_Test` — match the sibling file
  when editing; use `{ClassName}Test` for new classes).
- **Mock injection** — use `@TestVisible private static` fields, not constructor injection.
- **Test mock variables** — use lowercase `mocks`, not `MOCKS`.

### Naming — FM Focus

- **Class name length** — Apex class names must not exceed 36 characters (leaves a 4-char
  buffer for the `Test` suffix; Salesforce max is 40).
- **Variable/method name length** — all variable and method names must be longer than 3
  characters.
- **Blocked names** — never acceptable: `abc`, `xyz`, `lmn`, `str`, `arr`, `array`, `lst`,
  `list`, `bool`, `obj`, `val`, `tmp`, `temp`, `data`, `info`, `item`, `elem`, `ret`, `res`,
  `result`.
- **No numbers in names** — variable and method names must not contain numbers (e.g.
  `value1`, `result2`).
- **No Hungarian notation** — e.g. `lstAccounts` → `accounts`, `mapUsers` → `usersByIdMap`.
- **API version** — new Apex classes should use API version `>= 60.0`, consistent with
  sibling files in the same folder.

## 3. FM-Specific Anti-Patterns (Blockers)

The following are automatic blockers in code review:

| Anti-Pattern | Severity | Reason |
|---|---|---|
| SOQL/DML inside a loop | Critical | Governor limit violation |
| `SeeAllData=true` in test class | Critical | Test data isolation violation |
| Hardcoded record/profile/org IDs | Critical | Environment-specific, breaks in other orgs |
| No sharing declaration on Apex class | Major | Implicit `without sharing` is a security risk |
| Credentials in code or metadata | Critical | Security violation |
| `without sharing` without justification | Major | Potential data exposure |
| No assertions in test methods | Major | Tests don't verify behavior |
| Single-record trigger code | Major | Will fail in bulk operations |
| Class name exceeds 36 characters | Major | Test class name will exceed 40-char limit |
| Missing dedicated test class | Major | Every production class needs its own test |
| Variable/method name ≤ 3 chars | Major | Names must be descriptive |
| Placeholder names (`abc`, `xyz`, `lmn`) | Major | No placeholder names in production code |
| Numbers in variable/method names | Major | Use descriptive names |
| Apex class API version < 60.0 | Major | New classes should use API version >= 60.0 |
| New Aura component | Critical | All new UI must be LWC |
| `console.log` in LWC production code | Major | No console logging in production |
| Missing error/loading/empty state | Major | LWC must handle all three states |
| Unnecessary `@track` decorator | Minor | Plain properties are reactive by default |
| `slds-input` on `lightning-input` | Major | Causes double borders |
| New Process Builder | Critical | Deprecated — use Flow instead |
| Profile modification instead of PermSet | Major | Use Permission Sets, not Profile changes |
| New field without FLS in PermSet | Major | Field is invisible without FLS configured |
| Hardcoded string in LWC/Aura UI | Major | Use Custom Labels for i18n readiness |
| Adding features to existing Aura | Major | Significant changes should be LWC migration |
| `System.debug` for error logging | Major | Use `ExceptionService.registerException` |
| Mutating existing versioned class | Major | Create a new `_VN` version instead |
| fflib base classes in implementation code | Major | FM uses pragmatic patterns, not fflib architecture |
| `NoTriggers__c` bypass not honored | Major | Breaks Enqix import batches and other bulk-load flows |

## 4. Review Summary Output (MANDATORY)

After completing the review, you MUST generate a review summary markdown file.

**File Name & Location**

```
docs/artifacts/<TICKET-ID>/<TICKET-ID>-review-summary.md
```

Example: `docs/artifacts/FM-002/FM-002-review-summary.md`

**File Contents**

The review summary file must contain:

```markdown
# Code Review Summary — <TICKET-ID>

> **PR:** <PR title or URL>
> **Branch:** <source branch>
> **Reviewer:** AI-assisted review
> **Date:** <YYYY-MM-DD>

---

## Verdict: <APPROVED | APPROVED WITH COMMENTS | CHANGES REQUESTED>

---

## Summary

<1-3 sentence overview of what the PR does and the overall review outcome>

---

## Findings

### Critical (Blockers)

| # | File | Line | Finding | Recommendation |
|---|---|---|---|---|
| 1 | ... | ... | ... | ... |

(or "None")

### Major

| # | File | Line | Finding | Recommendation |
|---|---|---|---|---|
| 1 | ... | ... | ... | ... |

(or "None")

### Minor / Suggestions

| # | File | Line | Finding | Recommendation |
|---|---|---|---|---|
| 1 | ... | ... | ... | ... |

(or "None")

---

## Checklist Results

| Check | Result |
|---|---|
| Bulkification | ✅ / ❌ |
| Governor Limits | ✅ / ❌ |
| Security (FLS/sharing) | ✅ / ❌ |
| Test Coverage | ✅ / ❌ |
| Naming Conventions | ✅ / ❌ |
| Error Logging | ✅ / ❌ |
| No Hardcoded IDs | ✅ / ❌ |

---

## Files Reviewed

| File | Type | Verdict |
|---|---|---|
| ... | Apex/LWC/Metadata/Test | OK / Issues found |

---

## Recommendations

<Actionable next steps for the developer>
```

**Rules**

- Always create this file — the review summary is a mandatory deliverable, not optional.
- Use the Jira ticket number extracted from the branch name or PR title (e.g., `FM-002`).
- Create the artifact directory if it doesn't exist: `docs/artifacts/<TICKET-ID>/`
- Be factual — only include findings that are evidenced in the diff; do not speculate.
- Severity must match Section 3 — use the anti-pattern severity table above for
  classification.
