/**
 * Created by Matija on 8.6.2023..
 */

@IsTest
global class OnlIcsFilesGeneratorTest {

    @TestSetup
    static void dataSetup() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';

        update accounts[0];
    }

    @IsTest
    static void generateIcsFiles_test() {
        ServiceAppointment sa = new ServiceAppointment();
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addHours(1);
        sa.ParentRecordId = [SELECT Id FROM Account LIMIT 1].Id;
        insert sa;

        OnlIcsFilesGenerator.generateIcsFiles(sa.Id);

    }

}