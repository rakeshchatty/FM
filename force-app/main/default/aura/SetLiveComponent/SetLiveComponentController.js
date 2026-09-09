({
	setLive: function(component, event, helper) {
		var record = component.get("v.recordId");
		helper.setLiveHelper(component, record);
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