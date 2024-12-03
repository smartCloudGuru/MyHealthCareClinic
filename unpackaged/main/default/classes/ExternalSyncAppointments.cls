/**
 * Created 22.11.2021..
 */

/**
 * Layer above External Service controllers (uses HeyDocService and AeronaService).
 * Utilized by synchronization flows or jobs
 */

public without sharing class ExternalSyncAppointments {

    public static final String HEYDOC = 'HEYDOC';
    public static final String AERONA = 'AERONA';

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('ExtSync-App');

    /**
     * Future method to delete heydoc appointments by their Ids
     *
     * @param ids
     */
    public static void deleteAppointmentsFuture(String ids) {

        //[2024-04-04] commenting this out to never delete/cancel from SF
        /*
        List<ExternalSyncAppointments.IdsByExternalSystemRequest> eIds =
                (List<ExternalSyncAppointments.IdsByExternalSystemRequest>)
                        JSON.deserialize(ids, List<ExternalSyncAppointments.IdsByExternalSystemRequest>.class);


        Boolean successful = false;
        for (ExternalSyncAppointments.IdsByExternalSystemRequest eid : eIds) {
            if (eid != null && String.isNotBlank(eid.extId)) {
                if (eid.extSystem == HEYDOC) {
                    try {
                        //logger.addLog(LoggingLevel.INFO, null, 'on Delete, removing booking from HeyDoc', null, eid.extId);
                        successful = HeyDocService.deleteBooking(eid.extId);
                        if (!successful) logger.addLog(LoggingLevel.WARN, null, 'failed to remove booking on heydoc', null, eid.extId);
                    }
                    catch (Exception ex) {
                    }
                }
                if (eid.extSystem == AERONA && AeronaService.isIntegrationEnabled()) {
                    try {
                        //logger.addLog(LoggingLevel.INFO, null, 'on Delete, removing booking from Aerona', null, eid.extId);
                        successful = AeronaService.deleteBooking(eid.extId);
                        if (!successful) logger.addLog(LoggingLevel.WARN, null, 'failed to remove booking on heydoc', null, eid.extId);
                    }
                    catch (Exception ex) {
                    }
                }

            }
        }
        logger.persistLogs();
        */
    }

    public static void executeWatchdogCheck() {
        Datetime toDt = Datetime.now().addSeconds(-90);
        Datetime fromDt = Datetime.now().addHours(-48);

        Set<Id> medicalWorkTypeIds = getWorkTypeIdsForMedicalServices();
        Set<Id> dentalWorkTypeIds = getWorkTypeIdsForDentalServices();
        List<ServiceAppointment> stuckApps = [
                SELECT Id, Opportunity_Product__r.Product2.Name
                FROM ServiceAppointment
                WHERE CreatedDate < :toDt
                AND CreatedDate > :fromDt
                AND Status = 'Scheduled'
                AND WorkTypeId IN :medicalWorkTypeIds
                AND Opportunity_Product__c != NULL AND Opportunity_Product__r.Opportunity.StageName = 'Closed Won'
                AND
                (
                        NeedsSyncTo__c != NULL
                        OR (ServiceTerritory.Heydoc_Id__c != NULL AND Heydoc_Appointment_Id__c = NULL)
                )

                ORDER BY LastModifiedDate DESC
                LIMIT 50
        ];

        stuckApps.addAll([
                SELECT Id, Opportunity_Product__r.Product2.Name
                FROM ServiceAppointment
                WHERE CreatedDate < :toDt
                AND CreatedDate > :fromDt
                AND Status = 'Scheduled'
                AND WorkTypeId IN :dentalWorkTypeIds
                AND Opportunity_Product__c != NULL AND Opportunity_Product__r.Opportunity.StageName = 'Closed Won'
                AND
                (
                        NeedsSyncTo__c != NULL
                        OR (ServiceTerritory.Aerona_Id__c != NULL AND Aerona_Id__c = NULL)
                )

                ORDER BY LastModifiedDate DESC
                LIMIT 50
        ]);


        System.debug('::watchdog:apps:stucks:' + stuckApps.size());

        if (stuckApps.size() > 0) process_Future(JSON.serialize(stuckApps));
    }

    @Future(Callout=true)
    public static void syncAppointmentsFuture(String ids) {
        List<ServiceAppointment> apps = new List<ServiceAppointment>();
        Set<String> extIds = (Set<String>) JSON.deserialize(ids, Set<String>.class);
        for (String id : extIds) apps.add(new ServiceAppointment (Id = id));
        syncAppointments(apps);
    }

    @Future(Callout=true)
    public static void syncAppointmentFuture(String id) {
        List<ServiceAppointment> apps = new List<ServiceAppointment>();
        apps.add(new ServiceAppointment (Id = id));
        syncAppointments(apps);
    }

    @InvocableMethod(Category='External Sync' Label='Sync Bookings - by Future' Description='Sync bookings to eternal systems(s)')
    public static void syncAppointments(List<ServiceAppointment> apps) {

        System.debug('Sync Apps Invocable:apps: ' + apps);
        if (apps == null || apps.size() == 0) return;

        if (!System.isFuture() && !System.isQueueable() && !System.isBatch() && !System.isScheduled()) {
            process_Future(JSON.serialize(apps));
        }
        else {
            process(apps);
        }
    }

    @Future(Callout=true)
    public static void process_Future(String apps) {
        List<ServiceAppointment> appointments = (List<ServiceAppointment>) JSON.deserialize(apps, List<ServiceAppointment>.class);
        process(appointments);
    }

    public static Boolean isMedical(ServiceAppointment app, Map<String, String> mapServiceType) {
        return 'Medical'.equalsIgnoreCase(mapServiceType.get(app.WorkTypeId));
    }
    public static Boolean isDental(ServiceAppointment app, Map<String, String> mapServiceType) {
        return 'Dental'.equalsIgnoreCase(mapServiceType.get(app.WorkTypeId));
    }

    public static void process(List<ServiceAppointment> apps) {

        if (apps == null) return;

        Set<String> appIds = new Set<String>();
        Set<String> workTypeIds = new Set<String>();

        for (ServiceAppointment app : apps) {
            //logger.addLog(LoggingLevel.INFO, app.Id, 'processing sync for appointment');
            // add appointment ids to list so we can batch select
            appIds.add(app.Id);
        }

        System.debug(':ExSynApp:appids:' + appIds);

        apps = [
                SELECT
                        Id,
                        AppointmentNumber,
                        NeedsSyncTo__c,
                        SchedStartTime,
                        SchedEndTime,
                        AccountId,
                        Status,
                        CancellationReason,
                        Journey_Status__c,
                        WorkTypeId,
                        Resource_Names__c,
                        ServiceTerritoryId,
                        Heydoc_Appointment_Id__c,
                        Aerona_Id__c,
                        Account.Id,
                        Account.HeyDoc_Id__c,
                        Account.Aerona_Id__c,
                        Comments,
                        Treatment__r.StageName,
                        ServiceTerritory.Heydoc_Id__c,
                        ServiceTerritory.Aerona_Id__c,
                        Sync_Fingerprint__c,
                        Video_URL__c,
                        (
                                SELECT Id,
                                        ServiceResourceId,
                                        ServiceResource.Heydoc_Id__c
                                FROM
                                        ServiceResources
                                LIMIT 1
                        )
                FROM ServiceAppointment
                WHERE Id IN :appIds
        ];

        System.debug(':ExSynApp:apps.size:' + apps.size());

        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        String extId = null;
        for (ServiceAppointment app : apps) {

            if (app.WorkTypeId != null && app.Treatment__r?.StageName == 'Closed Won') {
                System.debug('::ExSynApp:added for processing:' + JSON.serialize(app));
                workTypeIds.add(app.WorkTypeId);
                appointments.add(app);
                extId = app.ServiceTerritory?.Heydoc_Id__c;
                if (extId == null) extId = app.ServiceTerritory?.Aerona_Id__c;
            }
            else {
                System.debug(LoggingLevel.WARN, '::ExSynApp:skipped processing appId:' + app.Id
                        + ', wtid:' + app.WorkTypeId
                        + ', oppStage:' + app.Treatment__r?.StageName
                );
            }
        }

        System.debug(':ExSynApp:appointments.size:' + appointments.size());

        Map<String, String> map_wtid_serviceType = new Map<String, String>();

        if (!appointments.isEmpty()) {
            //get all work types from mappings, so we know where to sync these appointment to
            List<WorkTypeGroupMember> wtgms = [SELECT Id, WorkTypeId, WorkTypeGroup.Service_Type__c FROM WorkTypeGroupMember WHERE WorkTypeId IN :workTypeIds];

            for (WorkTypeGroupMember wtgm : wtgms) {
                map_wtid_serviceType.put(wtgm.WorkTypeId, wtgm.WorkTypeGroup.Service_Type__c);
            }

            for (ServiceAppointment app : appointments) {
                app.NeedsSyncTo__c = 'EXT';
            }
        }
        else {
            return;
        }

        // get needed external Ids for workTypes
        // we need to retrieve appointment type id from WTG
        List<WorkTypeGroupMember> wtgms = [SELECT WorkTypeId, WorkTypeGroup.Heydoc_Id__c, WorkTypeGroup.Aerona_Id__c FROM WorkTypeGroupMember WHERE WorkTypeId IN :workTypeIds];

        System.debug('wtgms: ' + wtgms);

        Map<String, String> map_WorkTypeId_HeydocId = new Map<String, String>();
        Map<String, String> map_WorkTypeId_AeronaId = new Map<String, String>();
        for (WorkTypeGroupMember wtgm : wtgms) {
            map_WorkTypeId_HeydocId.put(wtgm.WorkTypeId, wtgm.WorkTypeGroup?.Heydoc_Id__c);
            map_WorkTypeId_AeronaId.put(wtgm.WorkTypeId, wtgm.WorkTypeGroup?.Aerona_Id__c);
        }
        System.debug('map_WorkTypeId_ExtIds: H:' + map_WorkTypeId_HeydocId + ' A:' + map_WorkTypeId_AeronaId);

        String log_detail = '_';

        Boolean isMedical;
        Boolean isDental;

        Map<Id, Account> accountToResetSembleID = new Map<Id, Account>();

        for (ServiceAppointment appointment : appointments) {

            isMedical = isMedical(appointment, map_wtid_serviceType);
            isDental = isDental(appointment, map_wtid_serviceType);

            //do not sync appointment if it's still on default account
            if (appointment.AccountId == OnlineStoreSettingsManager.getDefaultAccount()) continue;

            //FOR MEDICAL APPS
            if (isMedical) {
                log_detail = 'M';

                //logger.addLog(LoggingLevel.INFO, appointment.Id, 'syncing appointment to external MEDICAL system');

                if (appointment.ServiceTerritory?.Heydoc_Id__c != null) {
                    try {
                        log_detail += '2';
                        //process booking Status 'Canceled' - call delete booking in this case
                        if (appointment.Status == 'Canceled') {
                            //logger.addLog(LoggingLevel.INFO, appointment.Id, 'on Canceled, removing booking from HD');
                            Boolean successful = false;

                            successful = HeyDocService.deleteBooking(appointment.Heydoc_Appointment_Id__c);

                            if (successful) appointment.NeedsSyncTo__c = null;
                            else logger.addLog(LoggingLevel.WARN, appointment.Id, 'failed to remove booking on ext');
                            continue;
                        }

                        log_detail += '3';

                        //validations
                        String heyDocAppointmentTypeId = map_WorkTypeId_HeydocId.get(appointment.WorkTypeId);

                        if (String.isEmpty(heyDocAppointmentTypeId)) {
                            appointment.NeedsSyncTo__c = null;
                            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without SembleId on WTG for WorkType ' + appointment.WorkTypeId);
                            continue;
                        }

                        log_detail += '4';

                        if (appointment.Account.HeyDoc_Id__c == null) {
                            log_detail += '5';
                            logger.addLog(LoggingLevel.WARN, appointment.Id, 'no HeyDoc_Id on account, will attempt to sync ' + appointment.AccountId);
                            //we must first sync the patient!
                            List<Account> accounts = new List<Account>();
                            accounts.add(appointment.Account);
                            accounts = ExternalSyncPatients.syncPatient(accounts);
                            if (accounts != null && accounts.size() > 0 && accounts[0].HeyDoc_Id__c != null) {
                                log_detail += '6';
                                //logger.addLog(LoggingLevel.INFO, appointment.Id, 'using newly synced Patient ' + appointment.AccountId, null, 'hdid:' + accounts[0].HeyDoc_Id__c);
                                appointment.Account.HeyDoc_Id__c = accounts[0].HeyDoc_Id__c;
                            }
                            else {
                                log_detail += '7';
                                logger.addLog(LoggingLevel.WARN, appointment.Id, 'can not sync Patient ' + appointment.AccountId + ' for the appointment!');
                                continue;
                            }
                        }

                        if (!validateSyncCanBeDone_Heydoc(appointment)) {
                            log_detail += '8';
                            appointment.NeedsSyncTo__c = null;
                            continue;
                        }

                        HeyDocService.BookingDataInput full_bookingDataInput = new HeyDocService.BookingDataInput();
                        full_bookingDataInput.patient = appointment.Account.HeyDoc_Id__c;
                        full_bookingDataInput.start = appointment.SchedStartTime;
                        full_bookingDataInput.end_jsonsafe = appointment.SchedEndTime;
                        full_bookingDataInput.doctor = appointment.ServiceResources[0].ServiceResource.Heydoc_Id__c;
                        full_bookingDataInput.bookingType = heyDocAppointmentTypeId;
                        full_bookingDataInput.location = appointment.ServiceTerritory?.Heydoc_Id__c;
                        full_bookingDataInput.comments = appointment.Comments;

                        HeyDocService.Booking resp = null;


                        log_detail += '9';
                        // if CREATE
                        if (String.isBlank(appointment.Heydoc_Appointment_Id__c)) {
                            log_detail += '0';
                            try {
                                resp = HeyDocService.createBooking(full_bookingDataInput);
                            }
                            catch (MHCException ex) {
                                if (ex != null && ex.getMessage().contains('INVALID_PATIENT_SEMBLE_ID') && (appointment.AccountId != null)) {
                                    accountToResetSembleID.put(appointment.AccountId, new Account(Id = appointment.AccountId, HeyDoc_Id__c = null));
                                    resp = null;
                                }
                            }

                            log_detail += 'a';
                        }
                        else {
                            // IF UPDATE
                            //05-2024 removing updates to Semble
                            //   log_detail += 'b';
                            //   HeyDocService.BookingDataInput partial_bookingDataInput = new HeyDocService.BookingDataInput();
                            //   partial_bookingDataInput.start = appointment.SchedStartTime;
                            //   partial_bookingDataInput.end_jsonsafe = appointment.SchedEndTime;
                            //   resp = HeyDocService.updateBooking(appointment.Heydoc_Appointment_Id__c, partial_bookingDataInput);
                            //   log_detail += 'c';
                            resp = new HeyDocService.Booking();
                            resp.id = appointment.Heydoc_Appointment_Id__c;
                            resp.videoUrl = appointment.Video_URL__c;
                        }

                        if (resp != null && resp.id != null) {
                            log_detail += 'd';
                            appointment.Heydoc_Appointment_Id__c = resp.id;
                            appointment.Video_URL__c = resp.videoUrl;
                            appointment.NeedsSyncTo__c = null;
                        }
                        else {
                            log_detail += 'e';
                            //System.debug(LoggingLevel.ERROR, 'unable to create/update appointment on Heydoc:ServiceAppointment.ID=' + appointment.Id + ', no externalId returned');
                            String details = 'null resp';
                            if (resp != null) details = JSON.serialize(resp);
                            logAndSetSync(LoggingLevel.ERROR, appointment, 'unable to create/update appointment on Heydoc, no externalId returned', null, log_detail + ' RESP: ' + details, null);
                        }

                    }
                    catch (Exception e) {
                        logAndSetSync(LoggingLevel.ERROR, appointment, 'unable to create/update appointment on Heydoc, error:' + e.getMessage(), e.getStackTraceString(), log_detail, null);
                    }
                }
                else {
                    logAndSetSync(LoggingLevel.WARN, appointment, 'unable to sync appointment - no ServiceTerritory heydoc ID found', null, log_detail, null);
                }
            }


            //FOR DENTAL APPS
            if (isDental && AeronaService.isIntegrationEnabled()) {
                log_detail = 'D';

                //logger.addLog(LoggingLevel.INFO, appointment.Id, 'syncing appointment to external DENTAL system');

                if (appointment.ServiceTerritory?.Aerona_Id__c != null) {
                    try {
                        log_detail += '2';
                        // delete/cancel from SF only if the cancellationReason is "Requested by Patient" - so it can be canceled by mobile app

                        //process booking Status 'Canceled' - call delete booking in this case
                        if (appointment.Status == 'Canceled' && appointment.CancellationReason == 'Requested by Patient') {
                            logger.addLog(LoggingLevel.INFO, appointment.Id, 'on Canceled, removing booking from Aerona');
                            Boolean successful = false;

                            successful = AeronaService.deleteBooking(appointment.Aerona_Id__c);

                            //if (successful == true)
                            appointment.NeedsSyncTo__c = null;
                            //else logger.addLog(LoggingLevel.WARN, appointment.Id, 'failed to remove booking on Aerona, returned successful: ' + successful);
                            continue;
                        }

                        log_detail += '3';

                        //validations
                        String aeronaAppointmentTypeId = map_WorkTypeId_AeronaId.get(appointment.WorkTypeId);

                        if (String.isEmpty(aeronaAppointmentTypeId)) {
                            appointment.NeedsSyncTo__c = null;
                            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without AeronaId on WTG for WorkType ' + appointment.WorkTypeId);
                            continue;
                        }

                        log_detail += '4';

                        if (appointment.Account.Aerona_Id__c == null) {
                            log_detail += '5';
                            logger.addLog(LoggingLevel.WARN, appointment.Id, 'no Aerona_Id on account, will attempt to sync ' + appointment.AccountId);
                            //we must first sync the patient!
                            List<Account> accounts = new List<Account>();
                            accounts.add(appointment.Account);
                            accounts = ExternalSyncPatients.syncPatient(accounts);
                            if (accounts != null && accounts.size() > 0 && accounts[0].Aerona_Id__c != null) {
                                log_detail += '6';
                                //logger.addLog(LoggingLevel.INFO, appointment.Id, 'using newly synced Patient ' + appointment.AccountId, null, 'Aerona_Id__c:' + accounts[0].Aerona_Id__c);
                                appointment.Account.Aerona_Id__c = accounts[0].Aerona_Id__c;
                            }
                            else {
                                log_detail += '7';
                                logger.addLog(LoggingLevel.WARN, appointment.Id, 'can not sync Patient ' + appointment.AccountId + ' for the appointment!');
                                continue;
                            }
                        }

                        if (!validateSyncCanBeDone_Aerona(appointment)) {
                            log_detail += '8';
                            appointment.NeedsSyncTo__c = null;
                            continue;
                        }


                        log_detail += '9';
                        Boolean operationSuccessful = false;

                        // if CREATE
                        if (String.isBlank(appointment.Aerona_Id__c)) {
                            log_detail += 'A0';

                            // FILL create request
                            AeronaServiceOASApi.OASCreateAppointmentRequest createRequest = new AeronaServiceOASApi.OASCreateAppointmentRequest();
                            createRequest.appointmentStatusId = 10;
                            createRequest.patientId = Long.valueOf(appointment.Account.Aerona_Id__c);
                            createRequest.appointmentTime = appointment.SchedStartTime;
                            createRequest.duration = ((appointment.SchedEndTime.getTime() - appointment.SchedStartTime.getTime()) / 60000).intValue();
                            createRequest.appointmentTypeId = Long.valueOf(aeronaAppointmentTypeId);
                            createRequest.appointmentNotes = appointment.Comments;
                            createRequest.practiceId = Long.valueOf(appointment.ServiceTerritory?.Aerona_Id__c);
                            // clinicians have different IDs per clinic
                            ServiceTerritoryMember stm = getServiceTerritoryMember(appointment.ServiceTerritoryId, appointment.ServiceResources[0]?.ServiceResourceId);
                            if (stm != null) createRequest.userId = Long.valueOf(stm.Aerona_Clinician_Id__c);

                            Long resp = AeronaService.createAppointment(createRequest);
                            if (resp != null && resp >= 0) {
                                log_detail += 'a';
                                operationSuccessful = true;
                                appointment.Aerona_Id__c = '' + resp;
                                appointment.Sync_Fingerprint__c = AeronaService.calcAeronaFingerprint(appointment);
                            }
                            log_detail += 'b';
                        }
                        else {
                            // IF UPDATE
                            //05-2024 removing updates to aerona, not needed
                            /*
                            log_detail += 'c';

                            String newFingerprint = AeronaService.calcAeronaFingerprint(appointment);
                            if (appointment.Sync_Fingerprint__c == newFingerprint) {
                                // if no fingerprint change detected
                                log_detail += 'I';
                                appointment.NeedsSyncTo__c = null;
                                continue;
                            }

                            AeronaServiceOASApi.OASUpdateAppointmentRequest updateRequest = new AeronaServiceOASApi.OASUpdateAppointmentRequest();
                            updateRequest.appointmentStatusId = mapAeronaStatusFromSFStatus(appointment.Status);
                            updateRequest.appointmentTime = appointment.SchedStartTime;
                            // clinicians have different IDs per clinic
                            ServiceTerritoryMember stm = getServiceTerritoryMember (appointment.ServiceTerritoryId, appointment.ServiceResources[0]?.ServiceResourceId);
                            if (stm != null) updateRequest.userId = Long.valueOf(stm.Aerona_Clinician_Id__c);
                            //todo when available over api updateRequest.duration = ((appointment.SchedEndTime.getTime() - appointment.SchedStartTime.getTime()) / 60000).intValue();

                            operationSuccessful = AeronaService.updateAppointment(appointment.Aerona_Id__c, updateRequest);
                            */
                            operationSuccessful = true;
                            log_detail += 'd';
                        }

                        if (operationSuccessful != null && operationSuccessful == true) {
                            appointment.NeedsSyncTo__c = null;
                            appointment.Sync_Fingerprint__c = AeronaService.calcAeronaFingerprint(appointment);
                        }
                        else {
                            log_detail += 'e';
                            System.debug(LoggingLevel.ERROR, 'failed to create/update appointment on Aerona');
                            String details = 'null resp';
                            logAndSetSync(LoggingLevel.ERROR, appointment, 'failed to create/update appointment on Aerona', null, log_detail, null);
                        }

                    }
                    catch (AeronaServiceOAS.ApiException e) {
                        logAndSetSync(LoggingLevel.ERROR, appointment, 'unable to create/update appointment on Aerona, error:' + e.getMessage(), e.getStackTraceString(), log_detail + ' ' + e.getBody(), null);
                    }
                    catch (Exception e) {
                        logAndSetSync(LoggingLevel.ERROR, appointment, 'unable to create/update appointment on Aerona, error:' + e.getMessage(), e.getStackTraceString(), log_detail + ' ' + e.getMessage(), null);
                    }
                }
                else {
                    logAndSetSync(LoggingLevel.WARN, appointment, 'unable to sync appointment - no ServiceTerritory aerona ID found', null, log_detail, null);
                }
            }
        }


        logger.persistLogs();

        System.debug('::log_detail:' + log_detail);

        update appointments;

        Database.update (accountToResetSembleID.values(), false);
    }

    public static ServiceTerritoryMember getServiceTerritoryMember(Id serviceTerritoryId, Id serviceResourceId) {
        if (serviceTerritoryId == null || serviceResourceId == null) return null;
        List<ServiceTerritoryMember> stms = [SELECT Id, ServiceTerritoryMember.Aerona_Clinician_Id__c FROM ServiceTerritoryMember WHERE ServiceTerritoryId = :serviceTerritoryId AND ServiceResourceId = :serviceResourceId];
        if (stms.size() > 0) return stms[0];
        return null;
    }

    @TestVisible
    private static Boolean checkIsDifferentThanLastSync(HeyDocService.BookingDataInput full_bookingDataInput,
            HeyDocService.BookingDataInput partial_bookingDataInput,
            HeyDocService.BookingDataInput old) {

        Boolean is_different_than_last_sync = false;

        // we are checking for differences only in start & end dates, so that we do not overwrite other information
        if (full_bookingDataInput.start != old.start) {
            partial_bookingDataInput.start = full_bookingDataInput.start;
            is_different_than_last_sync = true;
        }

        if (full_bookingDataInput.end_jsonsafe != old.end_jsonsafe) {
            partial_bookingDataInput.end_jsonsafe = full_bookingDataInput.end_jsonsafe;
            is_different_than_last_sync = true;
        }


        return is_different_than_last_sync;
    }


    @TestVisible
    private static Boolean validateSyncCanBeDone_Heydoc(ServiceAppointment appointment) {


        if (appointment == null) return false;
        if (appointment.AccountId == null) return false;
        if (appointment.ServiceResources == null || appointment.ServiceResources.size() < 1) {
            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without ServiceResource on ServiceAppointment');
            return false;
        }

        String heyDocLocationId = appointment.ServiceTerritory?.Heydoc_Id__c;
        if (heyDocLocationId == null) {
            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without HeydocId on ServiceTerritory ' + appointment.ServiceTerritory?.Id);
            return false;
        }

        String heyDocDoctorId = appointment.ServiceResources[0].ServiceResource.Heydoc_Id__c;
        if (heyDocDoctorId == null) {
            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without HeydocId on ServiceResource ' + appointment.ServiceResources[0]?.ServiceResource?.Id);
            return false;
        }

        return true;

    }

    @TestVisible
    private static Boolean validateSyncCanBeDone_Aerona(ServiceAppointment appointment) {


        if (appointment == null) return false;
        if (appointment.AccountId == null) return false;
        if (appointment.ServiceResources == null || appointment.ServiceResources.size() < 1) {
            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without ServiceResource on ServiceAppointment');
            return false;
        }

        String extLocationId = appointment.ServiceTerritory?.Aerona_Id__c;
        if (extLocationId == null) {
            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without Aerona_Id__c on ServiceTerritory ' + appointment.ServiceTerritory?.Id);
            return false;
        }

        ServiceTerritoryMember stm = getServiceTerritoryMember(appointment.ServiceTerritoryId, appointment.ServiceResources[0]?.ServiceResourceId);
        String extDoctorId = stm?.Aerona_Clinician_Id__c;
        if (extDoctorId == null) {
            logger.addLog(LoggingLevel.WARN, appointment.Id, 'unable to sync without Aerona_Id__c for ServiceResource ' + appointment.ServiceResources[0]?.ServiceResourceId);
            return false;
        }

        return true;

    }

    @TestVisible
    // utility func to manipulate multipicklist as string
    private static String removeItemFromMultiPicklist(String picklist, String item) {
        if (item == null || picklist == null) {
            return picklist;
        }
        picklist = picklist.replaceAll(item + ';', '');
        picklist = picklist.replaceAll(item, '').trim();
        if (picklist.endsWith(';')) picklist = picklist.substringBeforeLast(';');
        if (String.isBlank(picklist)) {
            picklist = null;
        }
        return picklist;
    }

    public static Set<Id> getWorkTypeIdsForMedicalServices() {
        List<WorkTypeGroupMember> wtgms = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroup.Heydoc_Id__c != NULL];

        Set<Id> ret = new Set<Id>();
        for (WorkTypeGroupMember workTypeGroupMember : wtgms) {
            ret.add(workTypeGroupMember.WorkTypeId);
        }

        return ret;
    }

    public static Set<Id> getWorkTypeIdsForDentalServices() {

        List<WorkTypeGroupMember> wtgms = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroup.Aerona_Id__c != NULL];

        Set<Id> ret = new Set<Id>();
        for (WorkTypeGroupMember workTypeGroupMember : wtgms) {
            ret.add(workTypeGroupMember.WorkTypeId);
        }

        return ret;
    }

    public class IdsByExternalSystemRequest {

        public String extSystem;
        public String extId;

        public IdsByExternalSystemRequest() {
        }

        public IdsByExternalSystemRequest(String extSystem, String extId) {
            this.extSystem = extSystem;
            this.extId = extId;
        }

    }

    public static Integer mapAeronaStatusFromSFStatus(String status) {


        switch on status {
            when 'Scheduled' {
                return 10;
            }
            when 'Arrived' {
                return 3;
            }
            when 'Did Not Arrive' {
                return 4;
            }
            when 'Canceled' {
                return 5;
            }
            when 'Completed' {
                return 7;
            }
        }
        return 10;
    }

    @TestVisible
    private static void logAndSetSync(LoggingLevel loggingLvl, ServiceAppointment appointment, String message, String stack, String log_detail, String syncTo) {
        logger.addLog(loggingLvl, appointment.Id, message, stack, log_detail);
        appointment.NeedsSyncTo__c = syncTo;
        if (loggingLvl == LoggingLevel.ERROR || loggingLvl == LoggingLevel.WARN) appointment.Last_Error__c = capTo255(log_detail);
    }

    private static String capTo255(String source) {
        if (source == null || source.length() <= 255) return source;
        else return source.left(255);
    }

}