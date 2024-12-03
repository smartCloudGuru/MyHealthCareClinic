/**
 * Created 10.12.2021..
 */

/**
 * For a given Patient (Account), search SF Appointments that might need to be synced
 */

public without sharing class ExternalSyncAppsForPatient implements Queueable, Database.AllowsCallouts {

    private Set<String> accountIds;

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('ExtSync-App4Pat');

    public ExternalSyncAppsForPatient(List<Account> accounts) {
        this.accountIds = new Set<String>();
        for (Account acc : accounts) {
            this.accountIds.add(acc.Id);
        }
    }

    public ExternalSyncAppsForPatient(Set<String> ids) {
        this.accountIds = ids;
    }

    // dental/aerona-specific logic added 2022-09-08

    public void execute(QueueableContext context) {

        if (this.accountIds == null || this.accountIds.isEmpty())
        {
            //nothing to process
            return;
        }

        try {

            // by medical and dental appointments separately
            Set<Id> medicalWorkTypeIds = ExternalSyncAppointments.getWorkTypeIdsForMedicalServices();
            Set<Id> dentalWorkTypeIds = ExternalSyncAppointments.getWorkTypeIdsForDentalServices();

            List<ServiceAppointment> appointments = [
                    SELECT Id, WorkTypeId, NeedsSyncTo__c, ServiceTerritory.Heydoc_Id__c, ServiceTerritory.Aerona_Id__c,Opportunity_Won__c
                    FROM ServiceAppointment
                    WHERE AccountId IN :accountIds AND Heydoc_Appointment_Id__c = NULL AND WorkTypeId IN : medicalWorkTypeIds
                    AND Opportunity_Won__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 4
            ];

            appointments.addAll ([
                    SELECT Id, WorkTypeId, NeedsSyncTo__c, ServiceTerritory.Heydoc_Id__c, ServiceTerritory.Aerona_Id__c, Opportunity_Won__c
                    FROM ServiceAppointment
                    WHERE AccountId IN :accountIds AND Aerona_Id__c = NULL AND WorkTypeId IN : dentalWorkTypeIds
                    AND Opportunity_Won__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 4
            ]);

            if (!appointments.isEmpty()) {

//                for (ServiceAppointment app : appointments) {
//                    logger.addLog(LoggingLevel.INFO, app.Id, 'processing appointment');
//                    app.NeedsSyncTo__c = ExternalSyncUtility.addItemToMultiPicklist(app.NeedsSyncTo__c, 'EXT');
//                    logger.addLog(LoggingLevel.INFO, app.Id, 'needs sync to EXT (due to Account now synced)');
//                }
//                update appointments;

                //call appointment sync
                ExternalSyncAppointments.syncAppointments(appointments);
            }

        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to process execute: ' + e.getMessage(), e.getStackTraceString(), null);
        }

        logger.persistLogs();

    }



}