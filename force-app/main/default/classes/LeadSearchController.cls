global with sharing class LeadSearchController {
 /*   static list<string> lstStatus  =    new list<string>();
    public static string LatLong{get;set;}
    static integer iAccountRadius  =    0;
    static{
        // Find all the status we have in custom settings.
        for( Field_Sales_App_Setting__c field : Field_Sales_App_Setting__c.getAll().values() ) 
        {
            if ( field.FieldSalesPendingStatus__c != null )
            {
                lstStatus = field.FieldSalesPendingStatus__c.split(',');
            }
            if ( field.AccountRadius__c != null )
                iAccountRadius = integer.valueOf( field.AccountRadius__c );
            if ( field.DefaultLocation__c != null )
            {
                LatLong = field.DefaultLocation__c;
            }
            break;
        }
    }
     
     /* Consructor  */
    public LeadSearchController(){}
    /*
    @RemoteAction
    global static list<Lead> leadRecords( )
    {
       return [SELECT Id,Name,Company,City,Country,PostalCode,State,Street,geopointe__Geocode__r.geopointe__Longitude__c,geopointe__Geocode__r.geopointe__Latitude__c FROM Lead WHERE status IN :lstStatus and Field_Sales_Team__c=:Userinfo.getUserId() and  geopointe__Geocode__r.geopointe__Longitude__c !=NULL AND geopointe__Geocode__r.geopointe__Latitude__c != NULL ];
    }
    
    @RemoteAction
    global static list<Account> accountRecords( Double devicelat, Double devicelong )
    {//'WHERE DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'mi\') < 20 ' +'ORDER BY DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'mi\') ' +
       system.debug('RC devicelat '+devicelat);
       list<Account> accounts = new list<Account>();
       for (Account account: [SELECT Id,Name,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,geopointe__Geocode__r.geopointe__Latitude__c,geopointe__Geocode__r.geopointe__Longitude__c  FROM Account WHERE geopointe__Geocode__r.geopointe__Longitude__c!=NULL AND geopointe__Geocode__r.geopointe__Latitude__c != NULL ])
       {
       		double distance = geopointe.API.getDistance( devicelat, devicelong, double.valueOf(account.geopointe__Geocode__r.geopointe__Latitude__c), double.valueOf(account.geopointe__Geocode__r.geopointe__Longitude__c), geopointe.API.units.MILES );
       		if ( distance != null && iAccountRadius != null && distance < iAccountRadius )
       			accounts.add(account);
       }
       return accounts;
    }*/
}