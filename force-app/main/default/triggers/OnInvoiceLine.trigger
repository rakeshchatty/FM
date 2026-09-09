trigger OnInvoiceLine on Invoice_Line__c (after insert, after update, before delete) {
    OnInvoiceLineHelper.entry(
                        Trigger.operationType,
                        Trigger.new,
                        Trigger.newMap,
                        Trigger.old,
                        Trigger.oldMap
                        ); 
}