trigger AccountDiscountGrossPrice on Account_Discount__c(before insert, before update) {
    Map < Id, list < Account_Discount__c >> ProductToDiscountMap = new map < Id, list < Account_Discount__c >> ();
    Set < Id > accountIds = new Set < Id > ();
    for (Account_Discount__c ac: Trigger.New) {
        Id partnerdiscountRT = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();
        system.debug(partnerdiscountRT);
        system.debug(ac.RecordTypeId);
        if (ac.RecordTypeId != partnerdiscountRT) {
            if (ProductToDiscountMap.containsKey(ac.Product__c)) {
                ProductToDiscountMap.get(ac.Product__c).add(ac);
            } else {
                ProductToDiscountMap.put(ac.Product__c, new List < Account_Discount__c > {
                    ac
                });
            }
            accountIds.add(ac.Account__c);
        }
    }
    system.debug(accountIds);
    List < Account > accounts = [SELECT Id, Price_Book__c FROM Account WHERE Id IN: accountIds];
    Set < Id > pricebookIds = new Set < Id > ();
    for (Account a: accounts) {
        pricebookIds.add(a.Price_Book__c);
    }

    List < PricebookEntry > pbeList = [SELECT Product2Id, UnitPrice FROM PricebookEntry
        WHERE Product2Id IN: ProductToDiscountMap.keySet() and Pricebook2Id IN: pricebookIds
        ORDER BY LastModifiedDate DESC
    ];

    for (PricebookEntry pbe: pbeList) {
        system.debug(pbe);
        for (Account_Discount__c accDisc: ProductToDiscountMap.get(pbe.Product2Id)) {
            system.debug(accDisc);
            accDisc.Gross_Price__c = pbe.UnitPrice;
        }
    }
}