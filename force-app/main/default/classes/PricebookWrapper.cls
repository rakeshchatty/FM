global class PricebookWrapper implements Comparable {

	public Pricebook2 pbook;
	public boolean historicCheck;

	public PricebookWrapper(Pricebook2 pb, boolean b) {
		pbook = pb;
		historicCheck = b;
	}

	// Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        PricebookWrapper compareToPbook = (PricebookWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (pbook.Effective_Date__c < compareToPbook.pbook.Effective_Date__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (pbook.Effective_Date__c > compareToPbook.pbook.Effective_Date__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}