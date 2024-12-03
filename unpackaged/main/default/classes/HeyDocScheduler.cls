public without sharing class HeyDocScheduler implements System.Schedulable {

    @TestVisible
    private static IntegrationErrorReporter errorReporter = new IntegrationErrorReporter();
    @TestVisible
    private static PatientMatcher patientMatch = new PatientMatcher();
    @TestVisible
    private static SiteMatcher siteMatch = new SiteMatcher();
    @TestVisible
    private static AppointmentTypeMatcher appointmentMatcher = new AppointmentTypeMatcher();

    private static Integer PAGE_SIZE = Integer.valueOf(
        HeyDocService.INTEGRATIONS_SETTINGS.Page_Size__c
    );

    //Schedulable queuer
    public void execute(SchedulableContext sc) {
        //System.enqueueJob(new HeyDocQueueable(1));
    }

    /*
    public class HeyDocQueueable implements System.Queueable, Database.AllowsCallouts {
        private Integer pageNumber;
        private Boolean finished = false;

        public HeyDocQueueable(Integer pageCount) {
            this.pageNumber = pageCount != null ? pageCount : 1;
        }

        //Queueable execute
        public void execute(QueueableContext context) {
            patientMatch.setExternalIdField(Account.HeyDoc_Id__c);
            this.syncWithHeydoc();
        }

        public void syncWithHeydoc() {
            List<HeyDocBooking> bookings = this.getBookings();

            if (bookings.size() != 0) {
                //Savepoint sp = Database.setSavepoint();
                parseBookings(bookings);
                //Database.rollback(sp);

                errorReporter.persistLogs();

                if (!System.Test.isRunningTest()) {
                    System.enqueueJob(this);
                }
            }
        }

        private List<HeyDocBooking> getBookings() {
            List<HeyDocBooking> bookings = HeyDocService.getBookings(this.pageNumber);
            this.pageNumber++;
            return bookings;
        }

        private void parseBookings(List<HeyDocBooking> bookings) {
            for (HeyDocBooking booking : bookings) {
                if (booking?.patient?.email != null) {
                    patientMatch.addEmail(booking.patient.email);
                }
                if (booking.patientId != null) {
                    patientMatch.addExternalId(booking.patientId);
                }
                if (booking?.appointment?.title != null) {
                    appointmentMatcher.addAppointmentType(booking.appointment.title);
                }
                if (booking.location?.name != null) {
                    siteMatch.addSite(booking.location.name);
                }
            }

            Map<String, Account> patientsIdByKey = patientMatch.getPatients();
            Map<String, Id> appointmentByTitle = appointmentMatcher.getAppointmentTypeIds();
            Map<String, Id> sitesByName = siteMatch.getSiteIds();

            List<Account> heyDocPatients = new List<Account>();
            List<Account> newPatients = new List<Account>();
            Set<String> processedIds = new Set<String>();
            List<Proposed_Appointment__c> appointments = new List<Proposed_Appointment__c>();

            for (HeyDocBooking booking : bookings) {
                System.debug('Processing HeyDoc Booking ' + booking.id);
                if (!processedIds.contains(booking.patientId)) {
                    Account patient;
                    Account matchedPatient = patientsIdByKey.containsKey(booking.patientId)
                        ? patientsIdByKey.get(booking.patientId)
                        : patientsIdByKey.get(booking.patient.email);
                    if (matchedPatient != null) {
                        //If we cant match on external, fallback to email, and then create if cant on email
                        // get skinny patient record with external Id only to update for future syncs
                        Account newPatient = booking.getPatient(matchedPatient.Id);

                        if (
                            newPatient.PersonEmail != matchedPatient.PersonEmail ||
                            newPatient.PersonMobilePhone != matchedPatient.PersonMobilePhone ||
                            newPatient.Phone != matchedPatient.Phone ||
                            newPatient.Date_of_Birth__c != matchedPatient.Date_of_Birth__c
                        ) {
                            patient = newPatient;
                        }
                    } else {
                        System.debug('Creating new contact');
                        // get the full record for creation
                        patient = booking.getPatient();
                    }

                    if (patient != null) {
                        if (patient.Id != null) {
                            if (!processedIds.contains(patient.Id)) {
                                heyDocPatients.add(patient);
                                processedIds.add(patient.Id);
                            }
                        } else {
                            newPatients.add(patient);
                        }
                    }

                    processedIds.add(booking.patientId);

                    //If we have multiple contacts with the same email, they need to be created as duplicates
                    // eg children using a parent's email
                    patientsIdByKey.remove(booking.patient.email);
                }

                Proposed_Appointment__c appointment = booking.getAppointment();
                appointment.Appointment_Type__c = appointmentByTitle.get(
                    booking?.appointment?.title?.trim()
                );

                if (booking.location?.name != null) {
                    appointment.Site__c = sitesByName.get(booking.location?.name);
                }

                appointments.add(appointment);
            }

            Database.DMLOptions saveOptions = new Database.DMLOptions();
            saveOptions.DuplicateRuleHeader.AllowSave = true;
            saveOptions.AllowFieldTruncation = true;

            List<Database.SaveResult> createPatientSaveResult = Database.insert(
                newPatients,
                saveOptions
            );

            List<Database.UpsertResult> patientSaveResult = Database.upsert(heyDocPatients, false);
            List<Database.UpsertResult> appointmentSaveResult = Database.upsert(
                appointments,
                Proposed_Appointment__c.HeyDoc_Id__c,
                false
            );

            errorReporter.logDatabaseErrors(
                'HeyDoc Patient Creation',
                createPatientSaveResult,
                newPatients
            );
            errorReporter.logDatabaseErrors(
                'HeyDoc Patient Upsert',
                patientSaveResult,
                heyDocPatients
            );
            errorReporter.logDatabaseErrors(
                'HeyDoc Appointment Upsert',
                appointmentSaveResult,
                appointments
            );
        }
    }
    */
}