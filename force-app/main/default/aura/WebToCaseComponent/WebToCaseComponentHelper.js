({
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    uploadHelper: function(component, event) {
        var fileInput = component.find("fuploader").get("v.files");
        var file = fileInput[0];
        var self = this;  
        if (file.size > self.MAX_FILE_SIZE) {
            component.set("v.fileName", 'Alert : File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
            return;
        }
        
        var objFileReader = new FileReader();
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            
            fileContents = fileContents.substring(dataStart);
            self.uploadProcess(component, file, fileContents);
        });
        
        objFileReader.readAsDataURL(file);
    },
    
    uploadProcess: function(component, file, fileContents) {
        var startPosition = 0;
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        console.log('coming here 30');
        
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '');
    },
    
    
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId) {
        // call the apex method 'createCaseWithAttachment
        var descrip=component.get('v.description');//new code
        var getchunk = fileContents.substring(startPosition, endPosition);
        var businessName = component.get('v.businessName');
        var businessCode = component.get('v.businessCode');
        var subj;
        var action = component.get("c.createCaseWithAttachment");
         if (businessName === undefined){ businessName = "";}
        if (businessCode === undefined){businessCode = "";}
        if(businessName === ""&& businessCode === ""){subj="Message from the help centre";}
        else{subj = businessName + ' '+businessCode;}
        action.setParams({
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            webName:component.get('v.webName'),
            webEmail:component.get('v.webEmail'),
            subj:subj,
            description:descrip,//new change
            type:component.get('v.Type')
        });
        
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            attachId = response.getReturnValue();
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                component.set('v.isSuccess',true);
                component.set('v.caseNumber',response.getReturnValue());
            } else if (state === "INCOMPLETE") {
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    //method to call createcase apex class method
    saveCase: function(component, event,helper) {
      	var descrip=component.get('v.description');//new code
        var businessName = component.get('v.businessName');
        var businessCode = component.get('v.businessCode');
        var subj;
        if (businessName === undefined){ businessName = "";}
        if (businessCode === undefined){businessCode = "";}
        if(businessName === ""&& businessCode === ""){subj="Message from the help centre";}
        else{subj = businessName + ' '+businessCode;}
        var action = component.get("c.createCase");
        action.setParams({
            webName:component.get('v.webName'),
            webEmail:component.get('v.webEmail'),
            subj:subj,
            description:descrip,//new change
            type:component.get('v.Type')
        });
        // set call back 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.isSuccess',true);
                component.set('v.caseNumber',response.getReturnValue());
            } else if (state === "INCOMPLETE") {
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    //new method
     showSpinner: function (component) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
     //new method
    hideSpinner: function (component) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    closeModalHelper:function(component,event,helper){    
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open'); 
    },
})