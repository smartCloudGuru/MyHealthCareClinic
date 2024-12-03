@isTest 
Private class trustPilotTestClass{
    Public static testMethod void testMethod1(){   
     test.StartTest();
     Account acc = new Account(
               FirstName='Test FName',
               LastName='Test LName',
               Gender__c = 'Male',
               Patient_Type__c='New'
               );
      insert acc;         
     Opportunity opp = new Opportunity(
                     Name = 'test1',
                AccountID = acc.id,
                CloseDate = System.Today(),
                StageName = 'Qualification'); 
     insert opp; 
     test.StopTest(); 
     System.assert(opp.Name!=null);       
    }
}