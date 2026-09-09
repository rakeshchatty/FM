trigger SuppProdTrigger on Supplier_Product__c (before insert, after update) {
    if(trigger.isInsert){
        Set <Id> supplier = new Set <Id>();
        Set <Id> product = new Set <Id>();      
        for(Supplier_Product__c sp: trigger.new){
            supplier.add(sp.Supplier__c);
            product.add(sp.Product__c);
        }
        
        List <Supplier_Product__c> suppProd = [Select id , Start_Date__c, End_Date__c, Supplier__c, Product__c From Supplier_Product__c where Supplier__c = :supplier And Product__c = :product];       
        for(Supplier_Product__c newSuppProd: trigger.new){
            for(Supplier_Product__c currentSuppProd: suppProd){
                if(newSuppProd.Supplier__c == currentSuppProd.Supplier__c &&
                   newSuppProd.Product__c == currentSuppProd.Product__c &&
                   (!( currentSuppProd.End_Date__c != null && (newSuppProd.End_Date__c < currentSuppProd.Start_Date__c || newSuppProd.Start_Date__c > currentSuppProd.End_Date__c ) ) ||
                   currentSuppProd.Start_Date__c <= newSuppProd.End_Date__c && currentSuppProd.End_Date__c == null)){
                   newSuppProd.adderror('A Supplier Product for this product and between this Dates already exist.');            
                }
            }
        }
    }
    if(trigger.isUpdate && trigger.isAfter){ 
        for(Supplier_Product__c sp: trigger.new){
            set <Id> supplierIds = new set <Id>();
            set <Id> productIds = new set <Id>();
            List <Supplier_Product__c> suppProductsUpdated = new List <Supplier_Product__c>();
            //if supplier price changes, update related related recurrings "Supplier Unit Price"
            if (Trigger.oldMap.get(sp.Id).Supplier_Price__c != sp.Supplier_Price__c && sp.Start_Date__c <= system.today() && sp.End_Date__c >= system.today()){
                supplierIds.add(sp.Supplier__c);
                productIds.add(sp.Product__c);
                suppProductsUpdated.add(sp);
            }
            if (suppProductsUpdated.size() > 0){
                SupplierProductHelper.updateSupplierPrice(suppProductsUpdated, supplierIds, productIds);
            }
        }
    }
}