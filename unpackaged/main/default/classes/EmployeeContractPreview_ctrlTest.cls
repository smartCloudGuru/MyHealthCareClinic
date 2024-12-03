@isTest
public class EmployeeContractPreview_ctrlTest {
 
    
 @isTest
 static void itupdateStatusToSendContract(){
     
       EmployeeContractPreview_ctrl Empprview=new  EmployeeContractPreview_ctrl();
       Employee__c employee = new Employee__c();
       employee.Surname__c = 'Test'; 
       employee.First_Name__c = 'Test FirstName';
       insert employee;
	  
       Employee__c emp= [select id ,Surname__c ,First_Name__c from Employee__c where Id = :employee.Id ];
       Test.startTest();
       EmployeeContractPreview_ctrl.updateStatusToSendContract(emp.id);
       Test.stopTest();

      System.assertNotEquals(null, emp.Id);
     
     }
    
    @isTest
    static void itgetEmployeeRecord(){
       
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
     	insert employee;
    
        Employee__c emp = [SELECT Id FROM Employee__c where Id = :employee.Id LIMIT 1];        
        Test.startTest();
     	EmployeeContractPreview_ctrl.getEmployeeRecord(emp.id);
      	Test.stopTest();
        System.assertEquals(employee.id, emp.Id);
    }
        
	@isTest
	public static void itShouldThrowException() {

             
        Employee__c employee = new Employee__c();
        employee.Surname__c = 'Test Surname'; 
        employee.First_Name__c = 'Test FirstName';
        employee.Status__c = 'Submitted';
       
        String errorMsg;
        
        Test.startTest();  
        try {
            
            EmployeeContractPreview_ctrl.getEmployeeRecord(JSON.serialize(employee)); 
            EmployeeContractPreview_ctrl.updateStatusToSendContract(JSON.serialize(employee));
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }
        Test.stopTest();
 
        System.assertNotEquals(null, errorMsg);    
    }
        

         
     }