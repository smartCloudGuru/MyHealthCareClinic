public without sharing class HeyDocService {

    public static final HeyDoc_Integration_Setting__mdt INTEGRATIONS_SETTINGS = [
            SELECT Api_Key__c, Password__c, URL_Endpoint__c, Page_Size__c, Query_Time_Months__c, API_Token__c
            FROM HeyDoc_Integration_Setting__mdt
            LIMIT 1
    ];


    private static final String MUTATION_CREATE_PATIENT_DOCUMENT =
            'mutation createPatientDocument($patient: ID!, $name: String!, $type: String!) { createPatientDocument(patient: $patient, name: $name, type: $type) { data { id title path name type url uploadUrl downloadUrl} error }}';

    private static final String MUTATION_CREATE_BOOKING =
            'mutation createBooking($bookingData: BookingDataInput) { createBooking(bookingData: $bookingData) {' +
                    ' data { id createdAt videoUrl } error }}';

    private static final String MUTATION_CREATE_INVOICE =
            'mutation createInvoice($invoiceData: NewInvoiceDataInput) { createInvoice(invoiceData: $invoiceData) {' +
                    ' data { id status invoiceNumber paymentReference date patientId doctorId tax total outstanding comments extraInfo type createdAt  } error }}';

    private static final String MUTATION_UPDATE_BOOKING =
            'mutation updateBooking($id: ID!, $bookingData: BookingDataInput) { updateBooking(id: $id, bookingData: $bookingData) {' +
                    ' data { id createdAt videoUrl } error }}';

    private static final String MUTATION_DELETE_BOOKING =
            'mutation deleteBooking($id: ID!) { deleteBooking(id: $id) { data {id } error }}';


    private static final String QUERY_SEARCH_PATIENTS =
            'query patients($search: String, $pagination: Pagination, $options: QueryOptions) {' +
                    ' patients(search: $search, pagination: $pagination, options: $options) {' +
                    ' data {' +
                    '  id' +
                    '  status' +
                    '  firstName lastName' +
                    '  dob' +
                    '  email' +
                    '  gender' +
                    '  address { address city postcode country }' +
                    '  phones { phoneType phoneNumber }' +
                    '  updatedAt' +
                    ' }' +
                    ' pageInfo { hasMore } ' +
                    '}}';

    private static final String QUERY_INVOICES =
            'query invoices($dateRange: DateRange!, $pagination: Pagination, $options: QueryOptions) {' +
                    ' invoices( dateRange: $dateRange, pagination: $pagination, options: $options) {' +
                    '    data { id status date patientId total outstanding lineItems { id title productType itemCode} paymentReference invoiceNumber comments extraInfo type } ' +
                    '    pageInfo { hasMore } ' +
                    '}}';

    private static final String QUERY_PATIENT =
            'query patient($id: ID!) { patient(id: $id) { id status firstName lastName dob email address { address city postcode country } phones { phoneId phoneType phoneNumber } comments updatedAt }}';

    private static final String QUERY_PATIENT_BOOKINGS =
            'query patient($id: ID!, $start:Date!, $end:Date! ) { patient(id: $id) { id ' +
                    ' bookings(start: $start, end: $end) { id deleted start end appointment { id title } bookingJourney { arrived consultation departed dna } } }}';

    private static final String QUERY_BOOKINGS =
            'query bookings($dateRange: DateRange, $pagination: Pagination, $options: QueryOptions) {' +
                    ' bookings(dateRange: $dateRange, pagination: $pagination, options: $options) {' +
                    ' data {' +
                    '  id deleted cancellationReason ' +
                    '  doctor { id } ' +
                    '  location { id } ' +
                    '  appointment { id title }' +
                    '  start end ' +
                    '  patientId ' +
                    '  bookingJourney { arrived consultation departed dna }' +
                    '  createdAt updatedAt ' +
                    '  videoUrl ' +
                    '  comments ' +
                    ' }' +
                    ' pageInfo { hasMore } ' +
                    '}}';

    private static final String QUERY_RECORDS =
            'query records($dateRange: DateRange, $pagination: Pagination, $options: QueryOptions) {' +
                    ' records(dateRange: $dateRange, pagination: $pagination, options: $options) {' +
                    ' data { id consultationId sectionId sectionTitle recordType patient title term date dosage quantity comments }' +
                    ' pageInfo { hasMore } ' +
                    '}}';

    private static final String QUERY_PRODUCTS =
            'query products($search: String, $pagination: Pagination, $options: QueryOptions) {' +
                    ' products(search: $search, pagination: $pagination, options: $options) {' +
                    ' data {' +
                    ' id productType name price itemCode supplierName duration isBookable cost comments isVideoConsultation ' +
                    ' }' +
                    ' pageInfo { hasMore } ' +
                    '}}';

    private static final String MUTATION_CREATE_PATIENT =
            'mutation createPatient($patientData: CreatePatientDataInput) { createPatient(patientData: $patientData) {' +
                    ' data { id }' +
                    ' error' +
                    ' }}';

    private static final String MUTATION_UPDATE_PATIENT =
            'mutation updatePatient($id: ID!, $patientData: UpdatePatientDataInput!) { updatePatient(id: $id, patientData: $patientData) {' +
                    ' data { id } error }}';

    private static final String MUTATION_ADD_PATIENT_PHONE_NUMBER = '' +
            'mutation addPatientPhoneNumber($patientId: ID!, $phoneData: AddPhoneData!) {\n' +
            '  addPatientPhoneNumber(patientId: $patientId, phoneData: $phoneData) {\n' +
            '    data { id } error }}';

    private static final String MUTATION_REMOVE_PATIENT_PHONE_NUMBER = '' +
            'mutation removePatientPhoneNumber($patientId: ID!, $phoneId: ID!) {\n' +
            '  removePatientPhoneNumber(patientId: $patientId, phoneId: $phoneId) {\n' +
            '    data { id } error }}';

    private static final String MUTATION_UPDATE_PATIENT_PHONE_NUMBER = '' +
            'mutation updatePatientPhoneNumber($patientId: ID!, $phoneId: ID!, $phoneData: UpdatePhoneData) {\n' +
            '  updatePatientPhoneNumber(patientId: $patientId, phoneId: $phoneId, phoneData: $phoneData) {\n' +
            '    data { id } error }}';


    private static final String QUERY_PRACTICE =
            'query practice {' +
                    '  practice {' +
                    '    id' +
                    '    locations {' +
                    '      id name' +
                    '    }' +
                    '    appointmentTypes {' +
                    '      id title' +
                    '    }' +
                    '    paymentTypes {' +
                    '      id name' +
                    '    }' +
                    '  }' +
                    '}';

    private static final String QUERY_AVAILABILITIES =
            'query availabilities($dateRange: DateRange!, $locationId: ID!, $doctorId: ID) {' +
                    ' availabilities(dateRange: $dateRange, locationId: $locationId, doctorId: $doctorId) {' +
                    ' data { start end }' +
                    '}}';


    public static String authenticate_raw() {

        GraphQLNode authenticateNode = new GraphQLNode('')
                .setOperation('mutation')
                .add(
                        new GraphQLNode('signIn')
                                .addArguments(new GraphQLArgument('apiKey', INTEGRATIONS_SETTINGS.Api_Key__c))
                                .addArguments(
                                        new GraphQLArgument('password', INTEGRATIONS_SETTINGS.Password__c)
                                )
                                .add(new List<Object>{'token'})
                );

        System.debug(INTEGRATIONS_SETTINGS.URL_Endpoint__c);
        System.debug(INTEGRATIONS_SETTINGS.Api_Key__c);
        System.debug(INTEGRATIONS_SETTINGS.Password__c);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(INTEGRATIONS_SETTINGS.URL_Endpoint__c);
        req.setHeader('content-type', 'application/json');
        req.setMethod('POST');
        req.setBody(JSON.serialize(new Map<String, String>{'query' => authenticateNode.build()}));

        Http callout = new Http();
        HttpResponse res = callout.send(req);

        System.debug('::HDS:callout:res:body:' + res.getBody());

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'authenticate', req.getBody(), res?.getBody(), res?.getStatusCode());
        }

        Map<String, Map<String, Map<String, String>>> authResults = (Map<String, Map<String, Map<String, String>>>) JSON.deserialize(
                res.getBody(),
                Map<String, Map<String, Map<String, String>>>.class
        );

        String ret = authResults.get('data').get('signIn').get('token');
        return ret;
    }


    /*
    public static List<HeyDocBooking> getBookings() {
        return getBookings(1);
    }


    public static List<HeyDocBooking> getBookings(Integer pageNumber) {
        String startDate = String.valueOf(System.today().addDays(-7));
        String endDate = String.valueOf(
                System.today().addMonths(Integer.valueOf(INTEGRATIONS_SETTINGS.Query_Time_Months__c))
        );

        GraphQLNode patientNode = new GraphQLNode('patient');
        patientNode.add(PATIENT_FIELDS);
        patientNode.add(new GraphQLNode('phones').add(PHONE_FIELDS));
        patientNode.add(new GraphQLNode('address').add(ADDRESS_FIELDS));

        GraphQLNode queryNode = new GraphQLNode('')
                .setOperation('query')
                .add(
                        new GraphQLNode('bookings')
                                .addArguments(
                                        new GraphQLArgument(
                                                'dateRange',
                                                new List<GraphQLArgument>{
                                                        new GraphQLArgument('start', startDate),
                                                        new GraphQLArgument('end', endDate)
                                                }
                                        )
                                )
                                .addArguments(
                                        new GraphQLArgument(
                                                'pagination',
                                                new List<GraphQLArgument>{
                                                        new GraphQLArgument('page', pageNumber),
                                                        new GraphQLArgument(
                                                                'pageSize',
                                                                Integer.valueOf(INTEGRATIONS_SETTINGS.Page_Size__c)
                                                        )
                                                }
                                        )
                                )
                                .add(
                                        new GraphQLNode('data')
                                                .add(BOOKING_FIELDS)
                                                .add(patientNode)
                                                .add(new GraphQLNode('appointment').add(APPOINTM ENT_FIELDS))
                                                .add(new GraphQLNode('bookingJourney').add(JOURNEY_FIELDS))
                                                .add(new GraphQLNode('location').add(LOCATION_FIELDS))
                                )
                                .add(new GraphQLNode('pageInfo').add(PAGE_INFO_FIELDS))
                );

        HttpRequest req = new HttpRequest();
        req.setEndpoint(INTEGRATIONS_SETTINGS.URL_Endpoint__c);
        req.setHeader('content-type', 'application/json');

        req.setHeader('x-token', authToken);
        req.setMethod('POST');
        req.setBody(JSON.serialize(new Map<String, String>{'query' => queryNode.build()}));

        //        System.debug('::HeyDocService:getBookings:POST:body=' + req.getBody());
        Http callout = new Http();
        HttpResponse res = callout.send(req);

        System.debug('Queried HeyDoc with response code: ' + res.getStatusCode());
        //        System.debug('::HeyDocService:getBookings:resp.body=' + res.getBody());

        if (res.getStatusCode() != 200) {
            errorReporter.addError(
                    'HeyDoc Query',
                    null,
                    String.valueOf(res.getStatusCode()),
                    null,
                    res.getBody()
            );
            return new List<HeyDocBooking>();
        }

        return HeyDocBooking.parseBookings(res.getBody());
    }
    */

    /**
     * Add a booking to heydoc uses MUTATION_CREATE_PATIENT_DOCUMENT
     *
     * @param patientId
     * @param docName
     * @param docType application/pdf ?
     *
     * @return
     */
    public static PatientDocument createPatientDocument(String patientId, String docName, String docType) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('patient', patientId);
        variables.put('name', docName);
        variables.put('type', docType);

        HeyDocQueryResponse resp;
        try {
            HttpResponse res = sendPOST(MUTATION_CREATE_PATIENT_DOCUMENT, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, patientId, 'createPatientDocument', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            return resp?.data?.createPatientDocument?.data;
        }
        catch (Exception e) {
            String details = 'resp null';
            if (resp != null) details = JSON.serialize(resp);
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return null;
    }

    /**
     * Add a booking to heydoc uses MUTATION_CREATE_BOOKING
     *
     * @param bookingData
     *
     * @return
     */
    public static Booking createBooking(BookingDataInput bookingData) {

        Map<String, Object> variables = new Map<String, Object>();

        // we have to mote the heydoc start and end times to new timezones because they ignore timezone, and expect everything in local time notated as utc
        bookingData.start = adjustTimeZoneForHeydoc(bookingData.start);
        bookingData.end_jsonsafe = adjustTimeZoneForHeydoc(bookingData.end_jsonsafe);

        variables.put('bookingData', bookingData);

        HeyDocQueryResponse resp;
        try {
            HttpResponse res = sendPOST(MUTATION_CREATE_BOOKING, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'createBooking', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            return resp?.data?.createBooking?.data;
        }
        catch (Exception e) {
            publishIntegrationLog(true, null, 'createBooking', JSON.serialize(variables), e.getMessage(), 0);
            String details = 'resp null';
            if (resp != null) details = JSON.serialize(resp);
            System.debug(LoggingLevel.ERROR, e.getMessage());
            if (
                    (e.getMessage() != null && e.getMessage().contains('Patient must exist'))
                            || (details != null && details.contains('Patient must exist'))) {
                throw new MHCException('INVALID_PATIENT_SEMBLE_ID');
            }
        }

        return null;
    }

    /**
     * Update a booking to heydoc uses MUTATION_UPDATE_BOOKING
     *
     * @param id Id of booking to update
     * @param bookingData
     *
     * @return
     */
    public static Booking updateBooking(String id, BookingDataInput bookingData) {

        Map<String, Object> variables = new Map<String, Object>();

        // we have to mote the heydoc start and end times to new timezones because they ignore timezone, and expect everything in local time notated as utc
        bookingData.start = adjustTimeZoneForHeydoc(bookingData.start);
        bookingData.end_jsonsafe = adjustTimeZoneForHeydoc(bookingData.end_jsonsafe);

        variables.put('id', id);
        variables.put('bookingData', bookingData);

        try {
            HttpResponse res = sendPOST(MUTATION_UPDATE_BOOKING, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'updateBooking', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
                return null;
            }

            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            return resp?.data?.updateBooking?.data;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            if (e?.getMessage() != null && !e.getMessage().contains('uncommitted')) {
                publishIntegrationLog(true, null, 'updateBooking', JSON.serialize(variables), e.getMessage(), 0);
                return null;
            }
        }

        Booking b = new Booking();
        b.id = id;
        return b;
    }

    /**
     * Deletes a booking on HeyDoc by HeyDoc ID
     *
     * @param id Boking HeyDoc Id
     *
     * @return true if successful, otherwise false
     */
    public static Boolean deleteBooking(String id) {

        Map<String, Object> variables = new Map<String, Object>();
        variables.put('id', id);

        try {
            HttpResponse res = sendPOST(MUTATION_DELETE_BOOKING, variables);

            if (res?.getBody() != null && res.getBody().contains('Booking must exist')) return true;

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'deleteBooking', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);

            return String.isBlank(resp?.data?.deleteBooking?.error);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return false;
    }

    public static Datetime adjustTimeZoneForHeydoc(Datetime dt) {

        if (dt == null) return null;
        Datetime ret = Datetime.newInstanceGmt(
                dt.year(),
                dt.month(),
                dt.day(),
                dt.hour(),
                dt.minute(),
                dt.second());
        return ret;

    }

    public static Datetime adjustTimeZoneForHeydocOnReceive(Datetime dt) {
        if (dt == null) return null;
        Datetime ret = Datetime.newInstanceGmt(
                dt.year(),
                dt.month(),
                dt.day(),
                dt.hour(),
                dt.minute(),
                dt.second());

        ret = ret.addSeconds((Integer) (2 * (dt.getTime() - ret.getTime()) / 1000));

        return ret;

    }

    public static SembleResponseWrapper createInvoice(NewInvoiceDataInput invoiceData) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('invoiceData', invoiceData);

        SembleResponseWrapper ret = new SembleResponseWrapper();
        ret.sembleRequest = JSON.serialize(invoiceData);
        try {
            HttpResponse res = sendPOST(MUTATION_CREATE_INVOICE, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'createInvoice', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            ret.sembleResponseBody = res.getBody();
            ret.invoiceData = resp?.data?.createInvoice?.data;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return ret;
    }

    public class SembleResponseWrapper {
        public Invoice invoiceData;
        public String sembleRequest;
        public String sembleResponseBody;
    }


    /**
     * Create a patient in heydoc, uses MUTATION_CREATE_PATIENT
     *
     * @param input CreatePatientDataInput
     *
     * @return patientId String
     */
    public static String createPatient(CreatePatientDataInput input) {

        Map<String, CreatePatientDataInput> variables = new Map<String, CreatePatientDataInput>();

        variables.put('patientData', input);

        HttpResponse res = sendPOST(MUTATION_CREATE_PATIENT, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'createPatient', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);

        if (resp?.data?.createPatient?.error != null) {
            throw new HeyDocException(resp?.data?.createPatient?.error);
        }
        return resp?.data?.createPatient?.data?.id;

    }

    /**
     * Get patient by ID from Semble
     *
     * @param id patientId
     *
     * @return Patient data
     */
    public static Patient getPatient(String id) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('id', id);

        HttpResponse res = sendPOST(QUERY_PATIENT, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'getPatient', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);

        return resp?.data?.patient;
    }

    public static Patient getPatientBookings(String id, Date startDate, Date endDate) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('id', id);
        variables.put('start', startDate);
        variables.put('end', endDate);

        HttpResponse res = sendPOST(QUERY_PATIENT_BOOKINGS, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'getPatientBookings', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);

        return resp?.data?.patient;
    }

    /**
     * Update a patient in heydoc, uses MUTATION_UPDATE_PATIENT
     *
     * @param id
     * @param input CreatePatientDataInput
     *
     * @return patientId String
     */
    public static String updatePatient(String id, UpdatePatientDataInput input) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('id', id);
        variables.put('patientData', input);

        HttpResponse res = sendPOST(MUTATION_UPDATE_PATIENT, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'updatePatient', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);

        if (resp?.data?.updatePatient?.error != null) {
            throw new HeyDocException(resp?.data?.updatePatient?.error);
        }
        return resp?.data?.updatePatient?.data?.id;
    }


    public static String addPatientPhoneNumber(String patientId, AddPhoneData addPhoneData) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('patientId', patientId);
        variables.put('phoneData', addPhoneData);

        try {
            HttpResponse res = sendPOST(MUTATION_ADD_PATIENT_PHONE_NUMBER, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'addPatientPhoneNumber', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            return resp?.data?.addPatientPhoneNumber?.data?.id;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return null;
    }

    /**
     * Update a patient phone number in heydoc, uses MUTATION_UPDATE_PATIENT_PHONE_NUMBER
     *
     * @param id
     * @param phoneId UpdatePhoneData
     * @param updat UpdatePhoneData
     *
     * @return patientId String
     */
    public static String updatePatientPhoneNumber(String id, String phoneId, UpdatePhoneData updat) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('patientId', id);
        variables.put('phoneId', phoneId);
        variables.put('phoneData', updat);

        try {
            HttpResponse res = sendPOST(MUTATION_UPDATE_PATIENT_PHONE_NUMBER, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'updatePatientPhoneNumber', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            return resp?.data?.updatePatientPhoneNumber?.data?.id;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return null;
    }

    public static String removePatientPhoneNumber(String patientId, String phoneId) {

        Map<String, Object> variables = new Map<String, Object>();

        variables.put('patientId', patientId);
        variables.put('phoneId', phoneId);

        try {
            HttpResponse res = sendPOST(MUTATION_REMOVE_PATIENT_PHONE_NUMBER, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'removePatientPhoneNumber', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
            return resp?.data?.removePatientPhoneNumber?.data?.id;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return null;
    }


    /**
     * Search for patents by name
     * uses QUERY_SEARCH_PATIENTS
     *
     * @param search
     * @param pagination
     * @param queryOptions
     *
     * @return
     */
    public static PatientData searchPatients(String search, Pagination pagination, QueryOptions queryOptions) {

        Map<String, Object> variables = new Map<String, Object>();

        if (search != null) variables.put('search', search);
        if (pagination != null) variables.put('pagination', pagination);
        if (queryOptions != null) variables.put('options', queryOptions);

        HttpResponse res = sendPOST(QUERY_SEARCH_PATIENTS, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'searchPatients', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(res.getBody(), HeyDocQueryResponse.class);
        return resp?.data?.patients;
    }

    public static InvoiceData queryInvoices(DateRange dateRange, Pagination pagination, QueryOptions queryOptions) {

        Map<String, Object> variables = new Map<String, Object>();

        if (dateRange != null) variables.put('dateRange', dateRange);
        if (pagination != null) variables.put('pagination', pagination);
        if (queryOptions != null) variables.put('options', queryOptions);

        HttpResponse res = sendPOST(QUERY_INVOICES, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'queryInvoices', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        String body_jsonfixed = res.getBody().replaceAll('"date"', '"date_jsonsafe"');

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(body_jsonfixed, HeyDocQueryResponse.class);
        return resp?.data?.invoices;
    }

    public static BookingData queryBookings(DateRange dateRange, Pagination pagination, QueryOptions queryOptions) {

        Map<String, Object> variables = new Map<String, Object>();

        if (dateRange != null) variables.put('dateRange', dateRange);
        if (pagination != null) variables.put('pagination', pagination);
        if (queryOptions != null) variables.put('options', queryOptions);

        HttpResponse res = sendPOST(QUERY_BOOKINGS, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'queryBookings', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        String body_jsonfixed = res.getBody().replaceAll('"end"', '"end_jsonsafe"');
        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(body_jsonfixed, HeyDocQueryResponse.class);
        return resp?.data?.bookings;
    }

    public static RecordData queryRecords(DateRange dateRange, Pagination pagination, QueryOptions queryOptions) {

        Map<String, Object> variables = new Map<String, Object>();

        if (dateRange != null) variables.put('dateRange', dateRange);
        if (pagination != null) variables.put('pagination', pagination);
        if (queryOptions != null) variables.put('options', queryOptions);

        HttpResponse res = sendPOST(QUERY_RECORDS, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'queryRecords', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        String body_jsonfixed = res.getBody().replaceAll('"date"', '"date_jsonsafe"');

        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(body_jsonfixed, HeyDocQueryResponse.class);
        return resp?.data?.records;
    }

    public static List<AvailabilitiesData> queryAvailabilities(DateRange dateRange, String locationId, String doctorId) {

        try {

            Map<String, Object> variables = new Map<String, Object>();

            if (dateRange != null) variables.put('dateRange', dateRange);
            if (locationId != null) variables.put('locationId', locationId);
            if (doctorId != null) variables.put('doctorId', doctorId);

            HttpResponse res = sendPOST(QUERY_AVAILABILITIES, variables);

            if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
                publishIntegrationLog(true, null, 'queryAvailabilities', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
            }

            String body_jsonfixed = res.getBody().replaceAll('"end"', '"end_jsonsafe"');
            HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(body_jsonfixed, HeyDocQueryResponse.class);
            return resp?.data?.availabilities?.data;
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'error comm with Semble:' + ex.getMessage());
            return null;
        }

    }

    public static Practice queryPractice() {

        HttpResponse res = sendPOST(QUERY_PRACTICE, null);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'queryPractice', QUERY_PRACTICE, res?.getBody(), res?.getStatusCode());
        }

        String body_jsonfixed = res.getBody().replaceAll('"end"', '"end_jsonsafe"');
        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(body_jsonfixed, HeyDocQueryResponse.class);
        return resp?.data?.practice;
    }

    public static List<HeydocProduct> queryProducts(String search, Pagination pagination, QueryOptions queryOptions) {

        Map<String, Object> variables = new Map<String, Object>();

        if (search != null) variables.put('search', search);
        if (pagination != null) variables.put('pagination', pagination);
        if (queryOptions != null) variables.put('options', queryOptions);

        HttpResponse res = sendPOST(QUERY_PRODUCTS, variables);

        if ((res?.getStatusCode() != null && res.getStatusCode() >= 400) || (res?.getBody() != null && res.getBody().contains('"error":"'))) {
            publishIntegrationLog(true, null, 'queryProducts', JSON.serialize(variables), res?.getBody(), res?.getStatusCode());
        }

        String body_jsonfixed = res.getBody().replaceAll('"end"', '"end_jsonsafe"');
        HeyDocQueryResponse resp = (HeyDocQueryResponse) JSON.deserialize(body_jsonfixed, HeyDocQueryResponse.class);
        return resp?.data?.products?.data;
    }

    /**
     * Send GraphQL query and variables via POST to configured endpoint
     *
     * @param query
     * @param variables
     *
     * @return HttpResponse
     */
    private static HttpResponse sendPOST(String query, Map<String, Object> variables) {

        Map<String, Object> body = new Map<String, Object>();
        body.put('query', query);

        if (variables != null) {
            body.put('variables', variables);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(INTEGRATIONS_SETTINGS.URL_Endpoint__c);
        req.setHeader('content-type', 'application/json');
        req.setHeader('x-token', INTEGRATIONS_SETTINGS.API_Token__c);
        req.setMethod('POST');
        req.setTimeout(118000);
        //for availability, allow only 7 seconds for semble to respond
        if (req.getBody() != null && req.getBody().contains('query availabilities')) req.setTimeout(7000);
        req.setBody(JSON.serialize(body, true).replaceAll('_jsonsafe', ''));

        System.debug('::HeyDocService:sendPOST:POST:body=' + req.getBody());

        Http callout = new Http();
        Integer process_start = Datetime.now().millisecond();
        HttpResponse res = callout.send(req);

        System.debug('::HeyDocService:sendPOST:POST:resp.code;body=' + res.getStatusCode() + ';' + res.getBody());

        //        List<String> resHeaderKeys = res.getHeaderKeys();
        //
        //        if (resHeaderKeys!=null)
        //        {
        //            for (String hdr : resHeaderKeys) {
        //                System.debug('::HDS:sendPost:resp:header:' + hdr +'=' + res.getHeader(hdr));
        //            }
        //        }

        try {
            if (res.getBody() != null && res.getStatusCode() > 500) {

                publishIntegrationLog(true, null, 'Semble ' + res?.getStatusCode() + ', ' + ((Datetime.now().millisecond() - process_start)) + 'ms', req?.getBody(), res?.getBody(), res?.getStatusCode());
                callout = new Http();
                res = callout.send(req);

                System.debug('::HeyDocService:sendPOST:POST:retry:resp.code=' + res.getStatusCode());
                System.debug('::HeyDocService:sendPOST:POST:retry:resp.body=' + res.getBody());
            }
        }
        catch (Exception ignore) {

        }

        if (((Datetime.now().millisecond() - process_start)) >= 5000) {
            publishIntegrationLog(true, null, 'Semble Delay, ' + ((Datetime.now().millisecond() - process_start)) + 'ms', req?.getBody(), '', res?.getStatusCode());
        }

        return res;
    }

    public class HeyDocQueryResponse {
        public HeydocQueryResponseData data;
    }

    public class PatientData {
        public List<Patient> data;
        public PageInfo pageInfo;
    }

    public class BookingData {
        public List<Booking> data;
        public PageInfo pageInfo;
    }


    public class HeydocQueryResponseData {
        public HeydocQueryResponseCreatePatient createPatient;
        public HeydocQueryResponseUpdatePatient updatePatient;
        public BookingResponsePayload createBooking;
        public BookingResponsePayload updateBooking;
        public BookingResponsePayload deleteBooking;
        public NewInvoiceResponsePayload createInvoice;
        public PatientData patients;
        public BookingData bookings;
        public InvoiceData invoices;
        public RecordData records;
        public HeydocQueryResponseUpdatePatientPhoneNumber updatePatientPhoneNumber;
        public Products products;
        public Practice practice;
        public Availabilities availabilities;
        public Patient patient;
        public PatientResponsePayload addPatientPhoneNumber;
        public PatientResponsePayload removePatientPhoneNumber;
        public NewPatientDocumentPayload createPatientDocument;
    }

    public class Products {
        public List<HeydocProduct> data;
    }

    public class HeydocProduct {
        public String id;
        public String productType;
        public String name;
        public Decimal price;
        public Integer duration;
        public Boolean isBookable;
        public String comments;
        public Boolean isVideoConsultation;

        public Boolean isAppointment() {
            return this.productType == 'appointment';
        }
    }


    public class HeydocQueryResponseCreatePatient {
        public Patient data;
        public String error;
    }

    public class HeydocQueryResponseUpdatePatient {
        public Patient data;
        public String error;
    }

    public class BookingResponsePayload {
        public Booking data;
        public String error;
    }

    public class HeydocQueryResponseUpdatePatientPhoneNumber {
        public HeydocId data;
        public String error;
    }

    public class PatientResponsePayload {
        public Patient data;
        public String error;
    }

    public class NewPatientDocumentPayload {
        public PatientDocument data;
        public String error;
    }

    public class PatientDocument {
        public String id;
        public String title;
        public String patientId;
        public String path;
        public String name;
        public String type;
        public String url;
        public String parent;
        public Boolean deleted;
        public Date dateCreated;
        public Date dateModified;
        public String uploadUrl;
        public String downloadUrl;
    }

    public class HeydocId {
        public String id;
    }

    public class Patient {
        public String id;
        public String title;
        public String firstName;
        public String lastName;
        public Datetime dob;
        public String email;
        public String gender;
        public String sex;
        public String comments;
        public HeyDocService.Address address ;
        public List<Phone> phones;
        public List<Booking> bookings;

        public String getMobilePhone() {
            if (phones != null) {
                for (HeyDocService.Phone phone : phones) {
                    if (phone.phoneType == 'Mobile') {
                        return phone.phoneNumber;
                    }
                }
            }
            return null;
        }
    }

    public class Phone {
        public String phoneId;
        public String phoneType;
        public String phoneNumber;
    }

    public class CreatePatientDataInput {
        public String title;
        public String first;
        public String last;
        public String email;
        public Date dob;
        public String gender;
        public String sex;
        public String address = '';
        public String city = '';
        public String postcode = '';
        public String country = '';
        public String phoneType = '';
        public String phoneNumber = '';
    }

    public class UpdatePatientDataInput {
        public String title;
        public String first;
        public String last;
        public String email;
        public Date dob;
        public String gender;
        public String sex;
        public String address = '';
        public String city = '';
        public String postcode = '';
        public String country = '';
        public String comments;
    }

    public class BookingDataInput {
        public String patient;
        public String location;
        public String bookingType;
        public String doctor;
        public String comments;
        public Datetime start;
        public Datetime end_jsonsafe;
    }


    public class NewInvoiceDataInput {
        public Datetime date_jsonsafe;
        public String patientId;
        public String doctorId;
        public String locationId;
        public String comments;
        public String extraInfo;
        public List<NewLineItemDataInput> lineItems;
        public List<NewInvoicePaymentDataInput> payments;

        public NewInvoiceDataInput() {

        }
    }

    public class NewInvoiceResponsePayload {
        public Invoice data;
    }

    public class InvoiceData {
        public List<Invoice> data;
        public PageInfo pageInfo;
    }

    public class RecordData {
        public List<Record> data;
        public PageInfo pageInfo;
    }

    public class Invoice {
        public String id;
        public String status;
        public Datetime date_jsonsafe;
        public String patientId;
        public List<LineItem> lineItems;
        public Decimal total;
        public Decimal outstanding;
        public String invoiceNumber;
    }

    public class Record {
        public String id;
        public String consultationId;
        public String sectionId;
        public String sectionTitle;
        public String recordType;
        public String patient;
        public String term;
        public String title;
        public String date_jsonsafe;
        public String observation;
        public String dosage;
        public String quantity;
        public String comments;

    }

    public class LineItem {
        public String id;
        public Date date_jsonsafe;
        public String title;
        public String productType;
        public String itemCode;
        public Decimal cost;
        public Decimal price;
        public Decimal quantity;
        public Decimal taxRate;
        public Decimal total;
    }

    public class NewLineItemDataInput {
        public Datetime date_jsonsafe;
        public String productId;
        public Integer quantity;
        public Decimal price;
        public String referenceId;
    }

    public class NewInvoicePaymentDataInput {
        public Decimal paymentAmount;
        public String paymentTypeId;
        public Date paymentDate;
        public String comment;
    }

    public class UpdatePhoneData {
        public String phoneNumber;
        public String phoneType;
    }

    public class AddPhoneData {
        public String phoneNumber;
        public String phoneType;
    }

    public class Booking {
        public String id;
        public Boolean deleted;
        public String cancellationReason;
        public String doctorName;
        public User doctor;
        public BookingLocation location;
        public Appointment appointment;
        public Datetime start;
        public Datetime end_jsonsafe;
        public String patientId;
        public Journey bookingJourney;
        public Datetime createdAt;
        public Datetime updatedAt;
        public String videoUrl;
        public String comments;
        public String reference;
    }


    public class Journey {
        public Datetime arrived;
        public Datetime consultation;
        public Datetime departed;
        public Datetime dna;
    }


    public class Address {
        public String address;
        public String city;
        public String postcode;
        public String country;
    }

    public class QueryOptions {

        public Boolean includeDeleted = false;
        public DateRange createdAt;
        public DateRange updatedAt;
    }

    public class DateRange {
        public Datetime start;
        public Datetime end_jsonsafe;

        public DateRange() {

        }

        public DateRange(Datetime start, Datetime end_jsonsafe) {
            this.start = start;
            this.end_jsonsafe = end_jsonsafe;
        }

        public DateRange(Date start, Date end_jsonsafe) {
            this.start = Datetime.newInstance(start, Time.newInstance(0, 0, 0, 0));
            this.end_jsonsafe = Datetime.newInstance(end_jsonsafe, Time.newInstance(0, 0, 0, 0));
        }
    }

    public class Pagination {
        public Integer page;
        public Integer pageSize;
    }


    public class PageInfo {
        public Integer page;
        public Integer pageSize;
        public Boolean hasMore;
    }

    public class User {
        public String id;
    }

    public class BookingLocation {
        public String id;
    }

    public class Appointment {
        public String title;
        public String id;
    }

    public class Practice {
        public String id;
    }

    public class Availabilities {
        public List<AvailabilitiesData> data;
    }

    public class AvailabilitiesData {
        public Datetime start;
        public Datetime end_jsonsafe;
    }

    public class HeyDocException extends Exception {

    }


    public static void publishIntegrationLog(Boolean isError, String relatedId, String operation, String request, String detail, Integer httpCode) {
        try {

            if (request != null && request.length() > 10000) request = request.substring(0, 10000);
            if (detail != null && detail.length() > 20000) detail = detail.substring(0, 20000);

            List<Integration_Log__e> events = new List<Integration_Log__e>();
            events.add(new Integration_Log__e(
                    System__c = 'Semble',
                    Detail__c = detail,
                    Error__c = isError,
                    Http_Code__c = '' + httpCode,
                    Related_Id__c = relatedId,
                    Request__c = request,
                    Operation__c = operation
            ));
            EventBus.publish(events);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to publish Integration_Log__e:' + ex.getMessage());
        }
    }


}