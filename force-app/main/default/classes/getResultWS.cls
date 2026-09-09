@RestResource(urlMapping='/getResults')
global with sharing class  getResultWS {

    @HttpPost
    global static String getResult(String query) {        
        String result;
        if(query != null && query != ''){
            List<sObject> sobjList = Database.query(query);
            if(sobjList != null && sobjList.size() > 0){
                result = JSON.serialize(sobjList);
            }
        }
        return result;
    }
}