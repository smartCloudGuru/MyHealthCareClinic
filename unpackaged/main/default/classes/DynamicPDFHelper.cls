public without sharing class DynamicPDFHelper {

	private static final String INVALID_ACCESS = 'Invalid access, please reach out to the System Administrator';
    
    public String processedContent{get;set;}

    public DynamicPDFHelper(EmployeeContract_ctrl controller) {
        
        String recordId = ApexPages.currentPage().getParameters().get('id');
        contentProcessor(String.isNotBlank(recordId)?recordId:ApexPages.currentPage().getParameters().get('token'), documentIsPDF());
    }

    public DynamicPDFHelper() {

        String recordId = ApexPages.currentPage().getParameters().get('id');
        contentProcessor(String.isNotBlank(recordId)?recordId:ApexPages.currentPage().getParameters().get('token'), documentIsPDF());
    }

    public static Boolean documentIsPDF(){

        if (Test.isRunningTest() || ApexPages.currentPage().getUrl().contains('PDF')) {
            
            return true;
        }

        return false;
    }

    public static String getProcessedContentHelper() {
        
        Employee__c employee = getEmployeeById(ApexPages.currentPage().getParameters().get('token'));

        return ContractDocumentUtil.processedMergeFieldsContractDocument(
            employee.Contract_Document__r.CreateText__c, 
            employee.Id, 
            documentIsPDF()
        );
    }

    public void contentProcessor(String employeeId, Boolean toPDF){

        Employee__c employee = getEmployeeById(employeeId);

        processedContent = ContractDocumentUtil.processedMergeFieldsContractDocument(
            employee.Contract_Document__r.CreateText__c, 
            employee.Id, 
            toPDF
        );
    }

    public static Employee__c getEmployeeById(String employeeId){

        try {

            if (String.isBlank(employeeId)) {
                
                throw new DynamicPDFHelperException(INVALID_ACCESS);
            }
            
            return [SELECT 
                    Id, 
                    Contract_Document__c, 
                    Contract_Document__r.CreateText__c 
                   FROM Employee__c 
                   WHERE Id=:employeeId LIMIT 1];
        }
        catch (Exception ex) {
        
            throw new DynamicPDFHelperException(ex.getMessage());
        }
    }

    private class DynamicPDFHelperException extends Exception {}
}