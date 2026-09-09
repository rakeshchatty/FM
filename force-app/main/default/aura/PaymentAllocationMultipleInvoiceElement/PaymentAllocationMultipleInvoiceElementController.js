({
    init : function (component, event, helper)
    {
        debugger;
        var id = component.get("v.invoice.Id");
        if (component.get("v.isNotSelected") && component.get("v.amount") < component.get("v.invoice.AmountOutstanding__c"))
        {
            component.set("v.exceedsAmount", 'exceedsAmount slds-listbox__item');
            //$A.util.addClass(component.find(id), 'exceedsAmount');
        }
        else
        {
            component.set("v.exceedsAmount", 'slds-listbox__item');
        	//$A.util.removeClass(component.find(id), 'exceedsAmount');
        }
    },
    
	selectRecord : function(component, event, helper)
    {      
        // get the selected record from list  
        var getSelectRecord = component.get("v.invoice");
        
        // call the event   
        var compEvent = component.getEvent("PaymentAllocationMultipleInvoiceEvent");
        
        // set the Selected sObject Record to the event attribute.  
        compEvent.setParams({"recordByEvent" : getSelectRecord });
        
        // fire the event  
        compEvent.fire();
    },
})