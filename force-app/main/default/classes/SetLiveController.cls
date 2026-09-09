/**
(c) 2018 XPAND-IT
Developed by XPAND-IT
@date Date of creation: February 2019
Date of updates: 

@modifications ??/2018 [JIRA ???] - Set a prospect live and become a Location by going to Enqix
@Modifications Feb/2019 [JIRA 1376] - New Set Live feature, so account as autotonomy inside salesforce
*/
public class SetLiveController {

	@AuraEnabled
	public static Id setLiveCtrl(string recordId) {
		Account prosp = [select Name, Discount_Start_Date__c, RecordTypeId, Ready_to_Transfer__c, Opportunity__c, Transferred_To_Enqix__c, Enqix_Location_ID__c, ParentId, Parent.Enqix_Dead_Live__c, Parent.Ready_to_Transfer__c, Parent.Transferred_To_Enqix__c, Parent.Enqix_ID__c
			from Account where Id =: recordId
		];
        
        //Update Discount_Start_Date__c to today when setLive is pressed
        //prosp.Discount_Start_Date__c = Date.newInstance(2018, 08, 01); //system.today();
        //prosp.Parent.Discount_Start_Date__c = Date.newInstance(2018, 08, 01); //system.today();
       
        boolean discount = updateDiscountDate(prosp.ParentId);
		boolean finance = getContact(prosp.ParentId, true);
		boolean service = getContact(recordId, false);
        List<Account> accsToUpdate = new List<Account>();
        
        //jira 1899 update Enqix Start date depending on the Orders related
      	List <Order> recentOrders = [Select Id from Order where CreatedDate = LAST_N_DAYS:730 AND AccountId =: prosp.Id];
        system.debug('recentOrders --> ' +recentOrders.size());

        // BEGIN JIRA 958
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        if(prosp.RecordTypeId == partnerRecordTypeId){
            //It's a Partner Account Type
            system.debug('It\'s a Partner Account Type');
            prosp.Ready_to_Transfer__c = true;
            accsToUpdate.add(prosp);
         
        // BEGIN JIRA 1376
        }else if (finance && service && !prosp.Transferred_To_Enqix__c && prosp.ParentId != null) { //JIRA 1376 removed "prosp.Enqix_Location_ID__c == null &&" from the condition
            prosp.Ready_to_Transfer__c = true;
            system.debug('Prospect Location');
            Account acc2 = new Account();
            acc2.Id = prosp.ParentId;
            //acc.Ready_to_Transfer__c = true;
            acc2.Enqix_Dead_Live__c = 'Live';
            acc2.Enqix_Date_Made_Live__c = Date.today();
            
            prosp.Enqix_Dead_Live__c = 'Live';
            prosp.Enqix_Date_Made_Live__c = Date.today();
            prosp.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
            //jira 1899 update Enqix Start date depending on the Orders related
            if(recentOrders.size() == 0){
                prosp.Enqix_Start_Date__c = Date.today();
            //jira 1958 update Enqix Start date (new condition)
            }else if (recentOrders.size() > 0 && prosp.Enqix_Start_Date__c == null){
                prosp.Enqix_Start_Date__c = Date.today();
            }
            
            accsToUpdate.add(prosp);
            accsToUpdate.add(acc2);
            system.debug('prosp.Parent.Transferred_To_Enqix__c - '+prosp.Parent.Transferred_To_Enqix__c);
        } else if (finance && service && !prosp.Parent.Transferred_To_Enqix__c) { //JIRA 1376 removed "&& prosp.Parent.Enqix_ID__c == null" from the condition
            Account acc = new Account();
            system.debug('Changing parente dead live to live');
            acc.Id = prosp.ParentId;
            acc.Ready_to_Transfer__c = true;
            acc.Enqix_Dead_Live__c = 'Live';
            acc.Enqix_Date_Made_Live__c = Date.today();
            accsToUpdate.add(acc); 
            // END JIRA 1376
        } else {
            system.debug('Entrou');
            string message = '';
            if (!finance && !service) message = 'Finance Contact on Parent Account and Service Contact on Prospect needed.';
            else if (!finance) message = 'Finance Contact on Parent Account needed.';
            else if (prosp.ParentId == null) message = 'Account needs a Parent Account to be set live.';
            else if(prosp.Transferred_To_Enqix__c == true) message = 'This Account is Transferred To Enqix';
            else message = 'Service Contact on Prospect needed.';
            throw new AuraHandledException(message);
        }

		Map<Id, Account> noRepeats = new Map<Id, Account>();
		for(Account a : accsToUpdate){
			noRepeats.put(a.Id, a);
		}

		List<Account> noRepeatsAccounts = new List<Account>();
		for(Id ai : noRepeats.keySet()){
			noRepeatsAccounts.add(noRepeats.get(ai));
		}  

        update noRepeatsAccounts;

		if (prosp.Opportunity__c != null) return prosp.Opportunity__c;
		else return prosp.Id;
	}
    
   	//13.08.2018 - Created an empty list to update with the changed discounts, to avoid getting an error from a validation rule (DiscountStartDate_Today)
    private static boolean updateDiscountDate(Id parentAccount){
        List<Account_Discount__c> discounts = [select Account__c, DiscountSupStartDate__c, Account__r.Enqix_Dead_Live__c 
                                       from Account_Discount__c 
                                       where Account__c = :parentAccount AND DiscountSupStartDate__c <= TODAY AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];
        
        List<Account_Discount__c> discsToUpdate = new List<Account_Discount__c>();
        system.debug('Teste updateDiscountDate ::: lista dos descontos #'+discounts.size());
        for(Account_Discount__c discount : discounts){
            if (discount.Account__r.Enqix_Dead_Live__c == null) {
                system.debug('Data antiga para DiscountSupStartDate__c' + discount.DiscountSupStartDate__c);
            	discount.DiscountSupStartDate__c = system.today(); //Date.newInstance(2018, 08, 01); //
            	system.debug('Nova Data para DiscountSupStartDate__c' + discount.DiscountSupStartDate__c);
                discsToUpdate.add(discount);
            }
        }
        
        //update discounts
        update discsToUpdate;
        return true;
        
    }

	private static boolean getContact(string accountId, boolean parent) {
		boolean flag = false;
		List < AccountContactRelation > acrs = [select Roles from AccountContactRelation where AccountId =: accountId];
		if (acrs.size() > 0) {
			for (AccountContactRelation acr: acrs) {
				if (acr.Roles == null) continue;
				List < string > roles = new list < string > ();
				try {
					roles.addAll(acr.Roles.split(';'));
					system.debug(roles);
					if (roles.size() > 1) {
						for (integer i = 0; i < roles.size(); i++) {
							if (parent) {
								if (roles[i] == null) continue;
								else if (roles[i] == 'Finance Contact') flag = true;
							}
							else if (!parent) {
								if (roles[i] == null) continue;
								else if (roles[i] == 'Service Contact') flag = true;
							}
						}
					} else {
						if (parent) {
							system.debug(acr.Roles);
							if (acr.Roles == null) continue;
							else if (acr.Roles == 'Finance Contact') flag = true;
						} else if (!parent) {
							if (acr.Roles == null) continue;
							else if (acr.Roles == 'Service Contact') flag = true;
						}
					}
				} catch (Exception e) {
					return flag;
				}
			}
		}
		return flag;
	}

}