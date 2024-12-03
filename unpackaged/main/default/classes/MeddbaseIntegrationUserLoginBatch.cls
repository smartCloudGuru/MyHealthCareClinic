global class MeddbaseIntegrationUserLoginBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{     
    global Database.QueryLocator start(Database.BatchableContext BC){        
        return Database.getQueryLocator([SELECT id,Meddbase_Token_Session__c FROM MeddBase_Settings__c WHERE name='meddbase']);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){  
        try{
            list<MeddBase_Settings__c> objMeddBase_Settings = new list<MeddBase_Settings__c>();
            //[2024-02] commenting this out as it's no longer used but continues to generate error logs
//            for(MeddBase_Settings__c st : (list<MeddBase_Settings__c>)scope){
//                list<String> tokenSessionId = MeddbaseCalloutUtility.integrationUserloginHandler();
//                MeddBase_Settings__c ms = st;
//                ms.Meddbase_Token_Session__c = String.join(tokenSessionId,'_@_');
//				objMeddBase_Settings.add(ms);
//            }
//            if(objMeddBase_Settings.size() > 0) update objMeddBase_Settings;
        }catch(Exception e){DatabaseUtility.creatErrorlog('','MeddbaseIntegrationUserLoginBatch',''+e.getLineNumber(),e.getMessage()+'\n\n'+CommonUtility.objMeddBaseSettings.Integration_Username__c+'\n\n'+CommonUtility.objMeddBaseSettings.Integration_User_Password__c,'','','','','','');
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}