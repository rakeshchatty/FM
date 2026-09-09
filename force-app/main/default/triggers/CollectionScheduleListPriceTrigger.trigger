trigger CollectionScheduleListPriceTrigger on Schedule__c(before insert, before update) {

    //Get the the supplier product in order to get the products since you need it for getting the pricebook entries
    Set < Id > supplierProductIds = new Set < Id > ();
    Set < Id > pricebookIds = new Set < Id > ();
	Map<Id, Schedule__c> locationScheduleMap = new Map<Id,Schedule__c>();
    Map<Id, Id> accountWithPricebook = new Map<Id, Id>();
    Map<Id, Account> accountsWithParentOrPartnership = new Map<Id, Account>();
    for (Schedule__c coll: Trigger.new) {
        locationScheduleMap.put(coll.Location__c,coll);
    }
    
    for (Account acc: [SELECT Id, Price_Book__c, ParentId, Partnership__c from Account WHERE Id IN :locationScheduleMap.keySet()]) {
        supplierProductIds.add(locationScheduleMap.get(acc.Id).Supplier_Product__c);
        accountWithPricebook.put(acc.Id, acc.Price_Book__c);
        accountsWithParentOrPartnership.put(acc.Id, acc);
        pricebookIds.add(acc.Price_Book__c);
    }
    
    /*for (Schedule__c coll: Trigger.new) {
        Account acc = [Select Id, Price_Book__c from Account where ID =: coll.Location__c];
        supplierProductIds.add(coll.Supplier_Product__c);
        pricebookIds.add(acc.Price_Book__c);
    }*/

    //Need this map to have an easy way to get the product when needing to filter pricebook entries while updating list price on schedule
    List < Supplier_Product__c > supplierProducts = [SELECT Id, Product__c FROM Supplier_Product__c WHERE Id IN: supplierProductIds];
    Map < Id, Id > supplierProductProductMap = new Map < Id, Id > ();
    for (Supplier_Product__c sup: supplierProducts) {
        supplierProductProductMap.put(sup.Id, sup.Product__c);

    }
    system.debug('supplierProductIds ' + supplierProductIds);
    system.debug('pricebookIds ' + pricebookIds); 
    system.debug('supplierProduct ' + supplierProductProductMap);
    //Get the unit price for the product and put it in a map associated to the corresponding product;
    List < PricebookEntry > pbeList = [SELECT Product2Id, UnitPrice, Pricebook2.Id FROM PricebookEntry
        WHERE Product2Id IN: supplierProductProductMap.values() and Pricebook2.Id IN: pricebookIds
    ];
    System.debug('pbeList: ' + pbeList);
    Map < Id, List < PricebookEntry >> productPricebookEntryMap = new Map < Id, List < PricebookEntry >> ();
    if (pbeList.size() > 0) { 
        for (PricebookEntry pbe: pbeList) {
            if (productPricebookEntryMap.containsKey(pbe.Product2Id)) {
                productPricebookEntryMap.get(pbe.Product2Id).add(pbe);
            } else {
                productPricebookEntryMap.put(pbe.Product2Id, new List < PricebookEntry > {
                    pbe
                });
            }
        }
    }
    System.debug('productPricebookEntryMap: ' + productPricebookEntryMap);
    //Make the actual update to the record being updated or inserted

    //TODO JIRA-973
    if (Trigger.isUpdate) {
        // Set<Id> accountIds = new Set<Id>();
        // for (Schedule__c s : Trigger.NEW) {
        //     accountIds.add(s.Location__c);
        // }

        //Map<Id, Account> accountsWithParentOrPartnership = new Map<Id, Account>([SELECT Id, ParentId, Partnership__c FROM Account WHERE Id IN :accountIds]);

        Set<Id> accountIdsFromParent = new Set<Id>();
        Set<Id> accountIdsFromPartnership = new Set<Id>();
        for (Account a : accountsWithParentOrPartnership.values()) {
            if (a.ParentId != null) {
                accountIdsFromParent.add(a.ParentId);
            }
            if (a.Partnership__c != null) {
                accountIdsFromPartnership.add(a.Partnership__c);
            }
        }
        //system.debug(accountIds);
        //get all discounts related to the locations
        //JIRA 1487 no overlaping discounts (added start and end criterias)
        List<Account_Discount__c> accountDiscounts = [SELECT Id, Account__c, Product_Discount__c FROM Account_Discount__c WHERE Account__c IN :accountIdsFromParent AND DiscountSupStartDate__c <= TODAY AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];
        List<Account_Discount__c> partnerDiscounts = [SELECT Id, Account__c, Product_Discount__c FROM Account_Discount__c WHERE Account__c IN :accountIdsFromPartnership AND DiscountSupStartDate__c <= TODAY AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];
        system.debug('accountdiscounts: '+accountDiscounts);
        system.debug('partnerdiscounts: '+partnerDiscounts);

        //List < Account_Discount__c > checkDiscounts = [SELECT Id, Account__c, Product_Discount__c FROM Account_Discount__c];

        //Too many SQL Queries, call them here:
        //For each product get the PricebookEntry
        Map < Id, PricebookEntry > getPricebookEntries = new Map < Id, PricebookEntry > ();

        Set < Id > productIds = new Set < Id > ();
        Set < Id > pricebookIds = new Set < Id > ();
        for (Schedule__c sch: Trigger.New) {
            Id productId = supplierProductProductMap.get(sch.Supplier_Product__c);
            system.debug('PRODUCT ID >>>>>' + productId);
            productIds.add(productId);
            pricebookIds.add(sch.Location__r.Price_Book__r.Id);
        }

        List < PricebookEntry > p = [SELECT Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Product2Id IN: productIds AND Pricebook2Id IN: pricebookIds];
        system.debug('Lista dos PricebookEntrys >>>>>>>>>>> ' + p);

        for (Id productIdIn: productIds) {
            for (PricebookEntry thisP: p) {
                if (thisP.Product2Id == productIdIn) {
                    getPricebookEntries.put(productIdIn, thisP);
                }
            }
        }

        Map<Id, Boolean> hasAccountDiscountMap = new Map<Id,Boolean>();

        for (Schedule__c sch: Trigger.New) {
            //Account acc = [Select Id, Price_Book__c from Account where ID =: sch.Location__c];
            system.debug('Calcular Desconto--->');
            //JIRA-973
            Account_Discount__c thisDiscount = new Account_Discount__c();
            for (Account_Discount__c a: accountDiscounts) {
                //TODO alterar para quando nao tiver descontos nenhuns nao fazer nada
                if (a.Account__c == accountsWithParentOrPartnership.get(sch.Location__c).ParentId) {
                    thisDiscount = a;
                    hasAccountDiscountMap.put(sch.Location__c, true);
                    system.debug('Found Discount--->' + a.Product_Discount__c);
                    system.debug('Sale Price --->' + sch.Sale_Price__c);
                }
            }

            for (Account_Discount__c a : partnerDiscounts) {
                if (!hasAccountDiscountMap.containsKey(sch.Location__c) && a.Account__c == accountsWithParentOrPartnership.get(sch.Location__c).Partnership__c) {
                    thisDiscount = a;
                }
            }

            Id productId = supplierProductProductMap.get(sch.Supplier_Product__c);
            system.debug('PRODUCT ID >>>>>' + productId);

            //List<PricebookEntry> p = [SELECT Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Product2Id = :productId];



            if (!productPricebookEntryMap.isEmpty() && productPricebookEntryMap.get(productId) != null) {
                system.debug('entrei no if');
                for (PricebookEntry pbEntry: productPricebookEntryMap.get(productId)) {
                    if (pbEntry.Pricebook2Id == accountWithPricebook.get(sch.Location__c)) {
                        sch.List_Price__c = pbEntry.UnitPrice;
                        break;
                    }
                }
                sch.Sale_Price__c = sch.List_Price__c;
            }




            if (thisDiscount.Product_Discount__c != null && thisDiscount != null && sch.List_Price__c != null && sch.Sale_Price__c != null) {
                system.debug('***************************** UPDATE LIST PRICE AND SALE PRICE *****************************');
                sch.Sale_Price__c = sch.List_Price__c - thisDiscount.Product_Discount__c;
            }

            //END JIRA-973
        }
    }



}