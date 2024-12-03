@isTest
private class Lead_tgrTest {
    private static testMethod void myUnitTest(){
        
            Lead ld = new Lead();
            ld.LastName = 'Test';
            ld.Status = 'New';
            ld.Business_Unit__c = 'Implants';
            ld.Mode__c = 'Call';
            //ld.Site__c = 'Battersea Reach';
            insert ld;
            system.assert(ld.id != null);
        
        test.StartTest();
        //try{
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(ld.id);
            lc.setDoNotCreateOpportunity(false);
            lc.setConvertedStatus('Converted');
            
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.assert(lcr.isSuccess());
        //}Catch(Exception e){}
            
            
        test.StopTest();
    }
}