public class GenerateReportController {
    
    public Account StdAcc;
    public Account acc {get; set;}
    
    public GenerateReportController(ApexPages.StandardController controller) {
        StdAcc = (Account)controller.getRecord();
        system.debug(StdAcc);
        acc = [Select Id, Name, Report_Type__c, Report_Date__c, Linked_Group__c from Account Where Id =: StdAcc.id];
        acc.Linked_Group__c = stdAcc.Id;
        acc.Report_Date__c = system.today();

    }
    
    public PageReference GenerateReport(){
        
        //apex/MonthlyRecycledReportPDF?id={!Account.Id}&isCustomRange=true
      system.debug('Report Type::'+acc.Report_Type__c);  
      
      String TemplateName = '';
      if(acc.Report_Type__c == 'Group Report')
      TemplateName = 'Group_Recycling_Report';
      
      if(acc.Report_Type__c == 'Linked Account CO2 Report')
      TemplateName = 'Linked_Recycling_Report';
      
      if(acc.Report_Type__c == 'Dashboard')
      TemplateName = 'Monthly_Location_Dashboard';
      
      if(acc.Report_Type__c == 'Partnership CO2 Report')
      TemplateName = 'Partner_Recycling_Report';
      
      
      String PARTNER_REPORT = 'Partner_Recycling_Report';
      String GROUP_REPORT = 'Group_Recycling_Report';
      String LINKED_REPORT = 'Linked_Recycling_Report';
      
      Boolean isPartner = TemplateName.equalsIgnoreCase(PARTNER_REPORT);
      Boolean isGroup = TemplateName.equalsIgnoreCase(GROUP_REPORT);
      Boolean isLinked = TemplateName.equalsIgnoreCase(LINKED_REPORT);
      
        if(TemplateName != ''){
        
            PageReference pdfPage = Page.MonthlyRecycledReportPDF;
            pdfPage.getParameters().put('id', acc.Id);
            pdfPage.getParameters().put('isgroup',   isGroup ? 'true': 'false');
            pdfPage.getParameters().put('ispartner',isPartner ? 'true': 'false');
            pdfPage.getParameters().put('islinked', isLinked ? 'true': 'false');
            pdfPage.getParameters().put('isCustomRange','true');
            pdfPage.getParameters().put('DateRange',string.valueOf(acc.Report_Date__c));
            
            pdfPage.setRedirect(true);
            return pdfPage;
            
        }else{
            PageReference redirectPage = Page.MonthlyRecycledReportPDF;
            redirectPage.setRedirect(true);
            redirectPage.getParameters().put('id',acc.Id);
            redirectPage.getParameters().put('isCustomRange','true');
            redirectPage.getParameters().put('DateRange',string.valueOf(acc.Report_Date__c));
            
            return redirectPage;
        }
        return null;
    }
    
    
    public PageReference DownloadReport(){
        system.debug('selected account ::'+acc.Linked_Group__c);
        system.debug('selectedDownloadType:: '+selectedDownloadType);
        system.debug('acc.Report_Type__c'+acc.Report_Type__c);
        system.debug('acc.Report_Date__c'+acc.Report_Date__c);
        
        if(acc.Linked_Group__c == null || acc.Report_Date__c == null){
            return null;
        }
        String TemplateName = '';
      if(acc.Report_Type__c == 'Group Report')
      TemplateName = 'Group_Recycling_Report';
      
      if(acc.Report_Type__c == 'Linked Account CO2 Report')
      TemplateName = 'Linked_Recycling_Report';
      
      if(acc.Report_Type__c == 'Dashboard')
      TemplateName = 'Monthly_Location_Dashboard';
      
      if(acc.Report_Type__c == 'Partnership CO2 Report')
      TemplateName = 'Partner_Recycling_Report';
      
      
      String PARTNER_REPORT = 'Partner_Recycling_Report';
      String GROUP_REPORT = 'Group_Recycling_Report';
      String LINKED_REPORT = 'Linked_Recycling_Report';
      
      Boolean isPartner = TemplateName.equalsIgnoreCase(PARTNER_REPORT);
      Boolean isGroup = TemplateName.equalsIgnoreCase(GROUP_REPORT);
      Boolean isLinked = TemplateName.equalsIgnoreCase(LINKED_REPORT);
      
        if(selectedDownloadType == 'PDF'){
            PageReference pdfPage;
            if(acc.Report_Type__c == 'Dashboard')
            pdfPage = Page.DownloadRecyclingDashboardReportPDF;
            else
            pdfPage = Page.DownloadRecyclingReportPDF;
            
            pdfPage.getParameters().put('id', acc.Linked_Group__c);
            pdfPage.getParameters().put('isgroup',   isGroup ? 'true': 'false');
            pdfPage.getParameters().put('ispartner',isPartner ? 'true': 'false');
            pdfPage.getParameters().put('islinked', isLinked ? 'true': 'false');
            pdfPage.getParameters().put('isCustomRange','true');
            pdfPage.getParameters().put('DateRange',string.valueOf(acc.Report_Date__c));
            if(acc.Report_Type__c == 'Dashboard')
            pdfPage.getParameters().put('isDashboard','true');
            else
            pdfPage.getParameters().put('isDashboard','false');
            
            
            pdfPage.setRedirect(true);
            return pdfPage;
        }
        
        if(selectedDownloadType == 'Excel'){
            PageReference ExcelPage = Page.RecyclingExcelReport;
            ExcelPage.getParameters().put('id', acc.Linked_Group__c);
            ExcelPage.getParameters().put('isgroup',   isGroup ? 'true': 'false');
            ExcelPage.getParameters().put('ispartner',isPartner ? 'true': 'false');
            ExcelPage.getParameters().put('islinked', isLinked ? 'true': 'false');
            ExcelPage.getParameters().put('isCustomRange','true');
            system.debug('Date Range:: '+string.valueOf(acc.Report_Date__c));
            ExcelPage.getParameters().put('DateRange',string.valueOf(acc.Report_Date__c));
            
            ExcelPage.setRedirect(false);
            return ExcelPage;
        }
        
        return null;
    }
    
    public string selectedDownloadType {get; set;}
    public List<SelectOption> getDownloadTypes(){
        list<SelectOption> options = new list<SelectOption>();
        options.add(new selectOption('PDF','PDF'));
        options.add(new selectOption('Excel','Excel'));
        return options;
    }
}