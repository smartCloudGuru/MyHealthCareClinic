/**
 * Created 20.1.2023..
 */

public without sharing class LeadConvertCtrl {

    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);

    @AuraEnabled(Cacheable=false)
    public static String getPotentialDuplicates(String leadId) {

        List<Account> ret = new List<Account>();

        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Date_of_birth__c, Phone, MobilePhone FROM Lead WHERE Id = :leadId];

        if (leads.isEmpty()) return JSON.serialize(ret);

        Lead from_lead = leads[0];

        if (from_lead.Phone != NULL && from_lead.Phone.length()<4) from_lead.Phone = null;
        if (from_lead.MobilePhone != NULL && from_lead.MobilePhone.length()<4) from_lead.MobilePhone = null;



        ret = [
                SELECT
                        Id, Patient_Id__c, Patient_Type__c, FirstName, LastName, PersonMobilePhone, Date_of_Birth__c, Phone, PersonEmail
                FROM Account
                WHERE (
                        (FirstName != NULL AND FirstName = :from_lead.FirstName AND LastName = :from_lead.LastName)
                        OR
                        (LastName = :from_lead.LastName AND Date_of_Birth__c = :from_lead.Date_of_birth__c AND Date_of_Birth__c!=NULL)
                        OR
                        (PersonEmail != NULL AND PersonEmail = :from_lead.Email)
                        OR
                        (PersonMobilePhone != NULL AND PersonMobilePhone = :from_lead.MobilePhone)
                        OR
                        (Phone != NULL AND Phone = :from_lead.Phone)
                )
                AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID
                ORDER BY CreatedDate DESC
                LIMIT 8
        ];

        return JSON.serialize(ret);
    }

    @AuraEnabled(Cacheable=true)
    public static String getClinicValues() {
        return JSON.serialize(Lead.Clinic_Booked__c.getDescribe().getPicklistValues());
    }

    @AuraEnabled
    public static String doConvert(String fromId, String toId, String clinicName) {

        try {
            List<Lead> leads = [
                    SELECT Id,
                            Company,
                            Clinic_Booked__c
                    FROM Lead
                    WHERE Id = :fromId
                    LIMIT 1
            ];
            if (leads.isEmpty()) return null;

            Lead leadObj = leads[0];

            leadObj.Clinic_Booked__c = clinicName;

            update leadObj;

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadObj.Id);
            lc.setOpportunityName(leadObj.Company);
            lc.setAccountId(toId);

            LeadStatus convertStatus = [
                    SELECT
                            Id,
                            MasterLabel
                    FROM LeadStatus
                    WHERE IsConverted = TRUE
                    LIMIT 1
            ];

            lc.setConvertedStatus(convertStatus.MasterLabel);

            Database.LeadConvertResult lcr = Database.convertLead(lc);

            return String.valueOf(lcr.getAccountId());
        }
        catch (Exception ex)
        {
            throw newAuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    public static String doConvertAndReturnLeadConvertResult(String fromId, String toId, String clinicName) {

        try {
            List<Lead> leads = [
                    SELECT Id,
                            Company,
                            Clinic_Booked__c
                    FROM Lead
                    WHERE Id = :fromId
                    LIMIT 1
            ];
            if (leads.isEmpty()) return null;

            Lead leadObj = leads[0];

            leadObj.Clinic_Booked__c = clinicName;

            update leadObj;

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadObj.Id);
            lc.setOpportunityName(leadObj.Company);
            lc.setAccountId(toId);

            LeadStatus convertStatus = [
                    SELECT
                            Id,
                            MasterLabel
                    FROM LeadStatus
                    WHERE IsConverted = TRUE
                    LIMIT 1
            ];

            lc.setConvertedStatus(convertStatus.MasterLabel);

            Database.LeadConvertResult lcr = Database.convertLead(lc);

            // lcr.getAccountId());
            // lcr.getOpportunityId());
            return JSON.serializePretty(lcr);
        }
        catch (Exception ex) {
            throw newAuraHandledException(ex.getMessage());
        }
    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }
}