@isTest
private class EmployeeNewStarterForm_ctrlTest {

    @TestSetup
    static void testData() {
        
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        employee.Status__c = 'Submitted';
        employee.Signature__c = 'Test Signature'; 
        insert employee;
    }
        
    @isTest
    static void itShouldSaveAsDraftHandler() {

        //Given        
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        employee.Status__c = 'Submitted';
        employee.Signature__c = 'Test Signature'; 
        
        //When
        String employeeId;
        Test.startTest();
            
            employeeId = EmployeeNewStarterForm_ctrl.saveAsDraftHandler(JSON.serialize(employee));            
        Test.stopTest();
        
        //Then
        System.assertNotEquals(null, employeeId);    
    }
    
    @isTest
    static void itShouldGetEmployeeById() {

        //Given
        Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];

        //When
        Map<String, Object> resultSet;        
        Test.startTest();

            //Construction test
            EmployeeNewStarterForm_ctrl employeeNewStarterForm = new EmployeeNewStarterForm_ctrl();
            
            resultSet = EmployeeNewStarterForm_ctrl.getEmployee(employee.Id);
        Test.stopTest();
        
        //Then
        System.assertEquals(employee.Id, ((Employee__c)resultSet.get('employee')).Id);   
    }

    @isTest
    public static void itShouldSendNotification() {

        //Given
        string subject = 'Test Subject';
        string htmlBody = 'Test Body';
        List<String> emails = new List<String>{'test@test.com'};
        
        //When
        Test.startTest();
        
            EmployeeNewStarterForm_ctrl.sendNotification(subject, htmlBody, emails);
            
            //Then
            Integer invocations = Limits.getEmailInvocations();
            System.assertEquals(1, invocations, 'Email has been sent');
        Test.stopTest();
    }

    @isTest
    public static void itShouldThrowException() {

        //Given        
        Employee__c employee = new Employee__c(); 
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        employee.Status__c = 'Submitted';
        employee.Signature__c = 'Test Signature'; 
        employee.Email_Address_For_Payslip__c = 'test@test'; //invalid email
        
        //When
        String errorMsg;
        Test.startTest();
            
        try {
            
            EmployeeNewStarterForm_ctrl.saveAsDraftHandler(JSON.serialize(employee));            
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }
        Test.stopTest();
        
        //Then
        System.assertNotEquals(null, errorMsg);    
    }
}