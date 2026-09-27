<!--
Traceability
Ticket: CRMFM-6
Artifact: post-deployment-report.md
Purpose: report existing Recurrings__c records that still have neither pricing field populated.
-->

# Post-Deployment Candidate Report

Run this report against the developer sandbox only, after deployment verification. The
query is read-only and does not update or delete records.

## Salesforce CLI

```powershell
sf data query --target-org fm-ai --query "SELECT Id, Name, ManualPrice__c, Discount_to_Apply__c FROM Recurrings__c WHERE ManualPrice__c = null AND Discount_to_Apply__c = null ORDER BY CreatedDate ASC"
```

## SOQL

```sql
SELECT Id, Name, ManualPrice__c, Discount_to_Apply__c
FROM Recurrings__c
WHERE ManualPrice__c = null
AND Discount_to_Apply__c = null
ORDER BY CreatedDate ASC
```

The result is a candidate list for a separately approved data-fix process. This artifact
intentionally performs no mutation.
