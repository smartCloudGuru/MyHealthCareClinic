/**
 * Created by Matija on 13.2.2024..
 */

@IsTest
global class AWSBucketControllerTest {

    @IsTest
    static void testPutFileInS3FromContentDocument() {

        // Create a new ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test';
        contentVersion.PathOnClient = 'Test.pdf';
        Blob fileContent = Blob.valueOf('Test content');
        contentVersion.VersionData = fileContent;
        insert contentVersion;

        String s3Url = 'https://example.com';

        // Set up the mock HTTP response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AWSBucketControllerMock(201));

        Boolean result = AWSBucketController.putFileInS3FromContentDocument(contentVersion, s3Url);

        Test.stopTest();

        // Verify that the method returns true
        System.assertEquals(true, result);

    }

    /**
     * Mock for the HttpCallout interface. Used during tests
     * to generate a mock HTTP response
     */
    global class AWSBucketControllerMock implements HttpCalloutMock {
        protected Integer statusCode;

        public AWSBucketControllerMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{}');
            res.setStatusCode(this.statusCode);
            return res;
        }
    }
}