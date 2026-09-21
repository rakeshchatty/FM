// CRMFM-2: post-deployment data fix.
// Run once via `sf apex run --file manifest/CRMFM-2-datafix-discount-to-apply.apex --target-org <alias>`
// AFTER the RestrictDiscountToApply validation rule update has been deployed.
// Sets Discount_to_Apply__c = 'Account' on existing Recurrings__c records where both
// ManualPrice__c and Discount_to_Apply__c are blank, so they satisfy the merged
// RestrictDiscountToApply validation rule going forward. Idempotent - re-running finds
// zero matching records once fixed.

List<Recurrings__c> toFix = [
    SELECT Id, Discount_to_Apply__c, ManualPrice__c
    FROM Recurrings__c
    WHERE ManualPrice__c = null AND Discount_to_Apply__c = null
];

for (Recurrings__c r : toFix) {
    r.Discount_to_Apply__c = 'Account';
}

if (!toFix.isEmpty()) {
    update toFix;
}

System.debug('CRMFM-2 data fix: updated ' + toFix.size() + ' Recurrings__c records.');
