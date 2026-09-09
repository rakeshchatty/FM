({

	doInit: function(component, event, helper) {
		var record = component.get("v.recordId");
		helper.getParentLocationName(component, record);
	},

	createLocation: function(component, event, helper) {
		var record = component.get("v.recordId");
		var accFields = component.get("v.accountFields");
		helper.createLocationHelper(component, record, accFields);
		/*var spinner = component.find("mySpinner");
		$A.util.toggleClass(spinner, "slds-hide");*/
	},

	createLocationWFields: function(component, event, helper) {
		var record = component.get("v.recordId");
		var accFields = component.get("v.accountFields");
		helper.createLocationWithFieldsHelper(component, record, accFields);
	},
	
	closeModal: function(component, event) {
        // set "isOpen" attribute to false for hide/close model box 
        component.set("v.isOpen", false);
    },
    
    openModal: function(component, event) {
        // set "isOpen" attribute to true to show model box
        component.set("v.isOpen", true);
	},
	
	cancel: function(component, event) {
		$A.get("e.force:closeQuickAction").fire();
	},
	
	showSpinner : function (component, event, helper) {
		component.set("v.spinner", true);
	},

	hideSpinner : function (component, event, helper) {
		component.set("v.spinner", false);
	}
})