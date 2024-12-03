@isTest
private class RemoveUnusedProposedAppoinmentsBatchTest {
    static testMethod void myUnitTest() {
        Test.startTest();
        Proposed_Appointment__c pa = new Proposed_Appointment__c ();   
        pa.Start__c= system.Today();
        pa.Finish__c = system.Today()+5; 
        pa.Aerona_Key__c=10;   
        pa.state__c ='Not Available';  
        insert pa;
        RemoveUnusedProposedAppoinmentsBatch objRUPAUBatch = new RemoveUnusedProposedAppoinmentsBatch();
        try{Database.ExecuteBatch(objRUPAUBatch );}catch(Exception e){}  
        }
    }