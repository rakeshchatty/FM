trigger CaseTrigger on Case (before insert, before update, after update, after insert) {
    
    list <Case> countaminationCases = new list<Case>();
	list <Case> CasesToProcess = new list<Case>();
    
    for(Case c : trigger.new){
        if(Trigger.isAfter){
            if(c.AccountId != null && c.Ops_Issue_Type__c == 'Contamination'){
                countaminationCases.add(c);
            }
        }
        if(trigger.isBefore && trigger.isInsert){   
            CasesToProcess.add(c);
        }
        
        if(trigger.isBefore && trigger.isUpdate){
            if(trigger.oldMap.get(c.Id).Type != c.Type)    
            CasesToProcess.add(c);
        }    
    }
    
    
    CaseTriggerHandler handler = new CaseTriggerHandler();
    if(CasesToProcess.size() > 0){  
    	handler.UpdateCaseRecordType(CasesToProcess);  	
	}
    
    if(countaminationCases.size() > 0){
        handler.UpdateContaminationField(countaminationCases); 
    }
}