/**
 * Created 2021-12-13
 *
 * 2022-05-30 modified to sync only Journal statues into SF
 */

global class ExternalSyncJobRetrieveAppointments implements Database.AllowsCallouts {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('ExtSync-J-RetApp');


    @Future(Callout=true)
    public static void scheduleGetAppointments() {
        getAppointments();
    }

    @InvocableMethod(Category='Appointment' Label='External Sync - retrieve recently updated Appointments' Description='Retrieve recently updated Appointments' Callout=true)
    public static void getAppointments() {

        //        logger.addLog(LoggingLevel.INFO, null, 'Starting getAppointments()');

        try {
            //HEYDOC
            HeyDocService.Pagination pagination = new HeyDocService.Pagination();
            pagination.page = 0;
            pagination.pageSize = 200;

            HeyDocService.DateRange dateRange = new HeyDocService.DateRange();
            dateRange.start = Datetime.now().addHours(-24 * 1);
            dateRange.end_jsonsafe = Datetime.now().addMonths(24);

            HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
            queryOptions.includeDeleted = true;
            queryOptions.updatedAt = new HeyDocService.DateRange();
            queryOptions.updatedAt.start = Datetime.now().addHours(-18);
            queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(3);

            Boolean hasMore = true;
            HeyDocService.BookingData bookingData = null;
            List<HeyDocService.Booking> heyDocBookings = new List<HeyDocService.Booking>();

            while (hasMore) {
                pagination.page++;
                if (pagination.page >= 99) {
                    logger.addLog(LoggingLevel.ERROR, null, 'Too many appointments to sync from HEYDOC!');
                    break;
                }
                hasMore = false;
                bookingData = HeyDocService.queryBookings(dateRange, pagination, queryOptions);

                if (bookingData != null) {
                    heyDocBookings.addAll(bookingData.data);
                    hasMore = (bookingData.pageInfo?.hasMore != null && bookingData.pageInfo?.hasMore);
                }
            }
            //            logger.addLog(LoggingLevel.INFO, null, 'retrieved HD bookings:' + heyDocBookings.size());

            if (heyDocBookings.size() > 0) {

                System.debug('::esjra:heyDocBookings:' + heyDocBookings.size());

                List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
                List<ServiceAppointment> serviceAppointmentsToDelete = new List<ServiceAppointment>();
                List<AssignedResource> assignedResourcesToInsert = new List<AssignedResource>();
                List<AssignedResource> assignedResourcesToDelete = new List<AssignedResource>();

                // get the sets of relevant Idsfrom the bookings receives
                Set<String> heyDocBookingIds = new Set<String>();
                Set<String> heyDocDoctorIds = new Set<String>();
                Set<String> heyDocLocationIds = new Set<String>();

                Map<String, HeyDocService.Booking> map_hdid_HDBook = new Map<String, HeyDocService.Booking>();

                for (HeyDocService.Booking book : heyDocBookings) {
                    map_hdid_HDBook.put(book.id, book);
                    book.start = HeyDocService.adjustTimeZoneForHeydocOnReceive(book.start);
                    book.end_jsonsafe = HeyDocService.adjustTimeZoneForHeydocOnReceive(book.end_jsonsafe);
                    if (book.id != null) heyDocBookingIds.add(book.id);
                    if (book.location?.id != null) heyDocLocationIds.add(book.location?.id);
                    if (book.doctor?.id != null) heyDocDoctorIds.add(book.doctor?.id);
                }

                // get locations with mentioned hd ids
                List<ServiceTerritory> serviceTerritories = [SELECT Id, Heydoc_Id__c FROM ServiceTerritory WHERE Heydoc_Id__c IN :heyDocLocationIds];
                // get mentioned doctors
                List<ServiceResource> serviceResources = [SELECT Id, Heydoc_Id__c FROM ServiceResource WHERE Heydoc_Id__c IN :heyDocDoctorIds];
                // create maps for these
                Map<String, String> map_location_hdid_sfid = new Map<String, String>();
                Map<String, String> map_doctor_hdid_sfid = new Map<String, String>();
                for (ServiceTerritory st : serviceTerritories) {
                    map_location_hdid_sfid.put(st.Heydoc_Id__c, st.Id);
                }
                for (ServiceResource sr : serviceResources) {
                    map_doctor_hdid_sfid.put(sr.Heydoc_Id__c, sr.Id);
                }

                //get appointments with these Ids, if they exist
                List<ServiceAppointment> serviceAppointments = [
                        SELECT
                                Id,
                                Status,
                                Heydoc_Appointment_Id__c,
                                SchedStartTime,
                                SchedEndTime,
                                ServiceTerritoryId,
                                Journey_Status__c,
                                Latest_Haydoc_Sync__c, (SELECT Id, ServiceResourceId FROM ServiceResources)
                        FROM ServiceAppointment
                        WHERE Heydoc_Appointment_Id__c IN :heyDocBookingIds
                ];

                // put them into a map
                Map<String, ServiceAppointment> map_appointments_hdid_ServiceAppointment = new Map<String, ServiceAppointment>();
                for (ServiceAppointment sa : serviceAppointments) {
                    map_appointments_hdid_ServiceAppointment.put(sa.Heydoc_Appointment_Id__c, sa);
                }

                //upsert Local external records with service appointments
                List<External_Booking__c> externalRecords = new List<External_Booking__c>();

                List<String> patientIds = new List<String>();
                for (HeyDocService.Booking book : heyDocBookings) {
                    if (book?.patientId != null) patientIds.add(book?.patientId);
                }
                Map<String, Account> accounts = new Map<String, Account>();
                List<Account> accountsList = [SELECT Id, HeyDoc_Id__c FROM Account WHERE HeyDoc_Id__c IN :patientIds AND DoNotSync__pc != TRUE];
                for (Account account : accountsList) {
                    accounts.put(account.HeyDoc_Id__c, account);
                }

                Map<String, ServiceTerritory> allSts = new Map<String, ServiceTerritory>();

                List<ServiceTerritory> stList = [SELECT Id, Heydoc_Id__c, Site__c FROM ServiceTerritory WHERE Heydoc_Id__c != NULL];
                for (ServiceTerritory st : stList) {
                    allSts.put(st.Heydoc_Id__c, st);
                }

                Map<String, WorkTypeGroup> allWTGS = new Map<String, WorkTypeGroup>();
                List<WorkTypeGroup> wtgList = [SELECT Id, Heydoc_Id__c FROM WorkTypeGroup WHERE Heydoc_Id__c != NULL];
                for (WorkTypeGroup wtg : wtgList) {
                    allWTGS.put(wtg.Heydoc_Id__c, wtg);
                }


                for (HeyDocService.Booking book : heyDocBookings) {
                    if (book != null) {
                        External_Booking__c eb = toExternalBooking(book, accounts, allSts, allWTGS);
                        if (eb != null) externalRecords.add(eb);
                    }
                }

                // now for each HD appointment, check if we need to insert, update or ignore the appointment (ignore when we do not have the patient or location or doctor id)
                Boolean needsUpdate = false;
                for (HeyDocService.Booking book : heyDocBookings) {

                    // to MODIFY SA
                    ServiceAppointment sa = map_appointments_hdid_ServiceAppointment.get(book.id);

                    if (sa != null) {

                        needsUpdate = false;

                        // IF BOOKING CANCELED
                        if (book.deleted) {
                            if (sa.Status != 'Canceled') {
                                System.debug(sa.Id + ' : deleted appointment needs to be canceled on SF');
                                sa.Status = 'Canceled';
                                needsUpdate = true;
                            }
                        }

                        // DID JOURNEY CHANGE?
                        String journeyStatus = getJourneyStatus(book);
                        if (sa.Journey_Status__c != journeyStatus) {
                            System.debug(sa.Id + ' : Appointment Journey status needs update');
                            sa.Journey_Status__c = journeyStatus;
                            if (sa.Journey_Status__c == 'Departed') sa.Status = 'Completed';
                            else if (sa.Journey_Status__c == 'Consultation') sa.Status = 'Arrived';
                            else if (sa.Journey_Status__c == 'Arrived') sa.Status = 'Arrived';
                            else if (sa.Journey_Status__c == 'DNA') sa.Status = 'Did Not Arrive';
                            needsUpdate = true;
                        }

                        // DID TIMES CHANGE?
                        if ((Math.abs(sa.SchedStartTime.getTime() - book.start.getTime()) > 1000 * 30) || (Math.abs(sa.SchedEndTime.getTime() - book.end_jsonsafe.getTime()) > 1000 * 30)
                        ) {
                            System.debug(sa.Id + ' : Appointment Dates need update');
                            sa.SchedStartTime = book.start;
                            sa.SchedEndTime = book.end_jsonsafe;
                            needsUpdate = true;
                        }

                        //DID LOCATION CHANGE?
                        if (sa.ServiceTerritoryId != map_location_hdid_sfid.get(book.location?.id)) {
                            System.debug(sa.Id + ' : Location needs update');
                            sa.ServiceTerritoryId = map_location_hdid_sfid.get(book.location?.id);
                            needsUpdate = true;
                        }

                        //DID ASSIGNED RESOURCE CHANGE?
                        if (sa.ServiceResources == null || sa.ServiceResources.size() == 0 || sa.ServiceResources[0]?.ServiceResourceId != map_doctor_hdid_sfid.get(book.doctor?.id)) {
                            if (book.doctor?.id != null && map_doctor_hdid_sfid.get(book.doctor?.id) != null) {
                                System.debug(sa.Id + ' : Assigned resource needs update to ' + book.doctor?.id);
                                AssignedResource ar = new AssignedResource();
                                ar.ServiceResourceId = map_doctor_hdid_sfid.get(book.doctor?.id);
                                ar.ServiceAppointmentId = sa.Id;
                                ar.IsRequiredResource = true;
                                assignedResourcesToInsert.add(ar);
                            }
                            if (sa.ServiceResources != null || sa.ServiceResources.size() > 0) {
                                assignedResourcesToDelete.addAll(sa.ServiceResources);
                            }
                        }

                        // if anything changed, setup an update
                        if (needsUpdate) {
                            //potential modify existing appointment
                            System.debug(sa.Id + ' : Appointment will be updated');
                            serviceAppointmentsToUpdate.add(sa);
                        }
                    }

                }

                if (serviceAppointmentsToDelete.size() > 0) {
                    deleteServiceAppointments(serviceAppointmentsToDelete);
                }

                if (serviceAppointmentsToUpdate.size() > 0) {
                    updateServiceAppointments(serviceAppointmentsToUpdate);
                }

                try {
                    if (assignedResourcesToInsert.size() > 0) {
                        insertAssignedResources(assignedResourcesToInsert);
                    }
                }
                catch (Exception ex) {
                }

                if (externalRecords.size() > 0) {
                    try {
                        System.debug('upserting ' + externalRecords.size() + ' Semble external records');
                        Database.upsert(externalRecords, External_Booking__c.External_Id__c, false);
                    }
                    catch (Exception ex) {
                    }
                }

            } // end if any hd bookings
        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to do getAppointments() ' + e.getMessage() + e.getTypeName(), e.getStackTraceString(), null);
        }

        logger.persistLogs();

    }


    public static External_Booking__c toExternalBooking(HeyDocService.Booking sembleBooking, Map<String, Account> accounts, Map<String, ServiceTerritory> allSts, Map<String, WorkTypeGroup> allWTGS) {
        if (sembleBooking == null) return null;
        //store it also in our list of external bookings
        try {
            String patientId = String.valueOf(sembleBooking?.patientId);
            if (patientId != null) {
                Account acc = accounts.get(patientId);
                if (acc == null) return null;
                External_Booking__c externalBooking = new External_Booking__c();
                externalBooking.External_System__c = 'Semble';
                externalBooking.Account__c = acc.Id;
                externalBooking.Appointment_Time__c = sembleBooking.start;
                externalBooking.External_Appointment_Type__c = String.valueOf(sembleBooking.appointment?.id);
                externalBooking.External_Patient_Id__c = String.valueOf(sembleBooking.patientId);
                externalBooking.External_Clinic_Id__c = String.valueOf(sembleBooking.location.id);
                if (String.isNotEmpty(externalBooking.External_Clinic_Id__c)) {
                    ServiceTerritory st = allSts.get(externalBooking.External_Clinic_Id__c);
                    if (st != null) {
                        externalBooking.Site__c = st.Site__c;
                        externalBooking.Service_Territory__c = st.Id;
                    }
                }
                externalBooking.External_Id__c = String.valueOf(sembleBooking.id);
                externalBooking.Status__c = getJourneyStatus(sembleBooking);
                if (externalBooking.Status__c == 'Departed') externalBooking.Status__c = 'Completed';
                else if (String.isEmpty(externalBooking.Status__c)) externalBooking.Status__c = 'Scheduled';
                if (sembleBooking.deleted == true) externalBooking.Status__c = 'Canceled';

                if (externalBooking.External_Appointment_Type__c != null) {
                    WorkTypeGroup wtg = allWTGS.get(externalBooking.External_Appointment_Type__c);
                    if (wtg != null) externalBooking.Work_Type_Group__c = wtg.Id;
                }
                return externalBooking;
            }
        }
        catch (Exception ex) {
        }
        return null;
    }

    @TestVisible
    private static void updateServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        System.debug('::esjra:serviceAppointmentsToUpdate:' + serviceAppointments.size());
        List<Database.SaveResult> res = Database.update(serviceAppointments, false);
        for (Database.SaveResult r : res) {
            if (!r.isSuccess()) {
                logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to update serviceAppointment', null, JSON.serialize(r.getErrors()));
            }
        }
    }

    @TestVisible
    private static void deleteServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        System.debug('::esjra:serviceAppointmentsToUpdate:' + serviceAppointments.size());
        List<Database.DeleteResult> res = Database.delete(serviceAppointments, false);
        for (Database.DeleteResult r : res) {
            if (!r.isSuccess()) {
                logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to delete serviceAppointment', null, JSON.serialize(r.getErrors()));
            }
        }
    }

    @TestVisible
    private static void insertAssignedResources(List<AssignedResource> resources) {
        System.debug('::esjra:assignedResourcesToInsert:' + resources.size());
        List<Database.SaveResult> res = Database.insert(resources, false);
        for (Database.SaveResult r : res) {
            if (!r.isSuccess()) {
                if (r.getErrors() != null && r.getErrors().size() > 0 && r.getErrors()[0].statusCode != StatusCode.DUPLICATE_VALUE) {
                    logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to insert AssignedResource', null, JSON.serialize(r.getErrors()));
                }
            }
        }
    }
    @TestVisible
    private static void deleteAssignedResources(List<AssignedResource> resources) {
        System.debug('::esjra:assignedResourcesToDelete:' + resources.size());
        List<Database.DeleteResult> res = Database.delete(resources, false);
        for (Database.DeleteResult r : res) {
            if (!r.isSuccess()) {
                logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to delete AssignedResource', null, JSON.serialize(r.getErrors()));
            }
        }
    }

    @TestVisible
    private static String dateformat(Datetime dt) {
        if (dt == null) return '';
        return dt.format('yyyy-MM-dd HH:mm', 'Europe/London');
    }


    /* FULL VERSION BACKUP, disabled, for now syn only statuses for known appointments
    @InvocableMethod(Category='Appointment' Label='External Sync - retrieve recently updated Appointments' Description='Retrieve recently updated Appointments' Callout=true)
    public static void getAppointments() {

        //        logger.addLog(LoggingLevel.INFO, null, 'Starting getAppointments()');

        try {
            //HEYDOC
            HeyDocService.Pagination pagination = new HeyDocService.Pagination();
            pagination.page = 0;
            pagination.pageSize = 200;

            HeyDocService.DateRange dateRange = new HeyDocService.DateRange();
            dateRange.start = Datetime.now().addHours(-24);
            dateRange.end_jsonsafe = Datetime.now().addMonths(6);

            HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
            queryOptions.includeDeleted = true;
            queryOptions.updatedAt = new HeyDocService.DateRange();
            queryOptions.updatedAt.start = Datetime.now().addHours(-8);
            queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);

            Boolean hasMore = true;
            HeyDocService.BookingData bookingData = null;
            List<HeyDocService.Booking> heyDocBookings = new List<HeyDocService.Booking>();

            while (hasMore) {
                pagination.page++;
                if (pagination.page >= 99) {
                    logger.addLog(LoggingLevel.ERROR, null, 'Too many appointments to sync from HEYDOC!');
                    break;
                }
                hasMore = false;
                bookingData = HeyDocService.queryBookings(dateRange, pagination, queryOptions);

                if (bookingData != null) {
                    heyDocBookings.addAll(bookingData.data);
                    hasMore = (bookingData.pageInfo?.hasMore != null && bookingData.pageInfo?.hasMore);
                }
            }
            //            logger.addLog(LoggingLevel.INFO, null, 'retrieved HD bookings:' + heyDocBookings.size());

            if (heyDocBookings.size() > 0) {

                List<ServiceAppointment> serviceAppointmentsToInsert = new List<ServiceAppointment>();
                List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
                List<ServiceAppointment> serviceAppointmentsToDelete = new List<ServiceAppointment>();
                List<AssignedResource> assignedResourcesToInsert = new List<AssignedResource>();
                List<AssignedResource> assignedResourcesToUpdate = new List<AssignedResource>();
                List<AssignedResource> assignedResourcesToDelete = new List<AssignedResource>();

                // get the list of booking Ids and patient Ids from the bookings
                Set<String> heyDocBookingIds = new Set<String>();
                Set<String> heyDocPatientIds = new Set<String>();
                Set<String> heyDocDoctorIds = new Set<String>();
                Set<String> heyDocLocationIds = new Set<String>();

                Map<String, HeyDocService.Booking> map_hdid_HDBook = new Map<String, HeyDocService.Booking>();

                for (HeyDocService.Booking book : heyDocBookings) {
                    map_hdid_HDBook.put(book.id, book);
                    if (book.id != null) heyDocBookingIds.add(book.id);
                    if (book.patientId != null) heyDocPatientIds.add(book.patientId);
                    if (book.location?.id != null) heyDocLocationIds.add(book.location?.id);
                    if (book.doctor?.id != null) heyDocDoctorIds.add(book.doctor?.id);
                }

                //get appointments with these Ids, if they exist
                List<ServiceAppointment> serviceAppointments = [
                        SELECT
                                Id,
                                Heydoc_Appointment_Id__c,
                                Journey_Status__c,
                                Latest_Haydoc_Sync__c, (SELECT Id, ServiceResourceId FROM ServiceResources)
                        FROM ServiceAppointment
                        WHERE Heydoc_Appointment_Id__c IN :heyDocBookingIds
                ];

                // put them into a map
                Map<String, ServiceAppointment> map_appointments_hdid_ServiceAppointment = new Map<String, ServiceAppointment>();
                for (ServiceAppointment sa : serviceAppointments) {
                    map_appointments_hdid_ServiceAppointment.put(sa.Heydoc_Appointment_Id__c, sa);
                }

                // get patients from the response
                List<Account> patients = [SELECT Id, HeyDoc_Id__c FROM Account WHERE HeyDoc_Id__c IN :heyDocPatientIds];
                // get locations with hd ids
                List<ServiceTerritory> serviceTerritories = [SELECT Id, Heydoc_Id__c FROM ServiceTerritory WHERE Heydoc_Id__c IN :heyDocLocationIds];
                // get doctors
                List<ServiceResource> serviceResources = [SELECT Id, Heydoc_Id__c FROM ServiceResource WHERE Heydoc_Id__c IN :heyDocDoctorIds];
                // get workTypeGroups
                List<WorkTypeGroup> workTypeGroups = [SELECT Id, Heydoc_Id__c FROM WorkTypeGroup WHERE Heydoc_Id__c != NULL];

                // create maps for these
                Map<String, String> map_patient_hdid_sfid = new Map<String, String>();
                Map<String, String> map_location_hdid_sfid = new Map<String, String>();
                Map<String, String> map_doctor_hdid_sfid = new Map<String, String>();
                Map<String, String> map_workTypeGroups_hdid_sfid = new Map<String, String>();
                for (Account acc : patients) {
                    map_patient_hdid_sfid.put(acc.HeyDoc_Id__c, acc.Id);
                }
                for (ServiceTerritory st : serviceTerritories) {
                    map_location_hdid_sfid.put(st.Heydoc_Id__c, st.Id);
                }
                for (ServiceResource sr : serviceResources) {
                    map_doctor_hdid_sfid.put(sr.Heydoc_Id__c, sr.Id);
                }
                for (WorkTypeGroup wtg : workTypeGroups) {
                    map_workTypeGroups_hdid_sfid.put(wtg.Heydoc_Id__c, wtg.Id);
                }

                // get workTypeGroupMembers
                List<WorkTypeGroupMember> allWorkTypeGroupMembers = [SELECT Id, WorkTypeId, WorkTypeGroupId FROM WorkTypeGroupMember WHERE WorkTypeGroupId IN :map_workTypeGroups_hdid_sfid.values()];
                System.debug('using sas map: ' + map_appointments_hdid_ServiceAppointment);
                System.debug('using patient map: ' + map_patient_hdid_sfid);
                System.debug('using sts map: ' + map_location_hdid_sfid);
                System.debug('using srs map: ' + map_doctor_hdid_sfid);
                System.debug('using workTypeGroups map: ' + map_workTypeGroups_hdid_sfid);
                System.debug('using workTypeGroupMembers list: ' + allWorkTypeGroupMembers);

                // now for each HD appointment, check if we need to insert, update or ignore the appointment (ignore when we do not have the patient or location or doctor id)
                for (HeyDocService.Booking book : heyDocBookings) {

                    // if we do not know this patient , we can not save the record
                    if (map_patient_hdid_sfid.get(book.patientId) == null) {
                        logger.addLog(LoggingLevel.WARN, null, 'unable to save booking from HeyDoc, no such patient known. Booking Id:' + book.id + ', HD patient Id:' + book.patientId);
                        continue;
                    }

                    // if we do not know this doctor , we can not save the record
                    //                    if (map_doctor_hdid_sfid.get(book.doctor?.id) == null) {
                    //                        logger.addLog(LoggingLevel.WARN, null, 'unable to save booking from HeyDoc, no such doctor known. Booking Id:' + book.id);
                    //                        continue;
                    //                    }


                    // if we do not know this location, we can not save the record
                    if (map_location_hdid_sfid.get(book.location?.id) == null) {
                        logger.addLog(LoggingLevel.WARN, null, 'unable to save booking from HeyDoc, no such location known. Booking Id:' + book.id);
                        continue;
                    }

                    String journeyStatus = getJourneyStatus(book);

                    System.debug('journeyStatus:' + journeyStatus);

                    // calculate the booking input cache so that we prevent loops
                    HeyDocService.BookingDataInput full_bookingDataInput = new HeyDocService.BookingDataInput();
                    full_bookingDataInput.patient = book.patientId;
                    full_bookingDataInput.start = book.start;
                    full_bookingDataInput.end_jsonsafe = book.end_jsonsafe;
                    full_bookingDataInput.doctor = book.doctor?.id;
                    full_bookingDataInput.bookingType = book.appointment?.id;
                    full_bookingDataInput.location = book.location?.id;
                    full_bookingDataInput.comments = book.comments;
                    String latest_Haydoc_Sync = JSON.serialize(full_bookingDataInput);

                    String wtg_id = map_workTypeGroups_hdid_sfid.get(book.appointment?.id);
                    String workTypeId = null;
                    if (wtg_id != null) {
                        for (WorkTypeGroupMember wtgm : allWorkTypeGroupMembers) {
                            if (wtgm.WorkTypeGroupId == wtg_id) {
                                workTypeId = wtgm.WorkTypeId;
                                break;
                            }
                        }
                    }

                    // TO INSERT SA
                    if (map_appointments_hdid_ServiceAppointment.get(book.id) == null) {

                        if (book.deleted) {
                            System.debug('ignoring deleted appointment' + book.Id);
                            continue;
                        }

                        //add this new ServiceAppointment to insert
                        System.debug('need to add an appointment with hdid ' + book.Id);
                        ServiceAppointment sa = new ServiceAppointment();
                        sa.Heydoc_Appointment_Id__c = book.id;
                        sa.ParentRecordId = map_patient_hdid_sfid.get(book.patientId);
                        sa.SchedStartTime = book.start;
                        sa.SchedEndTime = book.end_jsonsafe;
                        sa.Subject = book.appointment.title;

                        sa.Comments = book.comments;
                        sa.ServiceTerritoryId = map_location_hdid_sfid.get(book.location?.id);
                        sa.Latest_Haydoc_Sync__c = latest_Haydoc_Sync;
                        sa.WorkTypeId = workTypeId;
                        sa.Journey_Status__c = journeyStatus;

                        serviceAppointmentsToInsert.add(sa);
                    }
                    else { // to MODIFY SA
                        ServiceAppointment sa = map_appointments_hdid_ServiceAppointment.get(book.id);
                        if (book.deleted) {
                            System.debug('deleted appointment needs to be removed from SF' + book.Id);
                            serviceAppointmentsToDelete.add(sa);
                            continue;
                        }

                        if (
                                (sa.Latest_Haydoc_Sync__c == latest_Haydoc_Sync)
                                        && (sa.Journey_Status__c == journeyStatus)
                                ) {
                            System.debug('appointment already up-to-date ' + book.Id);
                            continue;
                        }

                        //potential modify existing appointment
                        System.debug('need to update an appointment with hdid ' + book.Id);

                        // sa.ParentRecordId // patient can not be changed
                        sa.SchedStartTime = book.start;
                        sa.SchedEndTime = book.end_jsonsafe;
                        sa.Description = book.appointment.title;
                        sa.Comments = book.comments;
                        sa.ServiceTerritoryId = map_location_hdid_sfid.get(book.location?.id);
                        sa.WorkTypeId = workTypeId;
                        sa.Journey_Status__c = journeyStatus;
                        sa.Latest_Haydoc_Sync__c = latest_Haydoc_Sync;

                        if (sa.ServiceResources != null && sa.ServiceResources.size() > 0 && sa.ServiceResources[0].ServiceResourceId != map_doctor_hdid_sfid.get(book.doctor?.id)) {
                            System.debug('currently have a sresource');
                            AssignedResource ar = new AssignedResource(Id = sa.ServiceResources[0].Id);
                            if (map_doctor_hdid_sfid.get(book.doctor?.id) != null) {
                                System.debug('HD has a doctor');
                                ar.ServiceResourceId = map_doctor_hdid_sfid.get(book.doctor?.id);
                                assignedResourcesToUpdate.add(ar);
                            }
                            else {
                                System.debug('HD has no doctor');
                                assignedResourcesToDelete.add(ar);
                            }
                        }
                        else {
                            if (
                                    (map_doctor_hdid_sfid.get(book.doctor?.id) != null)
                                            && (sa.ServiceResources[0].ServiceResourceId != map_doctor_hdid_sfid.get(book.doctor?.id))) {
                                System.debug('HD has a doctor');
                                AssignedResource ar = new AssignedResource();
                                ar.ServiceResourceId = map_doctor_hdid_sfid.get(book.doctor?.id);
                                ar.ServiceAppointmentId = sa.Id;
                                assignedResourcesToInsert.add(ar);
                            }
                        }

                        serviceAppointmentsToUpdate.add(sa);
                    }

                }

                if (serviceAppointmentsToDelete.size() > 0) {
                    List<Database.DeleteResult> res = Database.delete(serviceAppointmentsToDelete, false);
                    for (Database.DeleteResult r : res) {
                        if (!r.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to delete serviceAppointment', null, JSON.serialize(r.getErrors()));
                        }
                    }
                }
                if (assignedResourcesToDelete.size() > 0) {
                    List<Database.DeleteResult> res = Database.delete(assignedResourcesToDelete, false);
                    for (Database.DeleteResult r : res) {
                        if (!r.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to delete assignedResourcesToDelete', null, JSON.serialize(r.getErrors()));
                        }
                    }
                }
                if (serviceAppointmentsToUpdate.size() > 0) {
                    List<Database.SaveResult> res = Database.update(serviceAppointmentsToUpdate, false);
                    for (Database.SaveResult r : res) {
                        if (!r.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to update serviceAppointment', null, JSON.serialize(r.getErrors()));
                        }
                    }
                }
                if (assignedResourcesToUpdate.size() > 0) {
                    List<Database.SaveResult> res = Database.update(assignedResourcesToUpdate, false);
                    for (Database.SaveResult r : res) {
                        if (!r.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to update assignedResources', null, JSON.serialize(r.getErrors()));
                        }
                    }
                }
                if (serviceAppointmentsToInsert.size() > 0) {
                    List<Database.SaveResult> res = Database.insert(serviceAppointmentsToInsert, false);
                    for (Database.SaveResult r : res) {
                        if (!r.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to insert serviceAppointment', null, JSON.serialize(r.getErrors()));
                        }
                    }

                    for (ServiceAppointment serviceAppointment : serviceAppointmentsToInsert) {
                        if (serviceAppointment.Id != null) {
                            AssignedResource ar = new AssignedResource();
                            ar.ServiceAppointmentId = serviceAppointment.Id;
                            ar.ServiceResourceId = map_doctor_hdid_sfid.get(map_hdid_HDBook.get(serviceAppointment.Heydoc_Appointment_Id__c)?.doctor?.id);
                            if (ar.ServiceResourceId != null) assignedResourcesToInsert.add(ar);
                        }
                    }
                }
                if (assignedResourcesToInsert.size() > 0) {
                    List<Database.SaveResult> res = Database.insert(assignedResourcesToInsert, false);
                    for (Database.SaveResult r : res) {
                        if (!r.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, r.getId(), 'unable to insert assignedResource', null, JSON.serialize(r.getErrors()));
                        }
                    }
                }


            } // end if any hd booking received

        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to do getAppointments() ' + e.getMessage() + e.getTypeName(), e.getStackTraceString(), null);
        }

        logger.persistLogs();

    }
     */

    /**
     * Returns if there is a change in the provided strings, but ignores changes if both are isBlank
     *
     * @param a
     * @param b
     *
     * @return
     */
    public static Boolean isDifferent(String a, String b) {
        if (String.isBlank(a) && String.isBlank(b)) return false;
        return a != b;
    }

    public static String getJourneyStatus(HeyDocService.Booking book) {
        if (book == null) return null;
        if (book.bookingJourney == null) return null;

        if (book.bookingJourney.dna != null) {
            return 'DNA';
        }
        else if (book.bookingJourney.departed != null) {
            return 'Departed';
        }
        else if (book.bookingJourney.consultation != null) {
            return 'Consultation';
        }
        else if (book.bookingJourney.arrived != null) {
            return 'Arrived';
        }

        return null;
    }


}