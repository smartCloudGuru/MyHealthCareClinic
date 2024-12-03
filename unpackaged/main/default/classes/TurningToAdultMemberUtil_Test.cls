@isTest
private class TurningToAdultMemberUtil_Test {

@testSetup 
    public static void setUpMockData(){
    Account acc = new Account();
           acc.FirstName='Test FName';
           acc.LastName='Test LName';   
           acc.PersonMailingStreet='test@yahoo.com';
           acc.PersonMailingPostalCode='12345';
           acc.PersonMailingCity='SFO';
           acc.PersonEmail='test@yahoo.com';
           acc.PersonHomePhone='1234567';
           acc.PersonMobilePhone='12345678';
           acc.Phone='122333333';
           acc.Patient_Type__c = 'Member';
           acc.Membership_Level__c='Child';  
           acc.Membership_Type__c='2019 MHC GP';
           acc.Payment_Frequency__c='Monthly';
           acc.Relation_With_Payer__c='Brother';
           acc.Home_Clinic__c='Wandsworth';
           insert acc; 
       }  

    static testMethod void myUnitTest() {
       test.StartTest();
          List<Account> lstAcc = new List<Account>();
          String emlBody = TurningToAdultMemberUtil.prepareEmailBody(lstAcc );
          TurningToAdultMemberUtil.pushNotification(emlBody );
          TurningToAdultMemberUtil obj = new TurningToAdultMemberUtil();
       test.StopTest();
       }   
}