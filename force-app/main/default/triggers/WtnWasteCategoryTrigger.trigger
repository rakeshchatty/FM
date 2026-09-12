trigger WtnWasteCategoryTrigger on WTN_Waste_Category__c (after insert) {

	new WtnWasteCategoryTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}