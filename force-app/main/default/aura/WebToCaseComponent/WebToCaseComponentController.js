({
    //initailize values and set picklist values
    doInit: function(component, event, helper) {
        component.set('v.description','');
        component.set('v.webName','');
        component.set('v.webEmail','');
        component.set('v.fileName','');
       var action = component.get("c.getSelectedType");
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS"){
                var result = a.getReturnValue();
                var industryMap = [];
                for(var key in result){
                    if(result[key] =='Order'){
                    industryMap.push({key: key, value:'Place an Order'});
                    }else if(result[key] =='General'){
                    industryMap.push({key: key, value:'Make A Complaint/Report a Missed Collection'});
                    }else if(result[key] =='General'){
                    industryMap.push({key: key, value:'Received a Council Fine'});
                    }else if(result[key] =='Invoice Query'){
                    industryMap.push({key: key, value:'There’s a problem with my invoice'});
                    }else if(result[key] =='New Quote or Location'){
                    industryMap.push({key: key, value:'Request a Clearance'});
                    }/*else{
                        industryMap.push({key: key, value: result[key]});
                    }*///[PS 30/06]commented else block to show only limited values
                }
                component.set('v.picklistMap',a.getReturnValue());//new code
                component.set('v.TypePicklist', industryMap);
                 var pickMap=a.getReturnValue();
                var val=pickMap[industryMap[0].key];
        		component.set('v.Type',val);
            } 
        });
        $A.enqueueAction(action);
    },
    //create case with or without attachment
    handleCreateCase: function(component, event, helper) {
        helper.showSpinner(component);//new code
        console.log(component.find("fuploader").get("v.files"));
        if (component.find("fuploader").get("v.files") !=null && component.find("fuploader").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {            
            helper.saveCase(component, event,helper);
        }
    },
    handleCancel : function(component, event, helper) {
        component.set('v.hidepopup',true);
        $A.get("e.force:closeQuickAction").fire();
    },
    onPicklistChange: function(component, event, helper) {
        //get the value of select option
        var pickListvalues=component.get('v.picklistMap');//new code
        var indexV=component.find("selectType").get("v.value");
        component.set('v.Type',pickListvalues[indexV]);//new code
    },
    closeModal:function(component,event,helper){    
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open'); 
    },
    openModalPopup : function(component, event, helper) {
        component.set('v.hidepopup',false);
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open'); 
     },
  
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
   
    
    
})