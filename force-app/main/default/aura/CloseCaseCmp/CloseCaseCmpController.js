({
	
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId"); 
        console.log("dynamic Id::"+recordId);
        var action = component.get("c.RetreiveCase");
        action.setParams({"caseId": recordId});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                var c = response.getReturnValue();
                component.set("v.record", c);
                window.setTimeout(
                    $A.getCallback(function () {
                        var button = component.find("mybtn");
                        if(c.Status == "New" || c.Status == "Active"){
                            button.set("v.label","Close Case");
                        }else if(c.Status == "Closed"){
                            button.set("v.label","Already Closed");
                        }else {
                            button.set("v.label","Withdraw Case");
                        }

                    })
                );

            } else {
                console.log('There was a problem : ',response.getError());
            }
        });
        $A.enqueueAction(action);

    },

closeCase : function (component, event, helper) {
    
     var action = component.get("c.saveCase");
    var recId = component.get("v.record");
        action.setParams({"caseA": recId});
    console.log('check this one::',recId);

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                var c = response.getReturnValue();
                component.set("v.case", c);
                
                location.reload();
                //$A.get('e.force:refreshView').fire();
            } else {
                console.log('There was a problem : ',response.getError());
            }
        });
        $A.enqueueAction(action);
}
})