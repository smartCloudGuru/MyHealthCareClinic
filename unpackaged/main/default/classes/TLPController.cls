/* TODO

- show error and confirmation modals
  - reschedule
*/

public without sharing class TLPController {

    public static Portal_Settings__c portalSettings;
    public static Portal_Settings__c getPortalSettings() {
        if (portalSettings == null) {
            portalSettings = Portal_Settings__c.getInstance();
        }
        return portalSettings;
    }

    // Key for AES encryption (must be 16, 24, or 32 bytes)
    private static final Blob aesKey = Blob.valueOf('123#"!TLPencrypt#2#session456&%$'); // Change this to your own encryption key

    private static TLC_Config tlc_cfg = null;

    private static TLC_Config getConfig() {
        if (tlc_cfg == null) {
            tlc_cfg = new TLC_Config();

            tlc_cfg.sf_serviceCenterId = getPortalSettings().Service_Territory_Id__c;
            tlc_cfg.semble_locationId = [SELECT Id, Heydoc_Id__c FROM ServiceTerritory WHERE Id = :tlc_cfg.sf_serviceCenterId].Heydoc_Id__c;
        }
        return tlc_cfg;
    }

    @AuraEnabled(Cacheable=true)
    public static String getServiceTerritoryMembers() {
        List<ServiceTerritoryMember> stms = [
                SELECT Id,
                        ServiceResourceId,
                        ServiceResource.Name,
                        ServiceResource.Gender__c
                FROM ServiceTerritoryMember
                WHERE ServiceTerritoryId = :getPortalSettings().Service_Territory_Id__c
        ];

        return JSON.serialize(stms);
    }


    @AuraEnabled(Cacheable=true)
    public static String getTLCPortalWorkTypeGroups() {

        List<Product2> prods = [SELECT Id, Name, Marketing_Name__c, Work_Type_Group__c FROM Product2 WHERE Online_Store_Tags__c INCLUDES ('TLC HS Portal') ORDER BY Store_Sort_Order__c ASC];

        List<OnlBookDomain.OptionWrapper> ret = new List<OnlBookDomain.OptionWrapper>();
        for (Product2 product2 : prods) {
            ret.add(new OnlBookDomain.OptionWrapper(product2.Marketing_Name__c, product2.Work_Type_Group__c));
        }
        return JSON.serialize(ret, true);
    }

    @TestVisible
    private static String getSembleDoctorId(String sfResourceId) {
        return [SELECT Id, Heydoc_Id__c FROM ServiceResource WHERE Id = :sfResourceId]?.Heydoc_Id__c;
    }

    @AuraEnabled(Cacheable=false)
    public static String aura_getTlpAvailability(String selectedWorkTypeGroupId, Datetime dateFrom) {
        Datetime dateTo = dateFrom.addDays(3);

        return OnlBookAvailabilityController.getAvailableSlots_raw(selectedWorkTypeGroupId, getConfig().sf_serviceCenterId, dateFrom, dateTo);
    }

    @AuraEnabled(Cacheable=false)
    public static String checkAccessKey(String accessKey) {
        Integer salt = Math.round(Math.random() * 800 + 101);
        if (accessKey == getPortalSettings().Team_1_Key__c) return obfuscate(salt + '#teamNum:1');
        if (accessKey == getPortalSettings().Team_2_Key__c) return obfuscate(salt + '#teamNum:2');
        return null;
    }

    @AuraEnabled(Cacheable=false)
    /** expects cookies as example "CookieConsentPolicy=0:1; myData=abc; tlcsession=cy63...=" */
    public static String checkAuthentication(String cookie) {
        if (String.isNotBlank(cookie)) {
            try {
                String[] cookieParts = cookie.split(';');
                for (String str : cookieParts) {
                    if (String.isNotBlank(str)) {
                        if (str.trim().startsWith('tlcsession')) {
                            //de-code with aes
                            String value = deobfuscate(str.trim().replace('tlcsession', '').replace(' ', '').replace('=', ''));
                            Integer pos = value.indexOf('#teamNum:');
                            if (pos > 0) return value.substring(pos + 9);
                            return value;
                        }
                    }
                }
            }
            catch (Exception ex) {
                return null;
            }
        }
        return null;
    }

    // get custom settings (in aura enabled function to pass to LWC)
    @AuraEnabled(Cacheable=true)
    public static String getCustomSettings() {
        return OnlineStoreSettingsManager.getStoreSettings().IdealPostcodes_API_Key__c;
    }

    @AuraEnabled
    public static String doSubmit(String request) {

        SubmitResponse ret = new SubmitResponse();

        try {
            SubmitRequest req = (SubmitRequest) JSON.deserialize(request, SubmitRequest.class);

            //check cookies
            String team = checkAuthentication(req.cookies);
            if (team == null) {
                ret.setError('NAT.C', 'Request unauthorized');
                return JSON.serialize(ret);
            }
            //empty auth, so that is does not get saved
            req.cookies = null;

            req.email = req.email?.trim();

            //check if patient exist on semble, return existing
            ret.extPatientId = checkIfPatientExists(req.email, req.getDOB());

            //if does not exist, create
            if (String.isEmpty(ret.extPatientId)) ret.extPatientId = createPatient(req);

            //is still no id, return error
            if (String.isEmpty(ret.extPatientId)) {
                ret.setError('PNL', 'Unable to create Patient data on Semble');
                return JSON.serialize(ret);
            }

            String semble_appointmentTypeId = null;
            try {
                semble_appointmentTypeId = [SELECT Id, Heydoc_Id__c FROM WorkTypeGroup WHERE Id = :req.selectedWorkTypeGroupId].Heydoc_Id__c;
            }
            catch (Exception ex) {
                ex.setMessage('No such WorkTypeGroup: ' + req.selectedWorkTypeGroupId);
                throw ex;
            }

            //create booking
            HeyDocService.Booking resp = createBooking(semble_appointmentTypeId, ret.extPatientId, req);

            if (resp != null && resp.id != null) {
                ret.extBookingId = resp.id;
            }
            else {
                ret.setError('PNL', 'Unable to create/update appointment on Semble, no externalId returned');
                return JSON.serialize(ret);
            }

            Booking_Detail__c bookingDetail = new Booking_Detail__c();
            bookingDetail.External_Booking_Id__c = ret.extBookingId;
            bookingDetail.External_Patient_Id__c = ret.extPatientId;
            bookingDetail.Request__c = request;
            bookingDetail.UUID__c = new Uuid().getValue().replace('-', '');
            bookingDetail.Work_Type_Group__c = req.selectedWorkTypeGroupId;
            bookingDetail.Scheduled_Start__c = req.timeSelected;
            bookingDetail.Team__c = String.valueOf(team);
            bookingDetail.Video_URL__c = resp.videoUrl;
            bookingDetail.Service_Resource__c = req.selectedResource;
            bookingDetail.Appointment_Reference__c = req.refA;
            bookingDetail.Patient_Reference__c = req.refP;
            bookingDetail.Patient_Email__c = req.email;
            bookingDetail.Patient_First_Name__c = req.firstName;
            bookingDetail.Patient_Last_Name__c = req.lastName;
            insert bookingDetail;

            ret.detailId = bookingDetail.Id;

            sendEmail(ret.detailId, 'BOOKED');
            sendEmailToPatient(req.email, ret.detailId, 'BOOKED');

        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, ex.getMessage());
            ret.setError('EXC', ex.getMessage());
        }

        return JSON.serialize(ret);
    }

    @AuraEnabled
    public static String getBookingDetailsByCode(String code) {
        List<Booking_Detail__c> dets = [
                SELECT Id, Scheduled_Start__c, UUID__c, Cancelled__c, Work_Type_Group__c, Work_Type_Group__r.Name
                FROM Booking_Detail__c
                WHERE UUID__c = :code
                ORDER BY CreatedDate DESC
        ];
        if (dets.isEmpty()) return null;

        Booking_Detail__c ret = new Booking_Detail__c();
        ret.UUID__c = dets[0].UUID__c;
        ret.Scheduled_Start__c = dets[0].Scheduled_Start__c;
        ret.Work_Type_Group__c = dets[0].Work_Type_Group__c;
        ret.Cancelled__c = dets[0].Cancelled__c;
        ret.Work_Type_Group__r = dets[0].Work_Type_Group__r;
        return JSON.serialize(ret);
    }

    @AuraEnabled
    public static String doCancelByCode(String auth, String code) {

        String team = checkAuthentication(auth);
        if (team == null) {
            return null;
        }

        List<Booking_Detail__c> dets = [
                SELECT Id, Scheduled_Start__c, UUID__c, External_Booking_Id__c, Patient_Email__c
                FROM Booking_Detail__c
                WHERE UUID__c = :code
                ORDER BY CreatedDate DESC
        ];
        if (dets.isEmpty()) return null;

        Boolean successful = cancelBooking(dets[0].External_Booking_Id__c);

        if (successful) {
            dets[0].Cancelled__c = true;

            update dets[0];

            sendEmail(dets[0].Id, 'CANCELLED');
            sendEmailToPatient(dets[0].Patient_Email__c, dets[0].Id, 'CANCELLED');

            return code;
        }
        else {
            return null;
        }
    }

    @AuraEnabled
    public static String doRescheduleByCode(String code, String request) {
        try {
            SubmitRequest req = (SubmitRequest) JSON.deserialize(request, SubmitRequest.class);

            String team = checkAuthentication(req.cookies);
            if (team == null) {
                return null;
            }

            List<Booking_Detail__c> dets = [
                    SELECT Id, Scheduled_Start__c, UUID__c, External_Booking_Id__c, Patient_Email__c
                    FROM Booking_Detail__c
                    WHERE UUID__c = :code
                    ORDER BY CreatedDate DESC
            ];
            if (dets.isEmpty()) return null;

            String semble_doctor_id = getSembleDoctorId(req.selectedResource);

            Boolean successful = rescheduleBooking(dets[0].External_Booking_Id__c, req.timeSelected, req.timeSelectedEnd, semble_doctor_id);

            if (successful) {
                dets[0].Service_Resource__c = req.selectedResource;
                dets[0].Scheduled_Start__c = req.timeSelected;
                update dets[0];
                sendEmail(dets[0].Id, 'RESCHEDULED');
                sendEmailToPatient(dets[0].Patient_Email__c, dets[0].Id, 'RESCHEDULED');

                return code;
            }
            else {
                return null;
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, ex.getMessage());
            return null;
        }
    }

    private static String checkIfPatientExists(String email, Date dob) {
        HeyDocService.PatientData patients = HeyDocService.searchPatients(email, null, null);

        if (patients?.data != null && patients.data.size() > 0) {
            for (HeyDocService.Patient semblePatient : patients.data) {
                if (semblePatient != null
                        && semblePatient.email != null
                        && semblePatient.email == email
                        && semblePatient.dob != null
                        && semblePatient.dob.date() == dob) {
                    return semblePatient.id;
                }
            }
        }
        return null;
    }

    private static String createPatient(SubmitRequest req) {
        // create on heydoc
        HeyDocService.CreatePatientDataInput input = new HeyDocService.CreatePatientDataInput();
        input.first = req.firstName;
        input.last = req.lastName;
        input.dob = req.getDOB();
        input.email = req.email;
        input.gender = ExternalSyncPatients.mapToHeydocGender(req.gender);
        input.address = req.address1;
        if (!String.isEmpty(req.address2)) input.address += ', ' + req.address2;
        if (!String.isEmpty(req.address3)) input.address += ', ' + req.address3;
        input.city = req.city;
        input.postcode = req.postalCode;
        input.country = ExternalSyncPatients.mapToCountryCode(req.county);
        if (String.isNotBlank(req.phone)) {
            input.phoneType = 'Mobile';
            input.phoneNumber = req.phone;
        }

        return HeyDocService.createPatient(input);
    }

    public static HeyDocService.Booking createBooking(String semble_appointmentTypeId, String patientId, SubmitRequest req) {
        HeyDocService.BookingDataInput full_bookingDataInput = new HeyDocService.BookingDataInput();
        full_bookingDataInput.patient = patientId;
        full_bookingDataInput.start = req.timeSelected;
        full_bookingDataInput.end_jsonsafe = req.timeSelectedEnd;
        full_bookingDataInput.doctor = getSembleDoctorId(req.selectedResource);
        full_bookingDataInput.bookingType = semble_appointmentTypeId;
        full_bookingDataInput.location = getConfig().semble_locationId;

        if (String.isNotEmpty(req.addons)) {
            full_bookingDataInput.comments = 'Addons ' + req.addons.replace(';', ',\n\n');
        }

        if (String.isNotEmpty(req.notes)) {
            if (String.isEmpty(full_bookingDataInput.comments)) full_bookingDataInput.comments = req.notes;
            else full_bookingDataInput.comments += '\n' + req.notes;
        }

        HeyDocService.Booking resp = null;
        resp = HeyDocService.createBooking(full_bookingDataInput);

        return resp;

    }

    public static Boolean cancelBooking(String semble_appointmentTypeId) {
        return HeyDocService.deleteBooking(semble_appointmentTypeId);
    }

    public static Boolean rescheduleBooking(String semble_appointmentTypeId, Datetime scheduleStart, Datetime scheduleEnd, String semble_doctor_id) {

        HeyDocService.BookingDataInput bookingDataInput = new HeyDocService.BookingDataInput();
        bookingDataInput.start = scheduleStart;
        bookingDataInput.end_jsonsafe = scheduleEnd;
        bookingDataInput.doctor = semble_doctor_id;
        return HeyDocService.updateBooking(semble_appointmentTypeId, bookingDataInput) != null;
    }


    public static void sendEmail(Id recordId, String action) {
        try {

            qsyd_InvocableEmailTemplateAction.InvocableEmailParam param = new qsyd_InvocableEmailTemplateAction.InvocableEmailParam();
            List<qsyd_InvocableEmailTemplateAction.InvocableEmailParam> params = new List<qsyd_InvocableEmailTemplateAction.InvocableEmailParam>();

            switch on action {
                when 'BOOKED' {
                    param.emailTemplate = getPortalSettings().Email_Team_Template_Booked__c;
                }
                when 'CANCELLED' {
                    param.emailTemplate = getPortalSettings().Email_Team_Template_Cancelled__c;
                }
                when 'RESCHEDULED' {
                    param.emailTemplate = getPortalSettings().Email_Team_Template_Rescheduled__c;
                }
            }

            param.toAddress = getPortalSettings().To_Email__c;
            param.targetObjectId = getPortalSettings().Email_Target_Contact_Id__c;
            param.whatId = recordId;
            param.treatTargetObjectAsRecipient = false;
            param.saveAsActivity = false;
            param.orgWideEmailAddress = getPortalSettings().From_Org_Wide_Email_Address__c;


            params.add(param);

            qsyd_InvocableEmailTemplateAction.sendEmail(params);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to send email:' + ex.getMessage());
        }
    }

    public static void sendEmailToPatient(String patientEmail, Id recordId, String action) {
        try {

            qsyd_InvocableEmailTemplateAction.InvocableEmailParam param = new qsyd_InvocableEmailTemplateAction.InvocableEmailParam();
            List<qsyd_InvocableEmailTemplateAction.InvocableEmailParam> params = new List<qsyd_InvocableEmailTemplateAction.InvocableEmailParam>();

            switch on action {
                when 'BOOKED' {
                    param.emailTemplate = getPortalSettings().Email_Template_Booked__c;
                }
                when 'CANCELLED' {
                    param.emailTemplate = getPortalSettings().Email_Template_Cancelled__c;
                }
                when 'RESCHEDULED' {
                    param.emailTemplate = getPortalSettings().Email_Template_Rescheduled__c;
                }
            }

            param.toAddress = patientEmail;
            param.targetObjectId = getPortalSettings().Email_Target_Contact_Id__c;
            param.whatId = recordId;
            param.treatTargetObjectAsRecipient = false;
            param.saveAsActivity = false;
            param.orgWideEmailAddress = getPortalSettings().From_Org_Wide_Email_Address__c;

            params.add(param);

            qsyd_InvocableEmailTemplateAction.sendEmail(params);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to send email:' + ex.getMessage());
        }
    }

    // Obfuscate the string using AES encryption
    public static String obfuscate(String input) {
        Blob inputBlob = Blob.valueOf(input);
        Blob encryptedBlob = Crypto.encryptWithManagedIV('AES256', aesKey, inputBlob);
        return EncodingUtil.base64Encode(encryptedBlob);
    }

    // Reverses the AES encryption to get the original string
    public static String deobfuscate(String obfuscated) {
        Blob encryptedBlob = EncodingUtil.base64Decode(obfuscated);
        Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', aesKey, encryptedBlob);
        return decryptedBlob.toString();
    }


    public class SubmitRequest {
        public String addons;
        public String firstName;
        public String lastName;
        public String dob_d;
        public String dob_m;
        public String dob_y;
        public String gender;
        public String email;
        public String phone;
        public String postalCode;
        public String city;
        public String address1;
        public String address2;
        public String address3;
        public String county;
        public String notes;
        public String selectedDate;
        public String selectedWorkTypeGroupId;
        public String selectedResource;
        public Datetime timeSelected;
        public Datetime timeSelectedEnd;
        public String refA;
        public String refP;
        public String cookies;

        public Date getDOB() {
            return Date.newInstance(Integer.valueOf(dob_y), Integer.valueOf(dob_m), Integer.valueOf(dob_d));
        }

    }

    public class SubmitResponse {
        public Boolean error = false;
        public String extPatientId;
        public String extBookingId;
        public String errorCode;
        public String errorMsg;
        public String detailId;

        public void setError(String code, String msg) {
            this.error = true;
            this.errorCode = code;
            this.errorMsg = msg;
        }
    }

    public class TLC_Config {
        public String sf_serviceCenterId;
        public String semble_locationId;
    }
}