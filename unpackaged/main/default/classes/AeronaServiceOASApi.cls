/**
 * Created 2.9.2022..
 */

/* CLASSES */

/*
 * Aerona API Specification
 * <h2>Overview</h2> This is the documentation for the Aerona API. Aerona provides a secure set of APIs to integrate with Aerona Clinic from third
 * party software. These APIs use a combination of RESTful URIs and JSON objects to pass the data back to the client. They will be only accessible
 * via a Secure Socket Layer (HTTPS) connection meaning all data communicated between the two systems will be encrypted using TLS. <h3>Usage</h3>
 * To use the API, the Login API must be called first to retrieve a token. This token is returned in the AERONA-AUTH-TOKEN header in the Login
 * response. This token must be subsequently passed to all other API requests in a header field called AERONA-AUTH-TOKEN. <h3>Rate Limit</h3>
 * This token is valid for a period of one hour after which it expires and you will have to log in again. A rate limit of 300 requests per 15 minute
 * period is in place. If you exceed this rate limit, your token will be invalidated. <h3>Webhooks</h3> Webhooks can be setup to notify you when an
 * event happens in Aerona (e.g. when a new appointment has been created). Each Webhook can be sent to a different URL, however you must use an
 * SSL/TLS URL. A response should be returned from your webhook handler with a 200-status code, to tell Aerona that the request was successful.
 * If no response is received or a response other than a status code of 200 is received then Aerona will retry the webhook up to 24 more times
 * (once each hour). <br><br>Webhooks are available for the following types of objects.<ul> <li>Patient</li> <li>Appointment</li> <li>Treatment</li></ul>
 *
 * The version of the OpenAPI document: 1.0
 * Contact: support@aerona.com
 *
 */

public class AeronaServiceOASApi {


    public static final String INVOICE_STATUS_PRECHARGED = 'Precharged';
    public static final String INVOICE_STATUS_COMPLETED = 'Completed';

    public class OASClient extends AeronaServiceOAS.ApiClient {
        public OASClient() {
            basePath = 'http://localhost:8080/AeronaAPI';
            calloutName = 'Aerona_API_Specification';
        }
        public OASClient(String path) {
            basePath = path;
            calloutName = 'Aerona_API_Specification';
        }

    }

    /**
     * OASCreatePaymentRequest
     */
    public class OASCreatePaymentRequest {
        public Long patientId { get; set; }
        public Datetime paymentDate { get; set; }
        public Long practiceId { get; set; }
        public Integer paymentTypeId { get; set; }
        public Integer paymentMethodId { get; set; }
        public String amount { get; set; }
    }

    public class OASCreateInvoiceRequest {
        public Long patientId { get; set; }
        public Datetime date_jsonsafe { get; set; }
        public Long userId { get; set; }
        public Integer quantity { get; set; }
        public Long saleItemId { get; set; }
        public String price { get; set; }
        public Integer discountPercentage { get; set; }
        public Double discountAmount { get; set; }
        public String vatRate { get; set; }
        public String itemStatus { get; set; }
    }

    public class OASPaymentMethod {
        public Long id { get; set; }
        public String method { get; set; }
    }

    /**
     * OASCreateAppointmentRequest
     */
    public class OASCreateAppointmentRequest {
        /**
         * The ID of the Practice. This is taken from the Practice list.
         */
        public Long practiceId { get; set; }

        /**
         * This is the ID of the Patient\'s preferred Clinician. This is taken from the Clinician list.
         */
        public Long userId { get; set; }

        /**
         * This is the Appointment Type ID. This is taken from the Appointment Type list.
         */
        public Long appointmentTypeId { get; set; }

        /**
         * This is the Appointment Status ID. <br><br>1 - Unconfirmed, 2 - Confirmed, 3 - Arrived, 4 - Failed to Attend, 5 - Cancelled by Practice, 6 - In Clinic, 7 - Completed, 8 - Online Booking Request, 9 - Reminder Sent, 10 - Scheduled, 11 - Unscheduled, 12 - Cancelled by Patient, 13 - Deleted, 14 - Late Cancellation, 16 - Was Not Brought.
         */
        public Integer appointmentStatusId { get; set; }

        /**
         * The date of the Appointment.
         */
        public Datetime appointmentTime { get; set; }

        /**
         * This is the identifier for stating if an Appointment is an emergency or not.
         */
        public Boolean emergency { get; set; }

        /**
         * Any additional notes related to the Appointment.	<br><br>Note: This is not clinical notes.
         */
        public String appointmentNotes { get; set; }

        /**
         * This is the length of the Appointment in minutes.
         */
        public Integer duration { get; set; }

        /**
         * This is the Patient ID of the Patient requesting the Appointment.
         */
        public Long patientId { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASCreateAppointmentRequest) {
                OASCreateAppointmentRequest createAppointmentRequest = (OASCreateAppointmentRequest) obj;
                return this.practiceId == createAppointmentRequest.practiceId
                        && this.userId == createAppointmentRequest.userId
                        && this.appointmentTypeId == createAppointmentRequest.appointmentTypeId
                        && this.appointmentStatusId == createAppointmentRequest.appointmentStatusId
                        && this.appointmentTime == createAppointmentRequest.appointmentTime
                        && this.emergency == createAppointmentRequest.emergency
                        && this.appointmentNotes == createAppointmentRequest.appointmentNotes
                        && this.duration == createAppointmentRequest.duration
                        && this.patientId == createAppointmentRequest.patientId;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (practiceId == null ? 0 : System.hashCode(practiceId));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (appointmentTypeId == null ? 0 : System.hashCode(appointmentTypeId));
            hashCode = (17 * hashCode) + (appointmentStatusId == null ? 0 : System.hashCode(appointmentStatusId));
            hashCode = (17 * hashCode) + (appointmentTime == null ? 0 : System.hashCode(appointmentTime));
            hashCode = (17 * hashCode) + (emergency == null ? 0 : System.hashCode(emergency));
            hashCode = (17 * hashCode) + (appointmentNotes == null ? 0 : System.hashCode(appointmentNotes));
            hashCode = (17 * hashCode) + (duration == null ? 0 : System.hashCode(duration));
            hashCode = (17 * hashCode) + (patientId == null ? 0 : System.hashCode(patientId));
            return hashCode;
        }
    }


    /**
     * OASAPIClinicianDetails
     */
    public class OASAPIClinicianDetails {
        /**
         * The Clinician ID.
         */
        public Long id { get; set; }

        /**
         * The Clinician\'s name.
         */
        public String clinicianName { get; set; }

        /**
         * The Clinician\'s username.
         */
        public String userName { get; set; }

        /**
         * The Clinician\'s email address.
         */
        public String emailAddress { get; set; }

        /**
         * The Clinician\'s Privilege. <br><br>1 - Practice Owner, 2 - Clinician, 3 - Practice Manager, 4 - Receptionist, 5 - Nurse, 6 - Shared Receptionist, 7 - Basic Access Clinician, 8 - Multi Site Receptionist, 9 - Business Owner, 10 - Multi Site Clinician, 11 - Intermediate Clinician, 12 - Multi Site TCO.
         */
        public Long userPrivilegeId { get; set; }

        /**
         * The ID of the Clinician\'s Practice.
         */
        public Long practiceId { get; set; }

        /**
         * The hour from when the Clinician can login to the Aerona system.
         */
        public Integer loginStartHour { get; set; }

        /**
         * The hour until the Clinician can login to the Aerona system.
         */
        public Integer loginEndHour { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPIClinicianDetails) {
                OASAPIClinicianDetails apIClinicianDetails = (OASAPIClinicianDetails) obj;
                return this.id == apIClinicianDetails.id
                        && this.clinicianName == apIClinicianDetails.clinicianName
                        && this.userName == apIClinicianDetails.userName
                        && this.emailAddress == apIClinicianDetails.emailAddress
                        && this.userPrivilegeId == apIClinicianDetails.userPrivilegeId
                        && this.practiceId == apIClinicianDetails.practiceId
                        && this.loginStartHour == apIClinicianDetails.loginStartHour
                        && this.loginEndHour == apIClinicianDetails.loginEndHour;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (id == null ? 0 : System.hashCode(id));
            hashCode = (17 * hashCode) + (clinicianName == null ? 0 : System.hashCode(clinicianName));
            hashCode = (17 * hashCode) + (userName == null ? 0 : System.hashCode(userName));
            hashCode = (17 * hashCode) + (emailAddress == null ? 0 : System.hashCode(emailAddress));
            hashCode = (17 * hashCode) + (userPrivilegeId == null ? 0 : System.hashCode(userPrivilegeId));
            hashCode = (17 * hashCode) + (practiceId == null ? 0 : System.hashCode(practiceId));
            hashCode = (17 * hashCode) + (loginStartHour == null ? 0 : System.hashCode(loginStartHour));
            hashCode = (17 * hashCode) + (loginEndHour == null ? 0 : System.hashCode(loginEndHour));
            return hashCode;
        }
    }


    /**
     * OASAPIFreeAppointmentSlot
     */
    public class OASAPIFreeAppointmentSlot {
        /**
         * This is the ID of the preferred Clinician.
         */
        public Long clinicianId { get; set; }

        /**
         * This is the name of the preferred Clinician.
         */
        public String clinicianName { get; set; }

        /**
         * The start date of the free Appointment slot
         */
        public Datetime slotStartTime { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPIFreeAppointmentSlot) {
                OASAPIFreeAppointmentSlot apIFreeAppointmentSlot = (OASAPIFreeAppointmentSlot) obj;
                return this.clinicianId == apIFreeAppointmentSlot.clinicianId
                        && this.clinicianName == apIFreeAppointmentSlot.clinicianName
                        && this.slotStartTime == apIFreeAppointmentSlot.slotStartTime;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (clinicianId == null ? 0 : System.hashCode(clinicianId));
            hashCode = (17 * hashCode) + (clinicianName == null ? 0 : System.hashCode(clinicianName));
            hashCode = (17 * hashCode) + (slotStartTime == null ? 0 : System.hashCode(slotStartTime));
            return hashCode;
        }
    }

    /**
     * OASAPIAppointmentType
     */
    public class OASAPIAppointmentType {
        // The Appointment Type ID.
        public Long id { get; set; }

        public Long saleItemId { get; set; }

        // The Appointment Type name.
        public String type { get; set; }

        // The length of the Appointment Type in minutes.
        public Integer duration { get; set; }

        /**
         * Is the Appointment Type enabled or not?
         */
        public Boolean enabled { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPIAppointmentType) {
                OASAPIAppointmentType apIAppointmentType = (OASAPIAppointmentType) obj;
                return this.id == apIAppointmentType.id
                        && this.type == apIAppointmentType.type
                        && this.duration == apIAppointmentType.duration
                        && this.enabled == apIAppointmentType.enabled;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (id == null ? 0 : System.hashCode(id));
            hashCode = (17 * hashCode) + (type == null ? 0 : System.hashCode(type));
            hashCode = (17 * hashCode) + (duration == null ? 0 : System.hashCode(duration));
            hashCode = (17 * hashCode) + (enabled == null ? 0 : System.hashCode(enabled));
            return hashCode;
        }
    }


    /**
     * OASAPIAppointmentDetails
     */
    public class OASAPIAppointmentDetails {
        /**
         * The ID of the Practice. This is taken from the Practice list.
         */
        public Long practiceId { get; set; }

        /**
         * This is the ID of the Patient\'s preferred Clinician. This is taken from the Clinician list.
         */
        public Long userId { get; set; }

        /**
         * This is the Appointment Type ID. This is taken from the Appointment Type list.
         */
        public Long appointmentTypeId { get; set; }

        /**
         * This is the Appointment Status ID. <br><br>1 - Unconfirmed, 2 - Confirmed, 3 - Arrived, 4 - Failed to Attend, 5 - Cancelled by Practice, 6 - In Clinic, 7 - Completed, 8 - Online Booking Request, 9 - Reminder Sent, 10 - Scheduled, 11 - Unscheduled, 12 - Cancelled by Patient, 13 - Deleted, 14 - Late Cancellation, 16 - Was Not Brought.
         */
        public Integer appointmentStatusId { get; set; }

        /**
         * The date of the Appointment.
         */
        public Datetime appointmentTime { get; set; }

        /**
         * This is the identifier for stating if an Appointment is an emergency or not.
         */
        public Boolean emergency { get; set; }

        /**
         * Any additional notes related to the Appointment.	<br><br>Note: This is not clinical notes.
         */
        public String appointmentNotes { get; set; }

        /**
         * This is the length of the Appointment in minutes.
         */
        public Integer duration { get; set; }

        /**
         * This is the ID of the Appointment.
         */
        public Long appointmentId { get; set; }

        /**
         * This is the ID of the patient requesting the appointment.
         */
        public Long patientId { get; set; }

        public String getStatusName() {
            switch on appointmentStatusId {
                when 1 {
                    return 'Unconfirmed';
                }
                when 2 {
                    return 'Confirmed';
                }
                when 3 {
                    return 'Arrived';
                }
                when 4 {
                    return 'Failed to Attend';
                }
                when 5 {
                    return 'Cancelled by Practice';
                }
                when 6 {
                    return 'In Clinic';
                }
                when 7 {
                    return 'Completed';
                }
                when 8 {
                    return 'Online Booking Request';
                }
                when 9 {
                    return 'Reminder Sent';
                }
                when 10 {
                    return 'Scheduled';
                }
                when 11 {
                    return 'Unscheduled';
                }
                when 12 {
                    return 'Cancelled By Patient';
                }
                when 13 {
                    return 'Deleted';
                }
                when 14 {
                    return 'Late Cancellation';
                }
                when 16 {
                    return 'Was Not Brought';
                }
            }

            return null;
        }


        public Boolean isCanceled() {
            return appointmentStatusId == 5
                    || appointmentStatusId == 11
                    || appointmentStatusId == 12
                    || appointmentStatusId == 13
                    || appointmentStatusId == 14;
        }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPIAppointmentDetails) {
                OASAPIAppointmentDetails apIAppointmentDetails = (OASAPIAppointmentDetails) obj;
                return this.practiceId == apIAppointmentDetails.practiceId
                        && this.userId == apIAppointmentDetails.userId
                        && this.appointmentTypeId == apIAppointmentDetails.appointmentTypeId
                        && this.appointmentStatusId == apIAppointmentDetails.appointmentStatusId
                        && this.appointmentTime == apIAppointmentDetails.appointmentTime
                        && this.emergency == apIAppointmentDetails.emergency
                        && this.appointmentNotes == apIAppointmentDetails.appointmentNotes
                        && this.duration == apIAppointmentDetails.duration
                        && this.appointmentId == apIAppointmentDetails.appointmentId
                        && this.patientId == apIAppointmentDetails.patientId;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (practiceId == null ? 0 : System.hashCode(practiceId));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (appointmentTypeId == null ? 0 : System.hashCode(appointmentTypeId));
            hashCode = (17 * hashCode) + (appointmentStatusId == null ? 0 : System.hashCode(appointmentStatusId));
            hashCode = (17 * hashCode) + (appointmentTime == null ? 0 : System.hashCode(appointmentTime));
            hashCode = (17 * hashCode) + (emergency == null ? 0 : System.hashCode(emergency));
            hashCode = (17 * hashCode) + (appointmentNotes == null ? 0 : System.hashCode(appointmentNotes));
            hashCode = (17 * hashCode) + (duration == null ? 0 : System.hashCode(duration));
            hashCode = (17 * hashCode) + (appointmentId == null ? 0 : System.hashCode(appointmentId));
            hashCode = (17 * hashCode) + (patientId == null ? 0 : System.hashCode(patientId));
            return hashCode;
        }
    }


    /**
     * OASUpdateAppointmentRequest
     */
    public class OASUpdateAppointmentRequest {
        /**
         * This is the ID of the Patient\'s preferred Clinician. This is taken from the Clinician list.
         */
        public Long userId { get; set; }

        /**
         * This is the Appointment Status ID. <br><br>1 - Unconfirmed, 2 - Confirmed, 3 - Arrived, 4 - Failed to Attend, 5 - Cancelled by Practice, 6 - In Clinic, 7 - Completed, 8 - Online Booking Request, 9 - Reminder Sent, 10 - Scheduled, 11 - Unscheduled, 12 - Cancelled by Patient, 13 - Deleted, 14 - Late Cancellation, 16 - Was Not Brought.
         */
        public Integer appointmentStatusId { get; set; }

        /**
         * The date and time of the Appointment.
         */
        public Datetime appointmentTime { get; set; }

        /**
         * This is the identifier for stating if an Appointment is an emergency or not.
         */
        public Boolean emergency { get; set; }

        /**
         * Any additional notes related to the Appointment.	<br><br>Note: This is not clinical notes.
         */
        public String appointmentNotes { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASUpdateAppointmentRequest) {
                OASUpdateAppointmentRequest updateAppointmentRequest = (OASUpdateAppointmentRequest) obj;
                return this.userId == updateAppointmentRequest.userId
                        && this.appointmentStatusId == updateAppointmentRequest.appointmentStatusId
                        && this.appointmentTime == updateAppointmentRequest.appointmentTime
                        && this.emergency == updateAppointmentRequest.emergency
                        && this.appointmentNotes == updateAppointmentRequest.appointmentNotes;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (appointmentStatusId == null ? 0 : System.hashCode(appointmentStatusId));
            hashCode = (17 * hashCode) + (appointmentTime == null ? 0 : System.hashCode(appointmentTime));
            hashCode = (17 * hashCode) + (emergency == null ? 0 : System.hashCode(emergency));
            hashCode = (17 * hashCode) + (appointmentNotes == null ? 0 : System.hashCode(appointmentNotes));
            return hashCode;
        }
    }

    /**
     * OASDuplicatePatient
     */
    public class OASDuplicatePatient {
        /**
         * The Patient ID of the duplicate record found.
         */
        public Long patientId { get; set; }

        /**
         * The full name of the duplicate Patient found.
         */
        public String patientFullName { get; set; }

        /**
         * The full address of the duplicate Patient found.
         */
        public String patientFullAddress { get; set; }

        /**
         * The date of birth of the Patient in duplicate record found.
         */
        public Date dob { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASDuplicatePatient) {
                OASDuplicatePatient duplicatePatient = (OASDuplicatePatient) obj;
                return this.patientId == duplicatePatient.patientId
                        && this.patientFullName == duplicatePatient.patientFullName
                        && this.patientFullAddress == duplicatePatient.patientFullAddress
                        && this.dob == duplicatePatient.dob;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (patientId == null ? 0 : System.hashCode(patientId));
            hashCode = (17 * hashCode) + (patientFullName == null ? 0 : System.hashCode(patientFullName));
            hashCode = (17 * hashCode) + (patientFullAddress == null ? 0 : System.hashCode(patientFullAddress));
            hashCode = (17 * hashCode) + (dob == null ? 0 : System.hashCode(dob));
            return hashCode;
        }
    }

    /**
     * OASAPITreatmentPlan
     */
    public class OASAPITreatmentPlan {
        /** The Treatment Plan ID. */
        public Long treatmentPlanId { get; set; }

        /** The Patient ID. */
        public Long patientId { get; set; }

        public String treatmentPlanDescription { get; set; }

        public String treatmentPlanComment { get; set; }

        public Datetime dateCreated { get; set; }

        public Datetime dateSigned { get; set; }

    }

    /**
     * OASAPITreatment
     */
    public class OASAPITreatment {
        /**
         * The Treatment ID.
         */
        public Long treatmentId { get; set; }


        /**
         * The Treatment ID.
         */
        public Long treatmentPlanId { get; set; }

        /**
         * The Patient ID.
         */
        public Long patientId { get; set; }

        /**
         * The Appointment Time.
         */
        public Datetime appointmentTime { get; set; }

        /**
         * The Clinician ID.
         */
        public Long userId { get; set; }

        /**
         * The date the Treatment was created.
         */
        public Datetime dateCreated { get; set; }

        /**
         * The date the Treatment was completed.
         */
        public Datetime dateCompleted { get; set; }

        /**
         * The Treatment Plan.
         */
        public String plan { get; set; }

        /**
         * The Treatment Status ID.
         */
        public String statusId { get; set; }

        /**
         * The Treatment Status.
         */
        public String status { get; set; }

        /**
         * The name of the Treatment Plan.
         */
        public String treatmentPlanDescription { get; set; }

        /**
         * The Delete Indicator.
         */
        public Boolean deleteInd { get; set; }

        /**
         * The Treatment Name.
         */
        public String saleItemText { get; set; }

        /**
         * The Treatment Code.
         */
        public String saleItemCode { get; set; }

        /**
         * This is the outstanding Insurance amount for the Treatment.
         */
        public String outstandingInsuranceAmount { get; set; }

        /**
         * This is the amount paid for the Treatment.
         */
        public String amountPaid { get; set; }

        /**
         * This is the amount refunded for the Treatment.
         */
        public String amountRefunded { get; set; }

        /**
         * This is the quantity of the Treatment.
         */
        public String quantity { get; set; }

        /**
         * This is the unit net price for the Treatment.
         */
        public String unitNetPrice { get; set; }

        /**
         * This is the total net price for the Treatment.
         */
        public String totalNetPrice { get; set; }

        /**
         * This is the discounted price for the Treatment.
         */
        public String totalDiscount { get; set; }

        /**
         * This is the total price for the Treatment.
         */
        public String totalPrice { get; set; }

        /**
         * This is the vat rate for the Treatment.
         */
        public Double vatRate { get; set; }

        /**
         * This is the list of consultation notes.
         */
        public List<OASAPIConsultationNote> consultationNotes { get; set; }

        /**
         * Get hasNotes
         */
        public Boolean hasNotes { get; set; }

        public OASAPITreatment() {
            consultationNotes = new List<OASAPIConsultationNote>();
        }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPITreatment) {
                OASAPITreatment apITreatment = (OASAPITreatment) obj;
                return this.treatmentId == apITreatment.treatmentId
                        && this.patientId == apITreatment.patientId
                        && this.appointmentTime == apITreatment.appointmentTime
                        && this.userId == apITreatment.userId
                        && this.dateCreated == apITreatment.dateCreated
                        && this.dateCompleted == apITreatment.dateCompleted
                        && this.plan == apITreatment.plan
                        && this.statusId == apITreatment.statusId
                        && this.status == apITreatment.status
                        && this.treatmentPlanDescription == apITreatment.treatmentPlanDescription
                        && this.deleteInd == apITreatment.deleteInd
                        && this.saleItemText == apITreatment.saleItemText
                        && this.saleItemCode == apITreatment.saleItemCode
                        && this.outstandingInsuranceAmount == apITreatment.outstandingInsuranceAmount
                        && this.amountPaid == apITreatment.amountPaid
                        && this.amountRefunded == apITreatment.amountRefunded
                        && this.quantity == apITreatment.quantity
                        && this.unitNetPrice == apITreatment.unitNetPrice
                        && this.totalNetPrice == apITreatment.totalNetPrice
                        && this.totalDiscount == apITreatment.totalDiscount
                        && this.totalPrice == apITreatment.totalPrice
                        && this.vatRate == apITreatment.vatRate
                        && this.consultationNotes == apITreatment.consultationNotes
                        && this.hasNotes == apITreatment.hasNotes;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (treatmentId == null ? 0 : System.hashCode(treatmentId));
            hashCode = (17 * hashCode) + (patientId == null ? 0 : System.hashCode(patientId));
            hashCode = (17 * hashCode) + (appointmentTime == null ? 0 : System.hashCode(appointmentTime));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (dateCreated == null ? 0 : System.hashCode(dateCreated));
            hashCode = (17 * hashCode) + (dateCompleted == null ? 0 : System.hashCode(dateCompleted));
            hashCode = (17 * hashCode) + (plan == null ? 0 : System.hashCode(plan));
            hashCode = (17 * hashCode) + (statusId == null ? 0 : System.hashCode(statusId));
            hashCode = (17 * hashCode) + (status == null ? 0 : System.hashCode(status));
            hashCode = (17 * hashCode) + (treatmentPlanDescription == null ? 0 : System.hashCode(treatmentPlanDescription));
            hashCode = (17 * hashCode) + (deleteInd == null ? 0 : System.hashCode(deleteInd));
            hashCode = (17 * hashCode) + (saleItemText == null ? 0 : System.hashCode(saleItemText));
            hashCode = (17 * hashCode) + (saleItemCode == null ? 0 : System.hashCode(saleItemCode));
            hashCode = (17 * hashCode) + (outstandingInsuranceAmount == null ? 0 : System.hashCode(outstandingInsuranceAmount));
            hashCode = (17 * hashCode) + (amountPaid == null ? 0 : System.hashCode(amountPaid));
            hashCode = (17 * hashCode) + (amountRefunded == null ? 0 : System.hashCode(amountRefunded));
            hashCode = (17 * hashCode) + (quantity == null ? 0 : System.hashCode(quantity));
            hashCode = (17 * hashCode) + (unitNetPrice == null ? 0 : System.hashCode(unitNetPrice));
            hashCode = (17 * hashCode) + (totalNetPrice == null ? 0 : System.hashCode(totalNetPrice));
            hashCode = (17 * hashCode) + (totalDiscount == null ? 0 : System.hashCode(totalDiscount));
            hashCode = (17 * hashCode) + (totalPrice == null ? 0 : System.hashCode(totalPrice));
            hashCode = (17 * hashCode) + (vatRate == null ? 0 : System.hashCode(vatRate));
            hashCode = (17 * hashCode) + (consultationNotes == null ? 0 : System.hashCode(consultationNotes));
            hashCode = (17 * hashCode) + (hasNotes == null ? 0 : System.hashCode(hasNotes));
            return hashCode;
        }
    }

    /**
     * OASAPINoteAnswer
     */
    public class OASAPINoteAnswer {
        /**
         * Answer to a question on a patients consultation note.
         */
        public String answer { get; set; }

        /**
         * Question on a patients consultation note.
         */
        public String question { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPINoteAnswer) {
                OASAPINoteAnswer apINoteAnswer = (OASAPINoteAnswer) obj;
                return this.answer == apINoteAnswer.answer
                        && this.question == apINoteAnswer.question;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (answer == null ? 0 : System.hashCode(answer));
            hashCode = (17 * hashCode) + (question == null ? 0 : System.hashCode(question));
            return hashCode;
        }
    }


    /**
     * The list of a Patient\&#39;s consultation notes.
     */
    public class OASAPIConsultationNote implements AeronaServiceOAS.MappedProperties {
        /**
         * The Consultation Note ID.
         */
        public Long id { get; set; }

        /**
         * The ID of the Appointment the note is associated with.
         */
        public Long appointmentId { get; set; }

        /**
         * The ID of the Patient the consultation note is for.
         */
        public Long patientId { get; set; }

        /**
         * The ID of the Clinician who created the note.
         */
        public Long userId { get; set; }

        /**
         * The ID of the note template.
         */
        public Long noteTemplateId { get; set; }

        /**
         * The ID of the tooth the note relates to.
         */
        public Long toothId { get; set; }

        /**
         * The date the note was created on.
         */
        public Datetime r_date { get; set; }

        /**
         * Get complete
         */
        public Boolean complete { get; set; }

        /**
         * The name of the Clinician who created the consultation note.
         */
        public String createdByName { get; set; }

        /**
         * The time of the Appointment the consultation note is associated with.
         */
        public Datetime appointmentTime { get; set; }

        /**
         * The template text of the consultation note.
         */
        public String noteTemplateText { get; set; }

        /**
         * Description of the treatment.
         */
        public String treatment { get; set; }

        /**
         * Get noteAnswers
         */
        public List<OASAPINoteAnswer> noteAnswers { get; set; }

        private final Map<String, String> propertyMappings = new Map<String, String>{
                'date' => 'r_date'
        };

        public Map<String, String> getPropertyMappings() {
            return propertyMappings;
        }

        public OASAPIConsultationNote() {
            noteAnswers = new List<OASAPINoteAnswer>();
        }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPIConsultationNote) {
                OASAPIConsultationNote apIConsultationNote = (OASAPIConsultationNote) obj;
                return this.id == apIConsultationNote.id
                        && this.appointmentId == apIConsultationNote.appointmentId
                        && this.patientId == apIConsultationNote.patientId
                        && this.userId == apIConsultationNote.userId
                        && this.noteTemplateId == apIConsultationNote.noteTemplateId
                        && this.toothId == apIConsultationNote.toothId
                        && this.r_date == apIConsultationNote.r_date
                        && this.complete == apIConsultationNote.complete
                        && this.createdByName == apIConsultationNote.createdByName
                        && this.appointmentTime == apIConsultationNote.appointmentTime
                        && this.noteTemplateText == apIConsultationNote.noteTemplateText
                        && this.treatment == apIConsultationNote.treatment
                        && this.noteAnswers == apIConsultationNote.noteAnswers;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (id == null ? 0 : System.hashCode(id));
            hashCode = (17 * hashCode) + (appointmentId == null ? 0 : System.hashCode(appointmentId));
            hashCode = (17 * hashCode) + (patientId == null ? 0 : System.hashCode(patientId));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (noteTemplateId == null ? 0 : System.hashCode(noteTemplateId));
            hashCode = (17 * hashCode) + (toothId == null ? 0 : System.hashCode(toothId));
            hashCode = (17 * hashCode) + (r_date == null ? 0 : System.hashCode(r_date));
            hashCode = (17 * hashCode) + (complete == null ? 0 : System.hashCode(complete));
            hashCode = (17 * hashCode) + (createdByName == null ? 0 : System.hashCode(createdByName));
            hashCode = (17 * hashCode) + (appointmentTime == null ? 0 : System.hashCode(appointmentTime));
            hashCode = (17 * hashCode) + (noteTemplateText == null ? 0 : System.hashCode(noteTemplateText));
            hashCode = (17 * hashCode) + (treatment == null ? 0 : System.hashCode(treatment));
            hashCode = (17 * hashCode) + (noteAnswers == null ? 0 : System.hashCode(noteAnswers));
            return hashCode;
        }
    }


    /**
     * List of Patient\&#39;s Care Plans.
     */
    public class OASAPIPatientCarePlan {
        /**
         * The Patient ID.
         */
        public Long patientId { get; set; }

        /**
         * The Care Plan ID.
         */
        public Long carePlanId { get; set; }

        /**
         * Is the Care Plan enabled?
         */
        public Boolean enabled { get; set; }

        /**
         * The Plan Reference.
         */
        public String planReference { get; set; }

        /**
         * The Plan Reference date.
         */
        public Date planReferenceDate { get; set; }

        /**
         * The start date of the Care Plan.
         */
        public Date startDate { get; set; }

        /**
         * The end date of the Care Plan.
         */
        public Date endDate { get; set; }

        /**
         * The cost of the Care Plan.
         */
        public Double price { get; set; }

        /**
         * The frequency of the Payment.  1 - Weekly, 2 - Monthly, 3 - Yearly
         */
        public Integer paymentFrequency { get; set; }

        /**
         * The Exemption, applies to NHS patients only.
         */
        public Integer exemption { get; set; }

        /**
         * The Exemption details, applies to NHS patients only..
         */
        public String exemptionDetails { get; set; }

        /**
         * Evidence seen, applies to NHS patients only.
         */
        public Boolean evidenceSeen { get; set; }

        /**
         * Care Plan description.
         */
        public String carePlanDescription { get; set; }

        public Boolean forceCreate { get; set; }


        public Boolean equals(Object obj) {
            if (obj instanceof OASAPIPatientCarePlan) {
                OASAPIPatientCarePlan apIPatientCarePlan = (OASAPIPatientCarePlan) obj;
                return this.patientId == apIPatientCarePlan.patientId
                        && this.carePlanId == apIPatientCarePlan.carePlanId
                        && this.enabled == apIPatientCarePlan.enabled
                        && this.planReference == apIPatientCarePlan.planReference
                        && this.planReferenceDate == apIPatientCarePlan.planReferenceDate
                        && this.startDate == apIPatientCarePlan.startDate
                        && this.endDate == apIPatientCarePlan.endDate
                        && this.price == apIPatientCarePlan.price
                        && this.paymentFrequency == apIPatientCarePlan.paymentFrequency
                        && this.exemption == apIPatientCarePlan.exemption
                        && this.exemptionDetails == apIPatientCarePlan.exemptionDetails
                        && this.evidenceSeen == apIPatientCarePlan.evidenceSeen
                        && this.carePlanDescription == apIPatientCarePlan.carePlanDescription;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (patientId == null ? 0 : System.hashCode(patientId));
            hashCode = (17 * hashCode) + (carePlanId == null ? 0 : System.hashCode(carePlanId));
            hashCode = (17 * hashCode) + (enabled == null ? 0 : System.hashCode(enabled));
            hashCode = (17 * hashCode) + (planReference == null ? 0 : System.hashCode(planReference));
            hashCode = (17 * hashCode) + (planReferenceDate == null ? 0 : System.hashCode(planReferenceDate));
            hashCode = (17 * hashCode) + (startDate == null ? 0 : System.hashCode(startDate));
            hashCode = (17 * hashCode) + (endDate == null ? 0 : System.hashCode(endDate));
            hashCode = (17 * hashCode) + (price == null ? 0 : System.hashCode(price));
            hashCode = (17 * hashCode) + (paymentFrequency == null ? 0 : System.hashCode(paymentFrequency));
            hashCode = (17 * hashCode) + (exemption == null ? 0 : System.hashCode(exemption));
            hashCode = (17 * hashCode) + (exemptionDetails == null ? 0 : System.hashCode(exemptionDetails));
            hashCode = (17 * hashCode) + (evidenceSeen == null ? 0 : System.hashCode(evidenceSeen));
            hashCode = (17 * hashCode) + (carePlanDescription == null ? 0 : System.hashCode(carePlanDescription));
            return hashCode;
        }
    }


    /**
     * OASAPINote
     */
    public class OASAPINote {
        /**
         * The list of a Patient\'s consultation notes.
         */
        public List<OASAPIConsultationNote> consultationNotes { get; set; }

        public OASAPINote() {
            consultationNotes = new List<OASAPIConsultationNote>();
        }

        public Boolean equals(Object obj) {
            if (obj instanceof OASAPINote) {
                OASAPINote apINote = (OASAPINote) obj;
                return this.consultationNotes == apINote.consultationNotes;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (consultationNotes == null ? 0 : System.hashCode(consultationNotes));
            return hashCode;
        }
    }

    public class OASCarePlan {
        public Long id;
        public String description;
        public Boolean enabled;
    }

    /**
     * OASStandardResponse
     */
    public class OASStandardResponse {

        public String status { get; set; }
        public Object result { get; set; }
        public String errorResult { get; set; }
        public Map<String, String> headers { get; set; }
        public Integer errorCode { get; set; }

    }

    /**
     * OASErrorResponse
     */
    public class OASErrorResponse {
        /**
         * The HTTP status code of the error.
         */
        public Integer status { get; set; }

        /**
         * The message describing the error.
         */
        public String message { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASErrorResponse) {
                OASErrorResponse errorResponse = (OASErrorResponse) obj;
                return this.status == errorResponse.status
                        && this.message == errorResponse.message;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (status == null ? 0 : System.hashCode(status));
            hashCode = (17 * hashCode) + (message == null ? 0 : System.hashCode(message));
            return hashCode;
        }
    }


    /**
     * OASRetrievePatientResponse
     */
    public class OASRetrievePatientResponse {

        /**
         * The ID of the Patient
         */
        public Long patientId { get; set; }

        /**
         * The ID of the Practice.
         */
        public Long practiceId { get; set; }

        /**
         * The Patient Type ID within Aerona:<br><br>Private - 1 (all patients not on care plan), GMS - 3, PRSI - 5, NHS - 7, DenPlan - 8
         */
        public Long patientTypeId { get; set; }

        /**
         * The ID of the source. This is taken from source list within Aerona.
         */
        public Long sourceId { get; set; }

        /**
         * The ID of the referrer. This is taken from referrer list within Aerona.
         */
        public Long referrerId { get; set; }

        /**
         * This is the gender ID within Aerona. <br><br>1 - Male, 2 - Female
         */
        public Long genderId { get; set; }

        /**
         * This is the patient\'s Title ID. This is taken from the title list within Aerona.
         */
        public Long titleId { get; set; }

        /**
         * The patient\'s forename.
         */
        public String forename { get; set; }

        /**
         * The patient\'s surname.
         */
        public String surname { get; set; }

        /**
         * The patient\'s maiden name.
         */
        public String maidenName { get; set; }

        /**
         * The patient\'s occupation.
         */
        public String occupation { get; set; }

        /**
         * The patient\'s date of birth. Format is yyyy-MM-dd.
         */
        public Date dob { get; set; }

        /**
         * This is the patient\'s known as name.
         */
        public String knownAs { get; set; }

        /**
         * First line of address.
         */
        public String address1 { get; set; }

        /**
         * Second line of address.
         */
        public String address2 { get; set; }

        /**
         * Third line of address.
         */
        public String address3 { get; set; }

        /**
         * Fourth line of address.
         */
        public String address4 { get; set; }

        /**
         * The patient\'s postcode.
         */
        public String code { get; set; }

        /**
         * The patient\'s email address.
         */
        public String emailAddress { get; set; }

        /**
         * The patient\'s mobile phone number. The leading zero should be replaced with country code.
         */
        public String mobileNumber { get; set; }

        /**
         * The patient\'s home phone number.
         */
        public String homeNumber { get; set; }

        /**
         * The patient\'s work phone number.
         */
        public String workNumber { get; set; }

        /**
         * The patient\'s fax number.
         */
        public String faxNumber { get; set; }

        /**
         * This is if the patient has given permission to be communicated via text message. The default value is false.
         */
        public Boolean allowText { get; set; }

        /**
         * This is if the patient has given permission to be communicated via email. The default value is false.
         */
        public Boolean allowEmail { get; set; }

        /**
         * This is if the patient has given permission to be communicated via post. The default value is false.
         */
        public Boolean allowPrint { get; set; }

        /**
         * This is the patient\'s preferred Clinician ID. This is taken from the Clinician list.
         */
        public Integer userId { get; set; }

        /**
         * The patient\'s status within Aerona. <br><br>1 - Active (default), 2 - Inactive, 3 - Deceased, 4 - Lead.
         */
        public Integer statusId { get; set; }

        /**
         * List of all the Patient\'s Appointments.
         */
        public List<OASAPIAppointmentDetails> appointments { get; set; }

        /**
         * List of Patient\'s Care Plans.
         */
        public List<OASAPIPatientCarePlan> patientCarePlans { get; set; }

        public OASRetrievePatientResponse() {
            appointments = new List<OASAPIAppointmentDetails>();
            patientCarePlans = new List<OASAPIPatientCarePlan>();
        }

        public Boolean equals(Object obj) {
            if (obj instanceof OASRetrievePatientResponse) {
                OASRetrievePatientResponse retrievePatientResponse = (OASRetrievePatientResponse) obj;
                return this.practiceId == retrievePatientResponse.practiceId
                        && this.patientTypeId == retrievePatientResponse.patientTypeId
                        && this.sourceId == retrievePatientResponse.sourceId
                        && this.referrerId == retrievePatientResponse.referrerId
                        && this.genderId == retrievePatientResponse.genderId
                        && this.titleId == retrievePatientResponse.titleId
                        && this.forename == retrievePatientResponse.forename
                        && this.surname == retrievePatientResponse.surname
                        && this.maidenName == retrievePatientResponse.maidenName
                        && this.occupation == retrievePatientResponse.occupation
                        && this.dob == retrievePatientResponse.dob
                        && this.knownAs == retrievePatientResponse.knownAs
                        && this.address1 == retrievePatientResponse.address1
                        && this.address2 == retrievePatientResponse.address2
                        && this.address3 == retrievePatientResponse.address3
                        && this.address4 == retrievePatientResponse.address4
                        && this.code == retrievePatientResponse.code
                        && this.emailAddress == retrievePatientResponse.emailAddress
                        && this.mobileNumber == retrievePatientResponse.mobileNumber
                        && this.homeNumber == retrievePatientResponse.homeNumber
                        && this.workNumber == retrievePatientResponse.workNumber
                        && this.faxNumber == retrievePatientResponse.faxNumber
                        && this.allowText == retrievePatientResponse.allowText
                        && this.allowEmail == retrievePatientResponse.allowEmail
                        && this.allowPrint == retrievePatientResponse.allowPrint
                        && this.userId == retrievePatientResponse.userId
                        && this.statusId == retrievePatientResponse.statusId
                        && this.appointments == retrievePatientResponse.appointments
                        && this.patientCarePlans == retrievePatientResponse.patientCarePlans;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (practiceId == null ? 0 : System.hashCode(practiceId));
            hashCode = (17 * hashCode) + (patientTypeId == null ? 0 : System.hashCode(patientTypeId));
            hashCode = (17 * hashCode) + (sourceId == null ? 0 : System.hashCode(sourceId));
            hashCode = (17 * hashCode) + (referrerId == null ? 0 : System.hashCode(referrerId));
            hashCode = (17 * hashCode) + (genderId == null ? 0 : System.hashCode(genderId));
            hashCode = (17 * hashCode) + (titleId == null ? 0 : System.hashCode(titleId));
            hashCode = (17 * hashCode) + (forename == null ? 0 : System.hashCode(forename));
            hashCode = (17 * hashCode) + (surname == null ? 0 : System.hashCode(surname));
            hashCode = (17 * hashCode) + (maidenName == null ? 0 : System.hashCode(maidenName));
            hashCode = (17 * hashCode) + (occupation == null ? 0 : System.hashCode(occupation));
            hashCode = (17 * hashCode) + (dob == null ? 0 : System.hashCode(dob));
            hashCode = (17 * hashCode) + (knownAs == null ? 0 : System.hashCode(knownAs));
            hashCode = (17 * hashCode) + (address1 == null ? 0 : System.hashCode(address1));
            hashCode = (17 * hashCode) + (address2 == null ? 0 : System.hashCode(address2));
            hashCode = (17 * hashCode) + (address3 == null ? 0 : System.hashCode(address3));
            hashCode = (17 * hashCode) + (address4 == null ? 0 : System.hashCode(address4));
            hashCode = (17 * hashCode) + (code == null ? 0 : System.hashCode(code));
            hashCode = (17 * hashCode) + (emailAddress == null ? 0 : System.hashCode(emailAddress));
            hashCode = (17 * hashCode) + (mobileNumber == null ? 0 : System.hashCode(mobileNumber));
            hashCode = (17 * hashCode) + (homeNumber == null ? 0 : System.hashCode(homeNumber));
            hashCode = (17 * hashCode) + (workNumber == null ? 0 : System.hashCode(workNumber));
            hashCode = (17 * hashCode) + (faxNumber == null ? 0 : System.hashCode(faxNumber));
            hashCode = (17 * hashCode) + (allowText == null ? 0 : System.hashCode(allowText));
            hashCode = (17 * hashCode) + (allowEmail == null ? 0 : System.hashCode(allowEmail));
            hashCode = (17 * hashCode) + (allowPrint == null ? 0 : System.hashCode(allowPrint));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (statusId == null ? 0 : System.hashCode(statusId));
            hashCode = (17 * hashCode) + (appointments == null ? 0 : System.hashCode(appointments));
            hashCode = (17 * hashCode) + (patientCarePlans == null ? 0 : System.hashCode(patientCarePlans));
            return hashCode;
        }
    }


    /**
     * OASLoginRequest
     */
    public class OASLoginRequest {
        /**
         * The username to log in as.
         */
        public String username { get; set; }

        /**
         * The password of the user.
         */
        public String password { get; set; }

        /**
         * The practice pin.
         */
        public String pin { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASLoginRequest) {
                OASLoginRequest loginRequest = (OASLoginRequest) obj;
                return this.username == loginRequest.username
                        && this.password == loginRequest.password
                        && this.pin == loginRequest.pin;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (username == null ? 0 : System.hashCode(username));
            hashCode = (17 * hashCode) + (password == null ? 0 : System.hashCode(password));
            hashCode = (17 * hashCode) + (pin == null ? 0 : System.hashCode(pin));
            return hashCode;
        }
    }

    /**
     * OASCreatePatientRequest
     */
    public class OASCreatePatientRequest {
        /**
         * The ID of the Practice.
         */
        public Long practiceId { get; set; }

        /**
         * The Patient Type ID within Aerona:<br><br>Private - 1 (all patients not on care plan), GMS - 3, PRSI - 5, NHS - 7, DenPlan - 8
         */
        public Long patientTypeId { get; set; }

        /**
         * The ID of the source. This is taken from source list within Aerona.
         */
        public Long sourceId { get; set; }

        /**
         * The ID of the referrer. This is taken from referrer list within Aerona.
         */
        public Long referrerId { get; set; }

        /**
         * This is the gender ID within Aerona. <br><br>1 - Male, 2 - Female
         */
        public Long genderId { get; set; }

        /**
         * This is the patient\'s Title ID. This is taken from the title list within Aerona.
         */
        public Long titleId { get; set; }

        /**
         * The patient\'s forename.
         */
        public String forename { get; set; }

        /**
         * The patient\'s surname.
         */
        public String surname { get; set; }

        /**
         * The patient\'s maiden name.
         */
        public String maidenName { get; set; }

        /**
         * The patient\'s occupation.
         */
        public String occupation { get; set; }

        /**
         * The patient\'s date of birth. Format is yyyy-MM-dd.
         */
        public Date dob { get; set; }

        /**
         * This is the patient\'s known as name.
         */
        public String knownAs { get; set; }

        /**
         * First line of address.
         */
        public String address1 { get; set; }

        /**
         * Second line of address.
         */
        public String address2 { get; set; }

        /**
         * Third line of address.
         */
        public String address3 { get; set; }

        /**
         * Fourth line of address.
         */
        public String address4 { get; set; }

        /**
         * The patient\'s postcode.
         */
        public String code { get; set; }

        /**
         * The patient\'s email address.
         */
        public String emailAddress { get; set; }

        /**
         * The patient\'s mobile phone number. The leading zero should be replaced with country code.
         */
        public String mobileNumber { get; set; }

        /**
         * The patient\'s home phone number.
         */
        public String homeNumber { get; set; }

        /**
         * The patient\'s work phone number.
         */
        public String workNumber { get; set; }

        /**
         * The patient\'s fax number.
         */
        public String faxNumber { get; set; }

        /**
         * This is if the patient has given permission to be communicated via text message. The default value is false.
         */
        public Boolean allowText { get; set; }

        /**
         * This is if the patient has given permission to be communicated via email. The default value is false.
         */
        public Boolean allowEmail { get; set; }

        /**
         * This is if the patient has given permission to be communicated via post. The default value is false.
         */
        public Boolean allowPrint { get; set; }

        /**
         * This is the patient\'s preferred Clinician ID. This is taken from the Clinician list.
         */
        public Integer userId { get; set; }

        /**
         * The patient\'s status within Aerona. <br><br>1 - Active (default), 2 - Inactive, 3 - Deceased, 4 - Lead.
         */
        public Integer statusId { get; set; }

        /**
         * This is if the possible matches have been reviewed and you need toforce Aerona to create the new patient.
         */
        public Boolean forceCreate { get; set; }


        public Boolean equals(Object obj) {
            if (obj instanceof OASCreatePatientRequest) {
                OASCreatePatientRequest createPatientRequest = (OASCreatePatientRequest) obj;
                return this.practiceId == createPatientRequest.practiceId
                        && this.patientTypeId == createPatientRequest.patientTypeId
                        && this.sourceId == createPatientRequest.sourceId
                        && this.referrerId == createPatientRequest.referrerId
                        && this.genderId == createPatientRequest.genderId
                        && this.titleId == createPatientRequest.titleId
                        && this.forename == createPatientRequest.forename
                        && this.surname == createPatientRequest.surname
                        && this.maidenName == createPatientRequest.maidenName
                        && this.occupation == createPatientRequest.occupation
                        && this.dob == createPatientRequest.dob
                        && this.knownAs == createPatientRequest.knownAs
                        && this.address1 == createPatientRequest.address1
                        && this.address2 == createPatientRequest.address2
                        && this.address3 == createPatientRequest.address3
                        && this.address4 == createPatientRequest.address4
                        && this.code == createPatientRequest.code
                        && this.emailAddress == createPatientRequest.emailAddress
                        && this.mobileNumber == createPatientRequest.mobileNumber
                        && this.homeNumber == createPatientRequest.homeNumber
                        && this.workNumber == createPatientRequest.workNumber
                        && this.faxNumber == createPatientRequest.faxNumber
                        && this.allowText == createPatientRequest.allowText
                        && this.allowEmail == createPatientRequest.allowEmail
                        && this.allowPrint == createPatientRequest.allowPrint
                        && this.userId == createPatientRequest.userId
                        && this.statusId == createPatientRequest.statusId
                        && this.forceCreate == createPatientRequest.forceCreate;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (practiceId == null ? 0 : System.hashCode(practiceId));
            hashCode = (17 * hashCode) + (patientTypeId == null ? 0 : System.hashCode(patientTypeId));
            hashCode = (17 * hashCode) + (sourceId == null ? 0 : System.hashCode(sourceId));
            hashCode = (17 * hashCode) + (referrerId == null ? 0 : System.hashCode(referrerId));
            hashCode = (17 * hashCode) + (genderId == null ? 0 : System.hashCode(genderId));
            hashCode = (17 * hashCode) + (titleId == null ? 0 : System.hashCode(titleId));
            hashCode = (17 * hashCode) + (forename == null ? 0 : System.hashCode(forename));
            hashCode = (17 * hashCode) + (surname == null ? 0 : System.hashCode(surname));
            hashCode = (17 * hashCode) + (maidenName == null ? 0 : System.hashCode(maidenName));
            hashCode = (17 * hashCode) + (occupation == null ? 0 : System.hashCode(occupation));
            hashCode = (17 * hashCode) + (dob == null ? 0 : System.hashCode(dob));
            hashCode = (17 * hashCode) + (knownAs == null ? 0 : System.hashCode(knownAs));
            hashCode = (17 * hashCode) + (address1 == null ? 0 : System.hashCode(address1));
            hashCode = (17 * hashCode) + (address2 == null ? 0 : System.hashCode(address2));
            hashCode = (17 * hashCode) + (address3 == null ? 0 : System.hashCode(address3));
            hashCode = (17 * hashCode) + (address4 == null ? 0 : System.hashCode(address4));
            hashCode = (17 * hashCode) + (code == null ? 0 : System.hashCode(code));
            hashCode = (17 * hashCode) + (emailAddress == null ? 0 : System.hashCode(emailAddress));
            hashCode = (17 * hashCode) + (mobileNumber == null ? 0 : System.hashCode(mobileNumber));
            hashCode = (17 * hashCode) + (homeNumber == null ? 0 : System.hashCode(homeNumber));
            hashCode = (17 * hashCode) + (workNumber == null ? 0 : System.hashCode(workNumber));
            hashCode = (17 * hashCode) + (faxNumber == null ? 0 : System.hashCode(faxNumber));
            hashCode = (17 * hashCode) + (allowText == null ? 0 : System.hashCode(allowText));
            hashCode = (17 * hashCode) + (allowEmail == null ? 0 : System.hashCode(allowEmail));
            hashCode = (17 * hashCode) + (allowPrint == null ? 0 : System.hashCode(allowPrint));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (statusId == null ? 0 : System.hashCode(statusId));
            hashCode = (17 * hashCode) + (forceCreate == null ? 0 : System.hashCode(forceCreate));
            return hashCode;
        }
    }


    /**
     * OASUpdatePatientRequest
     */
    public class OASUpdatePatientRequest {
        /**
         * The ID of the Practice.
         */
        public Long practiceId { get; set; }

        /**
         * The Patient Type ID within Aerona:<br><br>Private - 1 (all patients not on care plan), GMS - 3, PRSI - 5, NHS - 7, DenPlan - 8
         */
        public Long patientTypeId { get; set; }

        /**
         * The ID of the source. This is taken from source list within Aerona.
         */
        public Long sourceId { get; set; }

        /**
         * The ID of the referrer. This is taken from referrer list within Aerona.
         */
        public Long referrerId { get; set; }

        /**
         * This is the gender ID within Aerona. <br><br>1 - Male, 2 - Female
         */
        public Long genderId { get; set; }

        /**
         * This is the patient\'s Title ID. This is taken from the title list within Aerona.
         */
        public Long titleId { get; set; }

        /**
         * The patient\'s forename.
         */
        public String forename { get; set; }

        /**
         * The patient\'s surname.
         */
        public String surname { get; set; }

        /**
         * The patient\'s maiden name.
         */
        public String maidenName { get; set; }

        /**
         * The patient\'s occupation.
         */
        public String occupation { get; set; }

        /**
         * The patient\'s date of birth. Format is yyyy-MM-dd.
         */
        public Date dob { get; set; }

        /**
         * This is the patient\'s known as name.
         */
        public String knownAs { get; set; }

        /**
         * First line of address.
         */
        public String address1 { get; set; }

        /**
         * Second line of address.
         */
        public String address2 { get; set; }

        /**
         * Third line of address.
         */
        public String address3 { get; set; }

        /**
         * Fourth line of address.
         */
        public String address4 { get; set; }

        /**
         * The patient\'s postcode.
         */
        public String code { get; set; }

        /**
         * The patient\'s email address.
         */
        public String emailAddress { get; set; }

        /**
         * The patient\'s mobile phone number. The leading zero should be replaced with country code.
         */
        public String mobileNumber { get; set; }

        /**
         * The patient\'s home phone number.
         */
        public String homeNumber { get; set; }

        /**
         * The patient\'s work phone number.
         */
        public String workNumber { get; set; }

        /**
         * The patient\'s fax number.
         */
        public String faxNumber { get; set; }

        /**
         * This is if the patient has given permission to be communicated via text message. The default value is false.
         */
        public Boolean allowText { get; set; }

        /**
         * This is if the patient has given permission to be communicated via email. The default value is false.
         */
        public Boolean allowEmail { get; set; }

        /**
         * This is if the patient has given permission to be communicated via post. The default value is false.
         */
        public Boolean allowPrint { get; set; }

        /**
         * This is the patient\'s preferred Clinician ID. This is taken from the Clinician list.
         */
        public Integer userId { get; set; }

        /**
         * The patient\'s status within Aerona. <br><br>1 - Active (default), 2 - Inactive, 3 - Deceased, 4 - Lead.
         */
        public Integer statusId { get; set; }

        public Boolean equals(Object obj) {
            if (obj instanceof OASUpdatePatientRequest) {
                OASUpdatePatientRequest updatePatientRequest = (OASUpdatePatientRequest) obj;
                return this.practiceId == updatePatientRequest.practiceId
                        && this.patientTypeId == updatePatientRequest.patientTypeId
                        && this.sourceId == updatePatientRequest.sourceId
                        && this.referrerId == updatePatientRequest.referrerId
                        && this.genderId == updatePatientRequest.genderId
                        && this.titleId == updatePatientRequest.titleId
                        && this.forename == updatePatientRequest.forename
                        && this.surname == updatePatientRequest.surname
                        && this.maidenName == updatePatientRequest.maidenName
                        && this.occupation == updatePatientRequest.occupation
                        && this.dob == updatePatientRequest.dob
                        && this.knownAs == updatePatientRequest.knownAs
                        && this.address1 == updatePatientRequest.address1
                        && this.address2 == updatePatientRequest.address2
                        && this.address3 == updatePatientRequest.address3
                        && this.address4 == updatePatientRequest.address4
                        && this.code == updatePatientRequest.code
                        && this.emailAddress == updatePatientRequest.emailAddress
                        && this.mobileNumber == updatePatientRequest.mobileNumber
                        && this.homeNumber == updatePatientRequest.homeNumber
                        && this.workNumber == updatePatientRequest.workNumber
                        && this.faxNumber == updatePatientRequest.faxNumber
                        && this.allowText == updatePatientRequest.allowText
                        && this.allowEmail == updatePatientRequest.allowEmail
                        && this.allowPrint == updatePatientRequest.allowPrint
                        && this.userId == updatePatientRequest.userId
                        && this.statusId == updatePatientRequest.statusId;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (practiceId == null ? 0 : System.hashCode(practiceId));
            hashCode = (17 * hashCode) + (patientTypeId == null ? 0 : System.hashCode(patientTypeId));
            hashCode = (17 * hashCode) + (sourceId == null ? 0 : System.hashCode(sourceId));
            hashCode = (17 * hashCode) + (referrerId == null ? 0 : System.hashCode(referrerId));
            hashCode = (17 * hashCode) + (genderId == null ? 0 : System.hashCode(genderId));
            hashCode = (17 * hashCode) + (titleId == null ? 0 : System.hashCode(titleId));
            hashCode = (17 * hashCode) + (forename == null ? 0 : System.hashCode(forename));
            hashCode = (17 * hashCode) + (surname == null ? 0 : System.hashCode(surname));
            hashCode = (17 * hashCode) + (maidenName == null ? 0 : System.hashCode(maidenName));
            hashCode = (17 * hashCode) + (occupation == null ? 0 : System.hashCode(occupation));
            hashCode = (17 * hashCode) + (dob == null ? 0 : System.hashCode(dob));
            hashCode = (17 * hashCode) + (knownAs == null ? 0 : System.hashCode(knownAs));
            hashCode = (17 * hashCode) + (address1 == null ? 0 : System.hashCode(address1));
            hashCode = (17 * hashCode) + (address2 == null ? 0 : System.hashCode(address2));
            hashCode = (17 * hashCode) + (address3 == null ? 0 : System.hashCode(address3));
            hashCode = (17 * hashCode) + (address4 == null ? 0 : System.hashCode(address4));
            hashCode = (17 * hashCode) + (code == null ? 0 : System.hashCode(code));
            hashCode = (17 * hashCode) + (emailAddress == null ? 0 : System.hashCode(emailAddress));
            hashCode = (17 * hashCode) + (mobileNumber == null ? 0 : System.hashCode(mobileNumber));
            hashCode = (17 * hashCode) + (homeNumber == null ? 0 : System.hashCode(homeNumber));
            hashCode = (17 * hashCode) + (workNumber == null ? 0 : System.hashCode(workNumber));
            hashCode = (17 * hashCode) + (faxNumber == null ? 0 : System.hashCode(faxNumber));
            hashCode = (17 * hashCode) + (allowText == null ? 0 : System.hashCode(allowText));
            hashCode = (17 * hashCode) + (allowEmail == null ? 0 : System.hashCode(allowEmail));
            hashCode = (17 * hashCode) + (allowPrint == null ? 0 : System.hashCode(allowPrint));
            hashCode = (17 * hashCode) + (userId == null ? 0 : System.hashCode(userId));
            hashCode = (17 * hashCode) + (statusId == null ? 0 : System.hashCode(statusId));
            return hashCode;
        }
    }


    /**
     * OASCreatePatientResponse
     */
    public class OASCreatePatientResponse {
        /**
         * The newly created patient ID, if the patient has been created successfully. If the patient was not created due to a duplicate being found,  then the patient ID returned will be zero.
         */
        public Long id { get; set; }

        /**
         * This will only be set if any duplicate patients have been found in the Aerona system. The new patient will not be created if a duplicate is found, unless the request  indicated that the forceCreate parameter is true.
         */
        public List<OASDuplicatePatient> duplicatePatients { get; set; }

        public Boolean hasDuplicates() {
            return this.duplicatePatients != null && this.duplicatePatients.size() > 0;
        }

        public OASCreatePatientResponse() {
            duplicatePatients = new List<OASDuplicatePatient>();
        }

        public Boolean equals(Object obj) {
            if (obj instanceof OASCreatePatientResponse) {
                OASCreatePatientResponse createPatientResponse = (OASCreatePatientResponse) obj;
                return this.id == createPatientResponse.id
                        && this.duplicatePatients == createPatientResponse.duplicatePatients;
            }
            return false;
        }

        public Integer hashCode() {
            Integer hashCode = 43;
            hashCode = (17 * hashCode) + (id == null ? 0 : System.hashCode(id));
            hashCode = (17 * hashCode) + (duplicatePatients == null ? 0 : System.hashCode(duplicatePatients));
            return hashCode;
        }
    }


}