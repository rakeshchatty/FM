global class SubscribedProductsSch implements Schedulable {
	global void execute(SchedulableContext sc) {
		SubscribedProductRefreshBatch subsProdRefresh = new SubscribedProductRefreshBatch();
		database.executebatch(subsProdRefresh, 200);

		//checkRefreshDate();
	}

	/*public void checkRefreshDate(){
		Date today = system.today();

		List<Subscribed_Products__c> lista = [SELECT Id, NextRefreshDate__c, Enqix_BID_Location_Limit_Period__c FROM Subscribed_Products__c 
		WHERE NextRefreshDate__c != null and NextRefreshDate__c <= Today and Enqix_BID_Location_Limit_Period__c != null 
		];

		
		system.debug('ESTOU DENTRO DO SCH DOS SUBSCRIBED PRODUCTS+++++++++++++++++++++++++++++++++++++ TENHO ALGUM => '+lista.size());
		for(Subscribed_Products__c h : lista){
			//if(today.day() == h.NextRefreshDate__c.day() && today.month() == h.NextRefreshDate__c.month() && today.year() == h.NextRefreshDate__c.year()){
				h.quantityOrdered__c = 0;
			//}
		}
		
		update(lista);
		
	}*/

}