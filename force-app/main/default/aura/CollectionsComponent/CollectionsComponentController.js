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
			for(var i=0 ; records.length > i; i++){
				if(records[i].Collections__r) {
					for(var j=0 ; records[i].Collections__r.length > j; j++){
						if(records[i].Collections__r[j].Days__c == 'Monday') records[i].MondayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Tuesday') records[i].TuesdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Wednesday') records[i].WednesdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Thursday') records[i].ThursdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Friday') records[i].FridayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Saturday') records[i].SaturdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Sunday') records[i].SundayURL = records[i].Collections__r[j].Id;
						
					}
				} 
			}
            /*for (var i = 0; records.length > i; i++) {
				for (var j = 0; records.length > j; j++) {
					if (records[i].Id != records[j].Id && records[i].Supplier_Product__c == records[j].Supplier_Product__c && 
						records[i].Quantity__c == records[j].Quantity__c) {
                        if (records[i].Monday__c != null && records[j].Monday__c != null) records[i].Monday__c += '<br>'+records[j].Monday__c;
                        else if (records[i].Monday__c == null && records[j].Monday__c != null) records[i].Monday__c = '<br>'+records[j].Monday__c;
						if (records[i].Tuesday__c != null && records[j].Tuesday__c != null) records[i].Tuesday__c += '<br>'+records[j].Tuesday__c;
                        else if (records[i].Tuesday__c == null && records[j].Tuesday__c != null) records[i].Tuesday__c = '<br>'+records[j].Tuesday__c;
                        if (records[i].Wednesday__c != null && records[j].Wednesday__c != null) records[i].Wednesday__c += '<br>'+records[j].Wednesday__c;
                        else if (records[i].Wednesday__c == null && records[j].Wednesday__c != null) records[i].Wednesday__c = '<br>'+records[j].Wednesday__c;
                        if (records[i].Thursday__c != null && records[j].Thursday__c != null) records[i].Thursday__c += '<br>'+records[j].Thursday__c;
                        else if (records[i].Thursday__c == null && records[j].Thursday__c != null) records[i].Thursday__c = '<br>'+records[j].Thursday__c;
                        if (records[i].Friday__c != null && records[j].Friday__c != null) records[i].Friday__c += '<br>'+records[j].Friday__c;
                        else if (records[i].Friday__c == null && records[j].Friday__c != null) records[i].Friday__c = '<br>'+records[j].Friday__c;
                        if (records[i].Saturday__c != null && records[j].Saturday__c != null) records[i].Saturday__c += '<br>'+records[j].Saturday__c;
                        else if (records[i].Saturday__c == null && records[j].Saturday__c != null) records[i].Saturday__c = '<br>'+records[j].Saturday__c;
                        if (records[i].Sunday__c != null && records[j].Sunday__c != null) records[i].Sunday__c += '<br>'+records[j].Sunday__c;
                        else if (records[i].Sunday__c == null && records[j].Sunday__c != null) records[i].Sunday__c = '<br>'+records[j].Sunday__c;
						records.splice(j, 1);
					}
				}
			}
            debugger;*/
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
			for(var i=0 ; records.length > i; i++){
				if(records[i].Collections__r) {
					for(var j=0 ; records[i].Collections__r.length > j; j++){
						if(records[i].Collections__r[j].Days__c == 'Monday') records[i].MondayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Tuesday') records[i].TuesdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Wednesday') records[i].WednesdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Thursday') records[i].ThursdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Friday') records[i].FridayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Saturday') records[i].SaturdayURL = records[i].Collections__r[j].Id;
						if(records[i].Collections__r[j].Days__c == 'Sunday') records[i].SundayURL = records[i].Collections__r[j].Id;
					}
				} 
			}
			/*for (var i = 0; records.length > i; i++) {
				for (var j = 0; records.length > j; j++) {
					if (records[i].Id != records[j].Id && records[i].Supplier_Product__c == records[j].Supplier_Product__c && 
						records[i].Quantity__c == records[j].Quantity__c) {
                        if (records[i].Monday__c != null && records[j].Monday__c != null) records[i].Monday__c += '<br>'+records[j].Monday__c;
                        else if (records[i].Monday__c == null && records[j].Monday__c != null) records[i].Monday__c = '<br>'+records[j].Monday__c;
						if (records[i].Tuesday__c != null && records[j].Tuesday__c != null) records[i].Tuesday__c += '<br>'+records[j].Tuesday__c;
                        else if (records[i].Tuesday__c == null && records[j].Tuesday__c != null) records[i].Tuesday__c = '<br>'+records[j].Tuesday__c;
                        if (records[i].Wednesday__c != null && records[j].Wednesday__c != null) records[i].Wednesday__c += '<br>'+records[j].Wednesday__c;
                        else if (records[i].Wednesday__c == null && records[j].Wednesday__c != null) records[i].Wednesday__c = '<br>'+records[j].Wednesday__c;
                        if (records[i].Thursday__c != null && records[j].Thursday__c != null) records[i].Thursday__c += '<br>'+records[j].Thursday__c;
                        else if (records[i].Thursday__c == null && records[j].Thursday__c != null) records[i].Thursday__c = '<br>'+records[j].Thursday__c;
                        if (records[i].Friday__c != null && records[j].Friday__c != null) records[i].Friday__c += '<br>'+records[j].Friday__c;
                        else if (records[i].Friday__c == null && records[j].Friday__c != null) records[i].Friday__c = '<br>'+records[j].Friday__c;
                        if (records[i].Saturday__c != null && records[j].Saturday__c != null) records[i].Saturday__c += '<br>'+records[j].Saturday__c;
                        else if (records[i].Saturday__c == null && records[j].Saturday__c != null) records[i].Saturday__c = '<br>'+records[j].Saturday__c;
                        if (records[i].Sunday__c != null && records[j].Sunday__c != null) records[i].Sunday__c += '<br>'+records[j].Sunday__c;
                        else if (records[i].Sunday__c == null && records[j].Sunday__c != null) records[i].Sunday__c = '<br>'+records[j].Sunday__c;
						records.splice(j, 1);
					}
				}
			}
            debugger;*/
			component.set("v.allCollections", records);
            
		});
		
		$A.enqueueAction(action);
	},

	deleteAll: function (component, event) {
		debugger;
		var record = component.get("v.recordId");
		var action = component.get("c.deleteAllCollections");
		action.setParams({
			'recordId' : record
		});
		action.setCallback(this, function(response) {
			$A.get('e.force:refreshView').fire();
			var action2 = component.get("c.doInit");
			$A.enqueueAction(action2);
		});
		if(confirm('Are you sure?')) {
			$A.enqueueAction(action);
		}
	},

	openModal : function(component, event) {
		var windowHash = window.location.hash;
		var record = component.get("v.recordId");
		var createRecordEvent = $A.get("e.force:createRecord");
		createRecordEvent.setParams({
			"entityApiName": "Schedule__c",
			"defaultFieldValues": {
				'Location__c': record
			},
			"panelOnDestroyCallback": function(event) {
				window.location.hash = windowHash;
			}
		});
		createRecordEvent.fire();
	},

	navigateToRelatedList : function (component, event, helper) {
		var relatedListEvent = $A.get("e.force:navigateToRelatedList");
		relatedListEvent.setParams({
			"relatedListId": "Collections__r",
			"parentRecordId": component.get("v.recordId")
		});
		relatedListEvent.fire();
	}
})