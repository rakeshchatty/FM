trigger Pricebook2Trigger on Pricebook2(before insert) {

    Set < Integer > codes = new Set < Integer > ();
    for (Pricebook2 pb: Trigger.New) {
        codes.add(Integer.valueOf(pb.Enqix_Code__c));
    }

    List < Pricebook2 > mostRecentPricebooks = [SELECT Id, Enqix_Code__c, Effective_Date__c, Most_Recent__c
        FROM Pricebook2
        WHERE Enqix_Code__c IN: codes AND Effective_Date__c <= TODAY
        ORDER BY Effective_Date__c DESC];
    
    Map < Integer, List < PricebookWrapper >> myMap = new Map < Integer, List < PricebookWrapper >> ();
    for (Pricebook2 pb: Trigger.New) {   
        pb.Most_Recent__c = false;
        pb.IsActive = false;       
        if (myMap.containsKey(Integer.valueOf(pb.Enqix_Code__c)) && pb.Effective_Date__c <= System.TODAY()) {
            List < PricebookWrapper > pblist = myMap.get(Integer.valueOf(pb.Enqix_Code__c));
            pblist.add( new PricebookWrapper(pb, false) );
            myMap.put(Integer.valueOf(pb.Enqix_Code__c), pblist);
        } else if (pb.Effective_Date__c <= System.TODAY()) {
            List < PricebookWrapper > pblist = new List < PricebookWrapper > ();
            pblist.add( new PricebookWrapper(pb,false) );
            myMap.put(Integer.valueOf(pb.Enqix_Code__c), pblist);
        }
    }
    for (Pricebook2 pb: mostRecentPricebooks) { 
        pb.Most_Recent__c = false;    
        pb.IsActive = false;  
        if (myMap.containsKey(Integer.valueOf(pb.Enqix_Code__c))) {
            List < PricebookWrapper > pblist = myMap.get(Integer.valueOf(pb.Enqix_Code__c));
            pblist.add( new PricebookWrapper(pb,true));
            myMap.put(Integer.valueOf(pb.Enqix_Code__c), pblist);
        } else {
            List < PricebookWrapper > pblist = new List < PricebookWrapper > ();
            pblist.add( new PricebookWrapper(pb,true) );
            myMap.put(Integer.valueOf(pb.Enqix_Code__c), pblist);
        }
    }

    system.debug(myMap);

    List < Pricebook2 > historicPricebooks = new List < Pricebook2 > ();

    for(Integer i : myMap.keyset() ) {
       List<PricebookWrapper> pbws = myMap.get(i);
       pbws.sort();
       system.debug(pbws);
       pbws[0].pbook.Most_Recent__c = true;
       pbws[0].pbook.IsActive = true;
       for (PricebookWrapper pbw : pbws) {
           if (pbw.historicCheck) {
               historicPricebooks.add(pbw.pbook);
           }
       }
    }

    if (historicPricebooks.size() > 0) {
        update historicPricebooks;
    }
}