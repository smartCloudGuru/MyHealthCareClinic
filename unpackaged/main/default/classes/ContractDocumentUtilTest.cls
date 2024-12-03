@isTest
public class ContractDocumentUtilTest {
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
    static void itprocessedMergeFieldsContractDocument(){
       
        Employee__c employee=[select id from Employee__c]; 
      
        Test.startTest();
        ContractDocumentUtil.processedMergeFieldsContractDocument('Testing {!First_Name__c} - Hello World',employee.id,true);
		
        System.assertEquals('test', ContractDocumentUtil.processedMergeFieldsContractDocument('test',employee.id,true));
        System.assertNotEquals(null, ContractDocumentUtil.processedMergeFieldsContractDocument('test',employee.id,true)); 
        Test.stopTest();
    }
    @isTest
    static void itgetRecordWithAllFieldsById(){
        
   		ContractDocument__c  ContractDocument = [SELECT Id FROM  ContractDocument__c]; 
       
        Test.startTest();
        System.assertNotEquals(null,ContractDocumentUtil.getRecordWithAllFieldsById(ContractDocument.id,'ContractDocument__c'));
		Test.stopTest();
       
        
    }
    @isTest
    static void itgetFieldMappingValue(){
   		 ContractDocument__c  ContractDocument = [SELECT Id FROM  ContractDocument__c];
       
        Test.startTest();
        ContractDocumentUtil.getFieldMappingValue(ContractDocument,'testField','Employee__c');
		Test.stopTest();
        
    }
    @isTest
    static void itnormalizeMergeField(){
        Test.startTest();
        ContractDocumentUtil.normalizeMergeField( 'TestField');
		Test.stopTest();
    }   

 }