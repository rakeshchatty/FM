public with sharing class RecurringTriggerHelper {

	public static void populateDates(List<Recurrings__c> recurrings, Map<Id, Recurrings__c> oldRecs){
		system.debug('Entrei no Trigger Helper dos Recurrings');
		if (oldRecs == null) {
			for (Recurrings__c r: recurrings) {

				Date newDate = getLastWorkingDay(r.First_Date__c);
				r.Last_Working_Day__c = newDate;
				//r.Next_Date__c = newDate;
				r.isSalesforce__c = true;
				r.Active__c = true;
			}
		}
		else {
			for (Recurrings__c r : recurrings) {
				if (r.Rec__c != oldRecs.get(r.Id).Rec__c || r.Recur_Every__c != oldRecs.get(r.Id).Recur_Every__c) {
					Date newDate = getLastWorkingDay(r.First_Date__c);
					getNewNextDate(r, newDate);
				}
			}
		}

		//update rs;
	}

	public static Date getLastWorkingDay(Date firstDate){
		DateTime firstDate2 = Date.newInstance(firstDate.year(), firstDate.month(), firstDate.day());
		String day = firstDate2.format('u');	
		DateTime lastDay = Date.newInstance(firstDate.year(), firstDate.month(), firstDate.day());

		if(day == '7'){
			lastDay = Date.newInstance(firstDate.year(), firstDate.month(), firstDate.day()-2);
		}else if(day == '1') {
			lastDay = Date.newInstance(firstDate.year(), firstDate.month(), firstDate.day()-3);
		}else{
			lastDay = Date.newInstance(firstDate.year(), firstDate.month(), firstDate.day()-1);
		}
		Date returnDate = Date.newInstance(lastDay.year(), lastDay.month(), lastDay.day());
		return returnDate;
	}

	public static void getNewNextDate(Recurrings__c r, Date firstNextDate) {
		switch on(r.Rec__c) {
			when 'Day' {
				r.Next_Date__c = firstNextDate.addDays(Integer.valueof(r.Recur_every__c));
			}
			when 'Week' {
				r.Next_Date__c = firstNextDate.addDays(Integer.valueof(r.Recur_every__c) * 7);
			}
			when 'Month' {
				r.Next_Date__c = firstNextDate.addMonths(Integer.valueof(r.Recur_every__c));
			}
		}
	}
    
    public static void validateSupplierProduct(List<Recurrings__c> recurrings){
        Supplier_Product__c sp = new Supplier_Product__c();
        for (Recurrings__c rec : recurrings){
            try{
                sp = [Select Id, Product__c, Supplier__c from Supplier_Product__c where Supplier__c =: rec.Supplier__c AND Product__c =: rec.Product__c AND (Start_Date__c <= TODAY OR Start_Date__c = null) AND (End_Date__c >= Today OR End_Date__c = null) LIMIT 1];
            }catch (Exception e){
                rec.addError('The product being inserted is not an "Active" supplier product, on the Supplier related.'); 
            }
        }
    }
	
}