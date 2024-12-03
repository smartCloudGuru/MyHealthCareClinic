/**
 * Created 17.5.2024..
 */

@IsTest
private class AeronaTreatmentPlansCtrlTest {


    @TestSetup
    public static void setUp() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Aerona_Id__c = '123456';
        update accounts[0];
    }

    @IsTest
    static void testRefreshAllTreatmentPlansForPatient() {

        AeronaServiceMock.setAsMock();

        Test.startTest();
        List<Account> accounts = [SELECT Id, Name, Aerona_Id__c FROM Account LIMIT 1];

        AeronaTreatmentPlansCtrl.refreshAllTreatmentPlansForPatient(accounts[0].Aerona_Id__c);
        Test.stopTest();
    }

    @IsTest
    static void testProcessAllPatientTreatments() {

        List<Account> accounts = [SELECT Id, Name, Aerona_Id__c FROM Account LIMIT 1];

        List<AeronaServiceOASApi.OASAPITreatment> treatments = new List<AeronaServiceOASApi.OASAPITreatment>();

        Test.startTest();

        AeronaServiceOASApi.OASAPITreatment treatment1 = new AeronaServiceOASApi.OASAPITreatment();
        treatment1.patientId = Long.valueOf(accounts[0].Aerona_Id__c);
        treatment1.treatmentPlanDescription = 'Test Plan 1';
        treatment1.treatmentPlanId = 1;
        treatment1.deleteInd = false;

        AeronaServiceOASApi.OASAPITreatment treatment2 = new AeronaServiceOASApi.OASAPITreatment();
        treatment2.patientId = Long.valueOf(accounts[0].Aerona_Id__c);
        treatment2.treatmentPlanDescription = 'Test Plan 2';
        treatment1.treatmentPlanId = 2;
        treatment2.deleteInd = false;

        AeronaServiceOASApi.OASAPITreatment treatment3 = new AeronaServiceOASApi.OASAPITreatment();
        treatment3.patientId = Long.valueOf(accounts[0].Aerona_Id__c);
        treatment3.treatmentPlanDescription = 'Test Plan 2';
        treatment1.treatmentPlanId = 2;
        treatment3.deleteInd = false;

        treatments.add(treatment1);
        treatments.add(treatment2);
        treatments.add(treatment3);

        Map<String, AeronaServiceOASApi.OASAPITreatmentPlan> map_atpId_atplan = new Map<String, AeronaServiceOASApi.OASAPITreatmentPlan>();

        AeronaTreatmentPlansCtrl.processAllPatientTreatmentsWithTID(accounts[0], treatments, map_atpId_atplan);


        List<Opportunity> opps = [SELECT Id, Mode__c, Name, Aerona_Treatment_Plan_Name__c FROM Opportunity WHERE AccountId = :accounts[0].Id];
        System.debug('OPPS at end of test: ' + JSON.serialize(opps));
        System.assert(opps.size() == 2, 'Expected 2 Opportunities to be created, found:' + opps.size());
        System.assertEquals('Dental Treatment Plan', opps[0].Mode__c, 'Mode did not match');

        String dts = AeronaTreatmentPlansCtrl.aura_getDentalTreatmentPlansForOpportunity(opps[0].Id);

        Test.stopTest();

        System.assert(dts != null);


    }

    @IsTest
    static void test_updateBusinessUnit() {
        // Set up test data
        Opportunity testOpp = new Opportunity(Name = 'Test', StageName = 'Qualification', CloseDate = Date.today());
        insert testOpp;

        Test.startTest();
        AeronaTreatmentPlansCtrl.aura_updateBusinessUnit(testOpp.Id, 'Dentist');
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Business_Unit__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Dentist', updatedOpp.Business_Unit__c);
    }

    @IsTest
    static void test_aura_updateProbability() {
        // Set up test data
        Opportunity testOpp = new Opportunity(Name = 'Test', StageName = 'Qualification', CloseDate = Date.today());
        insert testOpp;

        Test.startTest();
        AeronaTreatmentPlansCtrl.aura_updateProbability(testOpp.Id, 33);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Probability FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(33, updatedOpp.Probability);
    }


}