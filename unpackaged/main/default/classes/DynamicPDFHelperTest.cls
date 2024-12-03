@isTest
public class DynamicPDFHelperTest {
    @TestSetup
    static void testData() {
        
        ContractDocument__c conDoc=new ContractDocument__c();
        conDoc.name='test';
        conDoc.CreateText__c='Testing {!First_Name__c} - Hello World';
        insert conDoc;
       
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        employee.Status__c = 'Submitted';
        employee.Contract_Document__c=conDoc.id;
        insert employee;
        
    }
    @isTest    
    static void itShouldPassed() {

        Test.startTest();
        Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id',employee.Id); 
        ApexPages.currentPage().getParameters().put('token',employee.Id); 
        PageReference pageRef = Page.EmployeeNewStarterFormPDF;
        pageRef.getparameters().put('id', employee.id);  
        pageRef.getparameters().put('token', employee.id);  
        Test.setCurrentPage(pageRef);
        DynamicPDFHelper objDynamicPDFHelper = new DynamicPDFHelper();
        DynamicPDFHelper.getEmployeeById(employee.id);
        DynamicPDFHelper.getProcessedContentHelper();
        Test.stopTest();    
    }

    @isTest    
    static void itShouldPassedStandard() {
        
        Test.startTest();
        Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id',employee.Id); 
        ApexPages.currentPage().getParameters().put('token',employee.Id); 
        EmployeeContract_ctrl sc = new EmployeeContract_ctrl();
        DynamicPDFHelper testAccPlan = new DynamicPDFHelper(sc);
        PageReference pageRef = Page.EmployeeNewStarterFormPDF;
        pageRef.getparameters().put('id', employee.id);  
        pageRef.getparameters().put('token', employee.id);  
        Test.setCurrentPage(pageRef);
        DynamicPDFHelper objDynamicPDFHelper = new DynamicPDFHelper();
        DynamicPDFHelper.getEmployeeById(employee.id);
        DynamicPDFHelper.getProcessedContentHelper();
        Test.stopTest();    
    }
}