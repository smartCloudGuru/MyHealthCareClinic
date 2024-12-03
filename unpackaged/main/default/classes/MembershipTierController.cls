/**
 * Created 14.1.2022..
 */

public with sharing class MembershipTierController {


    @AuraEnabled (Cacheable = true)
    public static String getMembershipTiers() {

        List<MembershipTierWrapper> ret = new List<MembershipTierWrapper>();

        //get all tiers
        List<Pricebook2> tiers = [
                SELECT
                        Id,
                        Name,
                        IsActive, (
                        SELECT Id, Product2.Name, Product2.Family, UnitPrice
                        FROM PricebookEntries
                        WHERE Product2.Family = 'Membership_Plan' AND IsActive = TRUE
                        ORDER BY Name ASC
                )
                FROM Pricebook2
                WHERE IsActive = TRUE
                ORDER BY Name ASC
        ];

        //get all Tier Benefit Members (junction table)
        List<Tier_Benefit_Member__c> tb_members = [SELECT Id, Membership_Tier__c, Benefit__c FROM Tier_Benefit_Member__c];

        //get all Benefits
        List<Membership_Benefit__c> mBenefits = [
                SELECT
                        Id,
                        Annual_Limit__c,
                        Benefit_Product_Group__c,
                        Covered_Days_Of_Week__c,
                        Discount_Percentage__c,
                        IsUnlimited__c,
                        Name
                FROM Membership_Benefit__c
                WHERE IsActive__c = TRUE
                ORDER BY Name ASC
        ];

        //make a map <Membership_Benefit_ID, Membership_Benefit__c>
        Map<String, Membership_Benefit__c> map_id_Benefit = new Map<String, Membership_Benefit__c>();
        for (Membership_Benefit__c mb : mBenefits) {
            map_id_Benefit.put(mb.Id, mb);
        }

        for (Pricebook2 mt : tiers) {
            MembershipTierWrapper wrap = new MembershipTierWrapper(mt);
            for (Tier_Benefit_Member__c tbm : tb_members) {
                if (map_id_Benefit.get(tbm.Benefit__c) != null) if (tbm.Membership_Tier__c == mt.Id) wrap.benefits.add(map_id_Benefit.get(tbm.Benefit__c));
            }
            ret.add(wrap);
        }

        return JSON.serialize(ret);
    }


    public static MembershipTierWrapper getMembershipTierByName(String tierName) {

        //get all tiers
        List<Pricebook2> tiers = [
                SELECT
                        Id,
                        Name,
                        IsActive, (
                        SELECT Id, Product2.Name, Product2.Family, UnitPrice
                        FROM PricebookEntries
                        WHERE Product2.Family = 'Membership_Plan' AND IsActive = TRUE
                        ORDER BY Name ASC
                )
                FROM Pricebook2
                WHERE IsActive = TRUE AND Name = :tierName
                LIMIT 1
        ];

        if (tiers.size() == 0) return null;

        Pricebook2 tier = tiers[0];

        //get all Tier Benefit Members for that tier
        List<Tier_Benefit_Member__c> tb_members = [
                SELECT Id,
                        Benefit__r.Id,
                        Benefit__r.Annual_Limit__c,
                        Benefit__r.Benefit_Product_Group__c,
                        Benefit__r.Covered_Days_Of_Week__c,
                        Benefit__r.Discount_Percentage__c,
                        Benefit__r.IsUnlimited__c,
                        Benefit__r.Name
                FROM Tier_Benefit_Member__c
                WHERE Membership_Tier__c = :tier.Id
        ];

        MembershipTierWrapper ret = new MembershipTierWrapper(tier);
        for (Tier_Benefit_Member__c tmb : tb_members) {
            ret.benefits.add(tmb.Benefit__r);
        }

        return ret;
    }

    /**
     * Get all members in the group, for an Id of any member in the group
     *
     * @param id
     *
     * @return
     */
    public static List<Account> getMembersByMemberId(String id) {
        return [
                SELECT
                        Id,
                        Name,
                        FirstName,
                        LastName, Date_of_Birth__c,
                        Member_Group__c,
                        Member_Status__c,
                        Membership_Type__c,
                        Membership_Level__c,
                        Member_Types__c,
                        Member_Since__c,
                        Membership_Change_Dates__c,
                        Membership_Start_Date__c,
                        Cancellation_Date__c,
                        Patient_Id__c,
                        Membership_Tier__r.Tier_Level__c
                FROM Account
                WHERE Id = :id OR Member_Group__c = :id
        ];
    }

    public class MembershipTierWrapper {
        public Pricebook2 tier;
        public List<Membership_Benefit__c> benefits;

        public MembershipTierWrapper(Pricebook2 tier) {
            this.tier = tier;
            benefits = new List<Membership_Benefit__c>();
        }
    }

}