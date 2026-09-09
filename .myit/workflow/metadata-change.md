# Workflow: Metadata / Configuration Change (lightweight)

For declarative changes (objects, fields, flows, layouts, flexipages, value sets). For
anything with Apex/LWC impact or cross-team risk, use `/salesforce-fm-develop`.

## 1. Plan
- List every metadata component touched and its type.
- Identify dependent permission sets, layouts, and Apex/LWC referencing the field/object.
- Confirm the change is in scope and explicitly requested — do **not** edit
  profiles / permission sets / Named Credentials / Custom Metadata unprompted
  (`.myit/instructions/salesforce-fm/architecture.instructions.md` → Metadata).

## 2. Make the change in an org, then retrieve
- Prefer building it in a sandbox / scratch org and retrieving:
  `sf project retrieve start --metadata <Type:Name> --target-org <sandbox>`.
- If authoring XML directly, preserve Salesforce's element ordering; keep `apiVersion`
  consistent with the folder.

## 3. Permissions
- Grant new field/object access via **permission sets**, not profiles. Update them in the
  same change — only when explicitly asked.

## 4. Validate
- `sf project deploy validate --source-dir <paths> --test-level RunLocalTests --target-org
  <sandbox>`.
- No production connection. No commit / push / branch without approval.
