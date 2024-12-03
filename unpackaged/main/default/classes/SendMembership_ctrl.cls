public with sharing class SendMembership_ctrl {
    @AuraEnabled
    public static Account getAccount(String accountId){
        list<Account> objAccount = new list<Account>();
        try{
            objAccount.add([SELECT Member_Group__r.Name, Age_In_Number__c,Member_Group__c,Id,General_Physician__c,Dentist__c,Membership_Level__c,Membership_Type__c,Receptionist__c,
                            Clinician__c,Billing_Address__c,Payment_Frequency__c,Home_Clinic__c,
                            PersonEmail,Total_Monthly_Membership_Fee__c,Name,Contract_Sent_Date__c,Signature_Date__c,
                            BillingCity,BillingCountry,BillingState,BillingStreet,BillingPostalCode,Patient_Type__c
                            FROM Account WHERE Id = :accountId LIMIT 1]);
        } catch(QueryException e){
            throw e;
        }
        return objAccount.get(0);
    }

    @AuraEnabled
    public static List<String> getPicklistvalues(String objectName, String field_apiname,Boolean nullRequired){
        List<String> optionList = new List<String>();
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> field_map = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap();
        List<Schema.PicklistEntry> picklistValues = field_map.get(field_apiname).getDescribe().getPickListValues();
        if(nullRequired == true){
            optionList.add('--None--');
        }
        for (Schema.PicklistEntry pv : picklistValues) {
            optionList.add(pv.getValue());
        }
        return optionList;
    }
    @AuraEnabled
    public static String updatePatient(Account objPatient, String clinician, Boolean isDentist){
        try {
            Account objAccount = new Account(Id = objPatient.Id);
            objAccount.PersonEmail = objPatient.PersonEmail;
            objAccount.Patient_Type__c = 'Member';
            objAccount.Membership_Type__c = objPatient.Membership_Type__c;
            objAccount.Home_Clinic__c = objPatient.Home_Clinic__c;
            objAccount.Payment_Frequency__c = objPatient.Payment_Frequency__c;
            objAccount.Membership_Level__c = objPatient.Membership_Level__c;
            objAccount.Receptionist__c = objPatient.Receptionist__c;
            if (isDentist) {
                objAccount.Dentist__c = clinician;
                objAccount.General_Physician__c = '';
            } else {
                objAccount.General_Physician__c = clinician;
                objAccount.Dentist__c = '';
            }
            objAccount.BillingStreet = objPatient.BillingStreet;
            objAccount.BillingPostalCode = objPatient.BillingPostalCode;
            objAccount.BillingState = objPatient.BillingState;
            objAccount.BillingCountry = 'United Kingdom';//objPatient.BillingCountry;
            objAccount.BillingCity = objPatient.BillingCity;
            update objAccount;
            return 'success';
        }catch(Exception e){
            String errorMsg = e.getMessage();
            if(errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                errorMsg = errorMsg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
            }
            return errorMsg;
        }
    }
}