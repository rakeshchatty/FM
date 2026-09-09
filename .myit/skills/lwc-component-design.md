# Skill: LWC Component Design

## Composition
- Small, single-purpose components. A page-level component orchestrates; child components
  render and emit events ("dumb" children, "smart" parent).
- Communicate down via `@api` properties, up via `CustomEvent`. Avoid pubsub except across
  unrelated DOM trees; prefer Lightning Message Service for cross-DOM.

## Data
- Reads: `@wire` to `getRecord`, `getObjectInfo`, `getPicklistValues`, or an
  `@AuraEnabled(cacheable=true)` Apex method. Wire gives caching + reactivity.
- Writes: imperative call to a non-cacheable Apex method, then refresh (`refreshApex` or
  `notifyRecordUpdateAvailable`).
- Never put SOQL / DML decisions in JS. Handle `{ data, error }` for every wire.

## UX
- Always render loading (`lightning-spinner`) and error states.
- Normalize errors with a shared `reduceErrors` util; show via `ShowToastEvent` or inline.
- SLDS + base components; no inline styles; responsive via SLDS grid.
- Accessibility: labels on inputs, semantic elements, keyboard operable, `aria-*` where
  needed.

## Metadata
- `js-meta.xml`: expose only the targets actually used; document `@api` props with
  `<targetConfig>` where relevant.

## Testing
- Jest under `__tests__/`. Mock Apex and wire adapters (`@salesforce/sfdx-lwc-jest`).
- Assert DOM output for each state (loading / data / error) and that events fire with the
  right `detail`.
