/**
* @author Zoran Zunko
* @date 11/17/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

public with sharing class EnqixImportCSVParametersManager {

    private static EnqixImportCSVParameters__c csvParameters;

    public static EnqixImportCSVParameters__c getCsvParameters() {

        if(csvParameters == null) {

            csvParameters = EnqixImportCSVParameters__c.getInstance();

            if(String.isBlank(csvParameters.Delimiter__c)) {

                upsert csvParameters;
            }

            csvParameters = EnqixImportCSVParameters__c.getInstance();
        }

        return csvParameters;
    }

}