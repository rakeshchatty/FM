({

	getParentLocationName: function(component, record) {
		var action = component.get("c.getParentLocName");
		action.setParams({
			"recordId": record
		});
		action.setCallback(this, function(response) {
			debugger;
			if (response.getState() === "SUCCESS") {
				var fields = response.getReturnValue();
				component.set("v.accountFields", fields);
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
	},

	createLocationHelper : function(component, record, accFields) {
		debugger;
		var action = component.get("c.createLocationController");
		action.setParams({
			"recordId": record,
			"fields": accFields
		});
		action.setCallback(this, function(response) {
			debugger;
			if (response.getState() === "SUCCESS") {
				var recordToRedirect = response.getReturnValue();
				var redirectEvent = $A.get("e.force:navigateToSObject");
				redirectEvent.setParams({
				"recordId": recordToRedirect,
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
	},

	createLocationWithFieldsHelper: function(component, record, accFields) {
		debugger;
		var action = component.get("c.createLocationWithFields");
		action.setParams({
			"recordId": record,
			"fields": accFields
		});
		action.setCallback(this, function(response) {
			debugger;
			if (response.getState() === "SUCCESS") {
				var recordToRedirect = response.getReturnValue();
				var redirectEvent = $A.get("e.force:navigateToSObject");
				redirectEvent.setParams({
				"recordId": recordToRedirect,
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