# Workflow: Bug Fix (lightweight)

Fast path for small, well-understood defects. For anything non-trivial or touching
multiple layers, use the gated `/salesforce-fm-develop` prompt instead.

## 1. Reproduce & isolate
- Get exact steps, expected vs. actual, org type, and error text / debug logs.
- Identify the entry point (trigger, flow, LWC, batch, REST) and the responsible class.
- Read the actual code end-to-end. The repository is the source of truth.

## 2. Failing test first
- Add a test that reproduces the defect. Confirm it fails for the right reason.
- Follow the testing standards in `.myit/instructions/salesforce-fm/architecture.instructions.md`.

## 3. Fix at the right layer
- Root cause, not symptom. Minimal, localized change.
- Watch bulk/recursion: a single-record fix that breaks at 200 records is not a fix.
- Follow the Apex Best Practices in `.myit/instructions/salesforce-fm/architecture.instructions.md`.

## 4. Verify
- New test passes; run `sf apex run test --target-org <sandbox> -l RunLocalTests` — check
  for regressions.
- `sf scanner run --target force-app/ --format table` — no new critical/high.

## 5. Document
- Fill `.myit/templates/pull-request.md` (root cause, fix, regression risk).
- Validate-only: `sf project deploy validate --source-dir <paths> --test-level RunLocalTests
  --target-org <sandbox>`. No deploy, commit, push, or branch without explicit approval.
