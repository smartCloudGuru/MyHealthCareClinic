/**
 * Created 22.2.2023..
 */
@RestResource(UrlMapping='/util/mempdf/*')
global without sharing class MemPdfContractResource {
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        //        res.headers.put('Content-Type', 'application/json');

        String contractDownloadLink;
        Account objAccount;

        try {

            MemPdfRequest pdfReq = (MemPdfRequest) JSON.deserialize(RestContext.request.requestBody.toString(), MemPdfRequest.class);

            String accId = pdfReq.accountId;
            objAccount = [
                    SELECT Total_Monthly_Membership_Fees__c, ContactId__c, Name, (SELECT Total_Monthly_Membership_Fee__c, PersonEmail, Payment_Frequency__c, Membership_Level__c, Membership_Type__c, LastName, FirstName FROM Member_Group__r)Patient_Type__c , Quantity__c, Billing_Address__c, List_Of_Members_Covered_By_The_Contract__c, Membership_Start_Date__c,
                    PersonEmail, Membership_Change_Dates__c, Signature__c, Signature_Date__c, Total_Monthly_Membership_Fee__c, Home_Clinic__c , Membership_Type__c,
                    Membership_Level__c, Payment_Frequency__c, ( SELECT Id, ContentDocumentId FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1)
                    FROM Account
                    WHERE Id = :accId
            ];
            if (objAccount != null && objAccount.ContentDocumentLinks.size() > 0) {
                contractDownloadLink = System.Label.My_Domain + '/sfc/servlet.shepherd/version/download/' + [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :objAccount.ContentDocumentLinks.get(0).ContentDocumentId LIMIT 1].Id + '?asPdf=false&operationContext=CHATTER';
                System.debug('************' + contractDownloadLink);
            }

            String month_Year = 'Nov 2018';
            if (!Test.isRunningTest()) {
                month_Year = MembershipContract_ctrl.getMonthByNumber.get(System.today().month()) + ' ' + System.today().year();
            }

            String fileName = 'MHC Membership Contract ' + month_Year;
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
            conVer.PathOnClient = fileName + '.pdf';
            conVer.Title = fileName;
            conVer.VersionData = Blob.valueOf(pdfReq.body);
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
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :System.Label.Membership_from_Email_Address];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (owea.size() > 0) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            List<String> toAddresses = new List<String>{objAccount.PersonEmail};//'usman.sfdc@gmail.com','pintub.sfdc@gmail.com'};
            List<String> ccAddresses = new List<String>();
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
            mail.setSubject(String.format(System.Label.GoCardless_Email_Subject, new List<String>{objAccount.Name}));
            mail.setHtmlBody(String.format(System.Label.GoCardless_Email_Body, new List<String>{objAccount.Name}));
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
            res.responseBody = Blob.valueOf(e.getMessage() + e.getStackTraceString());
        }
    }

    public class MemPdfRequest {
        public String accountId;
        public String body;
    }

}