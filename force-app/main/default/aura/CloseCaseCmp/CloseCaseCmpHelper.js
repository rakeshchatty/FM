({
	getStatusPickListValue : function(component) {

        var action = component.get("c.getCaseStausPickList");
        action.setCallback(this, function(response) {
            var state = response.getState();
            var hasImg = false;
            if (component.isValid() && state === "SUCCESS") {

                var statusPickList = response.getReturnValue();
                component.set("v.lstCaseStatus", statusPickList);

                console.log('status picklist ::', component.get("v.lstCaseStatus"));
            }
        });
        $A.enqueueAction(action);

    }
})