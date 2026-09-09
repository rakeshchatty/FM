({    
      handleSuccess : function(cmp, event, helper) {
           cmp.find('notifLib').showToast({
            "variant": "success",
            "title": "Case Created",
            "message": "Record ID: " + event.getParam("id")
        });
    },
    handleSave: function(component, event, helper) {
        if (component.find("fuploader").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
    },
     
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
     
    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})