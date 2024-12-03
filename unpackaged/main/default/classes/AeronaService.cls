/**
 * Created 2.9.2022..
 */

/*
 * Aerona API Specification
 * <h2>Overview</h2> This is the documentation for the Aerona API.
 * Aerona provides a secure set of APIs to integrate with Aerona Clinic from third party software.
 * These APIs use a combination of RESTful URIs and JSON objects to pass the data back to the client.
 * They will be only accessible via a Secure Socket Layer (HTTPS) connection meaning all data communicated between the two systems will be encrypted using TLS.
 * <h3>Usage</h3> To use the API, the Login API must be called first to retrieve a token.
 *  This token is returned in the AERONA-AUTH-TOKEN header in the Login response.
 * This token must be subsequently passed to all other API requests in a header field called AERONA-AUTH-TOKEN.
 * <h3>Rate Limit</h3> This token is valid for a period of one hour after which it expires and you will have to log in again.
 * A rate limit of 300 requests per 15 minute period is in place.
 * If you exceed this rate limit, your token will be invalidated.
 * <h3>Webhooks</h3> Webhooks can be setup to notify you when an event happens in Aerona (e.g. when a new appointment has been created).
 * Each Webhook can be sent to a different URL, however you must use an SSL/TLS URL.
 * A response should be returned from your webhook handler with a 200-status code, to tell Aerona that the request was successful.
 * If no response is received or a response other than a status code of 200 is received then Aerona will retry the webhook up to 24 more times (once each hour).
 * <br><br>Webhooks are available for the following types of objects.<ul> <li>Patient</li> <li>Appointment</li> <li>Treatment</li></ul>
 *
 * The version of the OpenAPI document: 1.0
 * Contact: support@aerona.com
 *
 */

public class AeronaService {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('AE-Service');

    public static Boolean FORCE_ENABLED = false;

    public static final AeronaIntegrationSettings__mdt INTEGRATIONS_SETTINGS = [
            SELECT Username__c, Password__c, PIN__c, loginEndpoint__c, Practice_Id__c, Enabled__c
            FROM AeronaIntegrationSettings__mdt
            LIMIT 1
    ];

    private static AeronaServiceOASApi.OASClient p_client;
    private static AeronaServiceOASApi.OASClient client {
        get {
            if (p_client == null) {
                p_client = new AeronaServiceOASApi.OASClient(INTEGRATIONS_SETTINGS.loginEndpoint__c);
            }
            return p_client;
        }
        private set;
    }

    public static Boolean isIntegrationEnabled() {
        //        System.debug('enabled: ' + (FORCE_ENABLED || INTEGRATIONS_SETTINGS.Enabled__c));
        //        return FORCE_ENABLED || INTEGRATIONS_SETTINGS.Enabled__c;
        return true;
    }


    /**
     * Create a new Payment
     *
     * @param request AeronaServiceOASApi.OASCreatePaymentRequest
     *
     * @return Long
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static Long createPayment(AeronaServiceOASApi.OASCreatePaymentRequest request) {

        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        if (request.amount == null || Decimal.valueOf(request.amount) == 0) {
            return 0;
        }
        else {
            return (Long) client.invokePOST('/v1/payments', request, Long.class);
        }
    }

    /**
     * Create a new Invoice
     *
     * @param request AeronaServiceOASApi.OASCreateInvoiceRequest
     *
     * @return Long
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static Long createInvoice(AeronaServiceOASApi.OASCreateInvoiceRequest request) {

        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        try {
            return (Long) client.invokePOST('/v1/invoices', request, Long.class);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
            return null;
        }
    }


    public static List<AeronaServiceOASApi.OASPaymentMethod> getPaymentMethods() {

        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        try {
            return (List<AeronaServiceOASApi.OASPaymentMethod>) client.invokeGET('/v1/payment-methods', List<AeronaServiceOASApi.OASPaymentMethod>.class);
        }
        catch (Exception ex)
        {
            System.debug(ex.getMessage());
            return null;
        }    }

    /**
     * Create a new Payment
     *
     * @param request AeronaServiceOASApi.OASCreateAppointmentRequest
     *
     * @return Long
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static Long createAppointment(AeronaServiceOASApi.OASCreateAppointmentRequest request) {

        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (Long) client.invokePOST('/v1/appointments', request, Long.class);
    }

    /**
     * Find Free Appointment Slots
     * Use to retrieve a list of available appointment slots when booking an appointment.
     * The next 50 available appointment slots will be returned which meet the search criteria.
     * Either the clinicianId or clinicianTypeId must be supplied in the request, but not both.
     *
     * @param appointmentTypeId
     * @param practiceId
     * @param practicePIN
     * @param clinicianId
     * @param searchStart
     *
     * @return List<OASAPIFreeAppointmentSlot>
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static List<AeronaServiceOASApi.OASAPIFreeAppointmentSlot> findAppointmentSlot(
            String appointmentTypeId,
            String practiceId,
            String practicePIN,
            String clinicianId,
            Date searchStart
    ) {
        return findAppointmentSlot(appointmentTypeId, practiceId, practicePIN, clinicianId, null, searchStart);
    }
    /**
     * Find Free Appointment Slots
     * Use to retrieve a list of available appointment slots when booking an appointment.
     * The next 50 available appointment slots will be returned which meet the search criteria.
     * Either the clinicianId or clinicianTypeId must be supplied in the request, but not both.
     *
     * @param appointmentTypeId
     * @param practiceId
     * @param practicePIN
     * @param clinicianId
     * @param clinicianTypeId
     * @param searchStart
     *
     * @return List<OASAPIFreeAppointmentSlot>
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static List<AeronaServiceOASApi.OASAPIFreeAppointmentSlot> findAppointmentSlot(
            String appointmentTypeId,
            String practiceId,
            String practicePIN,
            String clinicianId,
            String clinicianTypeId,
            Date searchStart
    ) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        System.debug('Free slots query for PIN:' + practicePIN);
        client.setPIN(practicePIN);
        List<AeronaServiceOAS.Param> query = new List<AeronaServiceOAS.Param>();
        query.add(new AeronaServiceOAS.Param('appointmentTypeId', appointmentTypeId));
        query.add(new AeronaServiceOAS.Param('timeOfDay', '0'));
        query.add(new AeronaServiceOAS.Param('searchStart', toYYYYMMDD(searchStart)));
        if (clinicianId != null) query.add(new AeronaServiceOAS.Param('clinicianId', clinicianId));
        if (practiceId != null) query.add(new AeronaServiceOAS.Param('practiceId', practiceId));
        if (clinicianTypeId != null) query.add(new AeronaServiceOAS.Param('clinicianTypeId', clinicianTypeId));

        try {
            return (List<AeronaServiceOASApi.OASAPIFreeAppointmentSlot>) client.invokeGET(
                    '/v1/find-appointment-slots', query,
                    List<AeronaServiceOASApi.OASAPIFreeAppointmentSlot>.class);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
            return null;
        }
    }

    // GET ALL CLINICIANS per practice
    public static List<AeronaServiceOASApi.OASAPIClinicianDetails> getClinicians() {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (List<AeronaServiceOASApi.OASAPIClinicianDetails>) client.invokeGET(
                '/v1/clinicians',
                List<AeronaServiceOASApi.OASAPIClinicianDetails>.class);
    }

    public static Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>> getAllClinicians() {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');

        Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>> map_practice_clinicians = new Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>>();


        List<ServiceTerritory> territories = [SELECT Id, Aerona_PIN__c FROM ServiceTerritory WHERE Aerona_PIN__c != NULL AND Aerona_Id__c != NULL AND IsActive = TRUE];

        for (ServiceTerritory serviceTerritory : territories) {

            String tempAuthToken = null;
            AeronaServiceOASApi.OASLoginRequest loginRequest = new AeronaServiceOASApi.OASLoginRequest();
            loginRequest.username = INTEGRATIONS_SETTINGS.Username__c;
            loginRequest.password = INTEGRATIONS_SETTINGS.Password__c;
            try {
                loginRequest.pin = serviceTerritory.Aerona_PIN__c;

                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(INTEGRATIONS_SETTINGS.loginEndpoint__c + '/login');
                req.setBody(JSON.serialize(loginRequest));

                System.debug('::getAllClinicians:send:body:' + req.getBody());
                HttpResponse resp = new Http().send(req);

                //System.debug('::AeronaServiceOAS:invokeLogin:res.body:' + res?.getBody());
                //System.debug('::getAllClinicians:resp.header.token:' + resp?.getHeader('AERONA-AUTH-TOKEN'));

                Integer code = resp.getStatusCode();
                Boolean isFailure = code / 100 != 2;

                if (isFailure) {
                    System.debug(LoggingLevel.ERROR, '::getAllClinicians:login failure for: ' + loginRequest.pin);
                    continue;
                }
                else {
                    tempAuthToken = resp.getHeader('AERONA-AUTH-TOKEN');
                }
            }
            catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '::AeronaService:getAllClinicians:ex:' + e);
                continue;
            }

            System.debug(LoggingLevel.ERROR, '::getAllClinicians:invoking GET for: ' + loginRequest.pin);
            List<AeronaServiceOASApi.OASAPIClinicianDetails> clinicians =
                    (List<AeronaServiceOASApi.OASAPIClinicianDetails>) client.invoke(
                            'GET', '/v1/clinicians', '', null, null, null,
                            new Map<String, Object>{'FORCE-AERONA-AUTH-TOKEN' => tempAuthToken},
                            new List<String>{'application/json', '*/*'},
                            null, List<AeronaServiceOASApi.OASAPIClinicianDetails>.class);
            map_practice_clinicians.put(serviceTerritory.Id, clinicians);
        }

        return map_practice_clinicians;
    }


    /**
     * Get an Appointment\&#39;s details
     * This API can be used to get the details of an appointment from Aerona.
     *
     * @param appointmentId (required)
     *
     * @return OASAPIAppointmentDetails
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static AeronaServiceOASApi.OASAPIAppointmentDetails getAppointment(Long appointmentId) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (AeronaServiceOASApi.OASAPIAppointmentDetails) client.invokeGET(
                '/v1/appointments/{appointmentId}',
                new Map<String, Object>{'appointmentId' => appointmentId},
                AeronaServiceOASApi.OASAPIAppointmentDetails.class
        );
    }

    /**
     * Get the consultation notes for a Patient
     *
     * @param patientId (required)
     *
     * @return OASAPIAppointmentDetails
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static AeronaServiceOASApi.OASAPINote getConsultationNotes(Long patientId) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (AeronaServiceOASApi.OASAPINote) client.invokeGET(
                '/v1/patients/notes/{patientId}',
                new Map<String, Object>{'patientId' => patientId},
                AeronaServiceOASApi.OASAPINote.class
        );
    }

    /**
     * Update an existing appointment.
     * This API is used to update an appointment in Aerona.
     *
     * @param appointmentId (required)
     * @param request OASUpdateAppointmentRequest
     *
     * @return Boolean
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static Boolean updateAppointment(String appointmentId, AeronaServiceOASApi.OASUpdateAppointmentRequest request) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (Boolean) client.invokePUT(
                '/v1/appointments/{appointmentId}',
                request,
                new Map<String, Object>{'appointmentId' => Long.valueOf(appointmentId)},
                Boolean.class
        );
    }


    /**
     * This method fetches the list of all available appointment types from the external service.
     * It makes a GET request to the service's '/v1/appointment-types' endpoint and
     * deserializes the JSON response into a list of OASAPIAppointmentType objects.
     *
     * @return A list of {@link AeronaServiceOASApi.OASAPIAppointmentType} objects
     *         representing the different types of appointments available in the service.
     *         If an error occurs during the invocation, the method will return null.
     *
     * @example
     * Usage:
     * List<AeronaServiceOASApi.OASAPIAppointmentType> appointmentTypes = getAppointmentTypes();
     * for (AeronaServiceOASApi.OASAPIAppointmentType type : appointmentTypes) {
     *     System.debug('Appointment Type: ' + type);
     * }
     */
    public static List<AeronaServiceOASApi.OASAPIAppointmentType> getAppointmentTypes() {
        return (List<AeronaServiceOASApi.OASAPIAppointmentType>) client.invokeGET(
                '/v1/appointment-types',
                List<AeronaServiceOASApi.OASAPIAppointmentType>.class
        );
    }


    /**
     * Create a new Patient
     * Used to create a new patient in Aerona. &lt;br&gt;&lt;br&gt;The patient\&#39;s date of birth and their forename and surname will be used to check if the patient already exists in Aerona Clinic. If an existing patient matches the details of the new patient, then the list of possible matches will be returned to the caller. &lt;br&gt;&lt;br&gt;If the possible duplicate matches have been reviewed and you still want to force Aerona to create the new patient, the forceCreate flag can be set to true and the request resubmitted. If a new patient is created successfully, the patient ID in the response will be a non-zero value. If a record for the patient already exists, then the patient ID returned will be 0 and a list containing the duplicate patient details are returned.
     *
     * @param request AeronaServiceOASApi.OASCreatePatientRequest
     *
     * @return OASCreatePatientResponse
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static AeronaServiceOASApi.OASCreatePatientResponse createPatient(AeronaServiceOASApi.OASCreatePatientRequest request) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        request.allowText = true;
        request.allowEmail = true;
        request.practiceId = INTEGRATIONS_SETTINGS.Practice_Id__c?.longValue();
        return (AeronaServiceOASApi.OASCreatePatientResponse) client.invokePOST('/v1/patients', request, AeronaServiceOASApi.OASCreatePatientResponse.class);
    }

    public static List<AeronaServiceOASApi.OASCarePlan> getCarePlans() {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (List<AeronaServiceOASApi.OASCarePlan>) client.invokeGET('/v1/care-plans', List<AeronaServiceOASApi.OASCarePlan>.class);
    }

    public static Long createPatientCarePlan(AeronaServiceOASApi.OASAPIPatientCarePlan request) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        return (Long) client.invokePOST('/v1/patient/care-plan', request, Long.class);
    }

    /**
     * Get a Patient\&#39;s details
     * This API can be used to get the complete Patient record of an existing Patient from Aerona.
     *
     * @param patientId (required)
     *
     * @return OASRetrievePatientResponse
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static AeronaServiceOASApi.OASRetrievePatientResponse getPatient(String patientId) {
        return (AeronaServiceOASApi.OASRetrievePatientResponse)
                client.invokeGET(
                        '/v1/patients/' + patientId,
                        AeronaServiceOASApi.OASRetrievePatientResponse.class
                );
    }


    /**
     * Get Treatments for a Patient
     * Used to retrieve a list of Treatments for a specific Patient.
     *
     * @param patientId patientId (required)
     *
     * @return List<OASAPITreatment>
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static List<AeronaServiceOASApi.OASAPITreatment> getTreatmentsForPatient(Long patientId) {
        return (List<AeronaServiceOASApi.OASAPITreatment>) client.invokeGET(
                '/v1/patients/treatments/' + patientId,
                List<AeronaServiceOASApi.OASAPITreatment>.class
        );
    }

    /**
     * Get Treatment Plans for a Patient
     * Used to retrieve a list of Treatment Plans (names & comments) for a specific Patient.
     *
     * @param patientId patientId (required)
     *
     * @return List<OASAPITreatment>
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static List<AeronaServiceOASApi.OASAPITreatmentPlan> getTreatmentPlansForPatient(Long patientId) {
        return (List<AeronaServiceOASApi.OASAPITreatmentPlan>) client.invokeGET(
                '/v1/patients/treatmentplans/' + patientId,
                List<AeronaServiceOASApi.OASAPITreatmentPlan>.class
        );
    }


    /**
     * Update a Patient\&#39;s details
     * Used to update Patient details in Aerona.
     *
     * @param patientId (required)
     * @param request AeronaServiceOASApi.OASUpdatePatientRequest
     *
     * @return Boolean
     *
     * @throws OAS.ApiException if fails to make API call
     */
    public static Boolean updatePatient(String patientId, AeronaServiceOASApi.OASUpdatePatientRequest request) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        if (request.practiceId == null) request.practiceId = INTEGRATIONS_SETTINGS.Practice_Id__c?.longValue();
        return (Boolean) client.invokePUT(
                '/v1/patients/{patientId}',
                request,
                new Map<String, Object>{'patientId' => patientId},
                Boolean.class
        );
    }

    public static List<AeronaServiceOASApi.OASDuplicatePatient> searchPatient(String email, Date dateOfBirth) {
        if (String.isBlank(email) || dateOfBirth == null) return null;

        List<AeronaServiceOAS.Param> query = new List<AeronaServiceOAS.Param>();
        query.add(new AeronaServiceOAS.Param('emailAddress', email));
        if (dateOfBirth != null) query.add(new AeronaServiceOAS.Param('dob', toYYYYMMDD(dateOfBirth)));

        return (List<AeronaServiceOASApi.OASDuplicatePatient>) client.invokeGET('/v1/patients/search', query, List<AeronaServiceOASApi.OASDuplicatePatient>.class);
    }

    public static Boolean deleteBooking(String appointmentId) {
        if (!isIntegrationEnabled()) throw new NotEnabledException('Aerona integration not enabled');
        AeronaServiceOASApi.OASUpdateAppointmentRequest request = new AeronaServiceOASApi.OASUpdateAppointmentRequest();

        request.appointmentStatusId = 12; //  12 - Cancelled by Patient
        return updateAppointment(appointmentId, request);
    }

    public static String toYYYYMMDD(Date dt) {
        return Datetime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
    }

    public static String calcAeronaFingerprint(ServiceAppointment app) {
        String content = '-';
        content += app?.Status;
        content = content + '-';
        content += app?.SchedStartTime?.getTime();
        content = content + '-';
        content += app?.SchedEndTime?.getTime();
        content = content + '-';
        content += app?.Resource_Names__c;
        content = content + '-';
        content += app?.ServiceTerritoryId;
        content = content + '-';
        content += app?.WorkTypeId;
        content = content + '-';
        content = content.replaceAll('-null-', '--');

        Blob requestBlob = Blob.valueOf(content);
        Blob hash = Crypto.generateDigest('MD5', requestBlob);
        return EncodingUtil.convertToHex(hash);
    }

    public class NotEnabledException extends Exception {
    }
}