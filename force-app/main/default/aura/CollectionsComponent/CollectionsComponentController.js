({
	doRefresh : function(component, event, helper) {
		$A.get('e.force:refreshView').fire();
		
		var record = component.get("v.recordId");
		var action = component.get("c.getCollections");
        action.setParams({
            recordId: record
        })
		action.setCallback(this, function(result){
			var records = result.getReturnValue();
			debugger;

			component.set("v.allCollections", records);
            
		});
		
		$A.enqueueAction(action);
	},

	doInit : function(component, event, helper) {
       
		var record = component.get("v.recordId");
		var action = component.get("c.getCollections");
        action.setParams({
            recordId: record
        })
		action.setCallback(this, function(result){
			var records = result.getReturnValue();

			component.set("v.allCollections", records);
            
		});
		
		$A.enqueueAction(action);
	},
    
    launchFlow : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var navEvt = $A.get("e.force:navigateToURL");
        navEvt.setParams({
            "url": "/flow/ScheduleAddAmendDelete?recordId=" + recordId + "&retURL=/lightning/r/Account/" + recordId + "/view"
        });
        navEvt.fire();
    }
})