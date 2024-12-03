@isTest
 private class MembershipFormPDF_Test{
   private static testMethod void testMethod1(){
   Test.StartTest();
    RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE Name = 'Person Account' and SObjectType = 'Account'];  
      Account acc = new Account(
           RecordTypeID=personAccountRecordType.id,
           FirstName='Test FName',
           LastName='Test LName',     
           Payment_Frequency__c='Monthly',
           PersonMailingStreet='test@yahoo.com',
           PersonMailingPostalCode='12345',
           PersonMailingCity='SFO',
           PersonEmail='test@yahoo.com',
           PersonHomePhone='1234567',
           PersonMobilePhone='12345678',
           Relation_With_Payer__c='Brother',
           Home_Clinic__c='Wandsworth',
           Membership_Start_Date__c  = system.Today(),
           Membership_Change_Dates__c = system.Today(),
           Patient_Type__c = 'Member',
           Membership_Level__c='Child',
           Signature_Date__c = system.Today(),
           Membership_Type__c  = '2019 MHC GP'
           
           ); 
           insert acc; 
      ApexPages.StandardController sc = new ApexPages.standardController(acc);
      MembershipFormPDF aa = new MembershipFormPDF(sc);     
    Test.StopTest(); 
   }
}