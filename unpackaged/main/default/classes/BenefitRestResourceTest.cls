/**
 * Created 27.2.2023..
 */

@IsTest
private class BenefitRestResourceTest {
    @IsTest
    static void getRecord_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Product2 product2 = new Product2(Name='testP');
        insert product2;

        Benefit_Product_Group__c bg = new Benefit_Product_Group__c();
        insert bg;

        Membership_Benefit__c mb = new Membership_Benefit__c();
        mb.Benefit_Product_Group__c = bg.Id;
        insert mb;

        Benefit_Product_Group_Member__c bgm = new Benefit_Product_Group_Member__c();
        bgm.Product__c = product2.Id;
        insert bgm;

        req.httpMethod = 'GET';
        req.requestURI = '/m/benefit/' + mb.Id;

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BenefitRestResource.BenefitWrapper ret = BenefitRestResource.getRecord();
        Test.stopTest();

        System.debug(JSON.serializePretty(ret, true));
        System.assert(ret != null);
        System.assert(ret.benefit !=null);

    }
}