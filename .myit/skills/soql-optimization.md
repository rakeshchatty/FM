# Skill: SOQL & Query Optimization

## Bulk safety
- Never query inside a loop. Collect keys into a `Set<Id>` / `Set<String>` and run one
  query with `WHERE Field IN :keys`.
- Build `Map<Id, SObject>` (or `Map<Key, List<SObject>>`) from the result for O(1) lookups.

## Selectivity (avoid full scans / non-selective query errors)
- Filter on indexed fields: `Id`, `Name`, `CreatedDate`, `SystemModstamp`, external ids,
  lookups / master-detail, and custom fields marked `unique` / `externalId`.
- Avoid leading `%` in `LIKE`, negative filters (`!=`, `NOT IN`, `<>`), and filtering on
  formula fields.
- Keep result sets under the 50k-row governor; use `Database.getQueryLocator` for batch.

## Projection & governors
- Select only the fields you use — wide `SELECT` inflates heap.
- Use aggregate queries (`COUNT()`, `GROUP BY`) instead of loading rows to count.
- Prefer relationship queries (`SELECT Id, (SELECT Id FROM Contacts) FROM Account`) over
  N+1 child queries.

## Security
- `WITH USER_MODE` (API 60+) or `WITH SECURITY_ENFORCED` on user-facing queries.
- Dynamic SOQL: bind variables only; never concatenate raw input
  (`String.escapeSingleQuotes` as a fallback for identifiers).

## Where queries belong
- In **selector classes**, not scattered through handlers / services. One method = one
  query shape, parameterized by collections.
