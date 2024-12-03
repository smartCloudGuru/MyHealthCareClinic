/**
 * Created 27.6.2024..
 */

//if there's a google campaign ID on a campaign, automatically update or create the Referral Code
public without sharing class CampaignTriggerHandler {

    public static void onChange(List<Campaign> campaigns) {
        Set<Id> ids = new Set<Id>();
        for (Campaign campaign : campaigns) {
            ids.add(campaign.Id);
        }

        List<Campaign> cams = [SELECT Id, Name, Google_Campaign_Id__c FROM Campaign WHERE Id IN :ids AND Google_Campaign_Id__c != NULL];
        //System.debug('a:' + cams.size());

        Map<String, Campaign> map_gciod_gcName = new Map<String, Campaign>();
        for (Campaign campaign : cams) {
            if (campaign != null && campaign.Google_Campaign_Id__c != null) map_gciod_gcName.put(campaign.Google_Campaign_Id__c, campaign);
        }

        //get all the referral codes
        List<Referral_Code__c> refCodes = [SELECT Id, Code__c, Campaign__c FROM Referral_Code__c];
        //System.debug('b:' + refCodes.size());

        Map<String, Referral_Code__c> referralCodeMap = new Map<String, Referral_Code__c>();
        for (Referral_Code__c referralCode : refCodes) {
            if (referralCode.Code__c != null) referralCodeMap.put(referralCode.Code__c, referralCode);
        }

        List<Referral_Code__c> rcsToInsert = new List<Referral_Code__c>();
        for (String gcid : map_gciod_gcName.keySet()) {
            Referral_Code__c rc = referralCodeMap.get(gcId);
            if (rc == null) {
                rc = new Referral_Code__c();
                rc.Code__c = gcid;
                rc.Active__c = true;
                rc.Name = 'Google Ads';
                rc.Instruction__c = 'Campaign tracking';
            }
            if (rc.Campaign__c==null) rc.Campaign__c = map_gciod_gcName.get(gcid)?.Id;

            rcsToInsert.add(rc);
        }

        //System.debug('c:' + rcsToUpsert.size());
        Database.upsert(rcsToInsert, true);

    }
}