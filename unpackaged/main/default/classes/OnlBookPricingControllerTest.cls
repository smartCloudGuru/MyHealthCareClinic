/**
 * Created by Matija on 28.11.2023..
 */

@IsTest
global class OnlBookPricingControllerTest {

    @TestSetup
    static void dataSetup() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';
        update accounts[0];

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical', IsActive = true, Appointment_Type__c = 'CLINIC');
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        Product2 product = new Product2(Name = 'GP 1', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true, Appointment__c = true);
        product.ProductCode = 'T-P-A';
        product.Store_Categories__c = 'GP Consultation';
        product.Business_Unit__c = 'GP';
        insert product;

        insert new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product.Id, IsActive = true, UnitPrice = 10);

        OperatingHours oh1 = new OperatingHours();
        oh1.Name = 'test Opening Hours';
        insert oh1;

        ServiceTerritory st1 = new ServiceTerritory();
        st1.Name = 'unit test location';
        st1.Heydoc_Id__c = 'test_st_hd_id';
        st1.IsActive = true;
        st1.OperatingHoursId = oh1.Id;
        insert st1;

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;

        ServiceTerritoryWorkType stwt = new ServiceTerritoryWorkType(ServiceTerritoryId = st1.Id, WorkTypeId = wt1.Id);
        insert stwt;

    }

    @IsTest
    static void surchargeMembershipProduct_Test() {
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
        memPriceBook.Name = '2022Sep MHC Premium';
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

        System.debug('PRETEST: ADDED pbeMembershipSurcharge' + JSON.serializePretty(pbeMembershipSurcharge, true));

        // create a membership Ter
        Membership_Tier__c memTier = new Membership_Tier__c();
        memTier.Tier_Level__c = 'Premium';
        memTier.Price_Book__c = memPriceBook.Id;
        memTier.Name = '2022 premium mem tier';
        memTier.Available_From__c = Date.today().addYears(-1);
        insert memTier;


        //create account member
        Account acc = new Account();
        acc.Date_of_Birth__c = Date.today().addYears(-44);
        acc.FirstName = 'MemberTest';
        acc.LastName = 'MemberTest';
        acc.Membership_Tier__c = memTier.Id;
        acc.Membership_Level__c = 'Adult - Main Payer';
        acc.Patient_Type__c = 'Member';
        acc.Member_Status__c = 'Member';

        acc.Membership_Start_Date__c = Date.today().addMonths(-10);
        acc.Home_Clinic__c = 'Fulham';
        insert acc;

        Contract contract = new Contract();
        contract.StartDate = Date.today();
        contract.AccountId = acc.Id;
        insert contract;

        Membership_Contract__c membershipContract = new Membership_Contract__c();
        membershipContract.Membership_Tier__c = memTier.Id;
        membershipContract.Contract__c = contract.Id;
        insert membershipContract;

        acc.Membership_Contract__c = membershipContract.Id;
        update acc;

        String groupToTest = 'Dental Examinations';

        // create a surcharge object
        OutOfMembership_Surcharge__c ooms = new OutOfMembership_Surcharge__c();
        ooms.Surcharge_Product__c = surchargeProduct.Id;
        ooms.Product__c = freeProduct.Id;
        ooms.Max_Free__c = 1;
        ooms.Membership_Tier_Level__c = 'Premium';
        ooms.Benefit_Group__c = groupToTest;

        insert ooms;

        //// TEST 1
        ///////////////////////
        System.debug('::surchargeMembershipProduct: TEST_1');
        // this should be free since there are no appointments before and we have 1 free
        OnlBookPricingController.OOMSurchargeCalcResponse oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, freeProduct.Id, Date.today());
        System.debug('::surchargeMembershipProduct_TEST_1:oomResp:' + JSON.serializePretty(oomResp));
        System.assert(oomResp!=null);
        System.assert(oomResp.surchargeData!=null);
        System.assert(oomResp.surchargeData.spentFree==0);
        System.assert(oomResp.surchargeData.pricebookEntry==null);
        System.assert(oomResp.surchargeData.maxFree==1);
        System.assert(oomResp.membershipBenefitCounter == groupToTest);

        //// TEST 2
        ///////////////////////
        // now let's put max free to 0, and try again
        System.debug('::surchargeMembershipProduct: TEST_2');
        ooms.Max_Free__c = 0;
        update ooms;
        oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, freeProduct.Id, Date.today());
        System.debug('::surchargeMembershipProduct_TEST_2:oomResp:' + JSON.serializePretty(oomResp));
        System.assert(oomResp.surchargeData.spentFree==0);
        System.assert(oomResp.surchargeData.pricebookEntry!=null);
        System.assert(oomResp.surchargeData.maxFree==0);
        System.assert(oomResp.membershipBenefitCounter == groupToTest);

        //// TEST 3
        ///////////////////////
        // now let's put max free to 2, and create 1 existing appointment, but within last 6 months
        System.debug('::surchargeMembershipProduct: TEST_3');
        ooms.Max_Free__c = 2;
        update ooms;

        Opportunity opp1 = new Opportunity();
        opp1.Amount = 0;
        opp1.StageName = 'Closed Won';
        opp1.CloseDate = Date.today();
        opp1.Name = 'test opp';
        insert opp1;

        ServiceAppointment sa1 = new ServiceAppointment();
        sa1.SchedStartTime = Datetime.now().addDays(-1);
        sa1.Treatment__c = opp1.Id;
        sa1.WorkTypeId = wtFree.Id;
        sa1.ParentRecordId = acc.Id;
        sa1.Membership_Benefit_Counter__c = groupToTest;
        insert sa1;

        oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, freeProduct.Id, Date.today());
        System.debug('::surchargeMembershipProduct_TEST_3:oomResp:' + JSON.serializePretty(oomResp));
        System.assert(oomResp.surchargeData!=null);
        System.assert(oomResp.surchargeData.spentFree==1);
        System.assert(oomResp.surchargeData.pricebookEntry!=null);
        System.assert(oomResp.surchargeData.maxFree==2);
        System.assert(oomResp.surchargeData.nextFreeDate!=null);
        System.assert(oomResp.membershipBenefitCounter == groupToTest);

        //// TEST 4
        ///////////////////////
        // now let's put max free to 2, and create 1 existing appointment, but more than 6 months ago
        System.debug('::surchargeMembershipProduct: TEST_4');

        sa1.SchedStartTime = Datetime.now().addMonths(-6);
        update sa1;

        oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, freeProduct.Id, Date.today());
        System.debug('::surchargeMembershipProduct_TEST_4:oomResp:' + JSON.serializePretty(oomResp));
        System.assert(oomResp.surchargeData!=null);
        System.assert(oomResp.surchargeData.spentFree==1);
        System.assert(oomResp.surchargeData.pricebookEntry==null);
        System.assert(oomResp.surchargeData.maxFree==2);
        System.assert(oomResp.surchargeData.nextFreeDate==null);
        System.assert(oomResp.membershipBenefitCounter == groupToTest);

        //// TEST 5
        ///////////////////////
        // now let's put max free to 2, and have 2 existing appointments, but more than 6 months ago, so that we go out of max limits
        System.debug('::surchargeMembershipProduct: TEST_4');

        Opportunity opp2 = new Opportunity();
        opp2.Amount = 0;
        opp2.StageName = 'Closed Won';
        opp2.CloseDate = Date.today();
        opp2.Name = 'test opp';
        insert opp2;

        ServiceAppointment sa2= new ServiceAppointment();
        sa2.SchedStartTime = Datetime.now().addMonths(-6).addDays(-1);
        sa2.Treatment__c = opp2.Id;
        sa2.WorkTypeId = wtFree.Id;
        sa2.ParentRecordId = acc.Id;
        sa2.Membership_Benefit_Counter__c = groupToTest;
        insert sa2;

        oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, freeProduct.Id, Date.today());
        System.debug('::surchargeMembershipProduct_TEST_4:oomResp:' + JSON.serializePretty(oomResp));
        System.assert(oomResp.surchargeData!=null);
        System.assert(oomResp.surchargeData.spentFree==2);
        System.assert(oomResp.surchargeData.pricebookEntry!=null);
        System.assert(oomResp.surchargeData.maxFree==2);
        System.assert(oomResp.surchargeData.nextFreeDate==null);
        System.assert(oomResp.surchargeData.lastBookedDate!=null);
        System.assert(oomResp.membershipBenefitCounter == groupToTest);

        //// TEST 6
        ///////////////////////
        // now move the second appointment closer to today, but move max free to 3 (still should charge surcharge)
        System.debug('::surchargeMembershipProduct: TEST_5');
        ooms.Max_Free__c = 3;
        update ooms;
        sa2.SchedStartTime = Datetime.now().addMonths(-1).addDays(-1);
        update sa2;

        oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, freeProduct.Id, Date.today());
        System.debug('::surchargeMembershipProduct_TEST_4:oomResp:' + JSON.serializePretty(oomResp));
        System.assert(oomResp.surchargeData!=null);
        System.assert(oomResp.surchargeData.spentFree==2);
        System.assert(oomResp.surchargeData.pricebookEntry!=null);
        System.assert(oomResp.surchargeData.maxFree==3);
        System.assert(oomResp.surchargeData.nextFreeDate!=null);
        System.assert(oomResp.surchargeData.lastBookedDate!=null);
        System.assert(oomResp.membershipBenefitCounter == groupToTest);



    }

}