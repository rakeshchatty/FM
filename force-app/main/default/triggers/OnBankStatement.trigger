trigger OnBankStatement on Bank_Statement__c (after insert, after update, after delete, before delete, before insert) {
    OnBankStatementHelper.entry(
                        Trigger.operationType,
                        Trigger.new,
                        Trigger.newMap,
                        Trigger.old,
                        Trigger.oldMap
                        );  
}