@IsTest
public class Covid_Test_Certificate_ControllerTest {

    @IsTest
    private static void test_Covid_Test_Certificate_Controller() {

        COVID_Test__c ctest = new COVID_Test__c();
        ctest.Test_Type__c = 'PCR Test';
        ctest.Test_URN__c = '12313';

        insert ctest;

        ctest.Swab_Collection_Date__c = Date.today();

        update ctest;

        ApexPages.StandardController ctc = new ApexPages.StandardController(ctest);
        Covid_Test_Certificate_Controller extController = new Covid_Test_Certificate_Controller(ctc);

        extController.getLivingWithCovid();

        String ret = extController.getFormattedSwabDateTime();

        System.debug(ret);
        System.assert(ret != null);

    }
}