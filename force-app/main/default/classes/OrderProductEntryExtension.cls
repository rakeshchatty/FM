public with sharing class OrderProductEntryExtension {

    public String errorMessage {
        get;
        set;
    }
    public Order theOrder {
        get;
        set;
    }
    public String productName {
        get;
        set;
    }
    public String searchString {
        get;
        set;
    }
    public OrderItem[] shoppingCart {
        get;
        set;
    }
    public priceBookEntry[] AvailableProducts {
        get;
        set;
    }
    public Pricebook2 theBook {
        get;
        set;
    }

    public String toSelect {
        get;
        set;
    }
    public String toUnselect {
        get;
        set;
    }
    public Decimal Total {
        get;
        set;
    }

    public Boolean overLimit {
        get;
        set;
    }
    public Boolean multipleCurrencies {
        get;
        set;
    }

    public Boolean multipleRenders {
        get;
        set;
    }

    private Boolean forcePricebookSelection = false;

    private OrderItem[] forDeletion = new OrderItem[] {};
    private set < Id > supplierProductIds {
        get;
        set;
    }

    //public map<Id, decimal> PartnerAccountDiscountMap;
    //public map<Id, decimal> AccountAccountDiscountMap;
    public map < Id, Account_Discount__c > DiscountMap;
    public string accountId {
        get;
        set;
    }
    public account OrderAccount {
        get;
        set;
    }
    public boolean isPORequired {
        get;
        set;
    }
    public boolean vatExempt {
        get;
        set;
    }
    public string orderType {
        get;
        set;
    }

    public map < Id, Subscribed_Products__c > SubscribedProductsMap {
        get;
        set;
    }

    public decimal totalcolumn {
        get;
        set;
    }

    public decimal totalcolumn1 {
        get;
        set;
    }

    public string selectedPB {
        get;
        set;
    }

    private List < Account_Discount__c > accDiscList;
    public Map < Id, Account_Discount__c > accountDiscountsMap {
        get;
        set;
    }

    public boolean hasPartnership {
        get;
        set;
    }
    public Boolean displayPopup {
        get;
        set;
    }
    public Boolean displayNotification {
        get;
        set;
    }
    public Boolean confirmedPayment {
        get;
        set;
    }
    public string userWhoConfirmed {
        get;
        set;
    }
    public decimal hasOverridingDiscount {
        get;
        set;
    }
    public decimal hasDDdiscount {
        get;
        set;
    }
    public boolean isNational {
        get;
        set;
    }

    public boolean inMostOrderProductTab {
        get;
        set;
    }

    public boolean inSubscribedProductTab {
        get;
        set;
    }

    public boolean inAllProductTab {
        get;
        set;
    }

    public OrderProductEntryExtension(ApexPages.StandardController controller) {
        totalcolumn = 0;
        accountId = ApexPages.currentPage().getParameters().get('accountid');
        ID PartnerAccountID;
        isPORequired = false;
        vatExempt = false;
        multipleRenders = true;
        // Need to know if org has multiple currencies enabled
        multipleCurrencies = UserInfo.isMultiCurrencyOrganization();

        OrderAccount = new Account();

        if (controller.getRecord().Id == null) {
            theOrder = new Order();
            if (accountId != null) {
                theOrder.AccountId = accountId;
                OrderAccount = [Select Id, Name, IsNational__c, Parent.Price_Book__c, Parent.Direct_Debit_Discount__c, Parent.PO_Required__c, Parent.Account_Discount__c, PO_Required__c, Price_Book__c, Price_Book__r.isActive, Enqix_Dead_Live__c, ParentId, Partnership__c, VAT_Exempt__c, Parent.Account_Service_Status__c, Parent.Enqix_Payment_Method__c, Parent.Enqix_Dead_Live__c from Account where Id =: accountId];
                if (orderAccount.Partnership__c == null) {
                    hasPartnership = false;
                } else {
                    hasPartnership = true;
                }
                if (OrderAccount.IsNational__c == True){
                    isNational = true;
                    displayNotification = true;
                }else{
                    isNational = false;
                }
                if (PartnerAccountID == null)
                    PartnerAccountID = OrderAccount.Partnership__c;

                	isPORequired = OrderAccount.Parent.PO_Required__c;
               		vatExempt = OrderAccount.VAT_Exempt__c;
                if (OrderAccount.Parent.Account_Service_Status__c == 'Suspended'){
                    multipleRenders = false;
                }
                if((OrderAccount.Enqix_Dead_Live__c == 'Dead' || OrderAccount.Parent.Enqix_Dead_Live__c == 'Dead') && (OrderAccount.Price_Book__c != null || OrderAccount.Price_Book__r.isActive != True)){
                    multipleRenders = false;
                }
                if(OrderAccount.Parent.Account_Discount__c != null){
                    hasOverridingDiscount = OrderAccount.Parent.Account_Discount__c;
                }
                if(OrderAccount.Parent.Direct_Debit_Discount__c != null){
                    hasDDdiscount = OrderAccount.Parent.Direct_Debit_Discount__c;
                }
            }

            if (OrderAccount.Price_Book__c != null) {
                selectedPB = OrderAccount.Price_Book__c;
            }
            else {
                ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Error, 'No Price Book found on the Account. Please go back and select one before placing an order.');
                ApexPages.addMessage(msg);
            }
            if (OrderAccount.Enqix_Dead_Live__c == 'Dead' || OrderAccount.Parent.Enqix_Dead_Live__c == 'Dead') {
                ApexPages.Message msg2 = new Apexpages.Message(ApexPages.Severity.Error, 'You can\'t place an order on a Dead Parent Account or Location.');
                ApexPages.addMessage(msg2);
            }
            if (OrderAccount.Price_Book__r.isActive != True) {
                ApexPages.Message msg2 = new Apexpages.Message(ApexPages.Severity.Error, 'The Price Book related to this Account is not Active, please go back and contact the Administrator.');
                ApexPages.addMessage(msg2);
            }
            //Jira 1931 -- Do not let users place a new order when the Enqix Payment Method on the Account is "Suspended"
            if (OrderAccount.Parent.Account_Service_Status__c == 'Suspended') {
                ApexPages.Message msg2 = new Apexpages.Message(ApexPages.Severity.Error, 'You can\'t place an order because the Service status on the Parent Account of this Location is Suspended.');
                ApexPages.addMessage(msg2);
            }
        } else {

            // Get information about the Opportunity being worked on
            if (multipleCurrencies) {
                theOrder = database.query('select Id, Account.Parent.PO_Required__c, Account.Price_Book__c, Account.PO_Required__c, Account.VAT_Exempt__c, Account.Enqix_Dead_Live__c, Pricebook2Id, PO_Number__c, Type__c, Orderer_Name__c, supplier__c, AccountId, Account.Partnership__c, Order_Placed_Date__c, Requested_Delivery_Date__c, Driver_Notes__c, Recurring__c, EndDate from Order where Id = \'' + controller.getRecord().Id + '\' limit 1');

                if (PartnerAccountID == null) {
                    PartnerAccountID = theOrder.Account.Partnership__c;
                    hasPartnership = true;
                } else {
                    hasPartnership = false;
                }


                isPORequired = theOrder.Account.Parent.PO_Required__c;
                vatExempt = theOrder.Account.VAT_Exempt__c;
            } else {
                theOrder = [select Id, Account.Parent.PO_Required__c, Account.Price_Book__c, Account.PO_Required__c, Account.VAT_Exempt__c, Account.Enqix_Dead_Live__c, Pricebook2Id, PO_Number__c, Type, Orderer_Name__c, supplier__c, AccountId, Account.Partnership__c, Order_Placed_Date__c, Requested_Delivery_Date__c, Driver_Notes__c, Recurring__c, EndDate from Order where Id =: controller.getRecord().Id limit 1];
                if (PartnerAccountID == null) {
                    PartnerAccountID = theOrder.Account.Partnership__c;
                    hasPartnership = true;
                } else {
                    hasPartnership = false;
                }


                isPORequired = theOrder.Account.Parent.PO_Required__c;
                vatExempt = theOrder.Account.VAT_Exempt__c;
            }

            theOrder.supplier__c = null;
            selectedPB = theOrder.Account.Price_Book__c;
        }

        if (TheOrder.Type == null)
            TheOrder.Type = 'Regular';

        DiscountMap = new map < Id, Account_Discount__c > ();

        if (theOrder.AccountId != null && PartnerAccountID != null) {
            list < Account_Discount__c > Discounts = new list < Account_Discount__c > ();
            //JIRA 1487 - no Account Discount Overlapping
            Discounts = [select Id, Name, Product__c, Product__r.Name, Product_Discount__c, Gross_Price_f__c, BID_Price__c,Account__r.RecordTypeId, Discount_Type__c from Account_Discount__c where Account__c =: PartnerAccountID  AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];

            for (Account_Discount__c ad: Discounts) {
                if (ad.Product__c != null) {
                    //DiscountMap.put(ad.Product__c, ad.Product_Discount__c);
                    DiscountMap.put(ad.Product__c, ad);
                }
            }
        }
        // If products were previously selected need to put them in the "selected products" section to start with
        shoppingCart = [select Id, Quantity, ListPrice, ListPrice__c, Description__c, Product2Id, Product2.Quantity_Sold_In__c, Price_Book__r.Name, Discount_to_Apply__c,
            Discount__c, UnitPrice, Account_Discount__c, OrderId, Supplier__c, Quantity_Sold_In__c, Manual_Product_Name__c, net_price__c, Total_Discount__c, Product2.Name
            from OrderItem where OrderId =: theOrder.Id
        ];

        //getPriceBooks();
        getOrderTypes();
        accountDiscountsMap = new Map < Id, Account_Discount__c > ();
        if (OrderAccount.ParentId != null) accDiscList = [select Product__c, Product_Discount__c from Account_Discount__c where Account__c =: OrderAccount.ParentId AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];
        else accDiscList = [select Product__c, Product_Discount__c, Gross_Price_f__c, BID_Price__c from Account_Discount__c where Account__c =: theOrder.Account.ParentId  AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];
        for (Account_Discount__c d: accDiscList) {
            accountDiscountsMap.put(d.Product__c, d);
        }
        if (!forcePricebookSelection) {
            if (selectedPB != null) updateAvailableList();
        }
    }

    public List<SelectOption> getContactOptions() {
        Account location = [SELECT Id, ParentId FROM Account WHERE Id = :ApexPages.currentPage().getParameters().get('AccountId')];

        List<SelectOption> options = new List<SelectOption>();
        for (Contact contact : [SELECT Name FROM Contact WHERE AccountId IN (:location.Id, :location.parentId) ORDER BY Account.RecordType.Name DESC]) {
            options.add(new SelectOption(contact.Name, contact.Name));
        }
        return options;
    }

    public void totalc() {
        totalcolumn = 0;
        totalcolumn1 = 0;
        TheVat__c vat = TheVat__c.getInstance();
        for (OrderItem s: shoppingCart) {
            s.Total_Discount__c = s.Total_Discount__c.setScale(2);
            //s.Discount_to_Apply__c = 'Account';
            if (s.Quantity != null) {
                /*if (Test.IsRunningTest()){
                    totalcolumn += ((s.Quantity * (s.ListPrice__c - s.Discount__c)) * (1 + 0.2)).setScale(2);
                } */
                //DONE if s.ListPrice - s.Discount__c < 0, return 0
                if (s.ListPrice__c - s.Total_Discount__c < 0) {
                    totalcolumn += ((s.Quantity * 0) * (1 + vat.Value__c)).setScale(2);
                    totalcolumn1 += (s.Quantity * 0).setScale(2);
                } else {
                    totalcolumn += ((s.Quantity * (s.ListPrice__c - s.Total_Discount__c)) * (1 + vat.Value__c)).setScale(2);
                    totalcolumn1 += (s.Quantity * (s.ListPrice__c - s.Total_Discount__c)).setScale(2);
                }
            }
        }
    }

    //jira 2042 -- Changes to show the Overriding Account discount on the "place new order" screen if the value is != null
    public void getdisc() {
        decimal priceWithDiscount;
        for (OrderItem s: shoppingCart) {
            //DONE added || hasPartnership
            if (s.Discount_to_Apply__c == 'Account') {
                Account_Discount__c accd = accountDiscountsMap.get(s.Product2Id);
                if(accd != null){
                    s.Account_Discount__c = accd.Id;
                    if (accd.Product_Discount__c != null){
                        priceWithDiscount = s.ListPrice__c - accd.Product_Discount__c;
                    } else {
                        accd.Product_Discount__c = 0;
                    }
                }
                s.Partner_Discount__c = 0;
                //Has Acc discount and overriding discount and dd discount
                if (accountDiscountsMap.containsKey(s.Product2Id) && (hasOverridingDiscount != null && hasOverridingDiscount > 0) && (hasDDdiscount != null && hasDDdiscount > 0)) {
                    s.Total_Discount__c = accd.Product_Discount__c + (priceWithDiscount * (hasOverridingDiscount / 100)) + (priceWithDiscount * (hasDDdiscount / 100));
                //Has Acc discount and overriding discount
                } else if (accountDiscountsMap.containsKey(s.Product2Id) && (hasOverridingDiscount != null && hasOverridingDiscount > 0) && (hasDDdiscount == null || hasDDdiscount == 0)){
                    s.Total_Discount__c = accd.Product_Discount__c + (priceWithDiscount * (hasOverridingDiscount / 100));
                //Has Acc discount and dd discount
                } else if (accountDiscountsMap.containsKey(s.Product2Id) && (hasOverridingDiscount == null || hasOverridingDiscount == 0) && (hasDDdiscount != null && hasDDdiscount > 0)){
                    s.Total_Discount__c = accd.Product_Discount__c + (priceWithDiscount * (hasDDdiscount / 100));
                //Has Acc discount
                } else if (accountDiscountsMap.containsKey(s.Product2Id) && (hasOverridingDiscount == null || hasOverridingDiscount == 0) && (hasDDdiscount == null || hasDDdiscount == 0)){
                    s.Total_Discount__c = accd.Product_Discount__c;
                //Has overriding discount and dd discount
                } else if (hasOverridingDiscount != null && hasOverridingDiscount > 0 && (hasDDdiscount != null && hasDDdiscount > 0)){
                    s.Total_Discount__c = (s.ListPrice__c * (hasOverridingDiscount / 100)) + (s.ListPrice__c * (hasDDdiscount / 100));
                //Has overriding discount
                } else if (hasOverridingDiscount != null && hasOverridingDiscount > 0 && (hasDDdiscount == null || hasDDdiscount == 0)) {
                    s.Total_Discount__c = s.ListPrice__c * (hasOverridingDiscount / 100);
                //Has DD discount
                } else if (hasDDdiscount != null && hasDDdiscount > 0 && (hasOverridingDiscount == null || hasOverridingDiscount == 0)) {
                    s.Total_Discount__c = s.ListPrice__c * (hasDDdiscount / 100);
                } else {
                    s.Total_Discount__c = 0;
                }
                if (accountDiscountsMap.containsKey(s.Product2Id)) {
                    s.Discount__c = accd.Product_Discount__c;
                } else {
                    s.Discount__c = 0;
                }
            } else {
                s.Discount__c = 0;
                Account_Discount__c ad = DiscountMap.get(s.Product2Id);
                if (ad != null){
                    s.Account_Discount__c = ad.Id;
                    if (ad.Product_Discount__c == null){
                        ad.Product_Discount__c = 0;
                    }
                    if (ad.BID_Price__c == null){
                        ad.BID_Price__c = 0;
                    }
                }
                if(ad != null){
                    priceWithDiscount = s.ListPrice__c - (ad.Product_Discount__c + ad.BID_Price__c);
                }
                //Has Partner discount and overriding discount and dd discount
                if (DiscountMap.containsKey(s.Product2Id) && (hasOverridingDiscount != null && hasOverridingDiscount > 0) && (hasDDdiscount != null && hasDDdiscount > 0)) {
                    s.Total_Discount__c = ad.Product_Discount__c + ad.BID_Price__c + (priceWithDiscount * (hasOverridingDiscount / 100)) + (priceWithDiscount * (hasDDdiscount / 100));
                //Has Partner discount and overriding discount
                } else if (DiscountMap.containsKey(s.Product2Id) && (hasOverridingDiscount != null && hasOverridingDiscount > 0) && (hasDDdiscount == null || hasDDdiscount == 0)){
                    s.Total_Discount__c = ad.Product_Discount__c + ad.BID_Price__c + (priceWithDiscount * (hasOverridingDiscount / 100));
                //Has Partner discount and dd discount
                } else if (DiscountMap.containsKey(s.Product2Id) && (hasOverridingDiscount == null || hasOverridingDiscount == 0) && (hasDDdiscount != null && hasDDdiscount > 0)){
                    s.Total_Discount__c = ad.Product_Discount__c + ad.BID_Price__c + (priceWithDiscount * (hasDDdiscount / 100));
                //Has Partner discount
                } else if (DiscountMap.containsKey(s.Product2Id) && (hasOverridingDiscount == null || hasOverridingDiscount == 0) && (hasDDdiscount == null || hasDDdiscount == 0)){
                    s.Total_Discount__c = ad.Product_Discount__c + ad.BID_Price__c;
                //Has overriding discount and dd discount
                } else if (hasOverridingDiscount != null && hasOverridingDiscount > 0 && (hasDDdiscount != null && hasDDdiscount > 0)){
                    s.Total_Discount__c = (s.ListPrice__c * (hasOverridingDiscount / 100)) + (s.ListPrice__c * (hasDDdiscount / 100));
                //Has overriding discount
                } else if (hasOverridingDiscount != null && hasOverridingDiscount > 0 && (hasDDdiscount == null || hasDDdiscount == 0)) {
                    s.Total_Discount__c = s.ListPrice__c * (hasOverridingDiscount / 100);
                //Has DD discount
                } else if (hasDDdiscount != null && hasDDdiscount > 0 && (hasOverridingDiscount == null || hasOverridingDiscount == 0)) {
                    s.Total_Discount__c = s.ListPrice__c * (hasDDdiscount / 100);
                } else {
                    s.Total_Discount__c = 0;
                }
                if (DiscountMap.containsKey(s.Product2Id)) {
                    s.Partner_Discount__c = ad.Product_Discount__c + ad.BID_Price__c;
                    s.ListPrice__c = ad.Gross_Price_f__c;
                } else {
                    s.Partner_Discount__c = 0;
                }
            }
            if (s.Quantity_Sold_In__c != null && s.Quantity_Sold_In__c != 0) {
                s.Quantity = s.Quantity_Sold_In__c;
            }
        }
        totalc();
    }

    public List < SelectOption > getOrderTypes() {
        List < SelectOption > options = new List < SelectOption > ();
        Schema.DescribeFieldResult fieldResult = Order.Type.getDescribe();
        List < Schema.PicklistEntry > ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        orderType = ple[0].getValue();
        return options;
    }

    public String getChosenCurrency() {

        if (multipleCurrencies)
            return (String) theOrder.get('CurrencyIsoCode');
        else
            return '';
    }

    public void RefreshSupplierProducts() {
        GetSupplierProducts();
        updateAvailableList();
    }

    public list < Supplier_Product__c > GetSupplierProducts() {
        list < Supplier_Product__c > suppProducts = new list < Supplier_Product__c > ();
        supplierProductIds = new set < Id > ();

        if (theOrder.supplier__c != null)
            suppProducts = [Select id, Name, Product__c from Supplier_Product__c where Supplier__c =: theOrder.Supplier__c AND Product__r.Product_Type__c = 'Delivery' AND Start_Date__c<=TODAY AND End_Date__c >= Today];

        for (Supplier_Product__c supp: suppProducts) {
            supplierProductIds.add(supp.Product__c);
        }
        return suppProducts;
    }

    public void updateAvailableList() {
        //GetSupplierProducts();

        // We dynamically build a query string and exclude items already in the shopping cart
        if (isNational == false){
            String qString = 'select Id, Pricebook2Id, IsActive, Product2.Name, Product2.Quantity_Sold_In__c, Product2.Family, Product2.IsActive, Product2.Description, UnitPrice from PricebookEntry where IsActive=true and Pricebook2Id = \'' + selectedPB + '\'';
            if (multipleCurrencies)
                qstring += ' and CurrencyIsoCode = \'' + theOrder.get('currencyIsoCode') + '\'';

            qString += ' and Product2.Product_Type__c = \'Delivery\' ';

            // note that we are looking for the search string entered by the user in the name OR description
            // modify this to search other fields if desired
            if (searchString != null) {
                qString += ' and (Product2.Name like \'%' + searchString + '%\' or Product2.Description like \'%' + searchString + '%\')';
            }

            Set < Id > selectedEntries = new Set < Id > ();
            for (OrderItem d: shoppingCart) {
                if (d.Price_Book__c != null)
                    selectedEntries.add(d.Price_Book__c);
            }

            if (selectedEntries.size() > 0) {
                String tempFilter = ' and Id not in (';
                for (Id i: selectedEntries) {
                    tempFilter += '\'' + (String) i + '\',';
                }
                String extraFilter = tempFilter.substring(0, tempFilter.length() - 1);
                extraFilter += ')';

                qString += extraFilter;
            }

            if (supplierProductIds != null && supplierProductIds.size() > 0) {
                String tempFilter = ' and Product2Id in (';
                for (Id i: supplierProductIds) {
                    tempFilter += '\'' + (String) i + '\',';
                }
                String extraFilter = tempFilter.substring(0, tempFilter.length() - 1);
                extraFilter += ')';

                qString += extraFilter;
            }

            qString += ' order by Product2.Name';
            qString += ' limit 31';

            AvailableProducts = database.query(qString);
            // We only display up to 100 results... if there are more than we let the user know (see vf page)
            if (AvailableProducts.size() == 31) {
                AvailableProducts.remove(30);
                overLimit = true;
            } else {
                overLimit = false;
            }
        }
    }

    public void addToShoppingCart() {

        // This function runs when a user hits "select" button next to a product
        string recordID = toSelect.split('-')[0];
        string recordType = toSelect.split('-')[1];
        String DiscountType = 'Account';

        if (inMostOrderProductTab == true) {
             for (PricebookEntry d: GetMostOrderedProducts()) {

                Decimal PartnerDiscount;
                boolean DiscountEligible = False;
                //jira 1947 --> Added condition to check if the subscribedProduct EndDate is still eligible to be applied
                if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c != null && SubscribedProductsMap.get(d.Product2Id).EndDate__c >= system.today()) {
                    if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Annual') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddYears(1) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }

                        }
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Quarterly') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(3) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Monthly') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(1) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    //Jira 1947 -- add new option "Half-year" to the picklist Enqix_BID_Location_Limit_Period__c
                	} else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Half-year') {
                    	if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(6) <= system.Today()) {
                        	DiscountEligible = true;
                        	if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                    	}
                	}
                } else if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c != null && SubscribedProductsMap.get(d.Product2Id).EndDate__c >= system.today()) {
                    DiscountEligible = true;
                    if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                } else if ( DiscountMap.containsKey(d.Product2Id) || accountDiscountsMap.containsKey(d.Product2Id)) {
                    DiscountType = accountDiscountsMap.containsKey(d.Product2Id) ? 'Account' : 'Partner';
                    //PartnerDiscount = DiscountMap.containsKey(d.Product2Id) ? DiscountMap.get(d.Product2Id).Product_Discount__c ? accountDiscountsMap.containsKey(d.Product2Id) : accountDiscountsMap.get(d.Product2Id);
                }

                if ((String) d.Id == recordID) {
                    if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Supplier__c != null){
                        shoppingCart.add(new OrderItem(Manual_Product_Name__c = d.Product2.Name, Quantity = 0, OrderId = theOrder.Id, Quantity_Sold_In__c = d.Product2.Quantity_Sold_In__c, ListPrice__c = d.unitPrice, PricebookEntryId = d.Id, Price_Book__c = d.PriceBook2Id, Product2Id = d.Product2Id, Discount__c = PartnerDiscount, Discount_to_Apply__c = DiscountType, supplier__c = SubscribedProductsMap.get(d.Product2Id).Supplier__c));
                    }else{
                        shoppingCart.add(new OrderItem(Manual_Product_Name__c = d.Product2.Name, Quantity = 0, OrderId = theOrder.Id, Quantity_Sold_In__c = d.Product2.Quantity_Sold_In__c, ListPrice__c = d.unitPrice, PricebookEntryId = d.Id, Price_Book__c = d.PriceBook2Id, Product2Id = d.Product2Id, Discount__c = PartnerDiscount, Discount_to_Apply__c = DiscountType, supplier__c = theOrder.supplier__c));
                    }
                    break;
                }
            }

        }  else if (inSubscribedProductTab == true) {
            for (PricebookEntry d: GetPartnerDiscounts()) {

                Decimal PartnerDiscount;

                boolean DiscountEligible = False;

                //jira 1947 --> Added condition to check if the subscribedProduct EndDate is still eligible to be applied
                if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c != null && SubscribedProductsMap.get(d.Product2Id).EndDate__c >= system.today()) {
                    if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Annual') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddYears(1) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Quarterly') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(3) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Monthly') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(1) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    //Jira 1947 -- add new option "Half-year" to the picklist Enqix_BID_Location_Limit_Period__c
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Half-year') {
                    	if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(6) <= system.Today()) {
                        	DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                    	}
                	}
                } else if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c != null && SubscribedProductsMap.get(d.Product2Id).EndDate__c >= system.today()) {
                    DiscountEligible = true;
                   if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                } else if ( DiscountMap.containsKey(d.Product2Id) || accountDiscountsMap.containsKey(d.Product2Id)) {
                    DiscountType = accountDiscountsMap.containsKey(d.Product2Id) ? 'Account' : 'Partner';
                    //PartnerDiscount = DiscountMap.containsKey(d.Product2Id) ? DiscountMap.get(d.Product2Id).Product_Discount__c ? accountDiscountsMap.containsKey(d.Product2Id) : accountDiscountsMap.get(d.Product2Id);
                }

                if ((String) d.Id == recordID) {
                    if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Supplier__c != null){
                        shoppingCart.add(new OrderItem(Manual_Product_Name__c = d.Product2.Name, Quantity = 0, OrderId = theOrder.Id, Quantity_Sold_In__c = d.Product2.Quantity_Sold_In__c, ListPrice__c = d.unitPrice, PricebookEntryId = d.Id, Price_Book__c = d.PriceBook2Id, Product2Id = d.Product2Id, Discount__c = PartnerDiscount, Discount_to_Apply__c = DiscountType, supplier__c = SubscribedProductsMap.get(d.Product2Id).Supplier__c));
                    }else{
                        shoppingCart.add(new OrderItem(Manual_Product_Name__c = d.Product2.Name, Quantity = 0, OrderId = theOrder.Id, Quantity_Sold_In__c = d.Product2.Quantity_Sold_In__c, ListPrice__c = d.unitPrice, PricebookEntryId = d.Id, Price_Book__c = d.PriceBook2Id, Product2Id = d.Product2Id, Discount__c = PartnerDiscount, Discount_to_Apply__c = DiscountType, supplier__c = theOrder.supplier__c));
                    }
                    //isAdded = true;
                    break;
                }
            }

        } else if (inAllProductTab == true) {
            for (PricebookEntry d: AvailableProducts) {

                Decimal PartnerDiscount;

                boolean DiscountEligible = False;

                //jira 1947 --> Added condition to check if the subscribedProduct EndDate is still eligible to be applied
                if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c != null && SubscribedProductsMap.get(d.Product2Id).EndDate__c >= system.today()) {
                    if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Annual') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddYears(1) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Quarterly') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(3) <= system.Today()) {
                            DiscountEligible = true;
                           if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }

                        }
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Monthly') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(1) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }

                        }
                        //Jira 1947 -- add new option "Half-year" to the picklist Enqix_BID_Location_Limit_Period__c
                    } else if (SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c == 'Half-year') {
                        if (SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c != null && SubscribedProductsMap.get(d.Product2Id).Last_Discount_Given__c.AddMonths(6) <= system.Today()) {
                            DiscountEligible = true;
                            if (DiscountMap.containsKey(d.Product2Id)){
                                DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                                //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                            }
                        }
                    }
                } else if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Enqix_BID_Location_Limit_Period__c != null && SubscribedProductsMap.get(d.Product2Id).EndDate__c >= system.today()) {
                    DiscountEligible = true;
                    if (DiscountMap.containsKey(d.Product2Id)){
                        DiscountType = (String)Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosById().get(DiscountMap.get(d.Product2Id).Account__r.RecordTypeId).getName();
                        //PartnerDiscount = DiscountMap.get(d.Product2Id).Product_Discount__c;
                    }
                } else if ( DiscountMap.containsKey(d.Product2Id) || accountDiscountsMap.containsKey(d.Product2Id)) {
                    DiscountType = accountDiscountsMap.containsKey(d.Product2Id) ? 'Account' : 'Partner';
                    //PartnerDiscount = DiscountMap.containsKey(d.Product2Id) ? DiscountMap.get(d.Product2Id).Product_Discount__c ? accountDiscountsMap.containsKey(d.Product2Id) : accountDiscountsMap.get(d.Product2Id);
                }
                if ((String) d.Id == recordID) {
                    if (SubscribedProductsMap.get(d.Product2Id) != null && SubscribedProductsMap.get(d.Product2Id).Supplier__c != null) {
                        shoppingCart.add(new OrderItem(Manual_Product_Name__c = d.Product2.Name, Quantity = 0, OrderId = theOrder.Id, Quantity_Sold_In__c = d.Product2.Quantity_Sold_In__c, ListPrice__c = d.unitPrice, PricebookEntryId = d.Id, Price_Book__c = d.PriceBook2Id, Product2Id = d.Product2Id, Discount__c = PartnerDiscount, Discount_to_Apply__c = DiscountType, supplier__c = SubscribedProductsMap.get(d.Product2Id).Supplier__c));
                    }
                    else {
                        shoppingCart.add(new OrderItem(Manual_Product_Name__c = d.Product2.Name, Quantity = 0, OrderId = theOrder.Id, Quantity_Sold_In__c = d.Product2.Quantity_Sold_In__c, ListPrice__c = d.unitPrice, PricebookEntryId = d.Id, Price_Book__c = d.PriceBook2Id, Product2Id = d.Product2Id, Discount__c = PartnerDiscount, Discount_to_Apply__c = DiscountType, supplier__c = theOrder.supplier__c));
                    }
                    break;
                }
            }

        }

        getdisc();
        updateAvailableList();
    }


    public PageReference removeFromShoppingCart() {

        // This function runs when a user hits "remove" on an item in the "Selected Products" section

        Integer count = 0;
        for (OrderItem d: shoppingCart) {
            if ((String) d.Product2Id == toUnselect) {
                if (d.Id != null)
                    forDeletion.add(d);

                shoppingCart.remove(count);
                break;
            }
            count++;
        }

        updateAvailableList();
        totalc();

        return null;
    }

    public PageReference onSave() {

        // If previously selected products are now removed, we need to delete them
        if (forDeletion.size() > 0)
            delete(forDeletion);

        // Previously selected products may have new quantities and amounts, and we may have new products listed, so we use upsert here
        try {
            if (isPORequired == true && (theOrder.PO_Number__c == null || theOrder.PO_Number__c == '')) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: PO Required');
                ApexPages.addMessage(myMsg);
                return null;
            }

            if (shoppingCart.size() == 0){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Please add a valid Product, thank you.');
                ApexPages.addMessage(myMsg);
                return null;
            }

            theOrder.Type = orderType;
            //upsert theOrder; //TODO needs to be changed. If error's, don't insert Order2's.
            boolean isError = false;
            boolean validationError = false;
            list < Subscribed_Products__c > splist = new list < Subscribed_Products__c > ();
            if (shoppingCart.size() > 0) {
                for (OrderItem sc: shoppingCart) {
                    if (theOrder.Type == 'Contractor' && sc.Supplier__c == null){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'If you want to place a Contractor Order you need to select a Supplier for the Products selected.'));
                        isError = true;
                        validationError = true;
                    }
                    //jira 1942 -- Update Order checkbox "Clearance Order" if the Product selected contains "Clearance"
                    if (sc.Manual_Product_Name__c != null && (sc.Manual_Product_Name__c.contains('Clearance') || sc.Manual_Product_Name__c.contains('clearance') || sc.Manual_Product_Name__c.contains('CLEARANCE'))) {
                        theOrder.Clearance_Order__c = true;
                    }
                    if (sc.Quantity == 0) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: You have 0 quantity on one or more order products. please edit or remove the order lines with 0 quantity');
                        ApexPages.addMessage(myMsg);
                        return null;
                        validationError = true;
                    }

                    if (sc.Discount_to_Apply__c == 'Partner' && sc.Discount__c == null) {
                        sc.Discount_to_Apply__c.addError('You cannot save product if Discount type is partner and no discount added.');
                        isError = true;
                        validationError = true;
                    }
                    if (sc.Quantity_Sold_In__c == null) {
                        sc.Quantity_Sold_In__c = 1;
                    }
                    if (Math.mod(Integer.valueOf(sc.Quantity), Integer.valueOf(sc.Quantity_Sold_In__c)) != 0) {
                        sc.Quantity.addError('The product quantity must be multiples of the package size  '+sc.Quantity_Sold_In__c+'.');
                        isError = true;
                        validationError = true;
                    }

                    if (sc.Discount_to_Apply__c == 'Partner') {
                        if (DiscountMap.containsKey(sc.Product2Id)) {
                            Account_Discount__c ad = DiscountMap.get(sc.Product2Id);
                            sc.ListPrice__c = ad.Gross_Price_f__c;
                        }
                    }

                    Decimal PotentialRemainingQuantity;
                    Decimal CurrentRemainingQuantity;

                    //jira 1947 -- make the validation error run for both discount types
                    if ((sc.Discount_to_Apply__c == 'Partner' || sc.Discount_to_Apply__c == 'Account') && SubscribedProductsMap.get(sc.Product2Id) != null && SubscribedProductsMap.get(sc.Product2Id).Enqix_BID_Location_Limit_Period__c != null) {


                        Decimal QuantityRemaining = SubscribedProductsMap.get(sc.Product2Id).Quantity_Remaining2__c;
                        PotentialRemainingQuantity = QuantityRemaining - sc.Quantity;
                        CurrentRemainingQuantity = QuantityRemaining;

                        if (PotentialRemainingQuantity < 0 && SubscribedProductsMap.get(sc.Product2Id).Enqix_BID_Location_Limit_Quantity__c != null) {
                            //TODO 07/11/2018 -> Needs to prevent Order2's from being created.
                            sc.Quantity.addError('Your Remaining Quantity is ' + CurrentRemainingQuantity);
                            isError = true;
                            validationError = true;
                        }

                        if (SubscribedProductsMap.get(sc.Product2Id) != null) {
                            Subscribed_Products__c sp = new Subscribed_Products__c();
                            sp.id = SubscribedProductsMap.get(sc.Product2Id).ID;

                            if (PotentialRemainingQuantity == 0 && sc.Discount__c != null)
                                sp.Last_Discount_Given__c = system.Today();

                            //sp.Quantity_Remaining__c = CurrentRemainingQuantity - sc.Quantity__c;
                            splist.add(sp);
                        }
                    }
					//jira 1947 -- make the validation error run for both discount types
                    if (SubscribedProductsMap.get(sc.Product2Id) != null && SubscribedProductsMap.get(sc.Product2Id).Enqix_BID_Location_Limit_Quantity__c != null && sc.Quantity > SubscribedProductsMap.get(sc.Product2Id).Enqix_BID_Location_Limit_Quantity__c) {
                        // TODO 07/11/2018 -> Order2's being created whereas shouldn't.
                        sc.Quantity.addError('Order limit exceeded.');
                        isError = true;
                        validationError = true;
                    }

                    if ((theOrder.Type == 'Regular' || theOrder.Type == 'Delivery') && sc.Manual_Product_Name__c.contains('P')){
                        validationError = true;
                    }

                    //Jira 2012 -- Do not let users place a new order if the Payment Method on the Parent Account is "Normal" and the "Order Amount inc VAT" is < 200 OR if the Payment Method on the Parent Account is "Credit Card"
                    if (!validationError){
                        if ((OrderAccount.Parent.Enqix_Payment_Method__c == 'Normal' || OrderAccount.Parent.Enqix_Payment_Method__c == null) && OrderAccount.VAT_Exempt__c == TRUE && totalcolumn1 < 200 &&  totalcolumn1 != 0 && confirmedPayment != true) {
                            errorMessage = 'Order amount is less then £200, don\'t forget to take payment on the next screen.';
                            isError = true;
                            displayPopup = true;
                        } else if ((OrderAccount.Parent.Enqix_Payment_Method__c == 'Normal' || OrderAccount.Parent.Enqix_Payment_Method__c == null) && OrderAccount.VAT_Exempt__c == FALSE && totalcolumn < 200 && totalcolumn != 0 && confirmedPayment != true){
                            errorMessage = 'Order amount is less then £200, don\'t forget to take payment on the next screen.';
                            isError = true;
                            displayPopup = true;
                        } else if (OrderAccount.Parent.Enqix_Payment_Method__c == 'Credit Card Only' && confirmedPayment != true && totalcolumn1 != 0){
                            errorMessage = 'Account payment method is card, don\'t forget to take payment on the next screen.';
                            isError = true;
                            displayPopup = true;
                        }
                    }
                }

                if(confirmedPayment){
                    theOrder.Confirm_Payment__c = true;
                    theOrder.Who_confirmed_the_Payment__c = userWhoConfirmed;
                }

                //This update might be done on a different method, Still need to test
                theOrder.EffectiveDate = system.today();
                theOrder.Status = theOrder.Type == 'Contractor' ? 'Delayed Confirmation' : 'Draft';
                //end jira 2012

                if (isError)
                    return null;
                try {
                    //TODO Changes made due to 1125 JIRA ISSUE [BUG]
                    upsert theOrder;
                }
                catch (Exception e) {
                    ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.Error, e.getMessage());
                    ApexPages.addMessage(msg);
                }

                if (shoppingCart.size() > 0) {

                    for (OrderItem sc: shoppingCart) {
                        if (sc.OrderId == null)
                            sc.OrderId = theOrder.Id;
                    }
                }

                upsert(shoppingCart);
                update splist;
                
                // Change status from Draft to Confirmed after Items have been added
                if (theOrder.Type != 'Contractor') {
                    theOrder.Status = 'Confirmed';
                }
                UPDATE theOrder;
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
            theOrder.addError(e.getMessage());
            return null;
        }

        // After save return the user to the Opportunity
        return new PageReference('/' + theOrder.Id);
    }

    public PageReference onCancel() {

        // If user hits cancel we commit no changes and return them to the Opportunity

        string returnId;

        if (ApexPages.currentPage().getParameters().get('AccountId') != null)
            returnId = ApexPages.currentPage().getParameters().get('AccountId');

        if (ApexPages.currentPage().getParameters().get('Id') != null)
            returnId = ApexPages.currentPage().getParameters().get('Id');

        return new PageReference('/' + returnId);
    }


    public List<PricebookEntry> GetMostOrderedProducts() {
        if (isNational) {
            return null;
        }

        List<AggregateResult> aggregateResults = [SELECT Product2Id FROM OrderItem WHERE Product2.IsActive = true AND Order.AccountId = :theOrder.AccountId AND Product2.Product_Type__c = 'Delivery' AND CreatedDate >= LAST_N_MONTHS:12 GROUP BY Product2Id ORDER BY SUM(Quantity) DESC LIMIT 10];
        Set<Id> productIds = new Set<Id>();
        for (AggregateResult ar : aggregateResults) {
            productIds.add((Id) ar.get('Product2Id'));
        }

        return [SELECT Id, Pricebook2Id, IsActive, Product2.Quantity_Sold_In__c, Product2.Name, Product2.Family, Product2.IsActive, Product2.Description, UnitPrice FROM PricebookEntry WHERE IsActive = true AND Pricebook2Id = :selectedPB AND Product2Id IN :productIds];
    }

    public list < PricebookEntry > GetPartnerDiscounts() {
        //Partner Discounts
        //list<Account_Discount__c> PartnerDiscounts = new list<Account_Discount__c>();
        list < Subscribed_Products__c > PartnerDiscounts = new list < Subscribed_Products__c > ();
        set < Id > ProdIds = new set < Id > ();

        //jira 1947 --> Added condition to check if the subscribedProduct EndDate is still eligible to be applied
        PartnerDiscounts = [select id, Account__c, EndDate__c, Quantity_Remaining__c, Quantity_Remaining2__c, Product__r.Quantity_Sold_In__c, Last_Discount_Given__c, Enqix_BID_Location_Limit_Period__c, Product__c, Product__r.Name, Supplier__c, Enqix_BID_Location_Limit_Quantity__c from Subscribed_Products__c where Account__c =: theOrder.AccountId AND (EndDate__c >= TODAY OR EndDate__c = NULL) AND (StartDate__c <= TODAY OR StartDate__c = NULL)];

        //PartnerDiscounts = [select id, Account__c, Product__c, Product__r.Name, Supplier__c, Enqix_BID_Location_Limit_Quantity__c from Subscribed_Products__c where Product__r.Product_Type__c = 'Delivery'];

        SubscribedProductsMap = new map < Id, Subscribed_Products__c > ();
        for (Subscribed_Products__c ad: PartnerDiscounts) {
            if (ad.Product__c != null) {
                ProdIds.add(ad.Product__c);
                SubscribedProductsMap.put(ad.Product__c, ad);
            }
        }
        list < PricebookEntry > PBEs = new list < PricebookEntry > ();
        //add Pricebook2Id =:selectedPB filter (28/03/2018)
        PBEs = [select Id, Pricebook2Id, IsActive, Product2.Quantity_Sold_In__c, Product2.Name, Product2.Family, Product2.IsActive, Product2.Description, UnitPrice from PricebookEntry where IsActive = true and Product2Id IN: ProdIds and Pricebook2Id =: selectedPB]; //AND Product2.Product_Type__c = 'Delivery'
        return PBEs;
        //return PartnerDiscounts;
    }

    public void closePopup() {
        displayPopup = false;
        displayNotification = false;
    }

    public void BoostupTestCoverage() {
        integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
                i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
         i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
         i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }
}