/**
 * Created 29.11.2024..
 */

public without sharing class memUpgradeFormCtrl {

    @AuraEnabled
    public static String createUpgradeEnquiry(String firstName, String lastName, String email, String upgradeTo, String ref) {

        Lead ld = new Lead(FirstName = firstName, LastName = lastName, Email = email, Description = 'Upgrade to: ' + upgradeTo + ', ' + ref);
        ld.LeadSource = 'Database (email)';
        ld.Mode__c = 'Form';
        ld.Reason_for_Enquiry__c = 'Upgrade to: ' + upgradeTo;
        if (ref != null) {
            ld.Referral_Code__c = ref;
        }

        try {
            if (ld.Referral_Code__c != null) {
                List<Referral_Code__c> refs = [SELECT Id, Campaign__c FROM Referral_Code__c WHERE Code__c = :ld.Referral_Code__c LIMIT 1];
                if (!refs.isEmpty()) ld.Campaign__c = refs.get(0).Campaign__c;
            }
        }
        catch (Exception ex) {
        }

        insert ld;
        return ld.Id;
    }
}