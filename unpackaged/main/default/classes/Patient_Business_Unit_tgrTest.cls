/**
 * Created by Matija on 12.9.2023..
 */

@IsTest
private class Patient_Business_Unit_tgrTest {
    @IsTest
    static void testBehavior() {
        Account acc = new Account();
        acc.PersonEmail = 'test1@example.com';
        acc.FirstName = 'fname';
        acc.LastName = 'lname';

        insert acc;

        Patient_Business_Unit__c pbu = new Patient_Business_Unit__c();
        pbu.Account__c = acc.Id;
        pbu.Business_Unit__c = 'GP';
        insert pbu;

        pbu = [SELECT Id, Composite_Key__c FROM Patient_Business_Unit__c WHERE Id = :pbu.Id];

        System.debug(pbu);
        System.assert(String.isNotBlank(pbu.Composite_Key__c));
    }
}