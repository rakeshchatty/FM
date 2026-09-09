/**
* Class wrapper for reporting
* @createdDate 15-Aug-2016
* @author Sopha Pum
*/
public class RecyclingReportWrapper {
    public List<String> lstMonths {get;set;}
    public List<String> lstKeyMonths {get;set;}
    public Map<String, Decimal> mapRecycledLast12Months {get;set;}
    public Map<String, Decimal> mapAnerobicLast12Months {get;set;}
    public Map<String, Decimal> mapWastesLast12Months {get;set;}
    public Map<String, Decimal> mapRecyclingLast12Months {get;set;}
    public Map<String, Decimal> mapTotalLast12Months {get;set;}
    public Map<String, Decimal> mapMaterialRecycled {get;set;}
    
    public Decimal treeSaveLast12m {get;set;} 
    public Decimal co2Last12m {get;set;}
    public Decimal kwhLast12m {get;set;}
    public Decimal recycledLast12m {get;set;}
    public Decimal recyclingRateLast12m {get;set;}
    public Decimal adLast12m {get;set;}
    public Decimal wteLast12m {get;set;}
    
    public Decimal treeSaveThisMonth {get;set;}
    public Decimal co2ThisMonth {get;set;}
    public Decimal kwhThisMonth {get;set;}
    public Decimal recycledThisMonth {get;set;}
    public Decimal recyclingRateThisMonth {get;set;}
    public Decimal adThisMonth {get;set;}
    public Decimal wteThisMonth {get;set;}
    
    //for dashboard
    public Decimal treeSaveDBThisMonth {get;set;}
    public Decimal co2DBThisMonth {get;set;}
    public Decimal kwhDBThisMonth {get;set;}
    public Decimal recycledDBThisMonth {get;set;}
    public Decimal recyclingRateDBThisMonth {get;set;}
    public Decimal adDBThisMonth {get;set;}
    public Decimal wteDBThisMonth {get;set;}
    
    
    public String chartURL {get;set;}
    
    private String accid;
    private Set<ID> accids;
    private static String googleChartEndpoint = 'http://chart.googleapis.com/chart?';
    public RecyclingReportWrapper(String accid, Boolean isGroup){
        
    }
    public RecyclingReportWrapper(String accid, Boolean isGroup, Boolean isPartner, Boolean isLinked){
        this.accid = accid;
        this.accids = new Set<ID>();
        if(isGroup){
            accids.addall(getAllAccountChildren());
        }
        if(isPartner){
            accids.addall(getAllAccountPartner());
        }
        if(isLinked){
            accids.addall(getAllAccountLinked());
        }
        if(!isPartner)
        accids.add(accid);
        init();
    }
    
    /**
    * Method to get all children Account to aggregate date
    */
    private Set<ID> getAllAccountChildren(){
        Map<ID, Account> mapAccounts = new Map<ID, Account>([Select Id From Account Where ParentId=: accid]);
        return mapAccounts.keySet();
    }
    
    /**
    * Method to get all Partnership Account to aggregate date
    */
    private Set<ID> getAllAccountPartner(){
        Map<ID, Account> mapAccounts = new Map<ID, Account>([Select Id From Account Where Partnership__c=: accid]);
        return mapAccounts.keySet();
    }
    
    /**
    * Method to get all Linked Account to aggregate date
    */
    private Set<ID> getAllAccountLinked(){
        Map<ID, Account> mapAccounts = new Map<ID, Account>([Select Id From Account Where Linked_Group__c=: accid]);
        return mapAccounts.keySet();
    }
    
    public String isRange {get; set;}
    public Date last12Months {get; set;}
    public Date lastMonth {get; set;}
        
    private void init(){
        isRange = Apexpages.currentPage().getParameters().get('isCustomRange');
        string DateRange = Apexpages.currentPage().getParameters().get('DateRange');
        
        Account acc = [Select Id, Name, Report_Date__c from Account where Id =:accid];
        
        Date DateRange_x;
        if(DateRange != null)
        DateRange_x = date.valueOf(DateRange);
        else if(acc.Report_Date__c != null)
        DateRange_x = acc.Report_Date__c;
        else
        DateRange_x = System.today();
        //Date last12Months;
        //Date lastMonth;
        
        if(isRange == 'true'){
            //&& acc.Report_Date__c != null
            
            last12Months = DateRange_x.addMonths(-12).toStartOfMonth();
            lastMonth = DateRange_x.toStartOfMonth().addDays(-1);
            
            //last12Months = acc.Report_Date__c.addMonths(-12).toStartOfMonth();
            //lastMonth = acc.Report_Date__c.toStartOfMonth().addDays(-1);
        }else{
            isRange = 'false';
            last12Months = System.today().addMonths(-12).toStartOfMonth();
            lastMonth = System.today().toStartOfMonth().addDays(-1);//always start this report a month behind
        }
        
        system.debug('acc Ids:: '+accids);
        system.debug('last12Months:: '+last12Months);
        system.debug('lastMonth:: '+lastMonth);
        //get all Order Item related Accounts in last 12 months
        List<OrderItem> lstOrderItems = [Select WTE_KG_Order_Line__c, 
                                                Trees_Saved_Order_Line__c, 
                                                Total_KG_Order_Line__c, 
                                                Tonnes_CO2_Saved_Order_Line__c, 
                                                AD_KG_Order_Line__c, 
                                                KWH_Produced_Order_Line__c,
                                                Recycled_KG_Order_Line__c, 
                                                AD_KG_from_Weights__c,
                                                Coffee_KG_from_Weights__c,
                                                KWH_Produced_from_Weights__c,
                                                Recycled_KG_from_Weights__c,
                                                Tonnes_CO2_Saved_from_Weights__c,
                                                Total_KG_from_Weights__c,
                                                Trees_Saved_from_Weights__c,
                                                WTE_KG_from_Weights__c,
                                                PricebookEntry.Product2.Report_Groupings__c, 
                                                Order.Delivery_Date__c 
                                            From OrderItem
                                            Where Order.Delivery_Date__c != null
                                                AND Order.Delivery_Date__c >=: last12Months
                                                AND Order.Delivery_Date__c <=: lastMonth
                                                AND Order.AccountId in: accids
                                                AND PricebookEntry.Product2.Report_Groupings__c != null];
        //system.debug('Select WTE_KG_Order_Line__c, Trees_Saved_Order_Line__c, Total_KG_Order_Line__c, Tonnes_CO2_Saved_Order_Line__c, AD_KG_Order_Line__c, KWH_Produced_Order_Line__c,Recycled_KG_Order_Line__c, PricebookEntry.Product2.Report_Groupings__c, Order.Delivery_Date__c From OrderItem Where Order.Delivery_Date__c != null AND Order.Delivery_Date__c >='+ last12Months+' AND Order.Delivery_Date__c <='+ lastMonth+' AND Order.AccountId in '+ accids +' AND PricebookEntry.Product2.Report_Groupings__c != null');                                        
        system.debug('Select WTE_KG_Order_Line__c, Trees_Saved_Order_Line__c, Total_KG_Order_Line__c, Tonnes_CO2_Saved_Order_Line__c, AD_KG_Order_Line__c, KWH_Produced_Order_Line__c,Recycled_KG_Order_Line__c, AD_KG_from_Weights__c,Coffee_KG_from_Weights__c,KWH_Produced_from_Weights__c,Recycled_KG_from_Weights__c,Tonnes_CO2_Saved_from_Weights__c,Total_KG_from_Weights__c,Trees_Saved_from_Weights__c,WTE_KG_from_Weights__c,PricebookEntry.Product2.Report_Groupings__c, Order.Delivery_Date__c From OrderItemWhere Order.Delivery_Date__c != null AND Order.Delivery_Date__c >= '+last12Months + ' AND Order.Delivery_Date__c <= '+lastMonth+' AND Order.AccountId IN '+accids+' AND PricebookEntry.Product2.Report_Groupings__c != null');
        String keyThisMonth = System.now().addMonths(-1).format('MM_yyyy').toLowerCase(); //-1 for this month because we use only previous month to report                      
        
        treeSaveLast12m = 0;
        co2Last12m = 0;
        kwhLast12m = 0;
        recycledLast12m = 0;
        recyclingRateLast12m = 0;
        adLast12m = 0;
        wteLast12m = 0;
        
        treeSaveThisMonth = 0;
        co2ThisMonth = 0;
        kwhThisMonth = 0;
        recycledThisMonth = 0;
        recyclingRateThisMonth = 0;
        adThisMonth = 0;
        wteThisMonth = 0;
        
        treeSaveDBThisMonth = 0;
        co2DBThisMonth = 0;
        kwhDBThisMonth = 0;
        recycledDBThisMonth = 0;
        recyclingRateDBThisMonth = 0;
        adDBThisMonth = 0;
        wteDBThisMonth = 0;
    
        mapRecycledLast12Months = new Map<String, Decimal>();
        mapAnerobicLast12Months = new Map<String, Decimal>();
        mapWastesLast12Months   = new Map<String, Decimal>();
        mapRecyclingLast12Months= new Map<String, Decimal>();
        mapTotalLast12Months = new Map<String, Decimal>();
        Map<String, Decimal> mapSumTotalKG = new Map<String, Decimal>();
        Map<String, Decimal> mapKWHLast12m = new Map<String, Decimal>();
        Map<String, Decimal> mapCO2Last12m = new Map<String, Decimal>();
        Map<String, Decimal> mapTreeSaveLast12m = new Map<String, Decimal>();
        
        Set<String> keyMonthExisted = new Set<String>();
        Decimal maxvAxis = 0;
        mapMaterialRecycled = new Map<String, Decimal>();
        
        //get all value in Report Grouping field
        Schema.DescribeFieldResult fieldResult = Product2.Report_Groupings__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple) {
            //4) Remove Stationary and Textiles in the report (just comment this out in case they want it back)
            if(f.getValue().equalsIgnoreCase('Stationery and Textiles')) continue;
            
            mapMaterialRecycled.put(f.getValue().toLowerCase(), 0);
        }
        
        //sum value for each month
        for(OrderItem oi: lstOrderItems)
        {
            Datetime month_dt = Datetime.newInstance(oi.Order.Delivery_Date__c.year(), oi.Order.Delivery_Date__c.month(), oi.Order.Delivery_Date__c.day());
            String keyMonth = month_dt.format('MM_yyyy').toLowerCase();
            keyMonthExisted.add(keyMonth);
            
            Decimal oldRecycledVal = mapRecycledLast12Months.containsKey(keyMonth) ? mapRecycledLast12Months.get(keyMonth): 0;
            Decimal oldAnerobicVal = mapAnerobicLast12Months.containsKey(keyMonth) ? mapAnerobicLast12Months.get(keyMonth): 0;
            Decimal oldWastesVal = mapWastesLast12Months.containsKey(keyMonth) ? mapWastesLast12Months.get(keyMonth): 0;
            Decimal oldKWHVal = mapKWHLast12m.containsKey(keyMonth) ? mapKWHLast12m.get(keyMonth): 0;
            Decimal oldCO2Val = mapCO2Last12m.containsKey(keyMonth) ? mapCO2Last12m.get(keyMonth): 0;
            Decimal oldTreeSaveVal = mapTreeSaveLast12m.containsKey(keyMonth) ? mapTreeSaveLast12m.get(keyMonth): 0;
            Decimal oldTotalKG = mapSumTotalKG.containsKey(keyMonth) ? mapSumTotalKG.get(keyMonth): 0;
            
            mapRecycledLast12Months.put(keyMonth, oldRecycledVal + (oi.Recycled_KG_Order_Line__c == null && oi.Recycled_KG_from_Weights__c == null ? 0 : (oi.Recycled_KG_from_Weights__c == null ? oi.Recycled_KG_Order_Line__c : oi.Recycled_KG_from_Weights__c)));
            mapAnerobicLast12Months.put(keyMonth, oldAnerobicVal + (((oi.AD_KG_Order_Line__c == null || oi.AD_KG_Order_Line__c < 0) && (oi.AD_KG_from_Weights__c == null || oi.AD_KG_from_Weights__c < 0) ) ? 0 : (oi.AD_KG_from_Weights__c == null ? oi.AD_KG_Order_Line__c : oi.AD_KG_from_Weights__c)));
            mapWastesLast12Months.put(keyMonth, oldWastesVal + (((oi.WTE_KG_Order_Line__c == null || oi.WTE_KG_Order_Line__c < 0) && (oi.WTE_KG_from_Weights__c == null || oi.WTE_KG_from_Weights__c < 0)) ? 0 : (oi.WTE_KG_from_Weights__c == null ? oi.WTE_KG_Order_Line__c : oi.WTE_KG_from_Weights__c)));
            mapKWHLast12m.put(keyMonth, oldKWHVal + (oi.KWH_Produced_Order_Line__c == null && oi.KWH_Produced_from_Weights__c == null ? 0 : (oi.KWH_Produced_from_Weights__c == null ? oi.KWH_Produced_Order_Line__c : oi.KWH_Produced_from_Weights__c)));
            mapCO2Last12m.put(keyMonth, oldCO2Val + (oi.Tonnes_CO2_Saved_Order_Line__c == null && oi.Tonnes_CO2_Saved_from_Weights__c == null ? 0 : (oi.Tonnes_CO2_Saved_from_Weights__c == null ? oi.Tonnes_CO2_Saved_Order_Line__c : oi.Tonnes_CO2_Saved_from_Weights__c)));
            mapTreeSaveLast12m.put(keyMonth, oldTreeSaveVal + (oi.Trees_Saved_Order_Line__c == null && oi.Trees_Saved_from_Weights__c == null ? 0 : (oi.Trees_Saved_from_Weights__c == null ? oi.Trees_Saved_Order_Line__c : oi.Trees_Saved_from_Weights__c)));
            mapSumTotalKG.put(keyMonth, oldTotalKG + (oi.Total_KG_Order_Line__c == null && oi.Total_KG_from_Weights__c == null ? 0 : (oi.Total_KG_from_Weights__c == null ? oi.Total_KG_Order_Line__c : oi.Total_KG_from_Weights__c)));
            
            //sum value for each Report Grouping
            String keyProReportGroup = oi.PricebookEntry.Product2.Report_Groupings__c.toLowerCase();
            
            //4) Remove Stationary and Textiles in the report (just comment this out in case they want it back)
            if(keyProReportGroup != null && keyProReportGroup.equalsIgnoreCase('Stationery and Textiles')) continue;
            
            //Decimal newVal = keyProReportGroup.equalsIgnoreCase('Food Recycling') || keyProReportGroup.equalsIgnoreCase('Coffee Grounds') ? oi.AD_KG_Order_Line__c : (keyProReportGroup.equalsIgnoreCase('General Waste') ? oi.WTE_KG_Order_Line__c: oi.Recycled_KG_Order_Line__c);
            Decimal newVal = keyProReportGroup.equalsIgnoreCase('Food Recycling') || keyProReportGroup.equalsIgnoreCase('Coffee Grounds') ? (oi.AD_KG_from_Weights__c == null ? oi.AD_KG_Order_Line__c : oi.AD_KG_from_Weights__c) : (keyProReportGroup.equalsIgnoreCase('General Waste') ? (oi.WTE_KG_from_Weights__c == null ? oi.WTE_KG_Order_Line__c : oi.WTE_KG_from_Weights__c) : (oi.Recycled_KG_from_Weights__c == null ? oi.Recycled_KG_Order_Line__c : oi.Recycled_KG_from_Weights__c));
            newVal = newVal == null ? 0: newVal;
            Decimal oldVal = mapMaterialRecycled.containsKey(keyProReportGroup) ? mapMaterialRecycled.get(keyProReportGroup) : 0;
            Decimal totalval = oldVal + newVal;
            totalval = totalval.round();
            if(totalval < 0)
            totalval = 0;
            mapMaterialRecycled.put(keyProReportGroup, totalval);
            
        }

        
        for(String keyMonth: mapRecycledLast12Months.keySet()){ //keyMonth = MM_yyyy
            Decimal totalValRecycled    = mapRecycledLast12Months.get(keyMonth);
            Decimal totalValAD          = mapAnerobicLast12Months.get(keyMonth);
            
            //1) "global" controlling fields to provide a percentage increase or decrease for particular months
            //We would like the ability to override the calculations on a month by month basis for each value in the report. 
            //So for example: June 2016... Total Recycled +15% would add 15% to the value Total Recycled for all reports sent. 
            //We wouldn't store the increased value, just display it on the report
            ReportPercentEachMonth__c reportPercent = ReportPercentEachMonth__c.getValues(keyMonth);
            if(reportPercent != null && reportPercent.Percentage__c != null){
                Decimal percent2InDe;
                Decimal totalValWTE = mapWastesLast12Months.get(keyMonth);
                if(reportPercent.Percentage__c >= 0){
                    percent2InDe = reportPercent.Percentage__c;
                }
                else
                {
                    percent2InDe = 0;
                }
                
                Decimal val2InDec = totalValRecycled * (percent2InDe/100);
                totalValRecycled = totalValRecycled + val2InDec;
                mapRecycledLast12Months.put(keyMonth, totalValRecycled);
                
                //it should also affect Anaerobic Digestion and Waste to Energy. 
                Decimal valAd2Update = totalValAD * (percent2InDe/100);
                totalValAD = totalValAD + valAd2Update;
                if(totalValAD < 0 )
                totalValAD = 0;
                mapAnerobicLast12Months.put(keyMonth, totalValAD);
                
                //for Waste to Energy. 
                Decimal valWTE2Update = totalValWTE * (percent2InDe/100);
                totalValWTE = totalValWTE + valWTE2Update;
                if(totalValWTE < 0)
                totalValWTE = 0;
                mapWastesLast12Months.put(keyMonth, totalValWTE);
                
            }
            //Recycling Rate formula
            //[8/12/16, 3:44:19 PM] Matthew Schutz: total recycling rate would be 
            //(Recycled KG + Recycled KG + Recycled KG + Recycled KG + Recycled KG) / (Total KG+ Total KG+ Total KG+ Total KG+ Total KG+
            //[8/12/16, 3:44:34 PM] Matthew Schutz: so sum of Ryclyced for all orders divided by total KG for all orders
            
            
            Decimal totalValWTE = mapWastesLast12Months.get(keyMonth);
          
               /* System.debug('Total Rate ?? ' + totalRate);
                System.debug('(totalValRecycled/ (totalvalrecyced+totalValWTE)' + totalValRecycled + '/'
                            + totalValRecycled + '+' + totalValWTE); */
            
            //[7:10:54 PM] Matthew Schutz: The recycling rate should = recycled + AD divided by total.  Which in the below case is 90+%
            Decimal totalKG = mapSumTotalKG.get(keyMonth);
            /*if((totalValRecycled + totalValWTE) != 0){
              Decimal totalRate = (totalKG == 0 ? 0: ((totalValRecycled/(totalValRecycled + totalValWTE)))); 
              totalRate = totalRate > 1 ? 1: totalRate;
              mapRecyclingLast12Months.put(keyMonth, totalRate);
            }
            else{
                Decimal totalRate = 0;
                mapRecyclingLast12Months.put(keyMonth, totalRate);
            }*/
            //BEN ALINGTON
            //
            // Decimal totalRate = (totalKG == 0 ? 0: ((totalValRecycled/(totalValRecycled + totalValWTE))));
            
            if((totalValRecycled + totalValAD + totalValWTE) == 0){
                Decimal totalRate = 0;
                mapRecyclingLast12Months.put(keyMonth, totalRate);
            }else{
                Decimal totalRate = (totalKG == 0 ? 0: ((totalValRecycled + totalValAD)/(totalValRecycled + totalValAD + totalValWTE)));
                totalRate = totalRate > 1 ? 1: totalRate; //avoid value greater than 100%, it can happened when creating data test incorrect
                if(totalRate < 0)
                totalRate = 0;
                mapRecyclingLast12Months.put(keyMonth, totalRate);
            }
            
            
            //total last 12 months
            treeSaveLast12m += mapTreeSaveLast12m.get(keyMonth);
            co2Last12m      += mapCO2Last12m.get(keyMonth);
            kwhLast12m      += mapKWHLast12m.get(keyMonth);
            recycledLast12m += mapRecycledLast12Months.get(keyMonth);
            adLast12m       += mapAnerobicLast12Months.get(keyMonth);
            wteLast12m      += mapWastesLast12Months.get(keyMonth);
        }
        
        //total this month (this month = previous month of the current month)
        if(mapRecycledLast12Months.containsKey(keyThisMonth)){
            treeSaveThisMonth   = mapTreeSaveLast12m.get(keyThisMonth);
            co2ThisMonth        = mapCO2Last12m.get(keyThisMonth);
            kwhThisMonth        = mapKWHLast12m.get(keyThisMonth);
            recycledThisMonth   = mapRecycledLast12Months.get(keyThisMonth);
            adThisMonth         = mapAnerobicLast12Months.get(keyThisMonth);
            wteThisMonth        = mapWastesLast12Months.get(keyThisMonth);
            recyclingRateThisMonth = mapRecyclingLast12Months.get(keyThisMonth);
        }
        
        //get last 12 months (include this month)
        lstMonths = new List<String>();
        lstKeyMonths = new List<String>();
        String last12MonthsLabel = '';
        String recycledData = '';
        String adData = '';
        String wteData = '';
        String recyclingRateData = '';
        Decimal totalRecycled = 0;
        Decimal totalAD = 0;
        Decimal totalWTE = 0;
        Decimal totalRecyclingRate = 0;
        Decimal totalTotalKG = 0;
        
        lastMonth = lastMonth.toStartOfMonth().addDays(10);//to avoid error Salesforce method month format
        for(Integer i=-11; i<=0; i++){
            
            Datetime month_dt = Datetime.newInstance(lastMonth.year(), lastMonth.month(), lastMonth.day());
            
            String month_val =  month_dt.addMonths(i).format('MMM');
            
            last12MonthsLabel += month_val + '|';
            
            //put data as format Recycled|Anerobic Digestion|Wastes to Energy|Recycling Rate
            String keyMonth = month_dt.addMonths(i).format('MM_yyyy');
            lstMonths.add(month_val);
            lstKeyMonths.add(keyMonth);
            
            if(!keyMonthExisted.contains(keyMonth)){
                mapRecycledLast12Months.put(keyMonth, 0);
                mapAnerobicLast12Months.put(keyMonth, 0);
                mapWastesLast12Months.put(keyMonth, 0);
                mapRecyclingLast12Months.put(keyMonth, 0);
                mapSumTotalKG.put(keyMonth, 0);
            }
            
            Decimal recycledVal = mapRecycledLast12Months.get(keyMonth);
            Decimal adVal = mapAnerobicLast12Months.get(keyMonth);
            Decimal wteVal = mapWastesLast12Months.get(keyMonth);
            Decimal recyclingRateVal = mapRecyclingLast12Months.get(keyMonth);
            
            //to set max axis
            maxvAxis = maxvAxis < recycledVal ? recycledVal : maxvAxis;
            maxvAxis = maxvAxis < adVal ? adVal : maxvAxis;
            maxvAxis = maxvAxis < wteVal ? wteVal : maxvAxis;
            
            //to put in string for request to google chart image
            recycledData += recycledVal.stripTrailingZeros().toPlainString() + ',';
            adData += adVal.stripTrailingZeros().toPlainString() + ',';
            wteData += wteVal.stripTrailingZeros().toPlainString() + ',';
            recyclingRateData += recyclingRateVal.stripTrailingZeros().toPlainString() + ','; 
            
            totalRecycled += recycledVal;
            totalAD += adVal;
            totalWTE += wteVal;
            totalTotalKG += mapSumTotalKG.get(keyMonth);
            
        }
        //BEN ALLINGTON
        /*
        if((totalRecycled + totalWTE) !=0){
            totalRecyclingRate = totalTotalKG == 0 ? 0: (totalRecycled/(totalRecycled + totalWTE));
            totalRecyclingRate = totalRecyclingRate > 1 ? 1: totalRecyclingRate;
            recyclingRateLast12m = totalRecyclingRate;
        }
        else{
            recyclingRateLast12m = 0;
        }
        */
        //totalRecyclingRate = totalTotalKG == 0 ? 0: (totalRecycled/(totalRecycled + totalWTE));
        //
        if((totalRecycled + totalAD + totalWTE) == 0){
            recyclingRateLast12m = 0;
        }else{
            totalRecyclingRate = totalTotalKG == 0? 0: (totalRecycled + totalAD)/(totalRecycled + totalAD + totalWTE);
            totalRecyclingRate = totalRecyclingRate > 1 ? 1: totalRecyclingRate;
            recyclingRateLast12m = totalRecyclingRate; 
        }
        
        totalRecycled = totalRecycled.round();
        totalAD = totalAD.round();
        totalWTE = totalWTE.round();
        
        
        maxvAxis = fillupNumber(maxvAxis);
        
        if(totalRecycled < 0)
        totalRecycled = 0;
        if(totalAD < 0)
        totalAD = 0;
        if(totalWTE < 0)
        totalWTE = 0;
        if(totalRecyclingRate < 0)
        totalRecyclingRate = 0;
        
        //put total Materual collected
        mapTotalLast12Months.put(CompoundChartController.RECYCLED, totalRecycled);
        mapTotalLast12Months.put(CompoundChartController.AD_KG, totalAD);
        mapTotalLast12Months.put(CompoundChartController.WTE_KG, totalWTE);
        mapTotalLast12Months.put(CompoundChartController.RECYCLING_RATE, totalRecyclingRate);
        
        
        
        //Only Monthly Dashboard
        //The THIS MONTH figures for the dashboard should be the last 12 months orders divided by 12.
        //Some bag customers only order every few months or less often, so the ‘this month’ needs to be a blended average.
        treeSaveDBThisMonth = treeSaveLast12m / 12;
        co2DBThisMonth = co2Last12m / 12;
        kwhDBThisMonth = kwhLast12m / 12;
        recycledDBThisMonth = recycledLast12m / 12;
        adDBThisMonth = adLast12m / 12;
        wteDBThisMonth = wteLast12m /12;
        Decimal totalDBTotalKG = totalTotalKG/12;
        
        
        //Currently this is dividing the 12 month recycling rate by 12.  That won’t work for a %.
        //It needs to be the same as the 12 month recycling % number.  
        recyclingRateDBThisMonth = totalDBTotalKG == 0 ? 0 : (recycledDBThisMonth + adDBThisMonth ) / totalDBTotalKG;
        recyclingRateDBThisMonth = recyclingRateDBThisMonth > 1 ? 1 : recyclingRateDBThisMonth;
        
        //round value
        treeSaveThisMonth = treeSaveThisMonth.round();
        if(treeSaveThisMonth < 0)
        treeSaveThisMonth = 0;
        co2ThisMonth = co2ThisMonth.round();
        if(co2ThisMonth < 0)
        co2ThisMonth = 0;
        kwhThisMonth = kwhThisMonth.round();
        if(kwhThisMonth < 0)
        kwhThisMonth = 0;
        recycledThisMonth = recycledThisMonth.round();
        adThisMonth = adThisMonth.round();
        wteThisMonth = wteThisMonth.round();
        
        treeSaveDBThisMonth = treeSaveDBThisMonth.round();
        co2DBThisMonth = co2DBThisMonth.round();
        kwhDBThisMonth = kwhDBThisMonth.round();
        recycledDBThisMonth = recycledDBThisMonth.round();
        adDBThisMonth = adDBThisMonth.round();
        wteDBThisMonth = wteDBThisMonth.round();
        
        treeSaveLast12m = treeSaveLast12m.round();
        if(treeSaveLast12m < 0)
        treeSaveLast12m = 0;
        co2Last12m = co2Last12m.round();
        kwhLast12m = kwhLast12m.round();
        if(kwhLast12m < 0)
        kwhLast12m = 0;
        recycledLast12m = recycledLast12m.round();
        adLast12m = adLast12m.round();
        wteLast12m = wteLast12m.round();
        
        for(String keyMonth: mapRecycledLast12Months.keySet()){ //keyMonth = MM_yyyy
            //to round number 
            mapAnerobicLast12Months.put(keyMonth, mapAnerobicLast12Months.get(keyMonth).round());
            mapWastesLast12Months.put(keyMonth, mapWastesLast12Months.get(keyMonth).round() < 0 ? 0 : mapWastesLast12Months.get(keyMonth).round());
            mapRecycledLast12Months.put(keyMonth, mapRecycledLast12Months.get(keyMonth).round());
        }
        
        
        //remove last camma
        recycledData = recycledData.length() > 1 ? recycledData.substring(0, recycledData.length()-1) : recycledData;
        adData = adData.length() > 1 ? adData.substring(0, adData.length()-1) : adData;
        wteData = wteData.length() > 1 ? wteData.substring(0, wteData.length()-1) : wteData;
        recyclingRateData = recyclingRateData.length() > 1 ? recyclingRateData.substring(0, recyclingRateData.length()-1) : recyclingRateData;
        
        chartURL = googleChartEndpoint +
                    'cht=bvg' + //chart type
                    '&chs=600x300' + //chart size
                    '&chxt=x,y,r' + //Visible axes 
                    '&chxr=1,0,' + maxvAxis.round() + //specify the range of values that appear on each axis 
                    '&chdl=Recycled|Anaerobic Digestion|Waste to Energy|Recycling Rate' + //chart legend
                    '&chdlp=t|l' + //chart legend position | order
                    '&chco=bee296,3ec39d,79cbe5,038f8e' + //chart color
                    '&chd=t3:' + recycledData + '|' + adData + '|' + wteData + '|' + recyclingRateData + //chart value, t3 display 3 values in a group
                    '&chds=0,' + maxvAxis.round() + ',0,' + maxvAxis.round() + ',0,' + maxvAxis.round()  + ',0,1'  + //automatic scale range
                    '&chbh=a,3,10' + //Bar width and spacing, a = auto, space between bars, space between groups
                    '&chxl=0:|' + last12MonthsLabel + '2:|0%|10%|20%|30%|40%|50%|60%|70%|80%|90%|100%' + //axes label
                    '&chxs=0,000000' + //axes color
                    '&chm=D*p*,038f8e,3,0,1.0'; //line chart
            
            
        chartURL =  chartURL.replace('%', '%25').replace('|', '%7C').replace(' ', '%20');
        
        System.debug('==============' + chartURL);  
        //chartURL = 'http://chart.googleapis.com/chart?cht=bvg&chs=600x300&chxt=x,y,r&chxr=1,0,700&chdl=Recycled%7CAnaerobic%20Digestion%7CWaste%20to%20Energy%7CRecycling%20Rate&chdlp=t%7Cl&chco=bee296,3ec39d,79cbe5,038f8e&chd=t3:100,220,70,110,210,140,90,40,30,10,675,0%7C0,0,0,0,0,0,0,0,0,0,0,0%7C0,0,0,0,0,0,0,0,0,0,0,0%7C0,0,0,0,1,1,0,0,0,0,1,0&chds=0,700,0,700,0,700,0,1&chbh=a,3,10&chxl=0:%7COct%7CNov%7CDec%7CJan%7CFeb%7CMar%7CApr%7CMay%7CJun%7CJul%7CAug%7CSep%7C2:%7C0%%7C10%%7C20%25%7C30%25%7C40%25%7C50%25%7C60%25%7C70%25%7C80%25%7C90%25%7C100%25&chxs=0,000000&chm=D*p*,038f8e,3,0,1.0';
        //  chartURL = 'http://chart.googleapis.com/chart?cht=bvg&chs=600x300&chxt=x,y,r&chxr=1,0,700&chdl=Recycled%7CAnaerobic%20Digestion%7CWaste%20to%20Energy%7CRecycling%20Rate&chdlp=t%7Cl&chco=bee296,3ec39d,79cbe5,038f8e&chd=t3:100,220,70,110,210,140,90,40,30,10,675,0%7C0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.000,0%7C0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.000,0%7C0,0,0,0,1,1,0,0,0,0,1,0&chds=0,700,0,700,0,700,0,1&chbh=a,3,10&chxl=0:%7COct%7CNov%7CDec%7CJan%7CFeb%7CMar%7CApr%7CMay%7CJun%7CJul%7CAug%7CSep%7C2:%7C0%25%7C10%25%7C20%25%7C30%25%7C40%25%7C50%25%7C60%25%7C70%25%7C80%25%7C90%25%7C100%25&chxs=0,000000&chm=D*p*,038f8e,3,0,1.0';
    }
    
    /**
    * Method to fill up number for max axis
    * @param val Decimal value to fill up
    * @return value filled up
    * e.g. 5->10, 250->300, 750->800
    */
    private Decimal fillupNumber(Decimal val){
        Integer valPrecision = Decimal.valueOf(val.round()).precision();  //get precision to find out divisor
        valPrecision = valPrecision <= 1 ? 1 : valPrecision-1; //-1 because we will pow it to get divisor
        
        Decimal divisor = 10;
        divisor = divisor.pow(valPrecision);
        
        Decimal resultDevide = val/divisor;
        Decimal resultFillup = resultDevide.round(System.RoundingMode.CEILING) * divisor;
        return resultFillup;
    }
}