/**
* Class to generate CompoundChart
* @createdDate 09-Aug-2016
* @author Sopha Pum
*/
public class CompoundChartController {
    public static String RECYCLED       {get {return 'recycled';} private set{}}
    public static String AD_KG          {get {return 'anerobic digestion';} private set{}}
    public static String WTE_KG         {get {return 'Waste to Energy';} private set{}}
    public static String RECYCLING_RATE {get {return 'recycling rate';}private set{}}
    
    public String accid {get;set;}
    public Boolean isGroupReport    {get;set;}
    public Boolean isPartnerReport  {get;set;}
    public Boolean isLinkedReport   {get;set;}
    public Boolean isCustomDateRange {get;set;}
    
    public String logoURL {get;set;}
    public String recycledURL {get;set;}
    public String adURL {get;set;}
    public String wteURL {get;set;}
    public String recyclingURL {get;set;}
    public String treeURL {get;set;}
    public String co2URL {get;set;}
    public String kwhURL {get;set;}
    public String headerURL {get;set;}
    public String msgIconUrl {get;set;} 
    public String msgIconFooterUrl {get;set;}
    public String logoWhiteUrl {get;set;}
    public String footerBGUrl {get;set;}
    public String phoneIconUrl {get;set;}
    public String twitterIcoUrl {get;set;}
    public String userIcoUrl {get;set;} 
    public String marketingSlotJan {get;set;}
    public String AccountLogo {get; set;}
    
    public RecyclingReportWrapper reportWrapper {get{
            if(reportWrapper == null){
                reportWrapper = new RecyclingReportWrapper(accid, 
                                                            (isGroupReport == null ? false : isGroupReport), 
                                                            (isPartnerReport == null ? false: isPartnerReport),
                                                            (isLinkedReport == null ? false: isLinkedReport)
                                                            );
            }
            return reportWrapper;
        }
        private set;}
        
    public Account acc {get{
            if(acc == null && accid != null){
                acc = [Select Name,Main_Contact_Email__c, Phone, Main_Contact_Name1__c, (Select Id from Attachments where Name = 'Account_Logo') From Account where id=: accid];
            }
            return acc;
        }
        private set;}
        
    public CompoundChartController(ApexPages.StandardController sctrl){
        accid = sctrl.getId();
        String groupParam = Apexpages.currentPage().getParameters().get('isgroup');
        groupParam = groupParam == null ? '': String.escapeSingleQuotes(groupParam);
        isGroupReport = groupParam.equalsIgnoreCase('true'); 
        
        String partnerParam = Apexpages.currentPage().getParameters().get('ispartner');
        partnerParam = partnerParam == null ? '': String.escapeSingleQuotes(partnerParam);
        isPartnerReport = partnerParam.equalsIgnoreCase('true');
        
    }
    
    public CompoundChartController(){
        String sfBaseURL = 'https://' + URL.getSalesforceBaseUrl().getHost() + '/servlet/servlet.ImageServer?id=';
        String orgParam = '&oid=' + UserInfo.getOrganizationId();
        
        Set<String> sDocName = new Set<String>{ 'Recycled_Icon',
                                                'FirstMileLogo',
                                                'Anaerobic_Icon',
                                                'WTE_Icon',
                                                'Recycling_Rate_Icon',
                                                'Trees_Icon',
                                                'CO2_Icon',
                                                'KWH_Icon',
                                                'Blue_Curve_Header',
                                                'User_Icon',
                                                'Twitter_Icon_Footer',
                                                'Phone_Icon',
                                                'Email_Icon',
                                                'Email_Icon_Footer',
                                                'FirstMile_Logo_White',
                                                'Footer_BG',
                                                'MarketingSlotJan'};
        List<Document> lstDoc = [Select Id, DeveloperName From Document where DeveloperName in: sDocName];
        Map<String, String> mapImages = new Map<String, String>();
        for(Document doc: lstDoc){
            mapImages.put(doc.DeveloperName, doc.Id);
        }
        
        logoURL = mapImages.containsKey('FirstMileLogo') ? sfBaseURL + mapImages.get('FirstMileLogo') +  orgParam : '';
        recycledURL = mapImages.containsKey('Recycled_Icon') ? sfBaseURL + mapImages.get('Recycled_Icon') +  orgParam : '';
        adURL = mapImages.containsKey('Anaerobic_Icon') ? sfBaseURL + mapImages.get('Anaerobic_Icon') +  orgParam : '';
        wteURL = mapImages.containsKey('WTE_Icon') ? sfBaseURL + mapImages.get('WTE_Icon') +  orgParam : '';
        recyclingURL = mapImages.containsKey('Recycling_Rate_Icon') ? sfBaseURL + mapImages.get('Recycling_Rate_Icon') +  orgParam : '';
        treeURL = mapImages.containsKey('Trees_Icon') ? sfBaseURL + mapImages.get('Trees_Icon') +  orgParam : '';
        co2URL = mapImages.containsKey('CO2_Icon') ? sfBaseURL + mapImages.get('CO2_Icon') +  orgParam : '';
        kwhURL = mapImages.containsKey('KWH_Icon') ? sfBaseURL + mapImages.get('KWH_Icon') +  orgParam : '';
        headerURL = mapImages.containsKey('Blue_Curve_Header') ? sfBaseURL + mapImages.get('Blue_Curve_Header') +  orgParam : '';
        
        msgIconUrl = mapImages.containsKey('Email_Icon') ? sfBaseURL + mapImages.get('Email_Icon') +  orgParam : '';
        msgIconFooterUrl = mapImages.containsKey('Email_Icon_Footer') ? sfBaseURL + mapImages.get('Email_Icon_Footer') +  orgParam : '';
        logoWhiteUrl = mapImages.containsKey('FirstMile_Logo_White') ? sfBaseURL + mapImages.get('FirstMile_Logo_White') +  orgParam : '';
        footerBGUrl = mapImages.containsKey('Footer_BG') ? sfBaseURL + mapImages.get('Footer_BG') +  orgParam : '';
        phoneIconUrl = mapImages.containsKey('Phone_Icon') ? sfBaseURL + mapImages.get('Phone_Icon') +  orgParam : '';
        twitterIcoUrl = mapImages.containsKey('Twitter_Icon_Footer') ? sfBaseURL + mapImages.get('Twitter_Icon_Footer') +  orgParam : '';
        userIcoUrl = mapImages.containsKey('User_Icon') ? sfBaseURL + mapImages.get('User_Icon') +  orgParam : '';
        marketingSlotJan = mapImages.containsKey('MarketingSlotJan') ? sfBaseURL + mapImages.get('MarketingSlotJan') +  orgParam : '';
        
        system.debug(accId);
        
        String accParamId = Apexpages.currentPage().getParameters().get('id');
        if(accParamId != null){
            Account accParam = [Select Name, Partnership__c, (Select Id from Attachments where Name = 'Account_Logo') From Account where id=: accParamId];
    
            for(Attachment at : accParam.attachments){
                AccountLogo = at.Id;
            }
        
        
        if(accParam.Attachments.size() == 0 && accParam.Partnership__c == null){
            List<Account> acclist = new List<Account>([Select Id , (Select Id from Attachments where Name = 'Account_Logo') from Account where ParentId = :accParamId]);
            if(accList.size() > 0){
                If(accList[0].Attachments.size() > 0){
                    AccountLogo = accList[0].Attachments[0].Id;
                }
            }
        }
        
        if(accParam.Attachments.size() == 0 && accParam.Partnership__c != null){
            List<Account> acclist = new List<Account>([Select Id , (Select Id from Attachments where Name = 'Account_Logo') from Account where Id = :accParam.Partnership__c]);
            if(accList.size() > 0){
                If(accList[0].Attachments.size() > 0){
                    AccountLogo = accList[0].Attachments[0].Id;
                }
            }
        }
        system.debug('AccountLogo :: '+AccountLogo );
        }
    }
    
}