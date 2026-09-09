public with sharing class RecyclingExcelController {

    public string accid {
        get;
        set;
    }
    public Boolean isGroupReport {
        get;
        set;
    }
    public Boolean isPartnerReport {
        get;
        set;
    }
    public Boolean isLinkedReport {
        get;
        set;
    }
    public Boolean isCustomDateRange {
        get;
        set;
    }

    public Account accDetail;
    public string accName {get; set;}
    public date last12Months {get; set;}
    public date lastMonth {get; set;}
    


    public RecyclingReportWrapper reportWrapper {
        get {
            if (reportWrapper == null) {
                string isgroup = Apexpages.currentPage().getParameters().get('isgroup');
                string ispartner = Apexpages.currentPage().getParameters().get('ispartner');
                string islinked = Apexpages.currentPage().getParameters().get('islinked');
                
                reportWrapper = new RecyclingReportWrapper(accid,
                    (isgroup == 'true' ? true : false),
                    (ispartner == 'true' ? true : false),
                    (islinked == 'true' ? true : false)
                );
                system.debug('::'+reportWrapper.mapMaterialRecycled);
            }
            return reportWrapper;
        }
        private set;
    }
    /*
    public decimal MixedRecycling {get; set;}
    public decimal GeneralWaste {get; set;}
    public decimal Food {get; set;}
    public decimal Coffee {get; set;}
    public decimal Clearances {get; set;}
    public decimal Glass {get; set;}
    public decimal Paper {get; set;}
    public decimal WEEEandToner {get; set;}
    */
    public decimal TotalRecycling {get; set;}
    
    public RecyclingExcelController() {
        accid = Apexpages.currentPage().getParameters().get('id');
        //ApexPages.currentPage().getParameters().put('DateRange', string.valueOf(date.today().addYears(-2)));

        if (accid != null){
            accDetail = [Select Id, Name, Report_Date__c from Account where Id =: accid];
            accName = accDetail.Name;
        }
        RetreiveRecycleInformation();
    }


    public void RetreiveRecycleInformation() {
        string isRange = Apexpages.currentPage().getParameters().get('isCustomRange');
        string DateRange = Apexpages.currentPage().getParameters().get('DateRange');


        Date DateRange_x;
        DateRange_x = date.valueOf(DateRange);
        last12Months = DateRange_x.addMonths(-12).toStartOfMonth();
        lastMonth = DateRange_x.toStartOfMonth().addDays(-1);

        //get all Order Item related Accounts in last 12 months
        List < OrderItem > lstOrderItems = [Select WTE_KG_Order_Line__c,
            Trees_Saved_Order_Line__c,
            Total_KG_Order_Line__c,
            Tonnes_CO2_Saved_Order_Line__c,
            AD_KG_Order_Line__c,
            KWH_Produced_Order_Line__c,
            Recycled_KG_Order_Line__c,
            PricebookEntry.Product2.Report_Groupings__c,
            Order.Delivery_Date__c,
            ProductCategory__c
            From OrderItem
            Where Order.Delivery_Date__c != null
            AND Order.Delivery_Date__c >=: last12Months
            AND Order.Delivery_Date__c <=: lastMonth
            AND Order.AccountId =: accid
            AND PricebookEntry.Product2.Report_Groupings__c != null
        ];
        
        //system.debug('Select WTE_KG_Order_Line__c, Trees_Saved_Order_Line__c, Total_KG_Order_Line__c,Tonnes_CO2_Saved_Order_Line__c,AD_KG_Order_Line__c,KWH_Produced_Order_Line__c, Recycled_KG_Order_Line__c,PricebookEntry.Product2.Report_Groupings__c,Order.Delivery_Date__c,ProductCategory__c From OrderItem Where Order.Delivery_Date__c != null AND Order.Delivery_Date__c >= '+last12Months+' AND Order.Delivery_Date__c <='+ lastMonth+' AND Order.AccountId ='+ accid+' AND PricebookEntry.Product2.Report_Groupings__c != null');
        /*
        Map < string, list < OrderItem >> itemsMap = new Map < string, list < OrderItem >> ();
        for (OrderItem item: lstOrderItems) {
            if (itemsMap.containsKey(item.PricebookEntry.Product2.Report_Groupings__c)) {
                list < OrderItem > temp = itemsMap.get(item.PricebookEntry.Product2.Report_Groupings__c);
                temp.add(item);
                itemsMap.put(item.PricebookEntry.Product2.Report_Groupings__c, temp);
            } else {
                list < OrderItem > temp = new list < OrderItem > ();
                temp.add(item);
                itemsMap.put(item.PricebookEntry.Product2.Report_Groupings__c, temp);
            }
        }
        */
        /*
        MixedRecycling = 0;
        GeneralWaste = 0;
        Food = 0;
        Coffee = 0;
        Clearances = 0;
        Glass = 0;
        Paper = 0;
        WEEEandToner = 0;
        */
        TotalRecycling = 0;
        //decimal TotalWaste = 0;
        //decimal TotalAnaerobic = 0;
        
        /*
        set<string> groupings = new set<string>();
        groupings.add('Mixed Recycling');
        groupings.add('General Waste');
        groupings.add('Food');
        groupings.add('Coffee Grounds');
        groupings.add('Clearances');
        groupings.add('Glass');
        groupings.add('Paper shredding');
        groupings.add('WEEE');
        groupings.add('Toner Sack');
        */
        /*
        for (OrderItem item: lstOrderItems) {
            if(item.ProductCategory__c == 'Mixed Recycling')
            MixedRecycling += item.Recycled_KG_Order_Line__c;
            else if (item.ProductCategory__c == 'General Waste')
            GeneralWaste += item.WTE_KG_Order_Line__c;
            else if(item.ProductCategory__c == 'Food')
            Food += item.AD_KG_Order_Line__c;
            else if(item.ProductCategory__c == 'Coffee Grounds')
            Coffee += item.Recycled_KG_Order_Line__c;
            else if(item.ProductCategory__c == 'Clearances')
            Clearances += item.Recycled_KG_Order_Line__c;
            else if(item.ProductCategory__c == 'Glass')
            Glass += item.Recycled_KG_Order_Line__c;
            else if(item.ProductCategory__c == 'Paper shredding')
            Paper += item.Recycled_KG_Order_Line__c;
            else if(item.ProductCategory__c == 'WEEE' || item.ProductCategory__c == 'Toner Sack')
            WEEEandToner += item.Recycled_KG_Order_Line__c;
        }
        */
        //TotalRecycling += MixedRecycling + Coffee + Clearances + Glass + Paper + WEEEandToner;
        list<string> groupings = new list<string>();
        groupings.add('weee and toner');
        groupings.add('cardboard');
        groupings.add('junk removal');
        //groupings.add('food recycling');
        groupings.add('paper shredding');
        //groupings.add('general waste');
        groupings.add('glass');
        groupings.add('mixed recycling');
        //groupings.add('stationery and textiles');
        groupings.add('coffee grounds');
        
        for(string ss: groupings){
          TotalRecycling += reportWrapper.mapMaterialRecycled.get(ss);  
        }
    }

}