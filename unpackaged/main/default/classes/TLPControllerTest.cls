/**
 * Created 5.4.2024..
 */

@IsTest
private class TLPControllerTest {

    @TestSetup
    static void setup() {

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st1 = new ServiceTerritory(IsActive = true, Name = 'ST1', Aerona_PIN__c = '1111', Aerona_Id__c = '1112', Heydoc_Id__c = 'mock_st_hd_id');
        st1.OperatingHoursId = oh.Id;
        insert st1;

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical', IsActive = true, Appointment_Type__c = 'CLINIC');
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        Product2 product = new Product2(Name = 'GP 1', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true, Appointment__c = true);
        product.ProductCode = 'T-P-A';
        product.Store_Categories__c = 'GP Consultation';
        product.Business_Unit__c = 'GP';
        product.Online_Store_Tags__c = 'TLC HS Portal';
        insert product;

        Portal_Settings__c testSettings = Portal_Settings__c.getInstance();
        testSettings.Team_1_Key__c = 'team1Key';
        testSettings.Team_2_Key__c = 'team2Key';
        testSettings.Service_Territory_Id__c = st1.Id;
        insert testSettings;

        TLPController.portalSettings = testSettings;
    }

    @IsTest
    static void testObfuscateDeObfuscate() {
        // Define an input string for the test
        String testInput = 'This is a test string.';

        // Call the obfuscate method and store the result
        String enc = TLPController.obfuscate(testInput);
        String deObfuscatedResult = TLPController.deobfuscate(enc);

        System.assertEquals(testInput, deObfuscatedResult);


    }

    @IsTest
    static void testGetTLCPortalWorkTypeGroups() {
        String serializedProducts = TLPController.getTLCPortalWorkTypeGroups();

        System.assert(serializedProducts != null);
    }

    @IsTest
    static void testGetSembleDoctorId() {
        String result = TLPController.getSembleDoctorId([SELECT Id FROM ServiceResource LIMIT 1].Id);

        // Validate the results
        System.assertEquals('mock_hd_sr_id', result, 'Expected Heydoc_Id__c to be retrieved correctly');
    }

    @IsTest
    static void testTeamKeys() {
        String result = TLPController.checkAccessKey('team1Key');
        System.assertNotEquals(null, result);
        String authCheck = TLPController.checkAuthentication('CookieConsentPolicy=0:1; myData=abc; tlcsession=' + result);
        System.assertEquals('1', authCheck);

        result = TLPController.checkAccessKey('team2Key');
        System.assertNotEquals(null, result);
        authCheck = TLPController.checkAuthentication('CookieConsentPolicy=0:1; myData=abc; tlcsession=' + result);
        System.assertEquals('2', authCheck);

        result = TLPController.checkAccessKey('invalidKey');
        System.assertEquals(null, result);
    }

    @IsTest
    static void testDoSubmit() {

        HeyDocServiceMock.setAsMock();

        String auth = TLPController.checkAccessKey('team1Key');

        // Setup method data
        TLPController.SubmitRequest submitRequest = new TLPController.SubmitRequest();
        submitRequest.cookies = 'tlcsession=' + auth;
        submitRequest.email = 'test@example.com';
        submitRequest.dob_d = '1';
        submitRequest.dob_m = '1';
        submitRequest.dob_y = '1999';
        submitRequest.selectedWorkTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        submitRequest.addons = 'Some addon';
        submitRequest.notes = 'Some notes';


        Test.startTest();

        String submit_result = TLPController.doSubmit(JSON.serialize(submitRequest));

        Test.stopTest();

        System.debug(submit_result);

        System.assertNotEquals(null, submit_result, 'Test failed. Null result received');
        TLPController.SubmitResponse res = (TLPController.SubmitResponse) System.JSON.deserialize(submit_result, TLPController.SubmitResponse.class);

        System.assertNotEquals(null, res.extPatientId, 'PatientId should not be null');

        List<Booking_Detail__c> bds = [SELECT Id, UUID__c, Team__c, Request__c, Work_Type_Group__c, External_Patient_Id__c, External_Booking_Id__c FROM Booking_Detail__c];
        System.debug(JSON.serialize(bds[0]));
        System.assert(bds.size() == 1);

        String bookingDetailsByCode = TLPController.getBookingDetailsByCode(bds[0].UUID__c);
        System.assert(bookingDetailsByCode != null);

    }

    @IsTest
    static void testDoReschedule() {

        String auth = TLPController.checkAccessKey('team1Key');

        TLPController.SubmitRequest submitRequest = new TLPController.SubmitRequest();
        submitRequest.cookies = 'tlcsession=' + auth;
        submitRequest.email = 'test@example.com';
        submitRequest.dob_d = '1';
        submitRequest.dob_m = '1';
        submitRequest.dob_y = '1999';
        submitRequest.selectedWorkTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        submitRequest.addons = 'Some addon';
        submitRequest.notes = 'Some notes';

        Booking_Detail__c bd = new Booking_Detail__c();
        bd.UUID__c = '#123';
        bd.Request__c = JSON.serialize(submitRequest);
        bd.Work_Type_Group__c = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        bd.External_Patient_Id__c = '5fbd1955d9aa7d001170fcb6';
        bd.External_Booking_Id__c = 'mock_hd_book_id';
        insert bd;

        // Setup method data
        TLPController.SubmitRequest rescheduleRequest = new TLPController.SubmitRequest();
        rescheduleRequest.cookies = 'tlcsession=' + auth;
        rescheduleRequest.email = 'test@example.com';
        rescheduleRequest.dob_d = '1';
        rescheduleRequest.dob_m = '1';
        rescheduleRequest.dob_y = '1999';
        rescheduleRequest.selectedWorkTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        rescheduleRequest.addons = 'Some addon';
        rescheduleRequest.notes = 'Some notes';

        HeyDocServiceMock.setAsMock();

        Test.startTest();
        String reschedule_result = TLPController.doRescheduleByCode(bd.UUID__c, JSON.serialize(rescheduleRequest));
        Test.stopTest();

        System.assert(reschedule_result != null);

    }

    @IsTest
    static void testDoCancel() {

        String auth = TLPController.checkAccessKey('team1Key');

        TLPController.SubmitRequest submitRequest = new TLPController.SubmitRequest();
        submitRequest.cookies = 'tlcsession=' + auth;
        submitRequest.email = 'test@example.com';
        submitRequest.dob_d = '1';
        submitRequest.dob_m = '1';
        submitRequest.dob_y = '1999';
        submitRequest.selectedWorkTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        submitRequest.addons = 'Some addon';
        submitRequest.notes = 'Some notes';

        Booking_Detail__c bd = new Booking_Detail__c();
        bd.UUID__c = '#123';
        bd.Request__c = JSON.serialize(submitRequest);
        bd.Work_Type_Group__c = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        bd.External_Patient_Id__c = '5fbd1955d9aa7d001170fcb6';
        bd.External_Booking_Id__c = 'mock_hd_book_id';
        insert bd;


        HeyDocServiceMock.setAsMock();

        Test.startTest();
        String reschedule_result = TLPController.doCancelByCode('tlcsession=' + auth, bd.UUID__c);
        Test.stopTest();

        System.assert(reschedule_result != null);

    }
}