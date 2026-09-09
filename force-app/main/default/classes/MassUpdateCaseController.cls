/********************************************************************************************
Create Date: 17/07/2017
By: Zachary Stevens
Description: Controller class for mass update pages MassUpdateCaseStatus, MassUpdateCaseOwner
TestClass: Test_MassUpdateCaseController
********************************************************************************************/
public class MassUpdateCaseController {
    private LIST<Case> selectedCases {get; set;}
    public Boolean isSelected {get; set;}
    public string msg {get; set;}
    public Case cse {get; set;}
    
    public boolean sendEmail {get; set;}
    
    public MassUpdateCaseController(ApexPages.StandardSetController sc){
        selectedCases = sc.getSelected();
        isSelected = true;
        sendEmail = false;
        cse = new Case();
        if(selectedCases.size() == 0){
            isSelected = false;
        }
    }
    
    public PageReference updateCaseStatus(){
        try{
            for(Case c : selectedCases){
                c.Status = cse.Status;
            }
            if(selectedCases.size() > 0){
                update selectedCases;     
                msg = 'Cases has been successfully updated.';
            }
        }catch(Exception e){
            msg = e.getMessage();
        }
        return null;
    }
    
    public PageReference updateCaseOwner(){
        try{
            for(Case c : selectedCases){
                c.OwnerId = cse.OwnerID;
            }
            if(selectedCases.size() > 0){
                //update selectedCases;
                Database.DMLOptions dmo = new Database.DMLOptions(); 
                dmo.EmailHeader.triggerUserEmail = sendEmail; 
                Database.update(selectedCases, dmo); // Actual DML operation is performed instead of implicit update
                
                msg = 'Cases owner has been successfully updated.';
            }
        }catch(Exception e){
            system.debug(e.getMessage());
            msg = e.getMessage();
        }
        return null;
    }
}