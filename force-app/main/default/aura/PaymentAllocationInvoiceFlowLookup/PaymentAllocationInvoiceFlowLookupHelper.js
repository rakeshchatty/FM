({
	searchHelper : function(component,event,getInputkeyWord) {
        
        if( getInputkeyWord.length > 0 )
        {
            component.set("v.FilteredInvoices", {});
            var availableInvoices = component.get("v.AvailableInvoices");
            var matchInvoices = new Array();
            availableInvoices.forEach(function(element) {
                if(element.InvoiceNo__c.includes(getInputkeyWord))
                {
                    matchInvoices.push(element);
                }
            });
        	component.set("v.FilteredInvoices", matchInvoices);
        }
        else
        {
        	component.set("v.FilteredInvoices", component.get("v.AvailableInvoices"));
        }    
	},
})