({
	setLiveHelper : function(component, record) {
		var action = component.get("c.setLiveCtrl");
		action.setParams({
			"recordId": record
		});
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				var redirectEvent = $A.get("e.force:navigateToSObject");
				redirectEvent.setParams({
				"recordId": record,
				"slideDevName": "detail"
				});
				redirectEvent.fire();
			}
			else if (response.getState() === "ERROR") {
				var errors = action.getError();
				if (errors) {
					if (errors[0] && errors[0].message) {
						component.set("v.errormsg", errors[0].message);
					}
					else if (errors[0] && errors[0].pageErrors) {
						component.set("v.errormsg", errors[0].pageErrors[0].message);
					}
				}
			}
		});
		$A.enqueueAction(action);
	}
})