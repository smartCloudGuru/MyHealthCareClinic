/**
 * Created 5.4.2024..
 */

@IsTest
private class emailTLPCtrlTest {

    @TestSetup
    static void dataSetup() {

        Booking_Detail__c bd = new Booking_Detail__c();
        bd.Request__c = '{}';
        bd.Scheduled_Start__c = Datetime.now();
        insert bd;
    }

    @IsTest
    static void testPageLoad() {
        Booking_Detail__c bd = [SELECT Id FROM Booking_Detail__c LIMIT 1];
        emailTLPCtrl ctrl = new emailTLPCtrl();
        ctrl.recId = bd.Id;
        System.assert(ctrl.formattedSchedStartTime != null);
    }

    @IsTest
    static void testSubmitRequest() {

        emailTLPCtrl.SubmitRequest sr = new emailTLPCtrl.SubmitRequest();
        sr.firstName = 'John';
        sr.lastName = 'Doe';
        sr.dob_d = '01';
        sr.dob_m = '01';
        sr.dob_y = '2000';

        sr.gender = '';
        sr.email = '';
        sr.phone = '';
        sr.postalCode = '';
        sr.city = '';
        sr.address1 = '';
        sr.address2 = '';
        sr.address3 = '';
        sr.county = '';
        sr.notes = '';
        sr.selectedDate = '';
        sr.timeSelected = Datetime.now();
        sr.timeSelectedEnd = Datetime.now();

        Date expectedDOB = Date.newInstance(2000, 1, 1);

        System.assertEquals(expectedDOB, sr.getDOB(), 'DOB should match the provided date');
    }
}