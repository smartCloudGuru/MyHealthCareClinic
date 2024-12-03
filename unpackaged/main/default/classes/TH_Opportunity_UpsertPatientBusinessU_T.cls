/**
 * Created by Matija on 18.9.2023..
 */

@IsTest
private class TH_Opportunity_UpsertPatientBusinessU_T {
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
                StageName = 'Qualification');
        insert opp;
        opp.StageName='Closed Won';
        update opp;
        Test.stopTest();

        opp = [SELECT Id, Name, Business_Unit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp.Name != null);

        List<Patient_Business_Unit__c> pbus = [
                SELECT
                        Id,
                        Account__c,
                        Composite_Key__c,
                        Business_Unit__c,
                        First_Opportunity__c,
                        Latest_Opportunity__c,
                        Won__c
                FROM Patient_Business_Unit__c
                WHERE Account__c =:acc.Id
        ];

        System.assert(pbus.size()==1);

        opp = [
                SELECT
                        Id,
                        AccountId,
                        Business_Unit__c,
                        Patient_Business_Unit__c
                FROM Opportunity
                WHERE Id =: opp.Id
                LIMIT 1
        ];

        System.assert(opp.Patient_Business_Unit__c!= null);
        System.assert(opp.Patient_Business_Unit__c == pbus[0].Id);
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
                StageName = 'Qualification');
        insert opp;
        opp.StageName='Closed Won';
        update opp;
        Test.stopTest();

        opp = [SELECT Id, Name, Business_Unit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp.Name != null);

        List<Patient_Business_Unit__c> pbus = [
                SELECT
                        Id,
                        Account__c,
                        Composite_Key__c,
                        Business_Unit__c,
                        First_Opportunity__c,
                        Latest_Opportunity__c,
                        Won__c
                FROM Patient_Business_Unit__c
                WHERE Account__c =:acc.Id
        ];

        System.assert(pbus.size()==1);

        opp = [
                SELECT
                        Id,
                        AccountId,
                        Business_Unit__c,
                        Patient_Business_Unit__c
                FROM Opportunity
                WHERE Id =: opp.Id
                LIMIT 1
        ];

        System.assert(opp.Patient_Business_Unit__c!= null);
        System.assert(opp.Patient_Business_Unit__c == pbus[0].Id);
    }
}