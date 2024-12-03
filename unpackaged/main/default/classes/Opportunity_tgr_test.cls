@IsTest
public class Opportunity_tgr_test {
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
    }

}