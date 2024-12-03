public with sharing class CancelMembership_ctrl {
    @AuraEnabled
    public Static Account getAccountById(String accountId){
        return [SELECT Id,Membership_Level__c,Membership_Type__c,Home_Clinic__c,
                Patient_Type__c,Membership_Add_On__c, Cancellation_Reason__c,
                Cancelled_membership__c, Member_Status__c,Cancellation_Date__c, Signature_Date__c
                FROM Account
                WHERE Id = :accountId LIMIT 1];
    }
    @AuraEnabled
    public Static Account cancelMembership(Account objAccount){
        try {
            objAccount.Cancelled_membership__c = true;
            objAccount.Patient_Type__c = 'Registered';
            objAccount.Membership_Type__c = null;
            objAccount.Membership_Level__c = null;
            objAccount.Membership_Add_On__c = null;
            objAccount.Member_Status__c = 'Membership Cancelled';
            objAccount.Cancellation_Date__c = system.Today();
            if(String.IsBlank(objAccount.Cancellation_Reason__c)){
                objAccount.Cancellation_Reason__c = 'Moving Away';
            }
            objAccount.Cancelled_membership__c = true;
            objAccount.Signature_Date__c = null;
            objAccount.Signature__c = null;
            objAccount.Direct_Debit_Setup__c = false;
            update objAccount;
            list<Opportunity> listOpp = [SELECT Id,Membership_Cancelled__c,
                                            (SELECT Id FROM OpportunityLineItems
                                            WHERE Product2.Family = 'Membership_Plan')
                                            FROM Opportunity WHERE AccountId=:objAccount.Id];
            for(Opportunity o:listOpp){
                o.Membership_Cancelled__c = true;
            }
            update listOpp;
            return objAccount;
        }catch(Exception e){
            throw e;
        }
    }
    @AuraEnabled 
    public static List<String> getPicklistValue() {
        List <String> options = new List <String>();
        Schema.DescribeFieldResult fieldResult = Account.Cancellation_Reason__c.getDescribe();
        List <Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
}