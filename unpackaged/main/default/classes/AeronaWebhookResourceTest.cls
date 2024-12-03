/**
 * Created 13.10.2022..
 */

@IsTest
private class AeronaWebhookResourceTest {

    @TestSetup
    static void dataSetup() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';

        update accounts[0];
    }

    @IsTest
    static void testPatientEvent() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();


        AeronaWebhookResource.FORCE_ENABLED = true;

        String postData = '{\n' +
                '  "insRefNumber2": null,\n' +
                '  "dob": "1972-03-16",\n' +
                '  "titleId": 70,\n' +
                '  "allowText": false,\n' +
                '  "mobileNumber": null,\n' +
                '  "allowEmail": false,\n' +
                '  "sourceId": null,\n' +
                '  "policyNo": null,\n' +
                '  "genderId": 2,\n' +
                '  "knownAs": null,\n' +
                '  "surname": "Smith",\n' +
                '  "practiceId": 1,\n' +
                '  "workNumber": null,\n' +
                '  "emailAddress": "test@example.com",\n' +
                '  "insExpiry2": null,\n' +
                '  "insExpiry1": null,\n' +
                '  "insRefNumber": null,\n' +
                '  "allowPrint": false,\n' +
                '  "occupation": null,\n' +
                '  "userId": null,\n' +
                '  "patientTypeId": null,\n' +
                '  "faxNumber": null,\n' +
                '  "forename": "Geoffrey",\n' +
                '  "statusId": 1,\n' +
                '  "address4": "MyCity",\n' +
                '  "address3": "MyTown",\n' +
                '  "address2": "MyStreet",\n' +
                '  "address1": "MyHouse",\n' +
                '  "maidenName": null,\n' +
                '  "code": "X32 B246",\n' +
                '  "homeNumber": null,\n' +
                '  "referrerId": null,\n' +
                '  "patientId": 412111,\n' +
                '  "recordType": "pt"\n' +
                '}';
        req.requestBody = Blob.valueOf(postData);
        req.addHeader('httpMethod', 'POST');
        req.requestURI = '/services/apexrest/aerona';


        RestContext.request = req;
        RestContext.response = res;



        Test.startTest();
        AeronaWebhookResource.doPost();
        Test.stopTest();
    }


    @IsTest
    static void testAppointmentEvent() {

        AeronaWebhookResource.FORCE_ENABLED = true;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        ServiceAppointment sa = new ServiceAppointment();
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addHours(1);
        sa.Aerona_Id__c = '3879021';
        sa.ParentRecordId = [SELECT ID FROM Account LIMIT 1].Id;
        insert sa;

        String postData = '{\n' +
                '  "appointmentStatusId": 2,\n' +
                '  "emergency": false,\n' +
                '  "practiceId": 1,\n' +
                '  "userId": 1154,\n' +
                '  "duration": 30,\n' +
                '  "appointmentTime": "2022-10-29T11:00:00+01:00",\n' +
                '  "appointmentId": 3879021,\n' +
                '  "appointmentTypeId": 2921,\n' +
                '  "patientId": 412361,\n' +
                '  "recordType": "app"\n' +
                '}';
        req.requestBody = Blob.valueOf(postData);
        req.addHeader('httpMethod', 'POST');
        req.requestURI = '/services/apexrest/aerona';


        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        AeronaWebhookResource.doPost();
        Test.stopTest();
    }

    @IsTest
    static void testAppointmentStatusMapping() {
        String sFstatus = null;
        for (Integer i = 1; i < 17; i++) {
            sFstatus = AeronaWebhookResource.mapAppointmentStatusIdToStatus(i);
            if (i == 1 || i == 2 || i == 9 || i == 10) System.assert(sFstatus == 'Scheduled');
        }

    }

    @IsTest
    static void testAppointmentStatusIdToJourneyStatusMapping() {
        String sFstatus = null;
        for (Integer i = 1; i < 17; i++) {
            sFstatus = AeronaWebhookResource.mapAppointmentStatusIdToJourneyStatus(i);
            if (i == 4 || i == 16) {
                System.assert(sFstatus == 'DNA');
            }
            else {
                System.assert(sFstatus != 'DNA');
            }
        }
    }

}