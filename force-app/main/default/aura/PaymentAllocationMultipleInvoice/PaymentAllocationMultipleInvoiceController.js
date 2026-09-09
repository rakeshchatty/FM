({
	init : function(component, event, helper)
    {
		component.set("v.availableAmount", component.get("v.paymentAmount"));
	},
    
    
    
  // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper)
    {
    // get the selected Account record from the COMPONETN event
        var selectedInvocie = document.getElementsByClassName("selected");
        if (selectedInvocie.length > 0)
        {
            selectedInvocie[0].classList.toggle("selected");
        }
        var selectedInvoiceGetFromEvent = event.getParam("recordByEvent");
        document.getElementById(selectedInvoiceGetFromEvent.Id).classList.toggle("selected");
        component.set("v.selectedInvoice" , selectedInvoiceGetFromEvent);
      
	},
    addInvoice : function(component, event, helper)
    {
        var selInvoices = component.get("v.selectedInvoices");
        var avalInvoices = component.get("v.availableInvoices");
        var selectedInv = component.get("v.selectedInvoice");
        if(selectedInv != undefined){
            for( var i = 0; i < avalInvoices.length; i++){
                if ( avalInvoices[i].InvoiceNo__c === component.get("v.selectedInvoice").InvoiceNo__c) {
                    if(component.get("v.selectedInvoice").AmountOutstanding__c > component.get("v.availableAmount"))
                    {
                        alert('You cannot pay this invoice. Invoice Outstanding is greater than the available amount.');
                        component.set("v.selectedInvoice", null);
                        return;
                    }
                    avalInvoices.splice(i, 1); 
                    selInvoices.push(selectedInv);
                    avalInvoices.sort(function(invA, invB)
                                      {  
                                          if (invA.InvoiceNo__c < invB.InvoiceNo__c) {
                                              return -1;
                                          }
                                          if (invA.InvoiceNo__c > invB.InvoiceNo__c) {
                                              return 1;
                                          }
                                          // a deve ser igual a b
                                          return 0;
                                      });
                    selInvoices.sort(function(invA, invB)
                                     {  
                                         if (invA.InvoiceNo__c < invB.InvoiceNo__c) {
                                             return -1;
                                         }
                                         if (invA.InvoiceNo__c > invB.InvoiceNo__c) {
                                             return 1;
                                         }
                                         // a deve ser igual a b
                                         return 0;
                                     });
                    component.set("v.availableInvoices", avalInvoices);
                    component.set("v.selectedInvoices", selInvoices);
                    component.set("v.selectedInvoice", null);
                    component.set("v.availableAmount", component.get("v.availableAmount") - selectedInv.AmountOutstanding__c);
                    break;
                }
            }
        }else{
            alert('Please select a valid Invoice Header if you want to continue.');
        }
	},
    
    removeInvoice : function(component, event, helper)
    {
        var selInvoices = component.get("v.selectedInvoices");
        var avalInvoices = component.get("v.availableInvoices");
        var selectedInv = component.get("v.selectedInvoice");
        for( var i = 0; i < selInvoices.length; i++){ 
            if ( selInvoices[i].InvoiceNo__c === selectedInv.InvoiceNo__c) {
                selInvoices.splice(i, 1);
                avalInvoices.push(selectedInv);
                avalInvoices.sort(function(invA, invB)
                                  {  
                                      if (invA.InvoiceNo__c < invB.InvoiceNo__c) {
                                          return -1;
                                      }
                                      if (invA.InvoiceNo__c > invB.InvoiceNo__c) {
                                          return 1;
                                      }
                                      // a deve ser igual a b
                                      return 0;
                                  });
                selInvoices.sort(function(invA, invB)
                                            {  
                                                  if (invA.InvoiceNo__c < invB.InvoiceNo__c) {
                                                    return -1;
                                                  }
                                                  if (invA.InvoiceNo__c > invB.InvoiceNo__c) {
                                                    return 1;
                                                  }
                                                  // a deve ser igual a b
                                                  return 0;
                                            });
                component.set("v.selectedInvoices", selInvoices);
                component.set("v.availableInvoices", avalInvoices);
                component.set("v.selectedInvoice", null);
                component.set("v.availableAmount", component.get("v.availableAmount") + selectedInv.AmountOutstanding__c);
                break;
            }
        }
	},
})