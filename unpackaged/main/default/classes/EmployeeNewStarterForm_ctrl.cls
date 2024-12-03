public without sharing class EmployeeNewStarterForm_ctrl {

    public Employee__c employee {get;set;}

    public static Employee_Contract_Setting__mdt employeeContractSetting = Employee_Contract_Setting__mdt.getInstance('default');

    public EmployeeNewStarterForm_ctrl() {

        employee = new Employee__c();
    }  
    
    @AuraEnabled
    public static string saveAsDraftHandler(String employeeData){

        try {
            if (String.isNotBlank(employeeData)) {

                Employee__c employeeToBeUpsert = (Employee__c) JSON.deserialize(employeeData, Employee__c.class);

                if (String.isNotBlank(employeeToBeUpsert.Signature__c)) {

                    employeeToBeUpsert.Signed_Date__c = System.today();
                }

                if (String.isNotBlank(employeeToBeUpsert.Email_Address_For_Payslip__c) && String.isBlank(employeeToBeUpsert.Id)) {

                    employeeToBeUpsert.Id = EmployeeNewStarterForm_ctrl.getEmployeeRecordIdByEmail(employeeToBeUpsert.Email_Address_For_Payslip__c);
                }
                
                Boolean isStatusInProgress = employeeToBeUpsert.Status__c == 'In Progress';
                employeeToBeUpsert.Status__c = isStatusInProgress ? 'Draft' : employeeToBeUpsert.Status__c;
                upsert employeeToBeUpsert;

                if (!isStatusInProgress && employeeToBeUpsert.Status__c == 'Draft' && String.isNotBlank(employeeToBeUpsert.Email_Address_For_Payslip__c)) {
                    
                    EmployeeNewStarterForm_ctrl.sendNotification(
                        String.Format(employeeContractSetting.Draft_Email_Subject__c, new list<String>{employeeToBeUpsert.First_Name__c , employeeToBeUpsert.Surname__c}), 
                        String.Format(employeeContractSetting.Draft_Email_Body__c, new list<String>{employeeToBeUpsert.First_Name__c , employeeToBeUpsert.Surname__c, employeeToBeUpsert.Id}),
                        employeeToBeUpsert.Email_Address_For_Payslip__c.split(',')
                    );
                }

                if (employeeToBeUpsert.Status__c == 'Submitted') {
                    
                    EmployeeNewStarterForm_ctrl.sendNotification(
                        String.Format(employeeContractSetting.Submit_Form_Email_Subject__c, new list<String>{employeeToBeUpsert.First_Name__c, employeeToBeUpsert.Surname__c}), 
                        String.Format(employeeContractSetting.Submit_Form_Email_Body__c, new list<String>{employeeToBeUpsert.First_Name__c, employeeToBeUpsert.Surname__c, employeeToBeUpsert.Id}),
                        employeeContractSetting.Submit_Form_Email_To_Addresses__c.split(',')
                    );
                }

                return employeeToBeUpsert.Id;
            }
            return null;
        } catch (Exception e) {

            String error = e.getMessage();
            if (error.contains('Upsert failed')) {

                throw new AuraHandledException(e.getDMLMessage(0));
            }else {

                throw new AuraHandledException(error);
            }
            
        }
    }

    public static String getEmployeeRecordIdByEmail(String employeeEmail) {
        
        if (String.isBlank(employeeEmail)) {
            
            return employeeEmail;
        }

        List<Employee__c> employees = [SELECT Id FROM Employee__c WHERE Email_Address_For_Payslip__c = :employeeEmail limit 1];

        if (!employees.isEmpty()) {
            
            return employees.get(0).Id;
        }

        return null;
    }
    
    @AuraEnabled
    public static Map<String, Object> getEmployee(String recordId){
        
        Map<String, Object> resultSet = new Map<String, Object>();
        try {
            List<Employee__c> employees = [SELECT Address__c,
            Do_you_have_Right_to_work_in_the_UK__c,
            Have_a_National_Insurance_Number__c,
            Accommodation_required_for_disability__c,
            Repaying_Student_Loan__c,
            Any_Medical_Issues_In_the_last_2_Years__c,
            Bank_Account_Number__c,
            CreatedById,
            CreatedDate,
            Date_Of_Birth__c,
            Department_Site__c,
            Disability_Or_Illness_Details__c,
            Email_Address_For_Payslip__c,
            Emergency_Address__c,
            Emergency_Email_Address__c,
            Emergency_Mobile_Number__c,
            Employee_Statement__c,
            First_Name__c,
            GP_s_Name_and_Address__c,
            Id,
            IsDeleted,
            Job_Title__c,
            LastModifiedById,
            LastModifiedDate,
            LastReferencedDate,
            LastViewedDate,
            Marital_Status__c,
            Mental_Physical_Disability_Or_Illness__c,
            Mobile_Number__c,
            Name,
            Name__c,
            Name_On_Bank_Account__c,
            National_Insurance_Number__c,
            Nationality__c,
            Normal_Hours_Per_Week__c,
            OwnerId,
            Owner.Type,
            Owner.Name,
            Owner.FirstName,
            Owner.LastName,
            Post_Code__c,
            Relationship__c,
            Salary_Pay_Rate__c,
            Signature__c,
            Signed_Date__c,
            Sort_Code__c,
            SSP_Qualifying_Days__c,
            Start_Date__c,
            Status__c,
            Student_Loan__c,
            Surname__c,
            SystemModstamp,
            Telephone_Number__c,
            Title__c,
            What_adjustments_if_any__c,
            What_type_of_Student_Loan_do_you_have__c,
            Working_Days__c,
            Preferred_Location__c,
            Your_Studies_Before_The_Last_6_April__c,
            Ee_Prefers_To_Be_Called__c,
            Ee_Middle_Name__c,Ee_Address_Number__c, Ee_County__c, Ee_Street_Name_1__c, Ee_Street_Name_2__c, Ee_Town__c,
            (Select Id, ContentDocumentId From ContentDocumentLinks order by ContentDocument.CreatedDate DESC limit 1) 
            FROM Employee__c WHERE Id = :recordId limit 1];

            if (!employees.isEmpty()) {

                resultSet.put('employee', employees.get(0));
            } else {
                
                resultSet.put('employee', new Employee__c());
            }

            resultSet.put('settings', employeeContractSetting);
            resultSet.put('locations', getPicklistvalues('Employee__c', 'Preferred_Location__c', false));

            return resultSet;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<String> getPicklistvalues(String objectName, String field_ApiName,Boolean nullRequired){

        List<String> optionList = new List<String>();       
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap();        
        List<Schema.PicklistEntry> picklistValues = field_map.get(field_ApiName).getDescribe().getPickListValues();       
        
        if (nullRequired == true) {

            optionList.add('--None--');
        }       
        
        for (Schema.PicklistEntry pv : picklistValues) {

            optionList.add(pv.getValue());
        }
        return optionList;
    }

    public static void sendNotification(String subject, String htmlBody, List<String> emails) {

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(emails);
        message.setSubject(subject);
        message.setHtmlBody(htmlBody);

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success) {
            
            System.debug('The email was sent successfully.');
        } else {
            
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }    
}