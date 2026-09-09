/**
* @author Zoran Zunko
* @date 10/23/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

@IsTest
public class TestDataFactory {

    public static List<String> accountLocationImportList = new List<String>{
            'Customer_Id,Col_CompanyName,Col_add_1,Col_add_2,Col_add_3,Col_Town,Col_County,Col_Postcode,DateMarkedDead,MarketingCategory,Council,LocStatus,DateMadeLive,SICCode,LocationGroup_Id,Classification,AccountName,Account_Id,AccountStatus,AC_Code,AddressLine1,AddressLine2,AddressLine3,PaymentMethod,PostCode',
            '7744,Fox TV (Regular Cleaning Services),3rd and 2nd Floor,10,Hammersmith Grove,London,,W6 7AP,,Office,Hammersmith & Fulham,Live,6/1/16,70100,3216,Cleaner Medium,Regular Cleaning Services,3149,OK,REG012,Martin Langford,Aldworth House,1 Aldworth Grove,account,SE13 6HJ',
            '8814,Bang & Olufson (KingstonFirst),,27,Fife Road,Kingston,,KT1 1SB,,Retail,Kingston upon Thames,Live,6/1/16,47190,1627,BID,Kingstonfirst,1538,OK,KIN005,Lucinda Raggett,3rd Floor,55 Eden Street,direct debit,KT1 1BW',
            '9748,Red Apple Creative ,,60,Greys Inn Road ,London,,WC1X 8AQ,,Office,Camden,Live,4/1/16,70100,9848,Single Small,SNK Studios,9730,OK,SNK002,Midford Place,114-115 ,Tottenham Court Road,account,W1T 5AH',
            '9749,The London Prosthodontics (Endersham),,29,Weymouth Street,London,,W1G 7DB,,Office,Westminster,Live,4/1/16,70100,1120,Cleaner Large,Endersham Limited,1000000043,OK,END004,78 Mount Pleasant Road,,,direct debit,NW10 3EJ',
            '9750,Mark Goucher Ltd,1st Floor,19,Garrick Street,London,,WC2E 9AX,,Office,Westminster,Live,4/1/16,70100,6285,Single Medium,The KleanTeam,6126,OK,KLE001,International House,223,Regents Street,direct debit,W1B 2QD',
            '9751,H & T Pawnbrokers (Durham) (f),,69,North Road,Durham,,DH1 4SQ,,Office,,Live,4/1/16,70100,5841,Multi Large,Harvey and Thompson,5709,OK,HAR030,Times House,Throwley  Way,,account,SM1 4AF'
    };

    @TestVisible private static List<String> orderOrderLineImportList = new List<String>{
            'Account,Location,Location_Id,Order_Id,Order_Date,Delivery_Date,Product_Category,Product_Name,Qty,Unit_Price,Product_Discount,DD_Discount_Price,Overriding_Discount_Price,Net_Price,Line_Value,Inv/Serv #,Product_Id,Product_Code,Inv/Serv Note Date',
            'Architects Design Partnership LLP,Architects Design Partnership LLP,{0},350785,16/12/2015,17/12/2015,Mxd Recyc,Medium Mixed Recycling Sack,200,1.05,0,0,0,1.05,210,LON000241404,1000000016,SPREC001,18/12/2015',
            'Architects Design Partnership LLP,Architects Design Partnership LLP,{1},350785,16/12/2015,17/12/2015,Tape,Cardboard Recycling Sticker,50,1.05,0,0,0,1.05,52.5,LON000241404,1000000015,SPTAP001,18/12/2015',
            'Avanta Shoreditch - PeoplePlus Group Ltd,Avanta Managed Offices Limited t/a Avanta Shoredit,{2},348582,09/12/2015,10/12/2015,Int. Bin,60L Mixed Recycling Bin & Lid (Card),10,5.5,5.5,0,0,0,0,LON000240380,113,ZBINCA005,11/12/2015',
            'Avanta Shoreditch - PeoplePlus Group Ltd,Avanta Managed Offices Limited t/a Avanta Shoredit,{2},348582,09/12/2015,10/12/2015,Int. Bin,60L Addis Mixed Recycling Bin & Lid (Grey)_RE02,1,17,0,0.43,0,16.57,16.57,LON000240380,116,ZBINAD015,11/12/2015',
            'Avanta Shoreditch - PeoplePlus Group Ltd,Avanta Managed Offices Limited t/a Avanta Shoredit,{3},351398,18/12/2015,21/12/2015,Rubbish,Medium Rubbish Sack,400,1.15,0.32,0.02,0,0.81,324,LON000241799,1000000013,SPRUB001,22/12/2015',
            'Avanta Shoreditch - PeoplePlus Group Ltd,Avanta Managed Offices Limited t/a Avanta Shoredit,{3},351398,18/12/2015,21/12/2015,Mxd Recyc,Medium Mixed Recycling Sack,400,1.05,0.26,0.02,0,0.77,308,LON000241799,1000000016,SPREC001,22/12/2015',
            'Avanta Shoreditch - PeoplePlus Group Ltd,Avanta Managed Offices Limited t/a Avanta Shoredit,{3},352488,23/12/2015,24/12/2015,Tape,Cardboard Recycling Sticker,200,1.05,0.26,0.02,0,0.77,154,LON000242278,1000000015,SPTAP001,29/12/2015'
    };

    public static String getOrderOrderLineImportList(List<String> locationEnqixIdList, List<String> productEnqixIdList) {

        List<String> parameters = new List<String>(locationEnqixIdList);
        parameters.addAll(productEnqixIdList);

        return String.format(
                String.join(
                        orderOrderLineImportList,
                        Parser.CRLF
                ),
                parameters
        );
    }
    public static List<Account> createAccounts(String baseName, Integer quantity) {

        List<Account> response = new List<Account>();

        for (Integer i = 0; i < quantity; i++) {

            response.add(new Account(
                    Name = baseName + String.valueOf(i)
            , Enqix_ID__c = 'Account' + String.valueOf(i)
            , RecordTypeId = Cache.RecordTypeId(AccountManager.RT_ACCOUNT)

            ));
        }
        return response;
    }

    public static List<Account> createLocations(List<Account> accounts, String baseName, Integer quantity) {

        List<Account> response = new List<Account>();
        for (Account acc : accounts) {

            for (Integer i = 0; i < quantity; i++) {

                response.add(new Account(
                        Name = baseName + String.valueOf(i)
                , Enqix_ID__c = 'Loc' + acc.Name + String.valueOf(i)
                , ParentId = acc.Id
                , RecordTypeId = Cache.RecordTypeId(AccountManager.RT_LOCATION)
                ));
            }
        }

        return response;
    }

    public static List<Product2> createProductsForImport(String baseName, Integer quantity) {

        List<Product2> response = new List<Product2>();

        for (Integer i = 0; i < quantity; i++) {

            response.add(new Product2(
                    Name = baseName + String.valueOf(i),
                    Enqix_Id__c = baseName + String.valueOf(i),
                    ProductCode = '126'+String.valueOf(i),
                    Product_Type__c = 'Collection'

            ));
        }
        return response;
    }

    public static List<PricebookEntry> createStandardPrice(List<Product2> products, Decimal price) {

        Id standardPB = Test.getStandardPricebookId();

        List<PricebookEntry> results = new List<PricebookEntry>();
        for (Product2 product : products) {
            results.add(new PricebookEntry(Product2Id = product.Id, Pricebook2Id = standardPB, UnitPrice = price, UseStandardPrice = false, IsActive = true));
        }
        system.debug(results);
        return results;

    }
}