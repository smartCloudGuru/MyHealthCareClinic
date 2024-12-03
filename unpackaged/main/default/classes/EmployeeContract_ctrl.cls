global without sharing class EmployeeContract_ctrl {

    public static final String CONTRACT_DOWNLOAD_LINK = System.Label.My_Domain + '/sfc/servlet.shepherd/version/download/{0}?asPdf=false&operationContext=CHATTER';
    public static final String DEFAULT_ERROR = 'Something went wrong, try again if issue persist contact to Receptionist at info@myhealthcareclinic.com';

    public String imgSource{get;set;}
    public Employee__c employee {get;set;}
    public string contractDownloadLink{get;set;}
    public boolean isError{get;set;}
    public String signImage{get;set;}
    public String pContent{get;set;}

    public static Employee_Contract_Setting__mdt employeeContractSetting = Employee_Contract_Setting__mdt.getInstance('default');

    public static map<Integer,String> getMonthByNumber{
        get{
            return new map<Integer,String>{ 
                1 => 'Jan',2 => 'Feb',
                3 => 'Mar', 4 => 'Apr',
                5 => 'May',6 => 'Jun',
                7 => 'Jul', 8 => 'Aug',
                9 => 'Sep',10 => 'Oct',
                11 => 'Nov', 12 => 'Dec'
            };            
        }
    }
    
    public EmployeeContract_ctrl() {
        
        try{

            initHelper();            
        }catch(Exception e){
            
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Illegal Access!'));
        }
    }
            
    public void initHelper() {

        employee = [SELECT Date_of_Commencement_of_Employment__c, 
                    Date_of_Continuous_Employment__c, 
                    Type_of_Contract__c, 
                    If_Fixed_Term_Date_of_Termination__c, 
                    Regular_place_of_work__c,
                    Work_Pattern__c, 
                    Hourly_Pay_Rate__c, 
                    Pay_Terms__c,
                    Ee_Middle_Name__c,
                    Contract_Document__r.CreateText__c, Contract_Document__r.Agreement_With__c,
                    Contract_Document__r.For_and_on_behalf_of__c, Addendum__c,
                    Notice_Period__c,Id, Email_Address_For_Payslip__c, Normal_Hours_Per_Week__c, 
                    Contract_Signature__c, Contract_Signed_Date__c, Signature__c, 
                    First_Name__c, Surname__c, Start_Date__c, Job_Title__c, Department_Site__c, Salary_Pay_Rate__c, 
                    (Select Id, ContentDocumentId From ContentDocumentLinks order by ContentDocument.CreatedDate DESC limit 1) 
                    FROM Employee__c WHERE Id= :ApexPages.currentPage().getParameters().get('token')];
        
        if (employee != null && employee.ContentDocumentLinks.size() > 0) {

            Id contentVersionId = [SELECT Id FROM ContentVersion WHERE ContentDocumentId=:employee.ContentDocumentLinks.get(0).ContentDocumentId limit 1].Id;
            contractDownloadLink = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE ContentVersionId=:contentVersionId]?.ContentDownloadUrl;//String.format(CONTRACT_DOWNLOAD_LINK, new List<String> {[SELECT Id FROM ContentVersion WHERE ContentDocumentId=:employee.ContentDocumentLinks.get(0).ContentDocumentId limit 1].Id}); //System.Label.My_Domain+'/sfc/servlet.shepherd/version/download/'+[SELECT Id FROM ContentVersion WHERE ContentDocumentId=:employee.ContentDocumentLinks.get(0).ContentDocumentId limit 1].Id+'?asPdf=false&operationContext=CHATTER';
            System.debug('Debug:- '+contractDownloadLink);
        }

        //It uses in PDF 
        String id15Char = (ApexPages.currentPage().getParameters().get('token')).substring(0,15);
        List<Document> listOfDoc = [SELECT Id FROM Document WHERE Name =: ApexPages.currentPage().getParameters().get('token') OR Name = :id15Char limit 1]; 
        if(listOfDoc.size() > 0){
            signImage = listOfDoc[0].Id;
        }

        pContent = DynamicPDFHelper.getProcessedContentHelper();
    } 
    
    public void onUpdate(){

        try{

            Employee__c tempEmp = new Employee__c(Id = employee.Id);
            
            if (null != imgSource) {                

                tempEmp.Contract_Signature__c = '<img src="'+imgSource+'" width="230px" height="71px"></img>';
                tempEmp.Contract_Signed_Date__c = system.Now();
                
                employee.Contract_Signature__c = tempEmp.Contract_Signature__c;
                employee.Contract_Signed_Date__c = tempEmp.Contract_Signed_Date__c;
                
                createSignatureInDoc(imgSource, employee.Id);
            }

            update tempEmp;
        } catch(Exception e) {
            
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DEFAULT_ERROR));
        }
    }

    public PageReference onUpdateContractForm(){

        try{

            update employee;
            initHelper();
        } catch(Exception e) {

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DEFAULT_ERROR));
        }
        return null;
    }
    
    public void createSignatureInDoc(String imgSource, String employeeId){

        List<Document> objDocs = [SELECT Id FROM Document WHERE Name=:employeeId.substring(0,15) OR Name=:employeeId];
        
        Document d;        
        if (objDocs.size() > 0) {

            d = new Document(Id = objDocs[0].id);
        } else {
            d = new Document();
        }

        d.name = employeeId.substring(0,15);
        d.IsPublic = true;
        d.type = 'png';
        d.body = EncodingUtil.base64Decode(imgSource.replace('data:image/png;base64,','')); // body field in document object which holds the file.
        d.folderId= employeeContractSetting.Contract_Signature_Folder_Id__c;
        upsert d;    
    }

    public void sendAndUploadContract(){

        try{

            String month_Year = 'Jan 2022'; // default for unit test
            
            if (!Test.IsRunningTest()) {
                month_Year = +' '+ system.today().day() + ' ' + getMonthByNumber.get(system.today().month()) +' '+ system.today().year();
            }

            PageReference pdf = new PageReference('/employeeportal/EmployeeContractPDF?token='+employee.Id);   
            // add parent id to the parameters for standardcontroller pdf.getParameters().put('id',objAccount.Id);        
            // create the new attachment/file
            Blob body;        
            try {            
                // returns the output of the page as a PDF
                body = pdf.getContent();            
                // need to pass unit test -- current bug    
            } catch (VisualforceException e) {

                body = Blob.valueOf('Is you do not receive correctly Formatted contract, Please contact to Receptionist!');
            }

            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
            conVer.PathOnClient = employee.First_Name__c + ' ' + employee.Surname__c +' - Contract '+ month_Year +'.pdf'; // The files name, extension is very important here which will help the file in preview.
            conVer.Title = 'Employee Contract '+month_Year+'.pdf'; // Display name of the files
            conVer.VersionData = body;//EncodingUtil.base64Decode(body); // converting your binary string to Blog
            insert conVer;

            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            
            //Create ContentDocumentLink
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = employee.Id; // you can use objectId,GroupId etc
            cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
            cDe.Visibility = 'AllUsers';//'InternalUsers';
            insert cDe;
            
            /* Creating ContentDistribution record */
            ContentDistribution objContentDistribution = new ContentDistribution(
                Name = conVer.Title,
                ContentVersionId = conVer.Id,
                PreferencesAllowViewInBrowser= true
            );
            insert objContentDistribution;
            
            contractDownloadLink = [SELECT Id, ContentDownloadUrl, PdfDownloadUrl FROM ContentDistribution WHERE Id=:objContentDistribution.Id].ContentDownloadUrl;//System.Label.My_Domain+'/sfc/servlet.shepherd/version/download/'+conVer.Id+'?asPdf=false&operationContext=CHATTER';   

            list<Messaging.SingleEmailMessage> messagingList = new List<Messaging.SingleEmailMessage>();
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: employeeContractSetting.Employee_Contract_From_Email_Address__c]; 
            Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage(); 
            
            if (owea.size() > 0 ) {

                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            } 
            
            list<String> toAddresses = new list <string>{employee.Email_Address_For_Payslip__c};//'usman.sfdc@gmail.com','pintub.sfdc@gmail.com'};
            list<String> ccAddresses = new list<String>(); 
            
            if (String.isNotBlank(employeeContractSetting.Employee_Contract_CC_Email_Addresses__c) && employeeContractSetting.Employee_Contract_CC_Email_Addresses__c !='NA') {
                ccAddresses.addAll(employeeContractSetting.Employee_Contract_CC_Email_Addresses__c.split(','));
            }

            mail.setCcAddresses(ccAddresses);
            mail.setToAddresses(toAddresses); 
            mail.setSubject(String.Format(employeeContractSetting.Signed_Contract_Email_Subject__c, new list<String>{employee.First_Name__c, employee.Surname__c}));
            mail.setHtmlBody(String.Format(employeeContractSetting.Signed_Contract_Email_Body__c, new list<String>{employee.First_Name__c, employee.Surname__c}));
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();        
            // Add to attachment file list
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('Employee Contract '+month_Year+'.pdf');
            efa.setBody(conVer.VersionData);
            fileAttachments.add(efa);
            mail.setFileAttachments(fileAttachments);
            messagingList.add(mail);

            if (!messagingList.isEmpty()) {

                Messaging.sendEmail(messagingList);
            }

            this.updateStatusToComplete();

            initHelper();
        } catch(Exception e) {

            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DEFAULT_ERROR));
        }
    } 
    
    public void updateStatusToComplete() {
        
        Employee__c employee2Update = new Employee__c(id = employee.Id);
        employee2Update.Status__c = 'Completed'; 
        Update employee2Update;
    }

    public static void sendEmployeeContract(List<Employee__c> employees, Map<Id, Employee__c> oldMap){

        try{            
            
            List<Messaging.SingleEmailMessage> messagesToBeSend = new List<Messaging.SingleEmailMessage>();

            for (Employee__c employee : employees) {
                
                if (oldMap.get(employee.Id).Status__c != employee.Status__c) {
                    
                    String subject;
                    String body;

                    if (employee.Status__c == 'Approved (Contract Sent)' && String.isNotBlank(employeeContractSetting.Contract_Email_Subject__c) && String.isNotBlank(employeeContractSetting.Contract_Email_Body__c)) {
                        
                        subject = String.Format(employeeContractSetting.Contract_Email_Subject__c, new list<String>{employee.First_Name__c, employee.Surname__c});
                        body = String.Format(employeeContractSetting.Contract_Email_Body__c, new list<String>{employee.First_Name__c, employee.Surname__c, employee.Id});
                    } else if (employee.Status__c == 'In Progress' && String.isNotBlank(employeeContractSetting.Resubmit_Request_Email_Subject__c) && String.isNotBlank(employeeContractSetting.Resubmit_Request_Email_Body__c)) {
                        
                        subject = String.Format(employeeContractSetting.Resubmit_Request_Email_Subject__c, new list<String>{employee.First_Name__c, employee.Surname__c});
                        body = String.Format(employeeContractSetting.Resubmit_Request_Email_Body__c, new list<String>{employee.First_Name__c, employee.Surname__c, employee.Id});
                    }

                    if (String.isNotBlank(subject) && String.isNotBlank(body) && String.isNotBlank(employee.Email_Address_For_Payslip__c)) {
                        
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.toAddresses = new String[] { employee.Email_Address_For_Payslip__c};
                        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :employeeContractSetting.Staff_Onboarding_Reply_To_Email_Address__c];
                        if ( owea.size() > 0 ) {
                            message.setOrgWideEmailAddressId(owea.get(0).Id);
                        }
                        message.setSubject(subject);
                        message.setHtmlBody(body);
                        message.setReplyTo(employeeContractSetting.Staff_Onboarding_Reply_To_Email_Address__c);
                        messagesToBeSend.add(message);
                    }
                }
            }

            if (!messagesToBeSend.isEmpty()) {
                
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messagesToBeSend);
                if (results[0].success) {

                    System.debug('The email was sent successfully.');
                } else{

                    System.debug('The email failed to send: ' + results[0].errors[0].message);
                }
            }            
        } catch(Exception e) {

            throw e;
        }
    }
}