public class LeadConversionAuraController {
    @AuraEnabled
    public static string convertSelectedLead(String leadId, String clinicBooked){
        Lead leadObj = [SELECT Id,Company,Clinic_Booked__c FROM Lead WHERE Id=:leadId limit 1];
        leadObj.Clinic_Booked__c = clinicBooked;
        update leadObj;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadObj.id);
        lc.setOpportunityName(leadObj.Company);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        string objAcc = lcr.getAccountId();
        return String.valueOf(objAcc);
    }
}