public without sharing class MembershipFormPDF {
    public Account objAccPdf {get;set;} 
    public String signImage{get;set;}

    public MembershipFormPDF(ApexPages.StandardController controller) {    
        objAccPdf = [select Total_Monthly_Membership_Fees__c,Name,Account.IsPersonAccount,Contract_Sent_Date__c,Patient_Type__c ,Quantity__c,Billing_Address__c,
                    List_Of_Members_Covered_By_The_Contract__c,Membership_Start_Date__c ,Membership_Change_Dates__c,
                    Signature__c,Signature_Date__c, Total_Monthly_Membership_Fee__c,Home_Clinic__c ,Membership_Type__c , 
                    Membership_Level__c ,Payment_Frequency__c FROM Account where id=:controller.getId()]; 
        String id15Char = (''+objAccPdf.Id).substring(0,15);
        List<Document> listOfDoc = [SELECT Id FROM Document WHERE Name =: objAccPdf.Id OR Name = :id15Char limit 1]; 
        if(listOfDoc.size() > 0){
            signImage = listOfDoc[0].Id;
        }
    }
}