/**
 * Created 27.2.2023..
 */

@IsTest
public class AppointmentRestResourceTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].FirstName = 'DFN';
        accounts[0].LastName = 'DLN';
        accounts[0].Date_of_Birth__c = Date.today();
        update accounts[0];
    }

    @IsTest
    static void doPatch_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        ServiceAppointment sa = new ServiceAppointment();
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addHours(1);
        sa.ParentRecordId = [SELECT Id FROM Account LIMIT 1].Id;
        insert sa;

        sa = new ServiceAppointment(Id = sa.Id);
        sa.Status = 'Canceled';
        sa.CancellationReason = 'testing';


        req.httpMethod = 'PATCH';
        req.requestURI = '/m/appointment/';

        req.requestBody = Blob.valueOf(JSON.serialize(sa));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        AppointmentRestResource.doPatch();
        Test.stopTest();

        System.assert(res.responseBody != null);
        System.assert(res.statusCode == 200);
        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void doPatch_noID_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        ServiceAppointment sa = new ServiceAppointment();
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addHours(1);
        sa.ParentRecordId = [SELECT Id FROM Account LIMIT 1].Id;
        insert sa;

        sa = new ServiceAppointment(Id = sa.Id);
        sa.Status = 'Canceled';
        sa.CancellationReason = 'testing';


        req.httpMethod = 'PATCH';
        req.requestURI = '/m/appointment/';

        sa.Id = null;

        req.requestBody = Blob.valueOf(JSON.serialize(sa));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        AppointmentRestResource.doPatch();
        Test.stopTest();

        System.assert(res.responseBody != null);
        System.assert(res.statusCode == 400);
        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void resFromMHCApiResponse_test() {
        RestResponse res = new RestResponse();
        AppointmentRestResource.resFromMHCApiResponse(res, 201, 'test');
        System.assert(res.statusCode == 201);
    }
}