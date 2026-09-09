({
    SearchHelper: function(component, event) {
        component.set("v.showLoading", true);
        var action = component.get("c.fetchAccount");
        action.setParams({
            'searchKeyWord': component.get("v.searchKeyword"),
            'fieldName': component.get("v.fieldName"),
            'fieldFilterValue': component.get("v.fieldFilterValue")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is 0 ,display no record found message on screen.
                if (storeResponse.length == 0) {
                    component.set("v.Message", true);
                } else {
                    component.set("v.Message", false);
                }
                // set numberOfRecord attribute value with length of return value from server
                component.set("v.numberOfRecord", storeResponse.length);
                // set searchResult list with return value from server.
                component.set("v.searchResult", storeResponse);
                component.set("v.showLoading", false);
            }
 
        });
        $A.enqueueAction(action);
 
    },
    fetchPickListVal: function(component, elementId) {
        var action = component.get("c.fetchFieldOptions");
        
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
 
                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
                Object.keys(allValues).forEach(function(key) {
                    opts.push({
                        class: "optionClass",
                        label: key,
                        value: allValues[key]
                    });
                });
                component.find(elementId).set("v.options", opts);
            }
        });
        $A.enqueueAction(action);
    },
    fetchFieldFilterVal: function(component, elementId) {
        var action = component.get("c.fetchFieldFilterOptions");
        
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
 
                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
                Object.keys(allValues).forEach(function(key) {
                    opts.push({
                        class: "optionClass",
                        label: key,
                        value: allValues[key]
                    });
                });
                component.find(elementId).set("v.options", opts);
            }
        });
        $A.enqueueAction(action);
    },
})