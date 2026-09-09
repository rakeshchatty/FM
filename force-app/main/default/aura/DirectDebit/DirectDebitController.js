({
    	doInit : function(component, event, helper) {
            
		var action = component.get("c.fillTable");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var accAmountList = response.getReturnValue();
				//for (var key in accAmountMap) {
					//accAmountList.push({accountName:key, amount:accAmountMap[key]});
				//}
                component.set("v.accAmountList", accAmountList);
                debugger;
                component.set("v.totalSize", component.get("v.accAmountList").length);
                var recordCount = component.get("v.totalSize");
                if (recordCount < 30) {
                    component.set("v.pageSize", recordCount);
                }
                else {
                    component.set("v.pageSize", 30);
                }
                var pageSize = component.get("v.pageSize");
                component.set("v.start",0);
                component.set("v.end",pageSize-1);
                var paginationList = [];
                for(var i=0; i< pageSize; i++)
                {
                    paginationList.push(accAmountList[i]);    
                }
                
                component.set('v.paginationList', paginationList);    
            }
		});
		$A.enqueueAction(action);
	},
    
    Close: function(cmp){
        debugger;
        var ComponentEvent = cmp.getEvent("ComponentEvent2");
        ComponentEvent.setParam("close", "CLOSEONLYCONF");
        ComponentEvent.fire();
    },
    
    OpenChildComponent : function(component, event, helper) {
        var action = component.get("c.createBankStatements");
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "info",
                    "mode": "sticky",
                    "title": 'Success!',
                    "message": response.getReturnValue()
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action)   
    },
    
    closeAction: function(cmp, event){
        var closevar = event.getParam("closeAll");
        if (closevar === 'CLOSEONLYCONF') {
            cmp.set("v.AreYouSure", false);
        }
        else if (closevar === 'CLOSEALL') {
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
        }
    },
    
    next : function(component, event, helper) 
    {
        var accountList = component.get("v.accAmountList");
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        
        var counter = 0;
        for(var i=end+1; i<end+pageSize+1; i++)
        {
            if(accountList.length > end)
            {
                paginationList.push(accountList[i]);
                counter ++ ;
            }
        }
        start = start + counter;
        end = end + counter;
        
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.paginationList', paginationList);
    },
    
    previous : function(component, event, helper) 
    {
        var accountList = component.get("v.accAmountList");
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++)
        {
            if(i > -1)
            {
                paginationList.push(accountList[i]);
                counter ++;
            }
            else
            {
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        
        component.set("v.start",start);
        component.set("v.end",end);
        
        component.set('v.paginationList', paginationList);
    },
    
})