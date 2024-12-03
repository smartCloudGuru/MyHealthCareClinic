/**
 * Created 8.11.2022..
 */

@IsTest
private class AeronaServiceOASApiTest {

    @IsTest
    static void testOASCreateAppointmentRequest() {
        AeronaServiceOASApi.OASCreateAppointmentRequest createAppointmentRequest = new AeronaServiceOASApi.OASCreateAppointmentRequest();
        createAppointmentRequest.practiceId = 9876L;
        createAppointmentRequest.userId = 34567L;
        createAppointmentRequest.appointmentTypeId = 1864L;
        createAppointmentRequest.appointmentStatusId = 7;
        createAppointmentRequest.appointmentTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        createAppointmentRequest.emergency = false;
        createAppointmentRequest.appointmentNotes = 'Patient is nervous.';
        createAppointmentRequest.duration = 45;
        createAppointmentRequest.patientId = 426909L;

        System.assert(createAppointmentRequest.hashCode()!=null);
        AeronaServiceOASApi.OASCreateAppointmentRequest createAppointmentRequest2 = new AeronaServiceOASApi.OASCreateAppointmentRequest();
        createAppointmentRequest2.practiceId = 9876L;
        createAppointmentRequest2.userId = 34567L;
        createAppointmentRequest2.appointmentTypeId = 1864L;
        createAppointmentRequest2.appointmentStatusId = 7;
        createAppointmentRequest2.appointmentTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        createAppointmentRequest2.emergency = false;
        createAppointmentRequest2.appointmentNotes = 'Patient is nervous.';
        createAppointmentRequest2.duration = 45;
        createAppointmentRequest2.patientId = 426909L;
        System.assert(createAppointmentRequest2.equals(createAppointmentRequest));
        createAppointmentRequest2.duration=createAppointmentRequest.duration+10;
        System.assert(!createAppointmentRequest2.equals(createAppointmentRequest));
    }

    @IsTest
    static void testOASAPIClinicianDetails() {
        AeronaServiceOASApi.OASAPIClinicianDetails apIClinicianDetails = new AeronaServiceOASApi.OASAPIClinicianDetails();
        apIClinicianDetails.id = 34567L;
        apIClinicianDetails.clinicianName = 'Dr. John Smith';
        apIClinicianDetails.userName = 'JohnSmith';
        apIClinicianDetails.emailAddress = 'john.smith@aerona.com';
        apIClinicianDetails.userPrivilegeId = 2L;
        apIClinicianDetails.practiceId = 9876L;
        apIClinicianDetails.loginStartHour = 9;
        apIClinicianDetails.loginEndHour = 18;
        System.assert(apIClinicianDetails.hashCode()!=null);
        System.assert(apIClinicianDetails.equals(apIClinicianDetails));
    }

    @IsTest
    static void testOASAPIFreeAppointmentSlot() {
        AeronaServiceOASApi.OASAPIFreeAppointmentSlot apIFreeAppointmentSlot = new AeronaServiceOASApi.OASAPIFreeAppointmentSlot();
        apIFreeAppointmentSlot.clinicianId = 34567L;
        apIFreeAppointmentSlot.clinicianName = 'Dr. John Smith';
        apIFreeAppointmentSlot.slotStartTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        System.assert(apIFreeAppointmentSlot.hashCode()!=null);
        System.assert(apIFreeAppointmentSlot.equals(apIFreeAppointmentSlot));
    }

    @IsTest
    static void testOASAPIAppointmentType() {
        AeronaServiceOASApi.OASAPIAppointmentType apIAppointmentType = new AeronaServiceOASApi.OASAPIAppointmentType();
        apIAppointmentType.id = 1864L;
        apIAppointmentType.type = 'Examination';
        apIAppointmentType.duration = 30;
        apIAppointmentType.enabled = true;
        System.assert(apIAppointmentType.hashCode()!=null);
        System.assert(apIAppointmentType.equals(apIAppointmentType));
    }

    @IsTest
    static void testOASAPIAppointmentDetails() {
        AeronaServiceOASApi.OASAPIAppointmentDetails apIAppointmentDetails = new AeronaServiceOASApi.OASAPIAppointmentDetails();
        apIAppointmentDetails.practiceId = 9876L;
        apIAppointmentDetails.userId = 34567L;
        apIAppointmentDetails.appointmentTypeId = 1864L;
        apIAppointmentDetails.appointmentStatusId = 7;
        apIAppointmentDetails.appointmentTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        apIAppointmentDetails.emergency = false;
        apIAppointmentDetails.appointmentNotes = 'Patient is nervous.';
        apIAppointmentDetails.duration = 45;
        apIAppointmentDetails.appointmentId = 123456789L;
        apIAppointmentDetails.patientId = 426709L;
        System.assert(apIAppointmentDetails.hashCode()!=null);
        System.assert(apIAppointmentDetails.equals(apIAppointmentDetails));
    }

    @IsTest
    static void testOASUpdateAppointmentRequest() {
        AeronaServiceOASApi.OASUpdateAppointmentRequest updateAppointmentRequest = new AeronaServiceOASApi.OASUpdateAppointmentRequest();
        updateAppointmentRequest.userId = 34567L;
        updateAppointmentRequest.appointmentStatusId = 7;
        updateAppointmentRequest.appointmentTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        updateAppointmentRequest.emergency = false;
        updateAppointmentRequest.appointmentNotes = 'Patient is nervous.';
        System.assert(updateAppointmentRequest.hashCode()!=null);
        System.assert(updateAppointmentRequest.equals(updateAppointmentRequest));
    }

    @IsTest
    static void testOASDuplicatePatient() {
        AeronaServiceOASApi.OASDuplicatePatient duplicatePatient = new AeronaServiceOASApi.OASDuplicatePatient();
        duplicatePatient.patientId = 426709L;
        duplicatePatient.patientFullName = 'Mary Simpson';
        duplicatePatient.patientFullAddress = 'The Cottage, Killylane, Eglinton, Co.Derry';
        duplicatePatient.dob = Date.newInstance(2000, 1, 23);
        System.assert(duplicatePatient.hashCode()!=null);
        System.assert(duplicatePatient.equals(duplicatePatient));
    }

    @IsTest
    static void testOASAPITreatment() {
        AeronaServiceOASApi.OASAPITreatment apITreatment = new AeronaServiceOASApi.OASAPITreatment();
        apITreatment.treatmentId = 4117594L;
        apITreatment.patientId = 426709L;
        apITreatment.appointmentTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        apITreatment.userId = 34567L;
        apITreatment.dateCreated = Datetime.newInstanceGmt(2022, 1, 19, 13, 34, 21);
        apITreatment.dateCompleted = Datetime.newInstanceGmt(2022, 1, 19, 13, 59, 21);
        apITreatment.plan = '1';
        apITreatment.statusId = '2';
        apITreatment.status = 'Planned';
        apITreatment.treatmentPlanDescription = 'Plan 1';
        apITreatment.deleteInd = false;
        apITreatment.saleItemText = 'Filling';
        apITreatment.saleItemCode = '';
        apITreatment.outstandingInsuranceAmount = '0.0';
        apITreatment.amountPaid = '50.0';
        apITreatment.amountRefunded = '0.0';
        apITreatment.quantity = '1';
        apITreatment.unitNetPrice = '50.0';
        apITreatment.totalNetPrice = '50.0';
        apITreatment.totalDiscount = '10.0';
        apITreatment.totalPrice = '40.0';
        apITreatment.vatRate = 20;
        apITreatment.hasNotes = true;
        System.assert(apITreatment.hashCode()!=null);
        System.assert(apITreatment.equals(apITreatment));
    }


    @IsTest
    static void testOASAPINoteAnswer() {
        AeronaServiceOASApi.OASAPINoteAnswer apINoteAnswer = new AeronaServiceOASApi.OASAPINoteAnswer();
        apINoteAnswer.answer = 'Yes';
        apINoteAnswer.question = 'Are you aged 65 years or older?';
        System.assert(apINoteAnswer.hashCode()!=null);
        System.assert(apINoteAnswer.equals(apINoteAnswer));
    }


    @IsTest
    static void testOASAPIConsultationNote() {
        AeronaServiceOASApi.OASAPIConsultationNote apIConsultationNote = new AeronaServiceOASApi.OASAPIConsultationNote();
        apIConsultationNote.id = 284291L;
        apIConsultationNote.appointmentId = 34234L;
        apIConsultationNote.patientId = 426709L;
        apIConsultationNote.userId = 34567L;
        apIConsultationNote.noteTemplateId = 561547L;
        apIConsultationNote.toothId = 8L;
        apIConsultationNote.r_date = Datetime.newInstanceGmt(2022, 1, 19, 13, 34, 21);
        apIConsultationNote.complete = true;
        apIConsultationNote.createdByName = 'Dr. John Smith';
        apIConsultationNote.appointmentTime = Datetime.newInstanceGmt(2000, 1, 23, 4, 56, 7);
        apIConsultationNote.noteTemplateText = 'General';
        apIConsultationNote.treatment = 'Root Canal Treatment';
        System.assert(apIConsultationNote.hashCode()!=null);
        System.assert(apIConsultationNote.equals(apIConsultationNote));
    }


    @IsTest
    static void testOASAPIPatientCarePlan() {
        AeronaServiceOASApi.OASAPIPatientCarePlan apIPatientCarePlan = new AeronaServiceOASApi.OASAPIPatientCarePlan();
        apIPatientCarePlan.patientId = 426909L;
        apIPatientCarePlan.carePlanId = 1254323L;
        apIPatientCarePlan.enabled = true;
        apIPatientCarePlan.planReference = '';
        apIPatientCarePlan.planReferenceDate = Date.newInstance(2000, 1, 23);
        apIPatientCarePlan.startDate = Date.newInstance(2000, 1, 23);
        apIPatientCarePlan.endDate = Date.newInstance(2000, 1, 23);
        apIPatientCarePlan.price = 15;
        apIPatientCarePlan.paymentFrequency = 2;
        apIPatientCarePlan.exemption = 1;
        apIPatientCarePlan.exemptionDetails = 'Patient Under 18.';
        apIPatientCarePlan.evidenceSeen = true;
        apIPatientCarePlan.carePlanDescription = 'Private';
        System.assert(apIPatientCarePlan.hashCode()!=null);
        System.assert(apIPatientCarePlan.equals(apIPatientCarePlan));
    }


    @IsTest
    static void testOASAPINote() {

    }


    @IsTest
    static void testOASStandardResponse() {
        AeronaServiceOASApi.OASStandardResponse standardResponse = new AeronaServiceOASApi.OASStandardResponse();
        standardResponse.status = '';
        standardResponse.result = null;
        standardResponse.errorResult = '';
        standardResponse.errorCode = 0;
        System.assert(standardResponse.hashCode()!=null);
        System.assert(standardResponse.equals(standardResponse));
    }


    @IsTest
    static void testOASErrorResponse() {
        AeronaServiceOASApi.OASErrorResponse errorResponse = new AeronaServiceOASApi.OASErrorResponse();
        errorResponse.status = 404;
        errorResponse.message = 'Not Found';
        System.assert(errorResponse.hashCode()!=null);
        System.assert(errorResponse.equals(errorResponse));
    }


    @IsTest
    static void testOASRetrievePatientResponse() {
        AeronaServiceOASApi.OASRetrievePatientResponse retrievePatientResponse = new AeronaServiceOASApi.OASRetrievePatientResponse();
        retrievePatientResponse.practiceId = 9876L;
        retrievePatientResponse.patientTypeId = 1L;
        retrievePatientResponse.sourceId = 4L;
        retrievePatientResponse.referrerId = 28L;
        retrievePatientResponse.genderId = 2L;
        retrievePatientResponse.titleId = 123456789L;
        retrievePatientResponse.forename = 'Mary';
        retrievePatientResponse.surname = 'Simpson';
        retrievePatientResponse.maidenName = 'Jones';
        retrievePatientResponse.occupation = 'Teacher';
        retrievePatientResponse.dob = Date.newInstance(2000, 1, 23);
        retrievePatientResponse.knownAs = 'Tom';
        retrievePatientResponse.address1 = 'The Cottage';
        retrievePatientResponse.address2 = 'Killylane';
        retrievePatientResponse.address3 = 'Eglinton';
        retrievePatientResponse.address4 = 'Co. Derry';
        retrievePatientResponse.code = 'BT473BD';
        retrievePatientResponse.emailAddress = 'support@aerona.com';
        retrievePatientResponse.mobileNumber = '44780123456';
        retrievePatientResponse.homeNumber = '0044 1234567';
        retrievePatientResponse.workNumber = '00353 1234567';
        retrievePatientResponse.faxNumber = '0044 7654321';
        retrievePatientResponse.allowText = true;
        retrievePatientResponse.allowEmail = true;
        retrievePatientResponse.allowPrint = true;
        retrievePatientResponse.userId = 34567;
        retrievePatientResponse.statusId = 1;
        System.assert(retrievePatientResponse.hashCode()!=null);
        System.assert(retrievePatientResponse.equals(retrievePatientResponse));
    }


    @IsTest
    static void testOASLoginRequest() {
        AeronaServiceOASApi.OASLoginRequest loginRequest = new AeronaServiceOASApi.OASLoginRequest();
        loginRequest.username = 'John Smith';
        loginRequest.password = 'mypassword';
        loginRequest.pin = '1234';
        System.assert(loginRequest.hashCode()!=null);
        System.assert(loginRequest.equals(loginRequest));
    }


    @IsTest
    static void testOASCreatePatientRequest() {
        AeronaServiceOASApi.OASCreatePatientRequest createPatientRequest = new AeronaServiceOASApi.OASCreatePatientRequest();
        createPatientRequest.practiceId = 9876L;
        createPatientRequest.patientTypeId = 1L;
        createPatientRequest.sourceId = 4L;
        createPatientRequest.referrerId = 28L;
        createPatientRequest.genderId = 2L;
        createPatientRequest.titleId = 123456789L;
        createPatientRequest.forename = 'Mary';
        createPatientRequest.surname = 'Simpson';
        createPatientRequest.maidenName = 'Jones';
        createPatientRequest.occupation = 'Teacher';
        createPatientRequest.dob = Date.newInstance(2000, 1, 23);
        createPatientRequest.knownAs = 'Tom';
        createPatientRequest.address1 = 'The Cottage';
        createPatientRequest.address2 = 'Killylane';
        createPatientRequest.address3 = 'Eglinton';
        createPatientRequest.address4 = 'Co. Derry';
        createPatientRequest.code = 'BT473BD';
        createPatientRequest.emailAddress = 'support@aerona.com';
        createPatientRequest.mobileNumber = '44780123456';
        createPatientRequest.homeNumber = '0044 1234567';
        createPatientRequest.workNumber = '00353 1234567';
        createPatientRequest.faxNumber = '0044 7654321';
        createPatientRequest.allowText = true;
        createPatientRequest.allowEmail = true;
        createPatientRequest.allowPrint = true;
        createPatientRequest.userId = 34567;
        createPatientRequest.statusId = 1;
        createPatientRequest.forceCreate = true;

        System.assert(createPatientRequest.hashCode()!=null);
        System.assert(createPatientRequest.equals(createPatientRequest));
    }


    @IsTest
    static void testOASUpdatePatientRequest() {

    }


    @IsTest
    static void testOASCreatePatientResponse() {
        AeronaServiceOASApi.OASCreatePatientResponse createPatientResponse = new AeronaServiceOASApi.OASCreatePatientResponse();
        createPatientResponse.id = 426909L;
        System.assert(createPatientResponse.hashCode()!=null);
        System.assert(createPatientResponse.equals(createPatientResponse));
    }




}