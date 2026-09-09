({
    doInit : function(component, event, helper)
    {   
        var quantID = 'quant'+'v.rowIndex';
        alert(quantID);
        //var maxQuant = component.get("v.ordProdInstance.Quantity__c");
        //comp.max = maxQuant;
        //component.set("v.maxQuantity", maxQuant);
    },
    
    removeRow : function (component, event, helper)
    {
		component.getEvent("XpandIT_CreditNoteDeleteLine_Event").setParams({"indexVar" : component.get("v.rowIndex") }).fire();
	}
})