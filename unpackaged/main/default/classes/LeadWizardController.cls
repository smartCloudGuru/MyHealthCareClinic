/**
 * Created by Matija on 19.9.2023..
 */

public without sharing class LeadWizardController {

    // INVOCABLE METHODS

    public class ProcessLeadRequest {

        @InvocableVariable(Label='Lead Id' Required=true)
        public String leadId;

        @InvocableVariable(Label='Outcome selected at start of Lead Wizard' Required=true)
        public String outcome;

        @InvocableVariable(Label='Do Conversion?' Required=true)
        public Boolean doConversion;

        @InvocableVariable(Label='Convert to which Account (or "new" for new account)?')
        public String convertToAccountId;

    }


    public class ProcessLeadResponse {
        @InvocableVariable(Label='Operation successful?' Required=false)
        public Boolean success;
        @InvocableVariable(Label='Error Message' Required=false Description='Message explaining the error if existing')
        public String message;
        @InvocableVariable(Label='Converted To Account Id' Required=false Description='If conversion was done, Id of account converted to')
        public String convertedToAccountId;
        @InvocableVariable(Label='Conversion Opportunity' Required=false Description='If conversion was done, Id of conversion Opportunity')
        public String convertedToOpportunityId;
        @InvocableVariable(Label='Conversion requested' Required=false Description='If conversion was requested')
        public Boolean conversionRequested;
    }

    @InvocableMethod(Category='Lead' Label='Lead Wizard - Process Lead' Description='Process 1st step of Lead Wizard' Callout=true)
    public static List<ProcessLeadResponse> processLeadOutcome(List<ProcessLeadRequest> requests) {

        List<ProcessLeadResponse> ret = new List<LeadWizardController.ProcessLeadResponse>();

        if (requests == null || requests.isEmpty()) return ret;

        ProcessLeadRequest request = requests[0];

        ProcessLeadResponse resp = new ProcessLeadResponse();
        resp.success = false;
        resp.message = 'General error processing';

        Lead ld = getLead(request.leadId);

        if (ld == null) {
            resp.success = false;
            resp.message = 'No such Lead found by Id: ' + request.leadId;
            ret.add(resp);
            return ret;
        }


        if (request.doConversion) {
            resp.conversionRequested = true;

            if (String.isBlank(request.convertToAccountId)) request.convertToAccountId = null;
            Database.LeadConvertResult lcr = convertLead(ld, request.convertToAccountId == 'new' ? null : request.convertToAccountId);

            resp.success = true;
            resp.message = 'Converted';
            resp.convertedToAccountId = lcr.accountId;
            resp.convertedToOpportunityId = lcr.opportunityId;

        }

        ret.add(resp);
        return ret;
    }

    @AuraEnabled (Cacheable=false)
    public static String aura_getLead(String leadId) {
        return JSON.serialize(getLead(leadId));
    }

    @AuraEnabled
    public static String copyFromAccount(String leadId, String accountId) {
        List<Account> accs = [
                SELECT Id, FirstName, LastName, Date_of_Birth__c, PersonEmail, BillingStreet, BillingCity, BillingPostalCode, BillingCountry,BillingState, Phone, PersonMobilePhone
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];

        if (accs.isEmpty()) return null;

        Account account = accs[0];

        Lead ld = new Lead(Id = leadId);
        if (account.FirstName != null) ld.FirstName = account.FirstName;
        if (account.LastName != null) ld.LastName = account.LastName;
        if (account.Date_of_Birth__c != null) ld.Date_of_birth__c = account.Date_of_Birth__c;
        if (account.PersonEmail != null) ld.Email = account.PersonEmail;
        if (String.isNotBlank(account.BillingStreet)) ld.Street = account.BillingStreet;
        if (String.isNotBlank(account.BillingCity)) ld.City = account.BillingCity;
        if (String.isNotBlank(account.BillingPostalCode)) ld.PostalCode = account.BillingPostalCode;
        if (String.isNotBlank(account.BillingCountry)) ld.Country = account.BillingCountry;
        if (String.isNotBlank(account.BillingState)) ld.State = account.BillingState;
        if (String.isNotBlank(account.Phone)) ld.Phone = account.Phone;
        if (String.isNotBlank(account.PersonMobilePhone)) ld.MobilePhone = account.PersonMobilePhone;

        ld.Account_for_Conversion__c = accountId;

        update ld;
        return ld.Id;
    }

    public static Lead getLead(String leadId) {

        if (String.isBlank(leadId)) return null;

        List<Lead> leads = [
                SELECT Id, FirstName, LastName, Company, Mode__c, Site__c, LeadSource, Business_Unit__c, Enquiry_Product__c, Enquiry_Product__r.Business_Unit__c, Status
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
        ];

        if (leads.isEmpty()) return null;

        Lead leadObj = leads[0];

        String businessUnit = leadObj.Business_Unit__c;
        if (String.isNotBlank(leadobj.Enquiry_Product__r.Business_Unit__c)) {
            businessUnit = leadobj.Enquiry_Product__r.Business_Unit__c;
        }
        // BU form product overrides BU specified on lead
        if (businessUnit != leadObj.Business_Unit__c) {
            leadObj.Business_Unit__c = businessUnit;
            update leadObj;
        }

        return leadObj;
    }

    public static Database.LeadConvertResult convertLead(Lead ld, String toId) {


        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        lc.setOpportunityName('Enquiry ' + ld.FirstName + ' ' + ld.LastName + ', ' + ld.Business_Unit__c + ' (' + ('' + Date.today()).substring(0, 10) + ')');
        if (String.isNotBlank(toId)) lc.setAccountId(toId);

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

        if (lcr.opportunityId != null) {
            Opportunity op = new Opportunity(Id = lcr.opportunityId);
            op.StageName = 'Qualification';
            op.Business_Unit__c = ld.Business_Unit__c;
            op.Mode__c = ld.Mode__c;
            op.Site__c = ld.Site__c;
            op.LeadSource = ld.LeadSource;
            op.Enquiry_Product__c = ld.Enquiry_Product__c;

            update op;
        }

        return lcr;

    }


}