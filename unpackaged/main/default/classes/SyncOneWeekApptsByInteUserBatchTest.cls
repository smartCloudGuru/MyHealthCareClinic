@isTest
private class SyncOneWeekApptsByInteUserBatchTest {
    static testMethod void unitTest() {
        Test.StartTest();
        list <Appointment_Type__c> objAptt = new list <Appointment_Type__c>();
        Appointment_Type__c objapt = new Appointment_Type__c ();
        objapt.Tele_Medicine_Option__c= true;
        objapt.Notes__c = 'test';
        objapt.Cancellation_Policy__c= 'testing';
        objapt.Can_Refer_Patient__c = true;
        objapt.Can_Book_Appointment__c = true;
        objapt.Name='Dentist Consultation';
        objapt.Meddbase_Key__c = '212345';
        insert objapt;    
          
        //list<string> tokenSessionId = MeddbaseCalloutUtility.integrationUserloginHandler();
        //MeddbaseCalloutUtility.syncTransferedWeeklyAppointments('Team','Test',null); 
        SyncOneWeekApptsByInteUserBatch objSowab = new SyncOneWeekApptsByInteUserBatch();
        //objSowab.convertDatetoString(); 
        DataBase.executeBatch(objSowab,1);
        Test.StopTest();
    }
}