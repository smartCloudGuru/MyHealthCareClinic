/**
 * Created by Matija on 8.2.2024..
 */

public without sharing class ExternalSyncDocuments {

    @Future(Callout=true)
    public static void scheduleSyncDocuments() {
        syncDocuments();
    }

    public static void syncDocuments() {

        //get unsynced documents
        List<External_Document_Sync__c> edsSemble = [
                SELECT
                        Id,
                        CreatedDate,
                        ContentVersionId__c,
                        Uploaded__c,
                        External_System__c,
                        External_URL__c,
                        Name,
                        Opportunity__c,
                        Opportunity__r.Account.HeyDoc_Id__c
                FROM External_Document_Sync__c
                WHERE Uploaded__c = FALSE
                AND Opportunity__r.IsWon = TRUE
                AND External_System__c = 'HEYDOC'
                AND Opportunity__r.Account.HeyDoc_Id__c != NULL
        ];

        if (edsSemble.isEmpty()) return;

        // Create a set to hold ContentVersionIDs
        Set<Id> contentIds = new Set<Id>();
        for (External_Document_Sync__c eds : edsSemble) {
            contentIds.add(eds.ContentVersionId__c);
        }

        // Query content versions using ids in contentIds set, along with their ContentDocument properties
        List<ContentVersion> contentVersionList = [
                SELECT
                        Id,
                        VersionData,
                        ContentDocumentId,
                        ContentDocument.Title,
                        ContentDocument.FileType,
                        ContentDocument.ContentSize
                FROM ContentVersion
                WHERE Id IN :contentIds
        ];

        // Create a map that links ContentDocumentId entries to entries in contentVersionList
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : contentVersionList) {
            contentVersionMap.put(cv.Id, cv);
        }

        for (External_Document_Sync__c externalDocumentSync : edsSemble) {
            String contentVersionId = externalDocumentSync.ContentVersionId__c;

            ContentVersion contentVersion = contentVersionMap.get(contentVersionId);
            String patientId = externalDocumentSync?.Opportunity__r?.Account?.HeyDoc_Id__c;
            String title = contentVersion?.ContentDocument?.Title;
            String docType = mapToContentType(contentVersion?.ContentDocument?.FileType);

            System.debug('::syncDocuments:' + patientId + ' ' + title + ' ' + docType);
            if (String.isNotBlank(patientId) && String.isNotBlank(title) && String.isNotBlank(docType)) {

                //check if we don't already have upload url, then create one
                if (String.isBlank(externalDocumentSync.External_URL__c)) {
                    HeyDocService.PatientDocument ret = HeyDocService.createPatientDocument(patientId, title, docType);
                    System.debug('::syncDocuments:ret:' + ret);

                    if (ret != null && ret.uploadUrl != null) {
                        externalDocumentSync.External_URL__c = ret.uploadUrl;
                    }
                }

                //if we now have one, send to AWS bucket
                if (String.isNotBlank(externalDocumentSync.External_URL__c)) {
                    Boolean success = AWSBucketController.putFileInS3FromContentDocument(contentVersion, externalDocumentSync.External_URL__c);
                    System.debug('::syncDocuments:success:' + success);
                    if (success) externalDocumentSync.Uploaded__c = true;
                }
            }
        }

        update edsSemble;
    }

    public static String mapToContentType(String fileType) {
        if (String.isBlank(fileType) || (fileType == 'PDF')) return 'application/pdf';
        return 'application/pdf';
    }

}