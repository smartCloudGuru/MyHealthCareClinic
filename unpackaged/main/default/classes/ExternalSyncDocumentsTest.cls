/**
 * Created by Matija on 13.2.2024..
 */

@IsTest
private class ExternalSyncDocumentsTest {


    @TestSetup
    static void dataSetup() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        accounts[0].HeyDoc_Id__c = 'test123';
        update accounts;

        Opportunity opp = new Opportunity(
                Name = 'Test',
                AccountId = accounts[0].Id,
                StageName = 'Closed Won',
                CloseDate = Date.today());

        insert opp;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test';
        contentVersion.PathOnClient = 'Test.pdf';
        Blob fileContent = Blob.valueOf('Test content');
        contentVersion.VersionData = fileContent;
        insert contentVersion;

        External_Document_Sync__c externalDocumentSync = new External_Document_Sync__c();
        externalDocumentSync.ContentVersionId__c = contentVersion.Id;
        externalDocumentSync.External_System__c = 'HEYDOC';
        externalDocumentSync.Opportunity__c = opp.Id;
        externalDocumentSync.Uploaded__c = false;
        insert externalDocumentSync;

    }

    @IsTest
    static void testBehavior() {

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AWSBucketControllerTest.AWSBucketControllerMock(201));
        ExternalSyncDocuments.syncDocuments();
        Test.stopTest();
    }
}