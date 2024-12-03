/**
 * Created 8.5.2023.
 *
 * Allows flows to update comments on Patients
 */

global class PatientNotesInvocable implements Database.AllowsCallouts {

    @InvocableMethod(Category='Patient' Label='External Sync - patient warnings/notes' Description='Update Patient comments/notes on external systems' Callout=true)
    public static void addCommentToPatientOnExternal(List<Patient_Warning__c> notes) {

        System.debug('::PatientNotesInvocable:apps: ' + notes);
        if (notes == null || notes.size() == 0) return;

        if (!System.isFuture() && !System.isQueueable() && !System.isBatch() && !System.isScheduled()) {
            process_Future(JSON.serialize(notes));
        }
        else {
            process(notes);
        }
    }

    @Future(Callout=true)
    public static void process_Future(String input) {
        List<Patient_Warning__c> notes = (List<Patient_Warning__c>) JSON.deserialize(input, List<Patient_Warning__c>.class);
        process(notes);
    }

    public static void process(List<Patient_Warning__c> notes)
    {
        Set <Id> notesIds = new Set<Id>();
        for (Patient_Warning__c patientWarning : notes) {
            notesIds.add(patientWarning.Id);
        }

        notes = [SELECT Id, Patient__r.HeyDoc_Id__c, Patient__r.Aerona_Id__c, Note_Warning__c, CreatedDate FROM Patient_Warning__c WHERE Id IN :notesIds];

        //Semble
        for (Patient_Warning__c patientWarning : notes) {
            try
            {
                ExternalSyncPatients.updatePatientCommentOnHeydoc(patientWarning?.Patient__r?.HeyDoc_Id__c, patientWarning?.CreatedDate, patientWarning?.Note_Warning__c);
            }
            catch (Exception ex)
            {
                System.debug(LoggingLevel.ERROR, '::PatientNotesInvocable:err: ' + ex);
            }

        }
    }
}