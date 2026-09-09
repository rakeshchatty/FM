# Skill: Salesforce Security Review

Run this checklist on any Apex / LWC / metadata change before it ships.

## CRUD / FLS
- [ ] Queries use `WITH USER_MODE` or `WITH SECURITY_ENFORCED`.
- [ ] DML on user-influenced data preceded by `Security.stripInaccessible(...)` or explicit
      `Schema.sObjectType.X.isCreateable / isUpdateable / isDeletable`.
- [ ] `Database` methods use `AccessLevel.USER_MODE` where available.

## Injection
- [ ] No string concatenation of user input into SOQL / SOSL / dynamic Apex.
- [ ] Bind variables used; `String.escapeSingleQuotes` only as a fallback for identifiers.
- [ ] No `Database.query` on unvalidated field / object names from the client.

## Sharing
- [ ] Classes declare `with sharing` (or `inherited sharing` with justification).
- [ ] `without sharing` only in a narrowly-scoped helper with a comment explaining why.

## Secrets & config
- [ ] No hardcoded endpoints, API keys, tokens, passwords, or org ids.
- [ ] Secrets come from Named Credentials / Custom Metadata / Protected Custom Settings.
- [ ] Nothing logs PII or secrets via `System.debug`.

## LWC
- [ ] `@AuraEnabled` methods are minimal and re-check access server-side (client checks are
      not security).
- [ ] No `lwc:dom="manual"` injecting unsanitized HTML; no `eval`.
- [ ] External URLs validated; `target="_blank"` uses `rel="noopener"`.

## Output
Report `severity | location | issue | fix`. Block merge on any High.
