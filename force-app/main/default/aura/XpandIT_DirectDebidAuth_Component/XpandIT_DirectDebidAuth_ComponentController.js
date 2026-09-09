({
	doInit : function(component, event, helper) {
		var action = component.get("c.getAuthorizedAccounts");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var accAmountList = response.getReturnValue();
                component.set("v.authorizedAccountList", accAmountList);   
            }
		});
		$A.enqueueAction(action);
	},
    
    Close: function(cmp){
        var ComponentEvent = cmp.getEvent("ComponentEvent2");
        ComponentEvent.setParam("close", "CLOSEONLYCONF");
        ComponentEvent.fire();
    },
    
    authorizeAccounts: function(component, event, helper) {
        component.set("v.ModalIsOpen", true);
        
        /*action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                alert(response.getReturnValue());
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action)     */   
    },
    
    confirmAuthorizationprosse : function(component, event, helper)
    {
        component.find("modalConfirmBtn").set('v.disabled',true);
        component.find("modalCancelBtn").set('v.disabled',true);
        
        var action = component.get("c.generateCSV");
        //$A.util.toggleClass(component.find('spinner'),'slds-hide');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //$A.util.toggleClass(component.find('spinner'),'slds-hide');
                alert(response.getReturnValue());
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                //$A.util.toggleClass(component.find('spinner'),'slds-hide');
                alert('We had a problem saving the Credit Note.\nPlease try again.\n\nIf problem persists contact your system administrator.');
            }
        });
        $A.enqueueAction(action);
    },
    closeModal  : function(component, event, helper)
    {
        component.set("v.ModalIsOpen", false);
    },
})