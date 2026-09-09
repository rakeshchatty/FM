({
    Search: function(component, event, helper) {

        var searchKeyFld = component.find("searchId");
        var selectedFieldFld = component.find("accountFieldOption");
        
        var srcValue = searchKeyFld.get("v.value");
        var selectedFieldValue = selectedFieldFld.get("v.value");
        if (srcValue == '' || srcValue == null || selectedFieldValue == 'NONE' ) {
            if( srcValue == '' || srcValue == null ){
            	// display error message if input value is blank or null
                searchKeyFld.set("v.errors", [{
                    message: "Enter Search Keyword."
                }]);    
            }else{
                searchKeyFld.set("v.errors", null);
            }
            
            if( selectedFieldValue == 'NONE' ){
                selectedFieldFld.set("v.errors", [{
                    message: "Select required field."
                }]);
            }else{
                selectedFieldFld.set("v.errors", null);
            }
            component.set("v.showLoading", false);
            component.set("v.numberOfRecord", 0);
            component.set("v.searchResult", null);
        } else {
            searchKeyFld.set("v.errors", null);
            selectedFieldFld.set("v.errors", null);
            // call helper method
            helper.SearchHelper(component, event);
        }
    },
    
    doInit: function(component, event, helper) {
        helper.fetchPickListVal(component, 'accountFieldOption');
        helper.fetchFieldFilterVal(component, 'accountFieldFilterOption');
        component.set("v.fieldFilterValue", "Equals");
        component.set("v.showLoading", false);
    },
    onPicklistChange: function(component, event, helper) {
        // get the value of select option
       component.set("v.fieldName", event.getSource().get("v.value"));
    },
    onFieldFilterChange: function(component, event, helper) {
        // get the value of select option
        component.set("v.fieldFilterValue", event.getSource().get("v.value"));
    },
    gotoRecord : function(component, event, helper) {
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent.setParams({
            "recordId": component.get("v.contact.Id"),
            "slideDevName": 'related'
        })
        sObjectEvent.fire();
    }
})