({
	searchHelper : function(component,event,getInputkeyWord) {
	  // call the apex class method 
     var action = component.get("c.fetchLookUpValues");
      // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName' : component.get("v.objectAPIName"),
            'RecordId' : component.get("v.selectedRecordId"),
            'selectedRecordToDelete' : component.get("v.selectedRecordToDelete")
          });
      // set a callBack    
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
              // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
 
        });
      // enqueue the Action  
        $A.enqueueAction(action);
    
	},
    
    handleOnChangeHelper : function(component,event,helper){
        var action = component.get("c.updateCases");
        // set param to method  
        action.setParams({
            'selectedRecordToDelete' : component.get("v.selectedRecordToDelete"),
            'selectedRecord' : component.get("v.selectedRecord.Id")
        });
        // set a callBack    
        action.setCallback(this, function(response) {   
            var state = response.getState();
            if(state == "SUCCESS" && component.isValid()) {
                $A.get("e.force:refreshView").fire();
                $A.get("e.force:closeQuickAction").fire();
                var navEvent = $A.get("e.force:navigateToSObject");
                navEvent.setParams({
                    recordId: component.get("v.selectedRecord").Id,
                    slideDevName: "detail"
                });
                navEvent.fire();
            }  
        });
        // enqueue the Action  
        $A.enqueueAction(action);
        
    },
})