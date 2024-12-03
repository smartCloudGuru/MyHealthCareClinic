public with sharing class EmployeeNewStarterFormPDF_ctrl {

    public Employee__c employee{get;set;}

    public EmployeeNewStarterFormPDF_ctrl(ApexPages.StandardController stdController) {

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
            Your_Studies_Before_The_Last_6_April__c,
            Ee_Middle_Name__c, Ee_Full_Address__c
        FROM Employee__c WHERE Id = :ApexPages.currentPage().getParameters().get('id') limit 1];
        
        if (!employees.isEmpty()) {

            employee = employees.get(0);
        }
    }
}