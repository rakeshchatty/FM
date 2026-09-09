trigger AccountTrigger on Account (before insert, after insert, after update, before update){

    new AccountTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);

    if(trigger.isInsert){
        
        if(trigger.isAfter){
            Set <ID> partner = new Set <Id>();
            List <Account> subsProdToCreateList = new List <Account>();  
            Id RecordTypeIdLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
            Id RecordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            for(Account acc :trigger.new){ 
                if(acc.Partnership__c != null){
                    partner.add(acc.Partnership__c);
                    system.debug('partner -->'+ partner);
                }
            }
            
            /*	
			* 2019-05-08 / JIRA 1487 -> Automatic creation of Subscribed products for partner locations and supplier locations
			*/
            List <Account_Discount__c> subsProdtoCreate = [Select id, BID_allocation_product__c, Product__c, Product__r.Name, DiscountSupStartDate__c From Account_Discount__c WHERE Account__c =: partner AND BID_allocation_product__c = True];
            system.debug('subsProdtoCreate --> '+subsProdtoCreate.size());
            for(Account acc :trigger.new){ 
                if(acc.recordTypeId == RecordTypeIdLocation || acc.recordTypeId == RecordTypeIdProspect && (subsProdtoCreate.size() > 0)){
                    subsProdToCreateList.add(acc); 
                }
            }  
            system.debug('subsProdToCreateList--> '+subsProdToCreateList.size());
            if(subsProdToCreateList.size() > 0){
                AccountTriggerHelper.createSubscribedProducts(subsProdToCreateList, subsProdtoCreate);
            }
        }
        
        if(trigger.isBefore){
            Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
            Id RecordTypeIdLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
            Id RecordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();

			Enqix_Id_automation__c enqixIdAuto;
            if (!Test.isRunningTest()) {
               	enqixIdAuto = [Select id, Enqix_id__c, Enqix_Location_Id__c from Enqix_Id_automation__c limit 1]; 
            }            
            else {
                enqixIdAuto = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
                system.debug('DEBUG========================='+enqixIdAuto);
            }
            
            Integer randomNumber = Integer.valueof((Math.random() * 999));
            string randomNumberString = String.valueof(randomNumber);
            system.debug('Math.random number -- ' + randomNumber);
            
            //When a prospect is created and the name already exists on another Prospect or Location, the account should not be created
            Set<string> newProspectNames = new Set<string>();
            Id rectypeProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            for (Account acc : trigger.new) { 
                string ProdName = acc.Name.trim().SubString(0,3);
                acc.CP_Account_Code__c = ProdName + randomNumberString;
                Boolean foundAGoodID = false;
                if(acc.recordTypeId == RecordTypeIdAccount){
                    system.debug('Account');
                    //JOAO [2019-03-06] added to prevent errors saving acocunts with duplicate Enqix IDs
                    While (!foundAGoodID)
                    {
                        enqixIdAuto.Enqix_id__c++;
                        List<Account> dummyAccount = Database.query('SELECT Id FROM Account WHERE Enqix_ID__c = \''+enqixIdAuto.Enqix_id__c+'\' LIMIT 1');
                        if (dummyAccount.size() == 0)
                        { 
                            if (!Test.isRunningTest()) {
                                update enqixIdAuto;
                            }
                            string EnqixId = String.valueof(enqixIdAuto.Enqix_id__c); 
                            acc.Enqix_ID__c = EnqixId;
                            foundAGoodID = true;
                        }
                    }
                    
                }else if(acc.recordTypeId == RecordTypeIdLocation || acc.recordTypeId == RecordTypeIdProspect){
                    system.debug('Location or Prospect');
                    //JOAO [2019-03-06] added to prevent erros saving acocunts with duplicate Enqix IDs
                    While (!foundAGoodID)
                    {
                        enqixIdAuto.Enqix_Location_Id__c++;
                        List<Account> dummyAccount = Database.query('SELECT Id FROM Account WHERE Enqix_Location_Id__c = \''+enqixIdAuto.Enqix_Location_Id__c+'\' LIMIT 1');
                        if (dummyAccount.size() == 0)
                        { 
                            if (!Test.isRunningTest()) {
                                update enqixIdAuto;
                            }
                            string EnqixLocationId = String.valueof(enqixIdAuto.Enqix_Location_Id__c); 
                            acc.Enqix_Location_Id__c = EnqixLocationId;
                            foundAGoodID = true;
                        }
                    }
                } 
                if (acc.RecordTypeId == rectypeProspect){ 
                    newProspectNames.add(acc.Name);
                } 
            }
            
            Id rectypeLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
            Set<Id> recTypeIds = new Set<Id>();
            recTypeIds.add(rectypeProspect);
            recTypeIds.add(rectypeLocation);
            List<Account> existingAccs = [select Name from Account where Name in :newProspectNames and RecordTypeId in :recTypeIds];
            Set<String> names = new set<string>();
            for (Account acc : existingAccs) {
                names.add(acc.Name);
            }
            for (Account acc : trigger.New) {
                if (names.contains(acc.Name)) acc.addError('A Prospect or Location with the entered Name already exists.');
            }
            
            
            //• When a location is created that has an enqix location ID and there are no opportunities attached 
            //to the location then it should look at the parent account.  If it finds any opportunities which are 
            //closed won on the parent account and closed within 6 months of the date the location was created, 
            //it should set the location primary opportunity to that opportunity.  It should also set another new 
            //field called ‘adopted parent opportunity’ with today’s date.
            
            set<Id> ParentAccountIds = new set<Id>();
            for(Account Acc : trigger.new){
                if(acc.Enqix_Location_ID__c != null && acc.Opportunity__c == null && acc.ParentId != null){
                    ParentAccountIds.add(acc.ParentId);
                }
            }
            
            map<Id, List<Opportunity>> ParentAccountOpportunites = new map<Id, list<Opportunity>>();
            list<Opportunity> opplist = new list<Opportunity>();
            date LAST_SIX_MONTHS = date.today().addMonths(-6);
            system.debug('LAST_SIX_MONTHS :: '+LAST_SIX_MONTHS );
            opplist = [Select Id, Name, AccountId from Opportunity Where AccountId IN :ParentAccountIds AND (StageName = '5 Collections Started' OR StageName = '6 Handed Over') AND CloseDate > :LAST_SIX_MONTHS];
            for(Opportunity opp : oppList){
                if(ParentAccountOpportunites.containsKey(opp.AccountId)){
                    ParentAccountOpportunites.get(opp.AccountId).add(opp);
                }
                else{
                    ParentAccountOpportunites.put(opp.AccountId, new  List <Opportunity> { opp });
                }
            }
            
            for(Account Acc : trigger.new){
                if(acc.Enqix_Location_ID__c != null && acc.Opportunity__c == null && acc.ParentId != null){
                    system.debug('ParentId :: '+acc.ParentId);
                    list<Opportunity> ParentoppList = ParentAccountOpportunites.get(acc.ParentId);
                    system.debug('Parent Opp:: '+ParentAccountOpportunites);
                    if(ParentoppList != null && ParentoppList.size() > 0){
                        acc.Opportunity__c = Parentopplist[0].Id;
                        acc.adopted_parent_opportunity__c = date.today();
                    }
                }
            }
            
        }
    }
    
    if(trigger.isUpdate){
        if (Trigger.IsBefore) {
            Set < Id > accIds = new Set < Id > ();
            for (Account acc: trigger.new) {
                Account oldAccount = Trigger.oldMap.get(acc.ID);  
                //Jira 1931 -- Store the value of the Enqix Payment Method field when the value is changed to Suspended to be used after
                if(oldAccount.Enqix_Payment_Method__c != acc.Enqix_Payment_Method__c && acc.Enqix_Payment_Method__c == 'Suspended'){
                    acc.Old_Enqix_Payment_Method_value__c = oldAccount.Enqix_Payment_Method__c;
                }
                //jira 1931 -- If the amount outstanding on the Account is now 0 or less update the Enqix Payment method to the value before it was chaged to Suspended
                if(acc.Amount_Outstanding__c <= 0 && acc.Enqix_Payment_Method__c == 'Suspended'){
                    acc.Enqix_Payment_Method__c = acc.Old_Enqix_Payment_Method_value__c;
                }
                
                if (acc.dd_sort_code__c != oldAccount.dd_sort_code__c || acc.dd_account_number__c != oldAccount.dd_account_number__c) {
                    acc.Direct_Debit_authorised__c = false;
                    acc.Direct_Debit_Authorised_Date__c = null;
                    acc.Paid_by_DD_Before__c = false;
                    if (acc.dd_sort_code__c == '' &&  acc.dd_account_number__c == '' || acc.dd_sort_code__c == null &&  acc.dd_account_number__c == null) {
                        acc.Direct_Debit_Details_Entry_Date__c = null;
                    } else {
                        acc.Direct_Debit_Details_Entry_Date__c = system.now();
                    }                    
                }
                // Isto poderá ser apagado visto que não é necessário mais ser usado.
                String deadOrAlive = acc.Enqix_Dead_Live__c;
                if (
                    String.isNotEmpty(deadOrAlive) &&
                    deadOrAlive.equalsIgnoreCase('DEAD') // to ignore case sensitivity
                    &&
                    Trigger.oldMap.get(acc.Id).Enqix_Dead_Live__c != deadOrAlive // change event
                ) {
                    accIds.add(acc.Id);
                } 
            }
            //Jira 1666 start
            Map<Id, Account> accountsMap = new Map<Id, Account>();
            Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
            for(Id acc : Trigger.newMap.keySet()){
                If(Trigger.newMap.get(acc).RecordTypeId == RecordTypeIdAccount && Trigger.oldMap.get(acc).PO_Required__c == False && Trigger.newMap.get(acc).PO_Required__c == True){
                    List<Recurrings__c> recurrings = [Select Id, Account__c, Account__r.ParentId from Recurrings__c where Account__r.ParentId =:trigger.newmap.keyset() AND Active__c = True AND (PO_Number__c = '' OR PO_Number__c = null) LIMIT 1];
                    if (recurrings.size() > 0)
                    {
                        Trigger.newMap.get(acc).addError('Recurrings with no PO exist. Please get a PO for recurrings or suspend them before making the account require a PO');
                    }
                }
            }
            //Jira 1666 end
        }
               
        if (Trigger.IsAfter) { 
            Set <ID> partner = new Set <Id>();
            List <Account> subsProdToCreateList = new List <Account>();
            List <AccountContactRelation> acrToUpdate = new List <AccountContactRelation>();
            Id RecordTypeIdLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
            Id RecordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            Set <Id> accToClearRound = new Set <Id>(); 
            Set <Id> accsToUpdateAccountContactRel = new Set <Id>(); 
            for (Account acc: trigger.new) {
                system.debug('Entered after update');
                Account oldAccount = Trigger.oldMap.get(acc.ID);
                if(oldAccount.Partnership__c == null && acc.Partnership__c != null){
                    partner.add(acc.Partnership__c);
                    system.debug('partner -->'+ partner);
                }
                if((Trigger.oldMap.get(acc.Id).Enqix_Dead_Live__c == 'Pending' && Trigger.newMap.get(acc.Id).Enqix_Dead_Live__c == 'Live' || Trigger.oldMap.get(acc.Id).Enqix_Dead_Live__c == 'Dead' && Trigger.newMap.get(acc.Id).Enqix_Dead_Live__c == 'Live') && Trigger.newMap.get(acc.Id).recordTypeId == RecordTypeIdLocation || Trigger.newMap.get(acc.Id).recordTypeId == RecordTypeIdProspect){
                    system.debug('Entered AccountContact update');
                    accsToUpdateAccountContactRel.add(acc.Id);
                }
                if(Trigger.newMap.get(acc.Id).BillingStreet != Trigger.oldMap.get(acc.Id).BillingStreet || Trigger.newMap.get(acc.Id).BillingCity != Trigger.oldMap.get(acc.Id).BillingCity || Trigger.newMap.get(acc.Id).BillingState != Trigger.oldMap.get(acc.Id).BillingState || Trigger.newMap.get(acc.Id).BillingPostalCode != Trigger.oldMap.get(acc.Id).BillingPostalCode || Trigger.newMap.get(acc.Id).BillingCountry != Trigger.oldMap.get(acc.Id).BillingCountry || Trigger.newMap.get(acc.Id).Enqix_Dead_Live__c == 'Dead'){
                    accToClearRound.add(acc.id);
                }

                if(oldAccount.Partnership__c != null && acc.Partnership__c == null){
                  	AccountTriggerHelper.cancelSubscribedProducts(oldAccount);
                } 
            }
            /*
			* 2019-05-08 / JIRA 1487 -> Automatic creation of Subscribed products for partner locations and supplier locations
			*/
            
            List <Account_Discount__c> subsProdtoCreate = [Select id, BID_allocation_product__c, Product__c, Product__r.Name, DiscountSupStartDate__c From Account_Discount__c WHERE Account__c =: partner AND BID_allocation_product__c = True];
            system.debug('subsProdtoCreate --> '+subsProdtoCreate.size());
            for(Account acc :trigger.new){
                Account oldAcc = Trigger.oldMap.get(acc.ID);
                if((acc.recordTypeId == RecordTypeIdLocation || acc.recordTypeId == RecordTypeIdProspect) && Trigger.oldMap.get(acc.Id).Partnership__c != Trigger.newMap.get(acc.Id).Partnership__c){
                    subsProdToCreateList.add(acc);
                }
            }
            if(subsProdToCreate.size() > 0 && subsProdtoCreate.size() > 0){
                AccountTriggerHelper.createSubscribedProducts(subsProdToCreateList, subsProdtoCreate);
            }
            
            List <AccountContactRelation> acr = [Select Id, AccountId, IsCustomerPortalUser__c, Roles From AccountContactRelation Where AccountId =: accsToUpdateAccountContactRel AND Roles = 'Service Contact' AND IsCustomerPortalUser__c != True];
            for(AccountContactRelation accCon : acr){
                system.debug('Entered with Set Account Live');
                accCon.IsCustomerPortalUser__c = True;
                //acrToUpdate.add(accCon);
            }
            update acr;

            List <Schedule__c> schedules = [Select Id, Location__c, Round__c From Schedule__c where Location__c =: accToClearRound];        
            for(Schedule__c sch : schedules){
                sch.Round__c = null;
            }
            update schedules;
        }
    }
}