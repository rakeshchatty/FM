({
    handleClick : function (cmp, event, helper) {
       if(event.getSource().get("v.label") === 'Confirm')
       {
           cmp.set("v.isOpen", true);
       }
       else if(event.getSource().get("v.title") === 'Cancel')
       {
           $A.get("e.force:closeQuickAction").fire();
       } else if (event.getSource().get("v.title") === 'Cancel popup') {
           cmp.set("v.isOpen", false);
       }
        
    },
    
    
    switchBetweenScreens: function(component, event, helper) {
        debugger;
        if (component.get("v.isLONInvoice") )
        {
            component.set("v.isLONInvoice", false);
        	var locationID = component.find("locationsDropdown").get("v.value");
            //Get orders for the selected location
            var action = component.get("c.getLocationsOrders");
            action.setParams({
                "invoiceID": component.get("v.invoiceId"),
                "locationID": locationID
            });
            // Register the callback function 
            action.setCallback(this, function(response) {
                component.set("v.orders", response.getReturnValue());
            });
            $A.enqueueAction(action);
            component.set("v.amount", '');
            component.set("v.creditNoteDescription", '');
        }
        else
        {
            component.set("v.isLONInvoice", true);
            component.set("v.orders", {});
            component.set("v.orderProds", {});
            component.set("v.creditNoteDescription", '');
        	
    	}
        setTimeout(function(){
            document.getElementById("Accspinner").style.display = "none";
        }, 150); 
    },
    
    removeDeletedRow: function(component, event, helper) {
        // get the selected row Index for delete, from Lightning Event Attribute  
        var index = event.getParam("indexVar"); 
        var AllRowsList = component.get("v.orderProds");
        AllRowsList.splice(index, 1); 
        component.set("v.orderProds", AllRowsList);
    },
    
	doInit : function(component, event, helper) {
        component.set("v.invoiceId", component.get("v.recordId"));
        var isLONInvoice = false;
        var isPerOrderInvoice = true;
        var groupAccountID = '';

        //Get Invoice method info
		var action = component.get("c.getInvoiceResumeData");
        action.setParams({
            "invoiceID": component.get("v.invoiceId")
        });
        // Register the callback function
        action.setCallback(this, function(response) {
            var invoiceInfo =  response.getReturnValue().split("/");
            if (invoiceInfo[1] != 'Per Order')
            {
                isPerOrderInvoice = false;
            }
            isLONInvoice = invoiceInfo[2]; 
            if(isLONInvoice == "true")
            {
                component.set("v.isLONInvoice", true);
            }else
            {
                component.set("v.isLONInvoice", false);
            }

            groupAccountID = invoiceInfo[0];
                //Get Locations from account's Invoice
                var action = component.get("c.getAccountsLocations");
                action.setParams({
                    "invoiceID": component.get("v.invoiceId"),
                    "accountID": groupAccountID
                });
                // Register the callback function
                action.setCallback(this, function(response) {
                    if(response.getState() == 'SUCCESS')
                    {
                        var x = response.getReturnValue();
                        component.set("v.locations", response.getReturnValue());
                        if(isPerOrderInvoice === true)
                        {
                            component.set("v.invoicesMethod", invoiceInfo[1]);
                            setTimeout(function(){ 
                                component.find("locationsDropdown").set("v.value", component.get("v.locations")[0].Id);
                                if (isLONInvoice != "true")
                                {
                                    helper.getOrderForLocation(component, event, helper);
                                }
                                else
                                {
                                    document.getElementById("Accspinner").style.display = "none";
                                }
                            }, 150);
                        }
                        else
                        {
                            document.getElementById("Accspinner").style.display = "none";
                            component.set("v.invoicesMethod", invoiceInfo[1]);
                        }
                    }
                    else if (response.getState() === "ERROR")
					{
                     	// Configure error toast
                        let toastParams = {
                            title: "Problems getting invoice's location",
                            message: response.getError()[0].message,
                            duration: 20000,
                            type: "error"
                        };
                        let toastEvent = $A.get("e.force:showToast");
						toastEvent.setParams(toastParams);
						toastEvent.fire();
                    }
                });
                $A.enqueueAction(action);
        });
        $A.enqueueAction(action);
	},
    
    getOrderForLocation : function(component, event, helper){
        var locationID = component.find("locationsDropdown").get("v.value");
        var isLonInvoice = component.get("v.isLONInvoice");
        if (locationID!='' && !isLonInvoice)
        {
            //Get orders for the selected location
            var action = component.get("c.getLocationsOrders");
            action.setParams({
                "invoiceID": component.get("v.invoiceId"),
                "locationID": locationID
            });
            // Register the callback function
            action.setCallback(this, function(response) {
                component.set("v.orders", response.getReturnValue());
            });
            $A.enqueueAction(action);
        }
        else if (locationID == '')
        {
            alert('Please select a location.');
        }
    },
    
    getOrderProds : function(component, event, helper){
        var isLonInvoice =component.get("v.isLONInvoice");
        if (!isLonInvoice)
        {
        	var orderID = component.find("ordersDropdown").get("v.value");
            if (orderID!='')
            {
                //Get Lines
                var action = component.get("c.generateCreditOrder");
                action.setParams({
                    "invoiceID": component.get("v.invoiceId"),
                    "OrderID": orderID
                });
                // Register the callback function
                action.setCallback(this, function(response) {
                    if (response.getReturnValue().length > 0)
                {
                    component.set("v.orderProds", response.getReturnValue());
                }else{
                    alert('The products used on the order selected do not have pricebook entries created on the Pricebook that is placed on the Location being used for this Credit Note'); 
                }
                });
                $A.enqueueAction(action);
            }
            else
            {
                alert('Please select a location.');
            }
        }
    },
    
    confirmNote : function(cmp, event, helper)
    {
        var isLonInvoice = cmp.get("v.isLONInvoice");
        cmp.find("modalConfirmBtn").set('v.disabled',true);
        cmp.find("modalCancelBtn").set('v.disabled',true);
        
        if(!isLonInvoice){
            var genCredOrdAction = cmp.get("c.createCreditOrder");
            var jsonParams = JSON.stringify(cmp.get("v.orderProds"));
            genCredOrdAction.setParams({
                "creditOrdProds": jsonParams,
                "notes": cmp.get("v.creditNoteDescription"),
                "invoiceId": cmp.get("v.invoiceId"),
                "locationID": cmp.find("locationsDropdown").get("v.value"),
                "creditPartner": cmp.get("v.creditPartner")
            });
            // Register the callback function
            genCredOrdAction.setCallback(this, function(response) {
                //cmp.set("v.orderProds", response.getReturnValue());
                var state = response.getState();
                if(cmp.isValid() && state === "SUCCESS")
                {     
                    var result = response.getReturnValue();
                    alert('Credit Note Created: '+result);
                    $A.get("e.force:closeQuickAction").fire()
                }
                else if (response.getState() === "ERROR")
                {
                    cmp.find("modalCancelBtn").set('v.disabled',false);
                    // Configure error toast
                    let toastParams = {
                        title: "Problems creating the credit Order",
                        message: response.getError()[0].message,
                        duration: 20000,
                        type: "error"
                    };
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams(toastParams);
                    toastEvent.fire();
                }
                    else
                    {
                        alert('We had a problem saving the Credit Note.\nPlease try again.\n\nIf problem persists contact your system administrator.');
                    }
            });
            $A.enqueueAction(genCredOrdAction);
            
        } else {
            var genSimpleCredOrdAction = cmp.get("c.createSimpleCreditOrder");
            var amount = cmp.get("v.amount"); 
            genSimpleCredOrdAction.setParams({
                "amount": amount,
                "notes": cmp.get("v.creditNoteDescription"),
                "invoiceId": cmp.get("v.invoiceId"),
                "locationID": cmp.find("locationsDropdown").get("v.value")
            });
            // Register the callback function
            genSimpleCredOrdAction.setCallback(this, function(response) {
                //cmp.set("v.orderProds", response.getReturnValue());
                var state = response.getState();
                if(cmp.isValid() && state === "SUCCESS")
                {     
                    var result = response.getReturnValue();
                    alert('Credit Note Created: '+result);
                    $A.get("e.force:closeQuickAction").fire()
                }
                else if (response.getState() === "ERROR")
                {
                    cmp.find("modalCancelBtn").set('v.disabled',false);
                    // Configure error toast
                    let toastParams = {
                        title: "Problems creating the credit Order",
                        message: response.getError()[0].message,
                        duration: 20000,
                        type: "error"
                    };
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams(toastParams);
                    toastEvent.fire();
                }
                    else
                    {
                        alert('We had a problem saving the Credit Note.\nPlease try again.\n\nIf problem persists contact your system administrator.');
                    }
            });
            $A.enqueueAction(genSimpleCredOrdAction);
        }
    },
    onChange: function(component, event, helper) {
        helper.handleChange(component);
    }
})