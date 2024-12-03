global without sharing class MembershipContract_ctrl {
    public String imgSource { get; set; }
    public Account objAccount { get; set; }
    public String contractDownloadLink { get; set; }
    public Boolean isError { get; set; }
    public String doTest { get; set; }

    public MembershipContract_ctrl() {
        this.doTest = null;
        try {
            init();
        }
        catch (Exception e) {
            isError = true;
            System.debug(e);
            System.debug(e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Illegal Access!'));
        }
    }

    public MembershipContract_ctrl(String doTest) {
        this.doTest = doTest;
        try {
            init();
        }
        catch (Exception e) {
            isError = true;
            System.debug(e);
            System.debug(e.getStackTraceString());
        }
    }

    public void onUpdate() {
        try {
            Account acc = new Account(Id = objAccount.Id);
            acc.Contract_Sent_Date__c = System.now();
            acc.Member_Status__c = 'Pending';
            if (null != imgSource) {
                acc.Signature__c = '<img src="' + imgSource + '" width="230px" height="71px"></img>';
                acc.Signature_Date__c = System.now();
                objAccount.Signature__c = '<img src="' + imgSource + '" width="230px" height="71px"></img>';
                objAccount.Signature_Date__c = System.now();
                createSignatureInDoc(imgSource, objAccount.Id);
            }
            update acc;
        }
        catch (Exception e) {
            isError = true;
            System.debug(e);
            System.debug(e.getStackTraceString());
            if (doTest == null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Something went wrong, try again if issue persist contact to Receptionist at info@myhealthcareclinic.com'));
        }
    }

    public void createSignatureInDoc(String imgSource, String accountId) {
        List<Document> objDocs = [SELECT Id FROM Document WHERE Name = :accountId.substring(0, 15) OR Name = :accountId];
        Document d;
        if (objDocs.size() > 0) {
            d = new Document(Id = objDocs[0].Id);
        }
        else {
            d = new Document();
        }
        d.Name = accountId.substring(0, 15);
        d.IsPublic = true;
        d.Type = 'png';
        d.Body = EncodingUtil.base64Decode(imgSource.replace('data:image/png;base64,', '')); // body field in document object which holds the file.
        d.FolderId = System.Label.Membership_Signature_Folder_Id;
        upsert d;
    }

    public static Map<Integer, String> getMonthByNumber {
        get {
            return new map<Integer, String>{
                    1 => 'Jan', 2 => 'Feb',
                    3 => 'Mar', 4 => 'Apr',
                    5 => 'May', 6 => 'Jun',
                    7 => 'Jul', 8 => 'Aug',
                    9 => 'Sep', 10 => 'Oct',
                    11 => 'Nov', 12 => 'Dec'
            };
        }
    }

    @TestVisible
    private static HttpRequest getHTTPRequest(String endpoint, String sessionId, String method) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'OAuth ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);

        return req;
    }

    public static Blob generatePdfBlob(String accId) {
        PageReference pdf = new PageReference('/apex/Membershipformpdf?id=' + accId);
        Blob body;
        try {
            // returns the output of the page as a PDF
            body = pdf.getContent();
        }
        catch (VisualforceException e) {
            body = Blob.valueOf('If you did not receive a correctly formatted contract, please contact our receptionist.');
        }

        return body;
    }

    @InvocableMethod(Category='Membership' Label='Generate Contract PDF (Legacy)' Description='Generate Contract PDF (Legacy)')
    public static void invocableGenerate(List<Account> accounts) {
        for (Account account : accounts) {
            generateAndSendContract(account.Id);
        }
    }

    public static void generateAndSendContract(String accountId) {
        String month_Year = 'Nov 2018';

        if (!Test.isRunningTest()) {
            month_Year = getMonthByNumber.get(System.today().month()) + ' ' + System.today().year();
        }

        Account account = [
                SELECT Total_Monthly_Membership_Fees__c, ContactId__c, Name, (SELECT Total_Monthly_Membership_Fee__c, PersonEmail, Payment_Frequency__c, Membership_Level__c, Membership_Type__c, LastName, FirstName FROM Member_Group__r)Patient_Type__c , Quantity__c, Billing_Address__c, List_Of_Members_Covered_By_The_Contract__c, Membership_Start_Date__c,
                PersonEmail, Membership_Change_Dates__c, Signature__c, Signature_Date__c, Total_Monthly_Membership_Fee__c, Home_Clinic__c , Membership_Type__c,
                Membership_Level__c, Payment_Frequency__c, ( SELECT Id, ContentDocumentId FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1)
                FROM Account
                WHERE Id = :accountId
        ];


        String fileName = 'MHC Membership Contract ' + month_Year;
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVer.PathOnClient = fileName + '.pdf'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = fileName; // Display name of the files
        conVer.VersionData = generatePdfBlob(accountId);
        conVer.IsMajorVersion = true;

        System.debug('::inserting content version for ' + fileName);
        insert conVer;
        System.debug('::inserted content version...');

        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id].ContentDocumentId;

        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = accountId; // you can use objectId,GroupId etc
        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDe.Visibility = 'AllUsers';//'InternalUsers';
        insert cDe;
        List<Messaging.SingleEmailMessage> messagingList = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :System.Label.Membership_from_Email_Address];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (owea.size() > 0) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        list<String> toAddresses = new list <string>{account.PersonEmail};//'usman.sfdc@gmail.com','pintub.sfdc@gmail.com'};
        list<String> ccAddresses = new list<String>();
        if (System.Label.GoCardless_CC_Email_Address != 'NA') {
            ccAddresses.addAll(System.Label.GoCardless_CC_Email_Address.split(','));
        }

        List<String> memberEmailAddress = new List<String>();
        for (Account a : account.Member_Group__r) {
            if (String.isNotEmpty(a.PersonEmail)) {
                memberEmailAddress.add(a.PersonEmail);
            }
        }
        ccAddresses.addAll(memberEmailAddress);
        System.debug('>>>>>>>>>>>>>>..' + ccAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setToAddresses(toAddresses);
        mail.setSubject(String.format(System.Label.GoCardless_Email_Subject, new list<String>{account.Name}));
        mail.setHtmlBody(String.format(System.Label.GoCardless_Email_Body, new list<String>{account.Name}));
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

    public void sendAndUploadContract() {

        // [2023-02-22] creating pdf no longer works, below might need to be done manually with a button
        try {
            generateAndSendContract(objAccount.Id);
        }
        catch (Exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            //isError = true;
            //if (doTest == null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Something went wrong, try again if issue persist contact to Receptionist at info@myhealthcareclinic.com'));
        }
    }


    public void init() {
        String accId;
        if (doTest != null) accId = doTest;
        else accId = ApexPages.currentPage().getParameters().get('token');
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
    }

    public pageReference onSend() {
        try {
            pageReference pr = new pageReference('/' + objAccount.Id);
            pr.setRedirect(true);
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :System.Label.Membership_from_Email_Address];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (owea.size() > 0) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setTargetObjectId(objAccount.ContactId__c);
            mail.setTemplateId(System.Label.Send_Membership_Email_Template_Id);
            mail.setWhatId(objAccount.Id);
            mail.setBccSender(false);
            mail.setReplyTo(System.Label.Membership_Contract_Reply_To_EmailAddress);
            if (System.Label.Membership_Contract_ToAddresses_EmailAddress != null && System.Label.Membership_Contract_ToAddresses_EmailAddress != '') {
                mail.setToAddresses(System.Label.Membership_Contract_ToAddresses_EmailAddress.split(','));
            }
            //mail.setSenderDisplayName(System.Label.Membership_Contract_Email_Display_Name);
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            Account ac2Update = new Account(id = objAccount.Id);
            ac2Update.Contract_Sent_Date__c = System.now();
            ac2Update.Member_Status__c = 'Pending';
            update ac2Update;
            return null;
        }
        catch (Exception e) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public void updateStatusToPending() {
        Account ac2Update = new Account(id = objAccount.Id);
        ac2Update.Contract_Sent_Date__c = System.Now();
        ac2Update.Member_Status__c = 'Pending';
        update ac2Update;
    }
    public List<String> getRelatedMembersEmails() {
        List<String> memberEmailAddress = new List<String>();
        for (Account a : objAccount.Member_Group__r) {
            if (String.IsNotEmpty(a.PersonEmail)) {
                memberEmailAddress.add(a.PersonEmail);
            }
        }
        return memberEmailAddress;
    }
    public PageReference sendMailMethod() {
        PageReference pr = new PageReference('/' + objAccount.Id);
        pr.setRedirect(true);
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :System.Label.Membership_from_Email_Address];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (owea.size() > 0) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        mail.setTargetObjectId(System.Label.Target_Object_Id);
        list<String> setToAddresses = new list<String>();
        mail.setToAddresses(System.Label.InPerson_Email_Address.split(','));
        mail.setTemplateId(System.Label.Inperson_Email_Template_Id);
        mail.setWhatId(objAccount.Id);
        mail.setBccSender(false);
        //mail.setSenderDisplayName(System.Label.Membership_Contract_Email_Display_Name);
        mail.setSaveAsActivity(false);
        Messaging.Email[] emails = new Messaging.Email[]{mail};
        Messaging.sendEmail(emails);
        return null;
    }
}