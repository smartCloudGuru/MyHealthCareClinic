@isTest
private class MeddbaseIntegrationUserLoginBatch_Test{
    static testMethod void unitTest(){
        Test.startTest();
        MeddBase_Settings__c objmed = new MeddBase_Settings__c();
        objmed.Client_Key__c = 'api-mhctest';
        objmed.Name = 'meddbase';
        insert objmed;          
        MeddbaseIntegrationUserLoginBatch obj = new MeddbaseIntegrationUserLoginBatch();
        DataBase.executeBatch(obj);   
    }
}