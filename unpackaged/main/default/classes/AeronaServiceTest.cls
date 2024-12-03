/**
 * Created 7.9.2022..
 */

@IsTest
private class AeronaServiceTest {


    @TestSetup
    public static void setUp() {

    }

    @IsTest
    static void createAppointment_test() {

        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASCreateAppointmentRequest request = new AeronaServiceOASApi.OASCreateAppointmentRequest();

        Test.startTest();
        Long response = AeronaService.createAppointment(request);
        Test.stopTest();

        System.debug('::createAppointment_test:response:' + response);
        System.assert(response != null); 
        System.assert(response > 0);

    }


    @IsTest
    static void getPaymentMethods_test() {

        AeronaServiceMock.setAsMock();

        Test.startTest();
        List<AeronaServiceOASApi.OASPaymentMethod> response = AeronaService.getPaymentMethods();
        Test.stopTest();

        System.debug('::getPaymentMethods_test:response:' + response);
        System.assert(response != null);

    }


    @IsTest
    static void createPayment_test() {

        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASCreatePaymentRequest request = new AeronaServiceOASApi.OASCreatePaymentRequest();
        request.amount = '12.34';

        Test.startTest();
        Long response = AeronaService.createPayment(request);

        Test.stopTest();

        System.debug('::createPayment_test:response:' + response);
        System.assert(response != null);
        System.assert(response > 0);

    }

    @IsTest
    static void createPayment_with0Amount_test() {
        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASCreatePaymentRequest request = new AeronaServiceOASApi.OASCreatePaymentRequest();
        request.amount = '0.00';

        Test.startTest();
        Long response = AeronaService.createPayment(request);

        Test.stopTest();

        System.debug('::createPayment_with0Amount_test:response:' + response);
        System.assert(response != null);
        System.assert(response == 0);

    }

    @IsTest
    static void createInvoice_test() {
        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASCreateInvoiceRequest request = new AeronaServiceOASApi.OASCreateInvoiceRequest();
        request.date_jsonsafe = Datetime.now();
        request.itemStatus = AeronaServiceOASApi.INVOICE_STATUS_PRECHARGED;

        Test.startTest();
        Long response = AeronaService.createInvoice(request);

        Test.stopTest();

        System.debug('::createInvoice__test:response:' + response);
        System.assert(response != null);
        System.assert(response > 0);

    }


    @IsTest
    static void getAppointment_test() {

        AeronaServiceMock.setAsMock();

        Test.startTest();
        AeronaServiceOASApi.OASAPIAppointmentDetails response = AeronaService.getAppointment(222);
        Test.stopTest();

        System.debug('::getAppointment_test:response:' + response);
        System.assert(response != null);

    }

    @IsTest
    static void findAppointmentSlot_test() {

        AeronaServiceMock.setAsMock();

        String appointmentTypeId = '1';
        String practiceId = '12';
        Date searchStart = Date.today();
        String clinicianId = '11';


        Test.startTest();
        List<AeronaServiceOASApi.OASAPIFreeAppointmentSlot> response = AeronaService.findAppointmentSlot(
                appointmentTypeId, practiceId, null, clinicianId, searchStart
        );
        response = AeronaService.findAppointmentSlot(
                appointmentTypeId, practiceId, '1111', clinicianId, searchStart
        );
        response = AeronaService.findAppointmentSlot(
                appointmentTypeId, practiceId, '1111', clinicianId, searchStart
        );

        response = AeronaService.findAppointmentSlot(
                appointmentTypeId, practiceId, '2222', clinicianId, searchStart
        );
        Test.stopTest();

        System.debug('::findAppointmentSlot_test:response:' + response);
        System.assert(response != null); 
        System.assert(response.size() > 0);

    }

    @IsTest
    static void updateAppointment_test() {
        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASUpdateAppointmentRequest request = new AeronaServiceOASApi.OASUpdateAppointmentRequest();

        Test.startTest();
        Boolean response = AeronaService.updateAppointment('123', request);
        Test.stopTest();

        System.assert(response != null);
        System.assert(response); 

    }

    @IsTest
    static void createPatient_test() {
        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASCreatePatientRequest request = new AeronaServiceOASApi.OASCreatePatientRequest();

        Test.startTest();
        AeronaServiceOASApi.OASCreatePatientResponse response = AeronaService.createPatient(request);
        Test.stopTest();

        System.debug('::createPatient_test:response:' + response);
        System.assert(response != null);
        System.assert(response.id != null); 
    }

    @IsTest
    static void createPatient_withDuplicates_test() {
        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASCreatePatientRequest request = new AeronaServiceOASApi.OASCreatePatientRequest();
        request.surname = 'FORCE_DUPLICATE';

        Test.startTest();
        AeronaServiceOASApi.OASCreatePatientResponse response = AeronaService.createPatient(request);
        Test.stopTest();

        System.debug('::createPatient_test:response:' + response);
        System.assert(response != null);
        System.assert(response.id == 0); 
        System.assert(response.hasDuplicates());
    }

    @IsTest
    static void updatePatient_test() {
        AeronaServiceMock.setAsMock();

        AeronaServiceOASApi.OASUpdatePatientRequest request = new AeronaServiceOASApi.OASUpdatePatientRequest();

        Test.startTest();
        Boolean response = AeronaService.updatePatient('123', request);
        Test.stopTest();

        System.assert(response != null);
        System.assert(response); 
    }

    @IsTest
    static void searchPatient_test() {
        AeronaServiceMock.setAsMock();

        Test.startTest();
        List<AeronaServiceOASApi.OASDuplicatePatient> response = AeronaService.searchPatient('test@example.com', Date.today().addDays(-50));
        Test.stopTest();

        System.assert(response != null);
        System.assert(response.size()>0);
    }

    @IsTest
    static void deleteBooking_test() {
        AeronaServiceMock.setAsMock();

        Test.startTest();
        Boolean response = AeronaService.deleteBooking('123');
        Test.stopTest();

        System.assert(response != null);
        System.assert(response); 
    }

    @IsTest
    static void getAllClinicians_test() {

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st1 = new ServiceTerritory(IsActive= true, Name = 'ST1', Aerona_PIN__c = '1111', Aerona_Id__c = '1112');
        st1.OperatingHoursId = oh.Id;
        ServiceTerritory st2 = new ServiceTerritory(IsActive= true, Name = 'ST1', Aerona_PIN__c = '2111', Aerona_Id__c = '2112');
        st2.OperatingHoursId = oh.Id;
        insert st1;
        insert st2;
        AeronaServiceMock.setAsMock();
        Test.startTest();
        Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>> ret = AeronaService.getAllClinicians();
        Test.stopTest();
        System.assert(ret.size()==2);
    }

    @IsTest
    static void getCarePlans_test() {

        AeronaServiceMock.setAsMock();
        Test.startTest();
        List<AeronaServiceOASApi.OASCarePlan> ret = AeronaService.getCarePlans();
        Test.stopTest();
        System.assert(ret.size()==2);
    }

    @IsTest
    static void createPatientCarePlans_test() {

        AeronaServiceOASApi.OASAPIPatientCarePlan request = new AeronaServiceOASApi.OASAPIPatientCarePlan();

        request.patientId = 2222;
        request.carePlanId = 3333;

        AeronaServiceMock.setAsMock();

        Test.startTest();
        Long ret = AeronaService.createPatientCarePlan(request);
        Test.stopTest();
        System.debug(ret);
        System.assert(ret!=null);
    }

    @IsTest
    static void calcAeronaFingerprint_test() {
        System.assert(AeronaService.calcAeronaFingerprint(new ServiceAppointment())!=null);
    }

    @IsTest
    static void publishIntegrationLog_test() {
        AeronaServiceOAS.publishIntegrationLog(true, '00326000014mOFsAAM', 'test operation', 'request json', 'response json', 201);
    }

}