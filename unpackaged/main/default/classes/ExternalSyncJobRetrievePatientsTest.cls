/**
 * Created 28.3.2022..
 */

@IsTest
private class ExternalSyncJobRetrievePatientsTest {
    @IsTest
    static void test_getPatients_new() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncJobRetrievePatients.getPatients();
        Test.stopTest();
        List<Account> accounts = [SELECT Id, HeyDoc_Id__c FROM Account WHERE HeyDoc_Id__c =: HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID];
        System.assert(accounts.isEmpty() == false);
    }

    @IsTest
    static void test_getPatients_update() {
        HeyDocServiceMock.setAsMock();
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].HeyDoc_Id__c = HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID;
        update accounts[0];

        Test.startTest();
        ExternalSyncJobRetrievePatients.getPatients();
        Test.stopTest();
        accounts = [SELECT Id, HeyDoc_Id__c, FirstName FROM Account
            WHERE HeyDoc_Id__c =: HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID
            AND FirstName = 'Hdmock'
        ];
        System.assert(accounts.isEmpty() == false);
    }

    @IsTest
    static void test_getPatients_mapToExisting() {
        HeyDocServiceMock.setAsMock();
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].HeyDoc_Id__c = null;
        accounts[0].Date_of_Birth__c = Date.newInstance(1998, 8, 4);
        accounts[0].PersonEmail = 'test2map@example.com';
        accounts[0].FirstName = 'Hdmock';
        accounts[0].LastName = 'Martin';
        update accounts[0];

        String sfId = accounts[0].Id;
        Test.startTest();
        ExternalSyncJobRetrievePatients.getPatients();
        Test.stopTest();
        Account account = [SELECT Id, HeyDoc_Id__c FROM Account WHERE Id = :sfId];
        System.assert(account.HeyDoc_Id__c == HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID);

    }

}