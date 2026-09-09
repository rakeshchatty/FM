/** 
(c) 2018 Nexell GmbH / Rolling-Space
Developed by Nexell GmbH, Zug (Switzerland) / Rolling-Space, Braga (Portugal)
@date Date of creation mm.yyyy 
@author Name of initial developer 

@description Initial PT or Case number + description of what the class does 

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields 
*/
trigger OnPaymentAllocation on PaymentAllocation__c (before insert, after insert, before update, after update, before delete) {
    OnPaymentAllocationHelper.entry(
                        Trigger.operationType,
                        Trigger.new,
                        Trigger.newMap,
                        Trigger.old,
                        Trigger.oldMap
                        ); 
}