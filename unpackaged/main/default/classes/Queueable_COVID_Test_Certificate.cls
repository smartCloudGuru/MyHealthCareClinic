/**
 * @author Zoran Zunko
 *
 * @date 4/13/21
 */
public with sharing class Queueable_COVID_Test_Certificate implements Queueable, Database.AllowsCallouts {
    @TestVisible
    public Set<Id> covidTestIds;

    public void execute(QueueableContext QC) {
        try {

            // FOLLOWING RENAMES OLD DOCUMENTS SO THAT ONLY THE NEW ONES GET SENT
            // get any existing (old) certificates for specified covid tests
            List<ContentDocumentLink> old_cdls = [
                    SELECT ContentDocumentId, ContentDocument.Title
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :covidTestIds AND LinkedEntity.Type = 'COVID_Test__c' AND ContentDocument.Title LIKE '%Certificate'
            ];

            // get those documents
            List <Id> old_cdls_ids = new List<Id>();
            for (ContentDocumentLink cdl : old_cdls) old_cdls_ids.add(cdl.ContentDocumentId);

            List <ContentDocument> old_cdocuments = [
                    SELECT Id, Title, Description
                    FROM ContentDocument
                    WHERE Id IN :old_cdls_ids
            ];

            // rename old cdocs
            for (ContentDocument cd : old_cdocuments) {
                if (cd.Title != null && cd.Title.indexOf('(OLD)') != 0) cd.Title = '(OLD) ' + cd.Title;
            }
            update old_cdocuments;

            //            //debug only
            //            ContentDocument cd = [SELECT Id, Title, Description FROM ContentDocument where ID = '0693H000000oulhQAA'];
            //            cd.Title = 'DBG ' + cd.Title;
            //            cd.Description = JSON.serialize(old_cdls);
            //            update cd;


            Map<Id, COVID_Test__c> covidTests = new Map<Id, COVID_Test__c>([SELECT Id, Test_Type__c, Certificate_Template__c FROM COVID_Test__c WHERE Id IN :covidTestIds]);
            Map<Id, List<ContentVersion>> covidTestContentVersionMap = new Map<Id, List<ContentVersion>>();
            Map<Id, Id> covidTestCertificateCovidTestMap = new Map<Id, Id>();

            List<ContentVersion> allContentVersions = new List<ContentVersion>();
            PageReference reportPage  = null;
            String fileName = null;
            String templatePageName = null;

            List<COVID_Test__c> testsWithoutCertificatesToUpdate = new List<COVID_Test__c>();

            for (Id covidTestId : covidTestIds) {
                Blob testCertificate;
                try {

                    System.debug(LoggingLevel.ERROR, 'execute - : ' + Test.isRunningTest());

                    reportPage = null;
                    fileName = Datetime.now().format('yyyy-MM-dd') + '_';
                    templatePageName = covidTests.get(covidTestId).Certificate_Template__c;

                    if (!String.isEmpty(templatePageName))
                    {
                        reportPage = new PageReference ('/apex/' + templatePageName);
                        fileName += templatePageName;
                    }
                    else
                    {
                        //2022-02-14 added to mark tests without certificates as they have sent certificates
                        testsWithoutCertificatesToUpdate.add(new COVID_Test__c(Id = covidTestId, Test_Certificate_Generated__c= true, Send_Certificate_Email__c=false));
                    }

                    if (reportPage != null) {
                        reportPage.getParameters().put('id', covidTestId);

                        if (Test.isRunningTest()) {
                            testCertificate = Blob.valueOf('Unit.Test');
                        }
                        else {
                            testCertificate = reportPage.getContentAsPDF();
                        }

                        ContentVersion contentVersion = new ContentVersion(Title = fileName, PathOnClient = fileName + '.pdf', VersionData = testCertificate, IsMajorVersion = true);
                        if (!covidTestContentVersionMap.containsKey(covidTestId)) {
                            covidTestContentVersionMap.put(covidTestId, new List<ContentVersion>());
                        }
                        covidTestContentVersionMap.get(covidTestId).add(contentVersion);
                        allContentVersions.add(contentVersion);
                    }

                }
                catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
                }
            }

            insert allContentVersions;
            for (Id covidTestId : covidTestIds) {
                if (covidTestContentVersionMap.containsKey(covidTestId)) {
                    for (ContentVersion contentVersionCert : covidTestContentVersionMap.get(covidTestId)) {
                        covidTestCertificateCovidTestMap.put(contentVersionCert.Id, covidTestId);
                    }
                }
            }
            List<ContentDocument> docs = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE LatestPublishedVersionId = :covidTestCertificateCovidTestMap.keySet()];

            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            Map<Id, COVID_Test__c> covidTestsToUpdate = new Map<Id, COVID_Test__c>();
            for (ContentDocument cDoc : docs) {
                cdlList.add(new ContentDocumentLink(LinkedEntityId = covidTestCertificateCovidTestMap.get(cDoc.LatestPublishedVersionId), ContentDocumentId = cDoc.Id, ShareType = 'V'));
                covidTestsToUpdate.put(covidTestCertificateCovidTestMap.get(cDoc.LatestPublishedVersionId),
                        new COVID_Test__c(
                                Id = covidTestCertificateCovidTestMap.get(cDoc.LatestPublishedVersionId),
                                Test_Certificate_Generated__c = true,
                                Send_Certificate_Email__c = true
                        )
                );
            }
            insert cdlList;
            AnthologyTriggerDispatch.noTriggers = true;
            update covidTestsToUpdate.values();
            update testsWithoutCertificatesToUpdate;

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }


    public static void queueJob(Set<Id> covidTestIds) {
        Queueable_COVID_Test_Certificate nextJob = new Queueable_COVID_Test_Certificate();
        nextJob.covidTestIds = covidTestIds;
        System.enqueueJob(nextJob);
    }
}