public without sharing class WebToCaseController {
    //to fetch type field values
    @AuraEnabled
    public static List<String> getSelectedType(){
        List<String> optionlist = new List<String>();       
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get('case').getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = field_map.get('Type').getDescribe().getPickListValues();       
        
        for (Schema.PicklistEntry pv : picklistValues) {
            optionlist.add(pv.getValue());
        }
        return optionlist;
    }
    //to create case with attachment
    @AuraEnabled
    public static string createCaseWithAttachment(String fileName, String base64Data, String contentType,String webName,String webEmail,String subj,String description,String type){
        String CaseId='';
        List<Case> lstCase= new List<Case>();
        Case c=new Case();
        c.Type=type;
        c.Subject=subj;
        c.SuppliedEmail=webEmail;
        c.SuppliedName=webName;
        c.Origin='Web';
        c.Description=description;
        lstCase.add(c);
        Database.SaveResult[] results = Database.Insert( lstCase ,false ) ;
        for(Integer i=0;i<results.size();i++){
            if (results.get(i).isSuccess()){
                CaseId=results.get(i).getId();
                base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
                Attachment attach = new Attachment();
                attach.parentId = results.get(i).getId();
                attach.Body = EncodingUtil.base64Decode(base64Data);
                attach.Name = fileName;
                attach.ContentType = contentType;
                Insert attach;
            }
        }
        Case casedata=[Select id,caseNumber from case where id=:CaseId limit 1];
        return casedata.caseNumber;
    }
    //to create case without attachment
     @AuraEnabled
    public static string createCase(String webName,String webEmail,String subj,String description,String type){
        List<Case> lstCase= new List<Case>();
        String CaseId='';
        Case c=new Case();
        c.Type=type;
        c.Origin='Web';
        c.Subject=subj;
        c.SuppliedEmail=webEmail;
        c.SuppliedName=webName;
        c.Description=description;
        Insert c;
         Case casedata=[Select id,caseNumber from case where id=:c.id limit 1];
        return casedata.caseNumber;
    }

}