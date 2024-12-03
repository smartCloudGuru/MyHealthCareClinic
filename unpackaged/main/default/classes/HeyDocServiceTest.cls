@IsTest
public class HeyDocServiceTest {

    @IsTest
    static void createBookingTest() {
        HeyDocService.BookingDataInput bookingData = new HeyDocService.BookingDataInput();
        bookingData.start = Datetime.now();
        bookingData.end_jsonsafe = Datetime.now().addMinutes(30);
        HeyDocServiceMock.setAsMock();
        HeyDocService.Booking booking = HeyDocService.createBooking(bookingData);
        System.assert(booking != null);
    }

    @IsTest
    static void createPatientTest() {
        HeyDocService.CreatePatientDataInput input = new HeyDocService.CreatePatientDataInput();
        HeyDocServiceMock.setAsMock();
        String id = HeyDocService.createPatient(input);
        System.assert(id != null);
    }

    @IsTest
    static void updatePatientTest() {
        HeyDocService.UpdatePatientDataInput input = new HeyDocService.UpdatePatientDataInput();
        HeyDocServiceMock.setAsMock();
        String id = HeyDocService.updatePatient('id', input);
        System.assert(id != null);
    }

    @IsTest
    static void searchPatientsTest() {

        HeyDocService.Pagination pagination = new HeyDocService.Pagination();
        pagination.page = 0;
        pagination.pageSize = 200;

        HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
        queryOptions.updatedAt = new HeyDocService.DateRange();
        queryOptions.updatedAt.start = Datetime.now().addHours(-4);
        queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);

        HeyDocService.PatientData patientData = null;

        HeyDocServiceMock.setAsMock();
        Test.startTest();
        patientData = HeyDocService.searchPatients(null, pagination, queryOptions);
        Test.stopTest();
        System.assert(patientData != null);
    }

    @IsTest
    static void getPatient_Test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.Patient pat = HeyDocService.getPatient('somepatid');
        Test.stopTest();
        System.assert(pat != null);
    }

    @IsTest
    static void authenticate_Test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        String token = HeyDocService.authenticate_raw();
        Test.stopTest();
        System.assert(token != null);
    }

    @IsTest
    static void createPatientDocument_test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.PatientDocument patDoc = HeyDocService.createPatientDocument('somepatid', 'filename', 'application/pdf');
        Test.stopTest();
        System.assert(patDoc != null);
    }

    @IsTest
    static void getPatientBookings_Test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.Patient pat = HeyDocService.getPatientBookings('somepatid', Date.today(), Date.today());
        Test.stopTest();
        System.assert(pat != null);
    }

    @IsTest
    static void addPatientPhoneNumber_Test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.AddPhoneData apd = new HeyDocService.AddPhoneData();
        String ret = HeyDocService.addPatientPhoneNumber('somepatid', apd);
        Test.stopTest();
        System.assert(ret != null);
    }

    @IsTest
    static void updatePatientPhoneNumber_Test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.UpdatePhoneData upd = new HeyDocService.UpdatePhoneData();
        String ret = HeyDocService.updatePatientPhoneNumber('somepatid', 'somephoneId', upd);
        Test.stopTest();
        System.assert(ret != null);
    }

    @IsTest
    static void removePatientPhoneNumber_Test() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        String ret = HeyDocService.removePatientPhoneNumber('somepatid', 'somephoneId');
        Test.stopTest();
        System.assert(ret != null);
    }

    @IsTest
    static void queryProductsTest() {

        HeyDocService.Pagination pagination = new HeyDocService.Pagination();
        pagination.page = 0;
        pagination.pageSize = 200;

        HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
        queryOptions.updatedAt = new HeyDocService.DateRange();
        queryOptions.updatedAt.start = Datetime.now().addHours(-4);
        queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);


        HeyDocServiceMock.setAsMock();
        Test.startTest();
        List<HeyDocService.HeydocProduct> products = HeyDocService.queryProducts(null, pagination, queryOptions);
        Test.stopTest();
        System.assert(products != null);
    }

    @IsTest
    static void queryBookingsTest() {

        HeyDocService.DateRange dateRange = new HeyDocService.DateRange();
        dateRange.start = Datetime.now().addHours(-24 * 7);
        dateRange.end_jsonsafe = Datetime.now().addMonths(6);

        HeyDocService.Pagination pagination = new HeyDocService.Pagination();
        pagination.page = 0;
        pagination.pageSize = 200;

        HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
        queryOptions.updatedAt = new HeyDocService.DateRange();
        queryOptions.updatedAt.start = Datetime.now().addHours(-4);
        queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);


        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.BookingData bookingData = HeyDocService.queryBookings(null, pagination, queryOptions);
        Test.stopTest();
        System.assert(bookingData != null && bookingData.data != null);
    }

    @IsTest
    static void queryInvoicesTest() {

        HeyDocService.DateRange dateRange = new HeyDocService.DateRange();
        dateRange.start = Datetime.now().addHours(-24 * 7);
        dateRange.end_jsonsafe = Datetime.now().addMonths(6);

        HeyDocService.Pagination pagination = new HeyDocService.Pagination();
        pagination.page = 0;
        pagination.pageSize = 200;

        HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
        queryOptions.updatedAt = new HeyDocService.DateRange();
        queryOptions.updatedAt.start = Datetime.now().addHours(-4);
        queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);


        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.InvoiceData invoiceData = HeyDocService.queryInvoices(null, pagination, queryOptions);
        Test.stopTest();
        System.assert(invoiceData != null && invoiceData.data != null);
    }

    @IsTest
    static void updateBookingTest() {

        HeyDocService.BookingDataInput bookingDataInput = new HeyDocService.BookingDataInput();

        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.Booking booking = HeyDocService.updateBooking('some-id', bookingDataInput);
        Test.stopTest();
        System.assert(booking != null && booking.id != null);
    }

    @IsTest
    static void deleteBookingTest() {

        HeyDocServiceMock.setAsMock();
        Test.startTest();
        Boolean ret = HeyDocService.deleteBooking('some-id');
        Test.stopTest();
        System.assert(ret == true);
    }

    @IsTest
    static void createInvoiceTest() {

        HeyDocService.NewInvoiceDataInput invoiceDataInput = new HeyDocService.NewInvoiceDataInput();
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocService.Invoice invoice = HeyDocService.createInvoice(invoiceDataInput)?.invoiceData;
        Test.stopTest();
        System.assert(invoice != null && invoice.id != null);
    }

    @IsTest
    static void queryAvailabilitiesTest() {
        HeyDocServiceMock.setAsMock();
        HeyDocService.DateRange dateRange = new HeyDocService.DateRange();
        dateRange.start = Datetime.now();
        dateRange.end_jsonsafe = Datetime.now().addDays(1);
        String locationId = 'loc-id';
        String doctorId = 'doc-id';
        Test.startTest();
        HeyDocService.queryAvailabilities(dateRange, locationId, doctorId);
        Test.stopTest();
    }

    @IsTest
    static void publishIntegrationLog_test() {
        HeyDocService.publishIntegrationLog(true, '00326000014mOFsAAM', 'test operation', 'request json', 'response json', 201);
    }

    @IsTest
    static void adjustTimeZoneForHeydocOnReceive_test() {
        System.debug(HeyDocService.adjustTimeZoneForHeydocOnReceive(Datetime.now()));
    }


}