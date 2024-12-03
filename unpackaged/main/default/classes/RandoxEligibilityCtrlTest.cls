/**
 * Created by Matija on 2.2.2024..
 */

@IsTest
public class RandoxEligibilityCtrlTest {

    @IsTest
    static void testProvision() {
        Randox_Eligibility__c rex = new Randox_Eligibility__c();
        rex.Email_with_PIDs__c = 'As per our discussion these are what the list of PID’s we get look like\n' +
                ' \n' +
                '230787\tDiscovery\t\n' +
                '228530\tEvery\t\n' +
                '230804\tEvery+TAM\t\n' +
                '230830 \tDiscovery+TAM\t\n' +
                '230988\tEvery+TAM\t\n' +
                '231042\tDiscovery+TAM\t\n' +
                '231081 \tEvery+TAM\t\n' +
                '229115\tDiscovery+TAM\tPreviously sent - I believe you were unable to get in contact customer would like GP appt in Feb\n' +
                ' \n' +
                'Below is some examples of how many files and the rough file sizes';
        insert rex;

        RandoxEligibilityCtrl.provision([SELECT Id, Email_with_PIDs__c FROM Randox_Eligibility__c]);

        // Selecting all Randox_Eligibility_Voucher__c
        List<Randox_Eligibility_Voucher__c> vouchers = [SELECT Id, Randox_Eligibility__c FROM Randox_Eligibility_Voucher__c];

        System.assert(vouchers.size() == 8, 'invalid number of vouchers written to db');
        System.assert(vouchers[0].Randox_Eligibility__c != null, 'unset parent Randox eligibility object');

        List<Randox_Eligibility__c> reList = [SELECT Id, Provisioned_at__c FROM Randox_Eligibility__c];
        for (Randox_Eligibility__c randoxEligibility : reList) {
            System.assert(randoxEligibility.Provisioned_at__c != null, 'one of the randox eligibility objects not provisioned');

        }


    }


    @IsTest
    static void testProcessEmail() {

        // Prepare test data
        Randox_Eligibility__c randoxEligibility = new Randox_Eligibility__c();
        randoxEligibility.Email_with_PIDs__c = 'As per our discussion these are what the list of PID’s we get look like\n' +
                ' \n' +
                '230787\tDiscovery\t\n' +
                '228530\tEvery\t\n' +
                '230804\tEvery+TAM\t\n' +
                '230830 \tDiscovery+TAM\t\n' +
                '230988\tEvery+TAM\t\n' +
                '231042\tDiscovery+TAM\t\n' +
                '231081 \tEvery+TAM\t\n' +
                '229115\tDiscovery+TAM\tPreviously sent - I believe you were unable to get in contact customer would like GP appt in Feb\n' +
                ' \n' +
                'Below is some examples of how many files and the rough file sizes';

        // Call the method to test
        List<RandoxEligibilityCtrl.EligibilityEntry> results = RandoxEligibilityCtrl.processEmail(randoxEligibility);

        for (RandoxEligibilityCtrl.EligibilityEntry eligibilityEntry : results) {
            System.debug(eligibilityEntry);
        }

        // Assert that the output is as expected
        System.assert(results.size() == 8, 'invalid number of EligibilityEntry results returned.');
        System.assert(results[0].patientId == '230787', 'invalid first patient id');
        System.assert(results[0].productsEligible == 'Discovery', 'invalid first product');
        System.assert(results[0].hasTAMProduct() == false, 'invalid tam flag in first record');
        System.assert(results[results.size() - 1].hasTAMProduct() == true, 'invalid tam flag in last record');


    }

    @IsTest
    static void testCheckVoucherIsAvailable() {

        Randox_Eligibility__c rex = new Randox_Eligibility__c();
        rex.Email_with_PIDs__c = '230787\tDiscovery';
        insert rex;

        // Prepare test data
        String testRandoxPatientId = 'testId123';
        Randox_Eligibility_Voucher__c testVoucher = new Randox_Eligibility_Voucher__c();
        testVoucher.Randox_PatientId__c = testRandoxPatientId;
        testVoucher.Eligible_For__c = 'Every/Discovery';
        testVoucher.Randox_Eligibility__c = rex.Id;
        testVoucher.Valid_Until__c = Date.today().addMonths(1);
        insert testVoucher;

        // Run the method to be tested
        Test.startTest();
        String result = RandoxEligibilityCtrl.checkVoucherIsAvailable(testRandoxPatientId);
        Test.stopTest();

        // Assert the results
        System.assertEquals(testVoucher.Eligible_For__c, result);
    }

    @IsTest
    static void testCheckVoucherIsNotAvailable() {
        Randox_Eligibility__c rex = new Randox_Eligibility__c();
        rex.Email_with_PIDs__c = '230787\tDiscovery';
        insert rex;

        // Prepare test data
        String testRandoxPatientId = 'testId123';
        Randox_Eligibility_Voucher__c testVoucher = new Randox_Eligibility_Voucher__c();
        testVoucher.Randox_PatientId__c = testRandoxPatientId;
        testVoucher.Eligible_For__c = 'Every/Discovery+TAM';
        testVoucher.Randox_Eligibility__c = rex.Id;
        testVoucher.Valid_Until__c = Date.today().addMonths(1);
        insert testVoucher;

        // Run the method to be tested
        Test.startTest();
        String result = RandoxEligibilityCtrl.checkVoucherIsAvailable('notanid');
        Test.stopTest();

        // Assert the results
        System.assertEquals(null, result);
    }
}