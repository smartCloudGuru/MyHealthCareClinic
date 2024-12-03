@isTest
public class EmployeeNewStarterFormPDF_ctrlTest {
    @isTest
    static void TestFormPDF_ctrl (){
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        insert employee ;
        
        Employee__c emp= [select id ,Surname__c ,First_Name__c from Employee__c where Id = :employee.Id];
        Test.StartTest();
            PageReference pageRef = Page.EmployeeNewStarterFormPDF;
            pageRef.getparameters().put('id', emp.id);  
            Test.setCurrentPage(pageRef);
            Apexpages.StandardController sc = new Apexpages.StandardController(employee);
            EmployeeNewStarterFormPDF_ctrl ext = new  EmployeeNewStarterFormPDF_ctrl(sc);
        Test.StopTest();
		system.assert(ext != null);  
       
        
        
    }
    

}