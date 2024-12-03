@isTest
private class EmployeeContract_ctrlTest {

    @TestSetup
    static void testData() {
        
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        employee.Status__c = 'Submitted';
        employee.Signature__c = 'Test Signature'; 
        employee.Email_Address_For_Payslip__c = 'test@test.com';
        insert employee;

        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
            
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='SampleTitle.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_1;
        
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = employee.id;
        contentLink.contentDocumentId = contentVersion_2.contentDocumentId;
        contentLink.ShareType = 'V';
        insert contentLink;

        Document document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'application/pdf';
        document.DeveloperName = 'my_document';
        document.IsPublic = true;
        document.Name = employee.Id;
        document.FolderId = EmployeeContract_ctrl.employeeContractSetting.Contract_Signature_Folder_Id__c;
        insert document;
    }

    @isTest
    static void constructorTest() {

        // Test data setup
        Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('token', employee.Id);

        // Actual test
        EmployeeContract_ctrl employeeContract;
        Test.startTest();

            employeeContract = new EmployeeContract_ctrl();
        Test.stopTest();
    
        // Asserts
        System.assertEquals(employee.Id, employeeContract.employee.Id);
    }

    @isTest
    static void itShouldUpdateSignature() {

        // Test data setup
        Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('token', employee.Id);

        // Actual test
        EmployeeContract_ctrl employeeContract;
        Test.startTest();

            employeeContract = new EmployeeContract_ctrl();
            employeeContract.employee = employee;
            employeeContract.imgSource = 'data:image/png;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==';
            employeeContract.onUpdate();

            // Asserts
            Employee__c employeeToAssert = [SELECT Id, Contract_Signed_Date__c, Contract_Signature__c FROM Employee__c LIMIT 1];
            System.assertNotEquals(null, employeeToAssert.Contract_Signed_Date__c);
            System.assertNotEquals(null, employeeToAssert.Contract_Signature__c);

        Test.stopTest();
    }

    @isTest
    static void itShouldSendAndUploadContract() {

        // Test data setup
        Employee__c employee = [SELECT Id, First_Name__c, Surname__c, Email_Address_For_Payslip__c FROM Employee__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('token', employee.Id);

        // Actual test
        EmployeeContract_ctrl employeeContract;
        map<Integer,String> monthByNumber;
        Test.startTest();

            employeeContract = new EmployeeContract_ctrl();
            employeeContract.employee = employee;
            employeeContract.imgSource = 'data:image/png;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==';
            employeeContract.onUpdate();
            employeeContract.sendAndUploadContract();
            monthByNumber = EmployeeContract_ctrl.getMonthByNumber;
            //Then
            Integer invocations = Limits.getEmailInvocations();
            System.assertEquals(1, invocations, 'Email has been sent');     
        Test.stopTest();

        // Asserts
        Employee__c employeeToAssert = [SELECT Id, Contract_Signed_Date__c, Contract_Signature__c FROM Employee__c LIMIT 1];
        System.assertNotEquals(null, employeeToAssert.Contract_Signed_Date__c);
        System.assertNotEquals(null, employeeToAssert.Contract_Signature__c);
        System.assertNotEquals(null, monthByNumber);
    }

    @isTest
    static void itShouldSendContractOnApprove() {

        // Test data setup
        Employee__c employee = [SELECT Id, First_Name__c, Surname__c, Email_Address_For_Payslip__c, Status__c FROM Employee__c LIMIT 1];
        Integer numberToBeEmailSent = 1; //Expected
        // Actual test
        Test.startTest();
        
            employee.Status__c = 'Approved (Contract Sent)';
            update employee;
        
            //Then Asserts            
            Integer invocations = Limits.getEmailInvocations();
            System.assertEquals(numberToBeEmailSent, invocations, 'Email has been sent');     
        Test.stopTest();
    }
}