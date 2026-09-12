trigger OnInvoiceLine on Invoice_Line__c (after insert) {
    OnInvoiceLineHelper.entry(
                        Trigger.operationType,
                        Trigger.new,
                        Trigger.newMap,
                        Trigger.old,
                        Trigger.oldMap
                        ); 
}