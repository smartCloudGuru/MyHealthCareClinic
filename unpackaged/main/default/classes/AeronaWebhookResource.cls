/**
 * Created 13.10.2022..
 */

/** Receives Aerona Webhook events
 * Currently supports Patient and Appointment Events */
@RestResource(UrlMapping='/hook/*')
global without sharing class AeronaWebhookResource {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('Aerona-Webhook');

    public static final AeronaIntegrationSettings__mdt INTEGRATIONS_SETTINGS = [
            SELECT Enabled__c
            FROM AeronaIntegrationSettings__mdt
            LIMIT 1
    ];

    public static Boolean FORCE_ENABLED = false;

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String body;
        try {
            body = req?.requestBody?.toString();

            if (!(INTEGRATIONS_SETTINGS.Enabled__c || FORCE_ENABLED)) {
                logger.addLog(LoggingLevel.WARN, null, 'Aerona event with Aerona not enabled', null, body);
            }
            else {
                System.debug(LoggingLevel.INFO, '::aerona:wh:req:body: ' + body);
                Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped (body);

                if (reqMap == null || reqMap.keySet().size() == 0) {
                    logger.addLog(LoggingLevel.WARN, null, 'unprocessable Aerona event: ' + body, null, 'no body'); res.statusCode = 400;
                }
                else {
                    if (reqMap?.get('recordType') == 'pt') {
                        processPatientEvent(reqMap);
                    }
                    else if (reqMap?.get('recordType') == 'app') {
                        processAppointmentEvent(reqMap);
                        recordExternalBooking(reqMap);
                    }
                    else if (reqMap?.get('recordType') == 'tr') {
//                        logger.addLog(LoggingLevel.INFO, null, 'Aerona event - treatment', null, body);
                        AeronaTreatmentPlansCtrl.onTreatment(reqMap);
                    }
                    else {
                        logger.addLog(LoggingLevel.INFO, null, 'Aerona event - other', null, body);
                    }

                }
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{}');

        }
        catch (System.JSONException ex) {
            logger.addLog(LoggingLevel.WARN, null, 'unprocessable Aerona event: ' + body, null, ex.getMessage()); res.statusCode = 400; res.responseBody = Blob.valueOf('{"error":"' + ex.getMessage() + '"}');
        }
        catch (Exception ex) {
            logger.addLog(LoggingLevel.WARN, null, 'unprocessable Aerona event: ' + body, null, ex.getMessage()); res.statusCode = 500; res.responseBody = Blob.valueOf('{"error":"' + ex.getMessage() + '"}');
        }

        res.headers.put('Content-Type', 'application/json');
        if (res.statusCode == 200) {
            res.responseBody = null;
        }
        else {
            logger.addLog(LoggingLevel.WARN, null, 'Aerona Webhook returning: ' + res.statusCode, null, res.responseBody?.toString());
        }

        logger.persistLogs();
    }


    public static void recordExternalBooking(Map<String, Object> reqMap) {
        //store it also in our list of external bookings
        try {
            AeronaServiceOASApi.OASAPIAppointmentDetails appEvent = (AeronaServiceOASApi.OASAPIAppointmentDetails) JSON.deserialize(JSON.serialize(reqMap), AeronaServiceOASApi.OASAPIAppointmentDetails.class);
            String patientId = String.valueOf(appEvent?.patientId);
            if (patientId != null) {
                List<Account> accs = [SELECT Id FROM Account WHERE Aerona_Id__c = :patientId AND DoNotSync__pc != TRUE];
                External_Booking__c externalBooking = new External_Booking__c();
                externalBooking.External_System__c = 'Aerona';
                externalBooking.Account__c = accs[0].Id;
                externalBooking.Appointment_Time__c = appEvent.appointmentTime;
                externalBooking.External_Appointment_Type__c = String.valueOf(appEvent.appointmentTypeId);
                externalBooking.External_Patient_Id__c = String.valueOf(appEvent.patientId);
                externalBooking.External_Clinic_Id__c = String.valueOf(appEvent.practiceId);
                if (String.isNotEmpty(externalBooking.External_Clinic_Id__c)) {
                    List<ServiceTerritory> sts = [SELECT Id, Site__c FROM ServiceTerritory WHERE Aerona_Id__c = :externalBooking.External_Clinic_Id__c];
                    if (!sts.isEmpty())
                    {
                        externalBooking.Site__c = sts[0].Site__c;
                        externalBooking.Service_Territory__c = sts[0].Id;
                    }
                }
                externalBooking.External_Id__c = String.valueOf(appEvent.appointmentId);
                externalBooking.Status__c = AeronaWebhookResource.mapAppointmentStatusIdToStatus(appEvent.appointmentStatusId);
                if (externalBooking.External_Appointment_Type__c != null) {
                    List<WorkTypeGroup> wtgs = [SELECT Id FROM WorkTypeGroup WHERE Aerona_Id__c = :externalBooking.External_Appointment_Type__c LIMIT 1];
                    if (!wtgs.isEmpty()) externalBooking.Work_Type_Group__c = wtgs[0].Id;

                }
                upsert externalBooking External_Id__c;
            }
        }
        catch (Exception ex) {
        }
    }

    public static String processAppointmentEvent(Map<String, Object> event) {

        AeronaServiceOASApi.OASAPIAppointmentDetails appEvent = (AeronaServiceOASApi.OASAPIAppointmentDetails) JSON.deserialize(JSON.serialize(event), AeronaServiceOASApi.OASAPIAppointmentDetails.class);
        System.debug(LoggingLevel.INFO, '::aerona:wh:appEvent:' + appEvent);

        if (appEvent?.appointmentId == null) throw new MHCException('Required field missing: appointmentId');

        List<AssignedResource> assignedResourcesToInsert = new List<AssignedResource>();
        List<AssignedResource> assignedResourcesToDelete = new List<AssignedResource>();

        String aeronaId = '' + appEvent.appointmentId;
        List<ServiceAppointment> apps = [
                SELECT Id,
                        Status,
                        SchedStartTime,
                        SchedEndTime,
                        Resource_Names__c,
                        ServiceTerritoryId,
                        ServiceTerritory.Aerona_Id__c,
                        WorkTypeId,
                        Sync_Fingerprint__c,
                        Aerona_Id__c, (SELECT Id, ServiceResourceId FROM ServiceResources)
                FROM ServiceAppointment
                WHERE Aerona_Id__c = :aeronaId
        ];

        //gracefully ignore if we do not have the appointment
        if (apps.size() == 0) return null;

        //logger.addLog(LoggingLevel.INFO, null, 'Aerona event', null, JSON.serialize(event));

        ServiceAppointment app = apps[0];

        Boolean doUpdate = false;

        // check if status changed
        if (appEvent.appointmentStatusId != null) {
            app.Status = mapAppointmentStatusIdToStatus(appEvent.appointmentStatusId);
            app.Journey_Status__c = mapAppointmentStatusIdToJourneyStatus(appEvent.appointmentStatusId);
        }

        // check if workType changed
        if (appEvent.appointmentTypeId != null) {
            String newWorkTypeId = null;
            List<WorkTypeGroupMember> wtgms = [SELECT WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroup.Aerona_Id__c = :('' + appEvent.appointmentTypeId) AND WorkTypeGroup.IsActive = TRUE];
            if (wtgms.size() > 0) newWorkTypeId = wtgms[0].WorkTypeId;
            if (newWorkTypeId != null) {
                app.WorkTypeId = newWorkTypeId;
            }
        }

        if (appEvent.appointmentTime != null) {

            Integer originalDuration = ((app.SchedEndTime.getTime() - app.SchedStartTime.getTime()) / 60000).intValue();
            app.SchedStartTime = appEvent.appointmentTime;
            if (appEvent.duration != null) {
                app.SchedEndTime = app.SchedStartTime.addMinutes(appEvent.duration);
            }
            else {
                app.SchedEndTime = app.SchedStartTime.addMinutes(originalDuration);
            }
        }

        if (appEvent.practiceId != null) {
            String newPracticeId = '' + appEvent.practiceId;
            if (newPracticeId != app.ServiceTerritory.Aerona_Id__c) {
                List<ServiceTerritory> sts = [SELECT Id FROM ServiceTerritory WHERE Aerona_Id__c = :newPracticeId];
                if (sts.size() > 0) app.ServiceTerritoryId = sts[0].Id;
            }
        }

        //        //DID ASSIGNED RESOURCE CHANGE?
        //        String oldAeronaUserId = null;
        //        String newAeronaUserId = ('' + appEvent.userId);
        //        if (app.ServiceResources != null && app.ServiceResources.size() > 0) {
        //            oldAeronaUserId = app.ServiceResources[0]?.ServiceResource?.Aerona_Id__c;
        //        }
        //
        //        if (newAeronaUserId != null && oldAeronaUserId != newAeronaUserId) {
        //            List<ServiceResource> srs = [SELECT Id, Name FROM ServiceResource WHERE Aerona_Id__c = :newAeronaUserId];
        //            if (srs.size() > 0) {
        //                assignedResourcesToDelete.addAll(app.ServiceResources);
        //                AssignedResource ar = new AssignedResource();
        //                ar.ServiceResourceId = srs[0].Id;
        //                ar.ServiceAppointmentId = app.Id;
        //                ar.IsRequiredResource = true;
        //                assignedResourcesToInsert.add(ar);
        //                app.Resource_Names__c = srs[0].Name;
        //            }
        //        }

        String newFingerprint = AeronaService.calcAeronaFingerprint(app);

        //Database.delete(assignedResourcesToDelete, false);
        //Database.insert(assignedResourcesToInsert, false);

        if (app.Sync_Fingerprint__c != newFingerprint) {
            doUpdate = true;
        }

        if (doUpdate) {
            app.Sync_Fingerprint__c = newFingerprint;
            Database.update(app);
            return app.Id;
        }

        return null;

    }

    public static String processPatientEvent(Map<String, Object> event) {

        AeronaServiceOASApi.OASRetrievePatientResponse ptEvent = (AeronaServiceOASApi.OASRetrievePatientResponse) JSON.deserialize(JSON.serialize(event), AeronaServiceOASApi.OASRetrievePatientResponse.class);
        System.debug(LoggingLevel.INFO, '::aerona:wh:ptEvent:' + ptEvent);

        if (ptEvent?.patientId == null) throw new MHCException('Required field missing: patientId');

        String aeronaId = '' + ptEvent.patientId;
        List<Account> accs = [
                SELECT Id,
                        CreatedDate,
                        Date_of_Birth__c,
                        Aerona_Id__c,
                        Gender__c,
                        Aerona_Fingerprint__c,
                        FirstName,
                        LastName,
                        PersonEmail,
                        BillingStreet,
                        BillingCity,
                        BillingCountry,
                        BillingPostalCode,
                        BillingState,
                        PersonMobilePhone,
                        Aerona_PatientTypeId__c
                FROM Account
                WHERE Aerona_Id__c = :aeronaId
                OR (PersonEmail = :ptEvent.emailAddress AND Date_of_Birth__c = :ptEvent.dob)
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        Account acc;
        if (accs.size() == 0) {
            //if no such patient is found, try to create patient
            acc = new Account();
            acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
            acc.Patient_Type__c = 'New';
            acc.Aerona_PatientTypeId__c = ptEvent.patientTypeId;
        }
        else {
            // update existing patient
            acc = accs[0];
        }

        Boolean doUpsert = false;
        acc.Aerona_Id__c = aeronaId;

        acc.FirstName = ptEvent.forename;
        acc.LastName = ptEvent.surname;
        acc.Date_of_Birth__c = ptEvent.dob;
        acc.PersonEmail = ptEvent.emailAddress;
        acc.PersonMobilePhone = ptEvent.mobileNumber;
        acc.Phone = ptEvent.homeNumber;
        acc.PersonHomePhone = ptEvent.homeNumber;

        acc.Aerona_Practice_Id__c = '' + ptEvent.practiceId;

        if (ptEvent.address1 != null && ptEvent.address2 != null) {
            if ((ptEvent.address2.indexOf(ptEvent.address1) < 0) && (ptEvent.address1.indexOf(ptEvent.address2) < 0)) {
                acc.BillingStreet = ptEvent.address1 + ' ' + ptEvent.address2;
            }
            else acc.BillingStreet = ptEvent.address1;
        }
        else if (ptEvent.address1 != null) acc.BillingStreet = ptEvent.address1;
        else if (ptEvent.address2 != null) acc.BillingStreet = ptEvent.address2;
        else acc.BillingStreet = null;

        if (String.isNotEmpty(acc.BillingStreet)) {
            acc.BillingStreet = ExternalSyncPatientsToAerona.addressPairToStreet(ptEvent.address1, ptEvent.address2);
        }
        acc.BillingCity = ptEvent.address3;
        acc.BillingState = ptEvent.address4;
        acc.BillingPostalCode = ptEvent.code;

        if (ptEvent.genderId == 1) acc.Gender__c = 'Male';
        else if (ptEvent.genderId == 2) acc.Gender__c = 'Female';

        if (acc.Aerona_PatientTypeId__c != ptEvent.patientTypeId) {
            acc.Aerona_PatientTypeId__c = ptEvent.patientTypeId;
            doUpsert = true;
        }

        String fingerprint = ExternalSyncPatients.calcFingerprint(acc);
        if (acc.Aerona_Fingerprint__c != fingerprint) {
            doUpsert = true;
        }

        if (!doUpsert) // no need to update anything if the fingerprint is the same
        {
            return null;
        }

        acc.Aerona_Fingerprint__c = fingerprint;

        Database.upsert(acc, false);
        //upsert acc;
        return acc.Id;
    }


    public static String mapAppointmentStatusIdToStatus(Integer appointmentStatusId) {
        switch on appointmentStatusId {
            when 1 {
                return 'Scheduled';
            }
            when 2 {
                return 'Scheduled';
            }
            when 3 {
                return 'Arrived';
            }
            when 4 {
                return 'Did Not Arrive';
            }
            when 5 {
                return 'Canceled';
            }
            when 6 {
                return 'Arrived';
            }
            when 7 {
                return 'Completed';
            }
            when 8 {
                return 'Scheduled';
            }
            when 9 {
                return 'Scheduled';
            }
            when 10 {
                return 'Scheduled';
            }
            when 11 {
                return 'Canceled';
            }
            when 12 {
                return 'Canceled';
            }
            when 13 {
                return 'Canceled';
            }
            when 14 {
                return 'Canceled';
            }
            when 16 {
                return 'Did Not Arrive';
            }
        }
        return null;
    }

    public static String mapAppointmentStatusIdToJourneyStatus(Integer appointmentStatusId) {
        String JS_Arrived = 'Arrived';
        String JS_Consultation = 'Consultation';
        String JS_Departed = 'Departed';
        String JS_DNA = 'DNA';

        switch on appointmentStatusId {
            when 1 {
                return null;
            }
            when 2 {
                return null;
            }
            when 3 {
                return JS_Arrived;
            }
            when 4 {
                return JS_DNA;
            }
            when 5 {
                return null;
            }
            when 6 {
                return JS_Arrived;
            }
            when 7 {
                return JS_Departed;
            }
            when 8 {
                return null;
            }
            when 9 {
                return null;
            }
            when 10 {
                return null;
            }
            when 11 {
                return null;
            }
            when 12 {
                return null;
            }
            when 13 {
                return null;
            }
            when 14 {
                return null;
            }
            when 16 {
                return JS_DNA;
            }
        }
        return null;
    }

}