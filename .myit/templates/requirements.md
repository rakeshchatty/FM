<!--
Traceability
Ticket: <TICKET-ID>
Artifact: requirements.md
Gate: 1
Status: DRAFT | APPROVED
Last updated: <YYYY-MM-DD>
-->

# Requirements — <TICKET-ID>: <title>

## Problem statement
<The problem in your own words. Why now.>

## Assumptions
- <assumption> — to be confirmed with <who>

## Open questions
- [ ] <question> -> answer:

## Scope
### In scope
- <item>
### Out of scope
- <item>

## Acceptance criteria
1. **Given** <context> **when** <action> **then** <observable outcome>
2. ...

## Non-functional requirements (Salesforce)
- **Objects affected:** <standard / custom>
- **Bulk / volume:** <trigger context, batch size, expected record counts>
- **Governor-limit budget:** SOQL <n>, DML <n>, CPU <ms>, callouts <n>
- **Sharing model:** `with sharing` | `without sharing` (justification: ...)
- **LWC:** <needed? which surfaces?>
- **Integrations:** <Named Credentials / Platform Events / callouts>
- **REST versioning:** <new `_V[N]` class? affects existing version?>
- **Security / compliance:** <PII, FLS, permission sets>

## Story type
- [ ] Code change  [ ] Analysis / spike only

## Sign-off
- Requirements approved by: <name> on <date>
