/**
 * Created 17.2.2023..
 */

public without sharing class AeronaCarePlanSync {

    // retrieves all aerona plans, and all membership tiers
    // takes enabled plans and active tiers
    // compares them by name
    // updates membership tiers with their aerona care plan id
    public static void syncAllPlanIds() {
        List<AeronaServiceOASApi.OASCarePlan> allPlans = AeronaService.getCarePlans();

        List<AeronaServiceOASApi.OASCarePlan> activePlans = new List<AeronaServiceOASApi.OASCarePlan>();

        Map<String, Long> map_planName_id = new Map<String, Long>();
        for (AeronaServiceOASApi.OASCarePlan plan : allPlans) {
            if (plan.enabled) {
                map_planName_id.put(plan.description.replaceAll('MHC', '').replaceAll(' ', '').toLowerCase(), plan.id);
            }
        }

        List<Membership_Tier__c> mTiers = [SELECT Id, Name, Available_To__c FROM Membership_Tier__c];

        Map<String, String> map_mtierName_id = new Map<String, String>();

        for (Membership_Tier__c mTier : mTiers) {
            if (mTier.Available_To__c == null || mTier.Available_To__c >= Date.today()) {
                map_mtierName_id.put(('' + mTier.Name).replaceAll('MHC', '').replaceAll(' ', '').toLowerCase(), mTier.Id);
            }
        }

        for (String mt : map_mtierName_id.keySet()) {
            System.debug('TIER: ' + mt + '=' + map_mtierName_id.get(mt));
        }

        List<Membership_Tier__c> tiersToUpdate = new List<Membership_Tier__c>();
        for (String pn : map_planName_id.keySet()) {
            System.debug('PLAN: ' + pn + '=' + map_planName_id.get(pn));
            if ((map_mtierName_id.get(pn) != null) && (map_planName_id.get(pn) != null)) {
                tiersToUpdate.add(new Membership_Tier__c(Id = map_mtierName_id.get(pn), Aerona_Care_Plan_Id__c = map_planName_id.get(pn)));
            }
        }

        for (Membership_Tier__c membershipTier : tiersToUpdate) {
            System.debug('-- ' + membershipTier);
        }

        update tiersToUpdate;

    }

}