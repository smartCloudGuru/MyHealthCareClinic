/**
 * Created 22.2.2023..
 */

public without sharing class MemPdfQueueable implements Queueable {

    Id accId;
    public MemPdfQueueable(Id accId) {
        this.accId = accId;
    }

    public void execute(QueueableContext context) {

        String contractDownloadLink;
        Account objAccount;

        try {

            objAccount = [
                    SELECT Total_Monthly_Membership_Fees__c, ContactId__c, Name, (SELECT Total_Monthly_Membership_Fee__c, PersonEmail, Payment_Frequency__c, Membership_Level__c, Membership_Type__c, LastName, FirstName From Member_Group__r)Patient_Type__c , Quantity__c, Billing_Address__c, List_Of_Members_Covered_By_The_Contract__c, Membership_Start_Date__c,
                    PersonEmail, Membership_Change_Dates__c, Signature__c, Signature_Date__c, Total_Monthly_Membership_Fee__c, Home_Clinic__c , Membership_Type__c,
                    Membership_Level__c, Payment_Frequency__c, ( SELECT Id, ContentDocumentId FROM ContentDocumentLinks order by ContentDocument.CreatedDate DESC limit 1)
                    FROM Account
                    WHERE Id = :accId
            ];
            if (objAccount != null && objAccount.ContentDocumentLinks.size() > 0) {
                contractDownloadLink = System.Label.My_Domain + '/sfc/servlet.shepherd/version/download/' + [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :objAccount.ContentDocumentLinks.get(0).ContentDocumentId limit 1].Id + '?asPdf=false&operationContext=CHATTER';
                System.debug('************' + contractDownloadLink);
            }

            String month_Year = 'Nov 2018';
            if (!Test.isRunningTest()) {
                month_Year = MembershipContract_ctrl.getMonthByNumber.get(System.today().month()) + ' ' + System.today().year();
            }

            PageReference pdf = new PageReference('/apex/Membershipformpdf?id=' + accId);// Page.Membershipformpdf;

            // the contents of the attachment from the pdf
            Blob body;
            try {
                // returns the output of the page as a PDF
                body = pdf.getContent();
            }
            catch (VisualforceException e) {
                body = Blob.valueOf('Is you did not receive a correctly formatted contract, please contact our receptionist.');
            }

            String fileName = 'MHC Membership Contract ' + month_Year;
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
            conVer.PathOnClient = fileName + '.pdf';
            conVer.Title = fileName;
            conVer.VersionData = body;
            conVer.IsMajorVersion = true;

            System.debug('::inserting content version for ' + fileName);
            insert conVer;
            System.debug('::inserted content version...');

            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id].ContentDocumentId;
            contractDownloadLink = System.Label.My_Domain + '/sfc/servlet.shepherd/version/download/' + conVer.Id + '?asPdf=false&operationContext=CHATTER';

            //Create ContentDocumentLink
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = objAccount.Id; // you can use objectId,GroupId etc
            cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
            cDe.Visibility = 'AllUsers';//'InternalUsers';
            insert cDe;
            List<Messaging.SingleEmailMessage> messagingList = new List<Messaging.SingleEmailMessage>();
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress where Address = :System.Label.Membership_from_Email_Address];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (owea.size() > 0) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            list<String> toAddresses = new list <string>{objAccount.PersonEmail};//'usman.sfdc@gmail.com','pintub.sfdc@gmail.com'};
            list<String> ccAddresses = new list<String>();
            if (System.Label.GoCardless_CC_Email_Address != 'NA') {
                ccAddresses.addAll(System.Label.GoCardless_CC_Email_Address.split(','));
            }

            List<String> memberEmailAddress = new List<String>();
            for (Account a : objAccount.Member_Group__r) {
                if (String.isNotEmpty(a.PersonEmail)) {
                    memberEmailAddress.add(a.PersonEmail);
                }
            }

            ccAddresses.addAll(memberEmailAddress);
            System.debug('>>>>>>>>>>>>>>..' + ccAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setToAddresses(toAddresses);
            mail.setSubject(String.format(System.Label.GoCardless_Email_Subject, new list<String>{objAccount.Name}));
            mail.setHtmlBody(String.format(System.Label.GoCardless_Email_Body, new list<String>{objAccount.Name}));
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();

            // Add to attachment file list
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(fileName + '.pdf');
            efa.setBody(conVer.VersionData);
            fileAttachments.add(efa);
            mail.setFileAttachments(fileAttachments);
            messagingList.add(mail);
            if (!messagingList.isEmpty()) {
                Messaging.sendEmail(messagingList);
            }
        }
        catch (Exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
        }
    }
}