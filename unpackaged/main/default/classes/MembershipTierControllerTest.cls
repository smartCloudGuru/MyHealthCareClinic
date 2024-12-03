/**
 * Created 27.2.2023..
 */

@IsTest
private class MembershipTierControllerTest {

    public static final String tier_name = '2022Sep MHC Premium';
    @TestSetup
    static void dataSetup() {

        Id standardPBid = Test.getStandardPricebookId();

        WorkTypeGroup wtgFree = new WorkTypeGroup(Name = 'WTG Free', Heydoc_Id__c = 'mock_hd_wtg_free_id', Service_Type__c = 'Medical', IsActive = true);
        insert wtgFree;

        WorkType wtFree = new WorkType(Name = 'WT for ' + wtgFree.Name, EstimatedDuration = 40);
        insert wtFree;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtgFree.Id, WorkTypeId = wtFree.Id);
        insert wtgm1;


        // create a membership product with price 0
        Product2 freeProduct = new Product2();
        freeProduct.Name = 'Limited Free Product';
        freeProduct.Work_Type_Group__c = wtgFree.Id;
        insert freeProduct;

        //create a surcharge Product
        Product2 surchargeProduct = new Product2();
        surchargeProduct.Name = 'Surcharge Product';
        surchargeProduct.IsActive = true;
        insert surchargeProduct;

        //make a membership price book
        Pricebook2 memPriceBook = new Pricebook2();
        memPriceBook.IsActive = true;
        memPriceBook.Name = tier_name;
        insert memPriceBook;

        System.debug('PRETEST: STANDARD PriceBookId' + standardPBid);
        System.debug('PRETEST: MEMBER PriceBookId' + memPriceBook.Id);


        //insert standard price for both products
        PricebookEntry pbeStandard = new PricebookEntry();
        pbeStandard.IsActive = true;
        pbeStandard.Product2Id = freeProduct.Id;
        pbeStandard.UnitPrice = 123;
        pbeStandard.Pricebook2Id = standardPBid;
        insert pbeStandard;


        PricebookEntry pbeStandard2 = new PricebookEntry();
        pbeStandard2.IsActive = true;
        pbeStandard2.Product2Id = surchargeProduct.Id;
        pbeStandard2.UnitPrice = 55;
        pbeStandard2.Pricebook2Id = standardPBid;
        insert pbeStandard2;



        //insert membership price for both products
        PricebookEntry pbeMembership = new PricebookEntry();
        pbeMembership.IsActive = true;
        pbeMembership.Product2Id = freeProduct.Id;
        pbeMembership.UnitPrice = 0;
        pbeMembership.Pricebook2Id = memPriceBook.Id;
        insert pbeMembership;

        PricebookEntry pbeMembershipSurcharge = new PricebookEntry();
        pbeMembershipSurcharge.IsActive = true;
        pbeMembershipSurcharge.Product2Id = surchargeProduct.Id;
        pbeMembershipSurcharge.UnitPrice = 55;
        pbeMembershipSurcharge.Pricebook2Id = memPriceBook.Id;
        insert pbeMembershipSurcharge;

        Membership_Tier__c memTier = new Membership_Tier__c();
        memTier.Tier_Level__c = 'Premium';
        memTier.Price_Book__c = memPriceBook.Id;
        memTier.Name = tier_name;
        memTier.Available_From__c = Date.today().addYears(-1);
        insert memTier;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].FirstName = 'DFN';
        accounts[0].LastName = 'DLN';
        accounts[0].Date_of_Birth__c = Date.today().addYears(-20);
        accounts[0].Patient_Type__c = 'Member';
        accounts[0].Membership_Type__c = tier_name;
        accounts[0].Membership_Level__c = 'Adult - Main Payer';
        accounts[0].Membership_Start_Date__c = Date.today().addDays(-7);
        accounts[0].Home_Clinic__c = 'Home';
        accounts[0].Membership_Tier__c = memTier.Id;

        update accounts[0];


    }
    @IsTest
    static void getMembershipTierByName_test() {
        MembershipTierController.MembershipTierWrapper mtw = MembershipTierController.getMembershipTierByName(tier_name);
        System.assert(mtw !=null);
    }

    @IsTest
    static void getMembershipTiers_test() {
        String ret = MembershipTierController.getMembershipTiers();
        System.assert(ret !=null);
    }

    @IsTest
    static void getMembersByMemberId_test() {
        List<Account> accs = MembershipTierController.getMembersByMemberId([SELECT Id FROM Account LIMIT 1].Id);
        System.assert(accs !=null);
    }
}