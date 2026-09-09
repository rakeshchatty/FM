({
	getOrderForLocation : function(component, event, helper){
        
        var locationID = component.find("locationsDropdown").get("v.value");
        if (locationID!='')
        {
            //Get orders for the selected location
            var action = component.get("c.getLocationsOrders");
            action.setParams({
                "invoiceID": component.get("v.invoiceId"),
                "locationID": locationID
            });
            // Register the callback function
            action.setCallback(this, function(response) {
                if (response.getReturnValue().length == 0)
                {
                    helper.cleanInputFields(component, event, helper);
                    component.set("v.isLONInvoice", true);
                    setTimeout(function(){ 
                    	document.getElementById("Accspinner").style.display = "none";
                    }, 100); 
                    return;

                }
                else
                {
                    component.set("v.orders", response.getReturnValue());
                    setTimeout(function(){ 
                        component.find("ordersDropdown").set("v.value", component.get("v.orders")[0].Id);
                        helper.getOrderProds(component, event, helper);
                    }, 150);
                }
            });
            $A.enqueueAction(action);
        }
        else
        {
            alert('Please select a location.');
        }
	},
    
    getOrderProds : function(component, event, helper){
        var orderID = component.find("ordersDropdown").get("v.value");
        if (orderID!='')
        {
            //Get Lines for per order invoices
            var action = component.get("c.generateCreditOrder");
            action.setParams({
                "invoiceID": component.get("v.invoiceId"),
                "OrderID": orderID
            });
            // Register the callback function
            action.setCallback(this, function(response) {
                    component.set("v.orderProds", response.getReturnValue());
                    document.getElementById("Accspinner").style.display = "none";
            });
            $A.enqueueAction(action);
        }
        else
        {
            alert('Please select a location.');
        }
    },
    
    cleanInputFields : function(component, event, helper){
    	 component.set("v.orders", null);
	},
    
     handleChange: function(component) {
        if(component.get('v.creditPartner') == false) {
            component.set('v.creditPartner', true);
        } else {
            component.set('v.creditPartner', false);
        }
    },
})