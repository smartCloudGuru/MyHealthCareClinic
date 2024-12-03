public with sharing class EmployeeContractPreview_ctrl {

    public EmployeeContractPreview_ctrl() {

    }

    /** This function is used from the Employee Contract Preview Aura Component. */
    @AuraEnabled
    public static void updateStatusToSendContract(String recordId){
        try {
             
            Employee__c employee = new Employee__c(
                Id = recordId,
                Status__c = 'Approved (Contract Sent)'
            );

            update employee;
        } catch (Exception e) {

            throw new AuraHandledException(e.getMessage());
        }
    }

    /** This function is used from the Employee Contract Preview Aura Component. */
    @AuraEnabled
    public static Employee__c getEmployeeRecord(String recordId){
        try {
            
            return [SELECT 
                        Id, Status__c,
                        Contract_Document__c
                    FROM Employee__c 
                    WHERE Id=:recordId LIMIT 1];
        } catch (Exception e) {
            
            return new Employee__c();
        }
    }
}