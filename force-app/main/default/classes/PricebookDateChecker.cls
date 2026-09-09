global class PricebookDateChecker implements Schedulable {
	global void execute(SchedulableContext sc) {
		
		system.debug('Entering new price book update method');
		List<Pricebook2> listActivePricebooks = [SELECT id, name, Enqix_Code__c, Most_Recent__c FROM Pricebook2 WHERE isActive = true];
		Map<Decimal,Pricebook2> activePriceboks = new Map<Decimal,Pricebook2>();
		for(Pricebook2 pricebook :listActivePricebooks)
		{
			activePriceboks.put(pricebook.Enqix_Code__c, pricebook);
		}
		system.debug('Generated the acive price book map. Price books:'+activePriceboks.size());
		List<Pricebook2> pricebooksToActivate = [SELECT id, name, Enqix_Code__c, Most_Recent__c FROM Pricebook2 WHERE isActive = false AND Most_Recent__c = true AND Effective_Date__c = TODAY];
		system.debug('# of price books to update: '+pricebooksToActivate.size());
		List<Pricebook2> pricebooksToUpdate = new List<Pricebook2>();
		Map<Decimal, PricebookChangeInfo> changedPricebooks = new Map<Decimal, PricebookChangeInfo>();
		for(Pricebook2 pricebookToActiv :pricebooksToActivate)
		{
			if ( activePriceboks.containsKey( pricebookToActiv.Enqix_Code__c ) )
			{
				Pricebook2 activePricebook = activePriceboks.get(pricebookToActiv.Enqix_Code__c);
				activePricebook.Most_Recent__c = false;
				activePricebook.isActive = false;
				pricebookToActiv.isActive = true;
				pricebooksToUpdate.add(activePricebook);
				pricebooksToUpdate.add(pricebookToActiv);
				changedPricebooks.put(pricebookToActiv.Enqix_Code__c, new PricebookChangeInfo(activePricebook.Enqix_Code__c, activePricebook.Id, pricebookToActiv.Id));
			}else{
				pricebookToActiv.isActive = true;
				pricebooksToUpdate.add(pricebookToActiv);
				changedPricebooks.put(pricebookToActiv.Enqix_Code__c, new PricebookChangeInfo(pricebookToActiv.Enqix_Code__c, null, pricebookToActiv.Id));
			}
		}
		system.debug('Price books ready to update: '+pricebooksToUpdate.size());
		if (pricebooksToUpdate.size() > 0)
		{
			update pricebooksToUpdate;
			
			system.debug('Price books ready to update.');
			system.debug('Ready to update historic data. Starting with accounts');
			Pricebook_AccountUpdateBatch accountsUpdate = new Pricebook_AccountUpdateBatch();
			accountsUpdate.changedPricebooks = changedPricebooks;
			Database.executeBatch (accountsUpdate, 180);
		}
	}
}