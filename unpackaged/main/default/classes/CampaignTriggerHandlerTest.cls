/**
 * Created 27.6.2024..
 */

@IsTest
private class CampaignTriggerHandlerTest {

    public static Campaign createCampaign(String name, String googleCampaignId) {
        Campaign c = new Campaign();
        c.Name = name;
        c.Google_Campaign_Id__c = googleCampaignId;
        insert c;
        return c;
    }

    public static Referral_Code__c createReferralCode(String code, Id campaignId) {
        Referral_Code__c rc = new Referral_Code__c();
        rc.Code__c = code;
        rc.Campaign__c = campaignId;
        rc.Instruction__c = 'Campaign tracking';
        insert rc;
        return rc;
    }

    @IsTest
    static void testOnChange_newReferralCode() {
        Campaign c1 = createCampaign('TestCampaign1', '123111');
        Campaign c2 = createCampaign('TestCampaign2', '123222');


        // Assert
        List<Referral_Code__c> rcs = [SELECT Id, Code__c, Campaign__c FROM Referral_Code__c WHERE Code__c IN :new Set<String>{'123111', '123222'}];

        System.assert(!rcs.isEmpty(), 'No referral codes found.');
        System.assertEquals(2, rcs.size(), 'Unexpected number of referral codes found.');
    }

    @IsTest
    static void testOnChange_existingReferralCode() {

        Referral_Code__c existingRc = createReferralCode('123111', null);

        Campaign c1 = createCampaign('TestCampaign1', '123111');


        // Assert
        List<Referral_Code__c> rcs = [SELECT Id, Code__c, Campaign__c FROM Referral_Code__c WHERE Code__c = :c1.Google_Campaign_Id__c];
        System.assertEquals(1, rcs.size(), 'Unexpected number of referral codes found.');

        Referral_Code__c rc = rcs.get(0);
        System.assertEquals(existingRc.Id, rc.Id, 'Unexpected referral code found.');
        System.assertNotEquals(null, rc.Campaign__c, 'Campaign is not set on referral code.');
    }
}