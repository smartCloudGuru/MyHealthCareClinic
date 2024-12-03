/**
 * Created 29.3.2022..
 */

@IsTest
private class ExternalSyncJobRetrieveAppsTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].HeyDoc_Id__c = HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID;
        update accounts;

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st = new ServiceTerritory();
        st.Name = 'unit test location';
        st.Heydoc_Id__c = 'mock_hd_loc_id';
        st.IsActive = true;
        st.OperatingHoursId = oh.Id;
        insert st;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = accounts[0].Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        insert sa;

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;
    }


    /*
    //commented out, we need updates to SAs only

    @IsTest
    static void test_getAppointments_new() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncJobRetrieveAppointments.scheduleGetAppointments();
        Test.stopTest();
        List<ServiceAppointment> apps = [SELECT Id, Heydoc_Appointment_Id__c FROM ServiceAppointment WHERE Heydoc_Appointment_Id__c != NULL];
         System.assert(apps.isEmpty() == false);
    }
    */

    @IsTest
    static void test_getAppointments_modifyApp() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Heydoc_Appointment_Id__c = NULL LIMIT 1];
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addHours(1);
        sa.Heydoc_Appointment_Id__c = 'mock_hd_book_id';
        update sa;

        HeyDocServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncJobRetrieveAppointments.getAppointments();
        Test.stopTest();
        List<ServiceAppointment> apps = [SELECT Id, Heydoc_Appointment_Id__c FROM ServiceAppointment WHERE Heydoc_Appointment_Id__c != NULL];
        System.assert(apps.isEmpty() == false);
    }

    @IsTest
    static void test_isDifferent() {
        System.assert(ExternalSyncJobRetrieveAppointments.isDifferent('a','b') == true);
    }

    @IsTest
    static void test_getJourneyStatus() {
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(null) == null);

        HeyDocService.Booking book = new HeyDocService.Booking();
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(book) == null);

        book.bookingJourney = new HeyDocService.Journey();
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(book) == null);

        book.bookingJourney.arrived = Datetime.now();
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(book) == 'Arrived');

        book.bookingJourney.consultation = Datetime.now();
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(book) == 'Consultation');

        book.bookingJourney.departed = Datetime.now();
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(book) == 'Departed');

        book.bookingJourney.dna = Datetime.now();
        System.assert(ExternalSyncJobRetrieveAppointments.getJourneyStatus(book) == 'DNA');

    }

    @IsTest
    static void test_dateFormat() {
        System.debug(ExternalSyncJobRetrieveAppointments.dateformat(Datetime.now()));
    }


    @IsTest
    static void test_deleteServiceAppointments() {

        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        ExternalSyncJobRetrieveAppointments.deleteServiceAppointments(serviceAppointments);
    }
    @IsTest
    static void test_updateServiceAppointments() {
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        ExternalSyncJobRetrieveAppointments.updateServiceAppointments(serviceAppointments);
    }

    @IsTest
    static void test_deleteAssignedResources() {

        List<AssignedResource> rs = [SELECT Id FROM AssignedResource];
        ExternalSyncJobRetrieveAppointments.deleteAssignedResources(rs);
    }
    @IsTest
    static void test_insertAssignedResources() {
        List<AssignedResource> rs = new List<AssignedResource>();
        rs.add (new AssignedResource(
                ServiceResourceId = [SELECT Id FROM ServiceResource].Id,
                ServiceAppointmentId = [SELECT Id FROM ServiceAppointment].Id
        ));
        ExternalSyncJobRetrieveAppointments.insertAssignedResources(rs);
    }
    @IsTest
    static void testToExternalBooking_NullBooking() {
        // Test when sembleBooking is null
        External_Booking__c result = ExternalSyncJobRetrieveAppointments.toExternalBooking(null, new Map<String, Account>(), new Map<String, ServiceTerritory>(), new Map<String, WorkTypeGroup>());
        System.assertEquals(null, result, 'Expected result to be null when sembleBooking is null');
    }

    @IsTest
    static void testToExternalBooking_ValidBooking() {
        // Create mock data
        String patientId = '0012w00000BkmXM'; // Sample patient Id
        String clinicId = '0Hh4H000000Kyw6SAC';
        String appointmentTypeId = '0VS8e000000Kyl6GAC';

        Account mockAccount = new Account(Id = patientId, Name = 'Test Patient');
        ServiceTerritory mockServiceTerritory = new ServiceTerritory(Id = clinicId, Site__c = 'Test Site');
        WorkTypeGroup mockWorkTypeGroup = new WorkTypeGroup(Id = appointmentTypeId);

        Map<String, Account> accounts = new Map<String, Account>{patientId => mockAccount};
        Map<String, ServiceTerritory> allSts = new Map<String, ServiceTerritory>{clinicId => mockServiceTerritory};
        Map<String, WorkTypeGroup> allWTGS = new Map<String, WorkTypeGroup>{appointmentTypeId => mockWorkTypeGroup};

        HeyDocService.Booking mockBooking = new HeyDocService.Booking();
        mockBooking.patientId = patientId;
        mockBooking.start = DateTime.now();
        mockBooking.appointment = new HeyDocService.Appointment();
        mockBooking.appointment.id = appointmentTypeId;
        mockBooking.location = new HeyDocService.BookingLocation();
        mockBooking.location.id = clinicId;
        mockBooking.id = '12345';

        Test.startTest();
        External_Booking__c result = ExternalSyncJobRetrieveAppointments.toExternalBooking(mockBooking, accounts, allSts, allWTGS);
        Test.stopTest();

        // Validate the results
        System.assertNotEquals(null, result, 'Expected result to be a valid External_Booking__c record');
        System.assertEquals('Semble', result.External_System__c);
        System.assertEquals(patientId, result.Account__c);
        System.assertEquals(mockBooking.start, result.Appointment_Time__c);
        System.assertEquals(String.valueOf(mockBooking.appointment.id), result.External_Appointment_Type__c);
        System.assertEquals(String.valueOf(mockBooking.patientId), result.External_Patient_Id__c);
        System.assertEquals(String.valueOf(mockBooking.location.id), result.External_Clinic_Id__c);
        System.assertEquals(mockServiceTerritory.Site__c, result.Site__c);
        System.assertEquals(mockServiceTerritory.Id, result.Service_Territory__c);
        System.assertEquals(String.valueOf(mockBooking.id), result.External_Id__c);
        System.assertEquals(mockWorkTypeGroup.Id, result.Work_Type_Group__c);
    }

    @IsTest
    static void testToExternalBooking_InvalidPatientId() {
        // Create mock data
        HeyDocService.Booking mockBooking = new HeyDocService.Booking();
        mockBooking.patientId = '67890';

        Map<String, Account> accounts = new Map<String, Account>();
        Map<String, ServiceTerritory> allSts = new Map<String, ServiceTerritory>();
        Map<String, WorkTypeGroup> allWTGS = new Map<String, WorkTypeGroup>();

        Test.startTest();
        External_Booking__c result = ExternalSyncJobRetrieveAppointments.toExternalBooking(mockBooking, accounts, allSts, allWTGS);
        Test.stopTest();

        // Validate the results
        System.assertEquals(null, result, 'Expected result to be null when patientId does not match any account');
    }


}