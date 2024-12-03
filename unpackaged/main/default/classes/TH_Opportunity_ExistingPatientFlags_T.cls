/**
 * Created by Matija on 18.9.2023..
 */

// OVO JE PROSLO OK

@IsTest
private class TH_Opportunity_ExistingPatientFlags_T {
    @IsTest
    public static void testOppGP() {
        Test.startTest();
        Account acc = new Account(
                FirstName = 'Test FName',
                LastName = 'Test LName',
                Gender__c = 'Male',
                Patient_Type__c = 'New'
        );
        insert acc;
        Opportunity opp = new Opportunity(
                Name = 'test1',
                AccountId = acc.Id,
                Business_Unit__c = 'GP',
                CloseDate = System.today(),
                StageName = 'Closed Won');
        insert opp;
        Test.stopTest();

        opp = [SELECT Id, Name, Business_Unit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp.Name != null);

        acc = [SELECT Id, Patient_Type__c, Existing_GP_Patient__c, Existing_Dental_Patient__c FROM Account WHERE Id = :acc.Id];
        System.assert(acc.Patient_Type__c == 'Registered');
        System.assert(acc.Existing_GP_Patient__c == true);
        System.assert(acc.Existing_Dental_Patient__c == false);


    }

    @IsTest
    public static void testOppDentist() {
        Test.startTest();
        Account acc = new Account(
                FirstName = 'Test FName',
                LastName = 'Test LName',
                Gender__c = 'Male',
                Patient_Type__c = 'New'
        );
        insert acc;
        Opportunity opp = new Opportunity(
                Name = 'test1',
                AccountId = acc.Id,
                Business_Unit__c = 'Dentist',
                CloseDate = System.today(),
                StageName = 'Closed Won');
        insert opp;
        Test.stopTest();

        opp = [SELECT Id, Name, Business_Unit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp.Name != null);

        acc = [SELECT Id, Patient_Type__c, Existing_GP_Patient__c, Existing_Dental_Patient__c FROM Account WHERE Id = :acc.Id];
        System.assert(acc.Patient_Type__c == 'Registered');
        System.assert(acc.Existing_Dental_Patient__c == true);
        System.assert(acc.Existing_GP_Patient__c == false);


    }
}