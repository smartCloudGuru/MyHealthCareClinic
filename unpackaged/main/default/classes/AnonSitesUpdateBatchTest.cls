@isTest
public class  AnonSitesUpdateBatchTest {
    static testMethod void unitTest() {
        Test.startTest();
            MeddBase_Settings__c objmed = new MeddBase_Settings__c();
            objmed.Client_Key__c = 'api-mhctest';
            objmed.Name = 'meddbase';
            insert objmed;                    
            AnonSitesUpdateBatch obj = new AnonSitesUpdateBatch();
            DataBase.executeBatch(obj); 
        Test.stopTest();
    } 
}