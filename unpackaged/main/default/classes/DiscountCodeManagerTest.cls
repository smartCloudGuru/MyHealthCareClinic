/**
 * Created by Matija on 27.6.2023..
 */

@IsTest
global class DiscountCodeManagerTest {

    private static final String APPOINTMENTS_STORE = 'Appointments';

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

        Product2 product = new Product2(Name = 'P1', IsActive = true, Available_in_Stores__c = APPOINTMENTS_STORE,
                Include_in_Store__c = true, Appointment__c = true,
                Family = 'GP');
        product.ProductCode = 'P1';
        product.Business_Unit__c = 'GP';
        insert product;

        Product2 product2 = new Product2(Name = 'P2', IsActive = true, Available_in_Stores__c = APPOINTMENTS_STORE,
                Include_in_Store__c = true, Appointment__c = true,
                Family = 'Skin');
        product2.ProductCode = 'P2';
        product2.Business_Unit__c = 'GP';
        insert product2;

        Product2 productBookable = new Product2(Name = 'Bookable', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true, Appointment__c = true);
        productBookable.ProductCode = 'T-P-A';
        productBookable.Store_Categories__c = 'GP Consultation';
        productBookable.Business_Unit__c = 'GP';
        insert productBookable;

        insert new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = productBookable.Id, IsActive = true, UnitPrice = 20);

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
    static void testDiscount_all() {

        Discount_Code__c discount_all = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_all.Name = 'ALL';
        discount_all.Coupon_Code__c = 'ALL';

        insert discount_all;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        List<OnlBookDomain.OptionWrapper> opts = DiscountCodeManager.getDiscountCodesForProduct(p1.Id, null);
        System.assert(opts.size() == 1);

        opts = DiscountCodeManager.getDiscountCodesForProduct(p2.Id, null);
        System.assert(opts.size() == 1);

        discount_all.Valid_for_Stores__c = APPOINTMENTS_STORE;
        update discount_all;
        opts = DiscountCodeManager.getDiscountCodesForProduct(p2.Id, APPOINTMENTS_STORE);
        System.assert(opts.size() == 1);
    }

    @IsTest
    static void testDiscount_forFamily() {

        Discount_Code__c discount_family = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_family.Name = 'FAMILY';
        discount_family.Coupon_Code__c = 'FAMILY';
        discount_family.Product_Family__c = 'GP';

        insert discount_family;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        List<OnlBookDomain.OptionWrapper> opts = DiscountCodeManager.getDiscountCodesForProduct(p1.Id, null);
        System.assert(opts.size() == 1);

        opts = DiscountCodeManager.getDiscountCodesForProduct(p2.Id, null);
        System.assert(opts.size() == 0);

    }

    @IsTest
    static void testDiscount_forProductGroup() {
        Discount_Code__c discount_forGroup = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_forGroup.Name = 'GROUP';
        discount_forGroup.Coupon_Code__c = 'GROUP';
        insert discount_forGroup;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        System.debug('::testDiscount_forProductGroup: T00');
        List<OnlBookDomain.OptionWrapper> opts = DiscountCodeManager.getDiscountCodesForProduct(p1.Id, null);
        System.assert(opts.size() == 1);

        opts = DiscountCodeManager.getDiscountCodesForProduct(p2.Id, null);
        System.assert(opts.size() == 1);

        Discount_Product_Member__c dpm = new Discount_Product_Member__c();
        dpm.Discount_Code__c = discount_forGroup.Id;
        dpm.Product__c = p2.Id;
        insert dpm;

        System.debug('::testDiscount_forProductGroup: T1');
        opts = DiscountCodeManager.getDiscountCodesForProduct(p1.Id, null);
        System.debug('::testDiscount_forProductGroup: T1 : ret : ' + opts);
        System.assert(opts.size() == 0);

        System.debug('::testDiscount_forProductGroup: T2');
        opts = DiscountCodeManager.getDiscountCodesForProduct(p2.Id, null);
        System.debug('::testDiscount_forProductGroup: T2 : ret : ' + opts);
        System.assert(opts.size() == 1);

    }


    @IsTest
    static void testValidate_all() {

        Discount_Code__c discount_all = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_all.Name = 'ALL';
        discount_all.Coupon_Code__c = 'ALL';
        discount_all.Valid_for_Stores__c = APPOINTMENTS_STORE;

        insert discount_all;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        System.debug('::testValidate_all: T3');
        Discount_Code__c ret = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'ALL' , p1.Id, null, null, null);
        System.debug('::testValidate_all: T3 : ret : ' + ret);
        System.assert(ret != null);

        System.debug('::testValidate_all: T4');
        ret = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'ALL',  p2.Id, null, null, null);
        System.debug('::testValidate_all: T4 : ret : ' + ret);
        System.assert(ret != null);
    }

    @IsTest
    static void testValidate_forFamily() {

        Discount_Code__c discount_family = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_family.Name = 'FAMILY';
        discount_family.Coupon_Code__c = 'FAMILY';
        discount_family.Product_Family__c = 'GP';
        discount_family.Valid_for_Stores__c = APPOINTMENTS_STORE;

        insert discount_family;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        System.debug('::testValidate_forFamily: T1');
        Discount_Code__c dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'FAMILY', p1.Id, null, null, null);
        System.debug('::testValidate_forFamily: T1 : ret : ' + dcode);
        System.assert(dcode != null);

        System.debug('::testValidate_forFamily: T2');
        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'FAMILY', p2.Id, null, null, null);
        System.debug('::testValidate_forFamily: T2 : ret : ' + dcode);
        System.assert(dcode == null);

    }

    @IsTest
    static void testValidate_forMaxUsages() {

        Discount_Code__c discount_maxUsages = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_maxUsages.Name = 'MAXUSAGES';
        discount_maxUsages.Coupon_Code__c = 'MAXUSAGES';
        discount_maxUsages.Valid_for_Stores__c = APPOINTMENTS_STORE;

        insert discount_maxUsages;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];

        System.debug('::testValidate_forMaxUsages: T1');
        Discount_Code__c dCode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, discount_maxUsages.Coupon_Code__c, p1.Id, null, null, null);
        System.debug('::testValidate_forMaxUsages: T1 : ret : ' + dCode);
        System.assert(dCode != null);

        discount_maxUsages.Max_Number_of_Usages__c = 0;
        update discount_maxUsages;

        System.debug('::testValidate_forMaxUsages: T2');
        dCode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, discount_maxUsages.Coupon_Code__c, p1.Id, null, null, null);
        System.debug('::testValidate_forMaxUsages: T2 : ret : ' + dCode);
        System.assert(dCode == null);

    }


    @IsTest
    static void testValidate_forProductGroup() {
        Discount_Code__c discount_forGroup = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_forGroup.Name = 'GROUP';
        discount_forGroup.Coupon_Code__c = 'GROUP';
        discount_forGroup.Valid_for_Stores__c = APPOINTMENTS_STORE;

        insert discount_forGroup;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        System.debug('::testValidate_forProductGroup: T00');
        Discount_Code__c dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p1.Id, null, null, null);
        System.assert(dcode != null);

        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p2.Id, null, null, null);
        System.assert(dcode != null);

        Discount_Product_Member__c dpm = new Discount_Product_Member__c();
        dpm.Discount_Code__c = discount_forGroup.Id;
        dpm.Product__c = p2.Id;
        insert dpm;

        System.debug('::testValidate_forProductGroup: T1');
        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p1.Id, null, null, null);
        System.debug('::testValidate_forProductGroup: T1 : ret : ' + dcode);
        System.assert(dcode == null);

        String dcode_st = DiscountCodeManager.aura_validateCoupon('GROUP', APPOINTMENTS_STORE, p1.Id, null, null);
        System.assert(dcode_st == null);

        System.debug('::testValidate_forProductGroup: T2');
        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p2.Id, null, null, null);
        System.debug('::testValidate_forProductGroup: T2 : ret : ' + dcode);
        System.assert(dcode != null);

        dcode_st = DiscountCodeManager.aura_validateCoupon('GROUP', APPOINTMENTS_STORE, p2.Id, null, null);
        System.assert(dcode_st != null);

    }

    @IsTest
    static void testValidate_forProductGroupAndLocation() {
        Discount_Code__c discount_forGroup = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_forGroup.Name = 'GROUP';
        discount_forGroup.Coupon_Code__c = 'GROUP';
        discount_forGroup.Valid_for_Stores__c = APPOINTMENTS_STORE;

        insert discount_forGroup;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        System.debug('::testValidate_forProductGroupAndLocation: T00');
        Discount_Code__c dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p1.Id, null, null, null);
        System.assert(dcode != null);

        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p2.Id, null, null, null);
        System.assert(dcode != null);

        Discount_Product_Member__c dpm = new Discount_Product_Member__c();
        dpm.Discount_Code__c = discount_forGroup.Id;
        dpm.Product__c = p2.Id;
        insert dpm;

        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        Discount_Location_Member__c dlm = new Discount_Location_Member__c();
        dlm.Discount_Code__c = discount_forGroup.Id;
        dlm.Service_Territory__c = st.Id;
        insert dlm;

        ServiceTerritory st2 = new ServiceTerritory();
        st2.Name = 'unit test location 2';
        st2.Heydoc_Id__c = 'test_st_hd_id2';
        st2.IsActive = true;
        st2.OperatingHoursId = [SELECT Id FROM OperatingHours LIMIT 1].Id;
        insert st2;

        System.debug('::testValidate_forProductGroupAndLocation: T1');
        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p1.Id, st2.Id, null, null);
        System.debug('::testValidate_forProductGroup: T1 : ret : ' + dcode);
        System.assert(dcode == null);

        System.debug('::testValidate_forProductGroupAndLocation: T2');
        dcode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, 'GROUP', p2.Id, st.Id, null, null);
        System.debug('::testValidate_forProductGroupAndLocation: T2 : ret : ' + dcode);
        System.assert(dcode != null);

    }

    @IsTest
    static void testValidate_forDateTime() {

        Datetime startTime = Datetime.newInstance(2024, 5, 8, 9, 0, 0);

        OperatingHours oh = new OperatingHours();
        oh.Name = 'TEST OH';
        insert oh;
        TimeSlot ts1 = new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = startTime.format('EEEE'),
                StartTime = Time.newInstance(8, 0, 0, 0),
                EndTime = Time.newInstance(10, 0, 0, 0)
        );
        insert ts1;

        Discount_Code__c discount_forStartTime = new Discount_Code__c();
        discount_forStartTime.Start_date__c = Date.today().addYears(-1);
        discount_forStartTime.End_date__c = Date.today().addYears(1);
        discount_forStartTime.Name = 'STARTTIME';
        discount_forStartTime.Coupon_Code__c = 'STARTTIME';
        discount_forStartTime.Valid_for_Stores__c = APPOINTMENTS_STORE;

        insert discount_forStartTime;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];

        Test.startTest();
        System.debug('::testValidate_forDateTime_T0');
        Discount_Code__c dCode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, discount_forStartTime.Coupon_Code__c, p1.Id, null, null, startTime);
        System.assert(dCode != null);

        System.debug('::testValidate_forDateTime_T1');

        //now add operating hours
        dCode.Applicable_To_Hours__c = oh.Id;
        update dCode;

        dCode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, discount_forStartTime.Coupon_Code__c, p1.Id, null, null, startTime);
        System.assert(dCode != null);

        System.debug('::testValidate_forDateTime_T2');

        ts1.StartTime = Time.newInstance(18, 0, 0, 0);
        ts1.EndTime = Time.newInstance(19, 0, 0, 0);

        update ts1;

        dCode = DiscountCodeManager.validateDiscountCode(APPOINTMENTS_STORE, discount_forStartTime.Coupon_Code__c, p1.Id, null, null, startTime);
        System.assert(dCode == null);

        Test.stopTest();


    }

    @IsTest
    static void doBookWithLimitedDiscount_test() {

        Discount_Code__c discount_all = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_all.Name = 'ALL';
        discount_all.Coupon_Code__c = 'ALL';
        discount_all.Max_Usages_Per_Account_Per_Product__c = 1;
        discount_all.Discount_Amount__c = 5;

        insert discount_all;


        OnlBookUI.BookRequest req = new OnlBookUI.BookRequest();
        req.recordId = [SELECT Id FROM Account LIMIT 1].Id;
        req.productSelected = [SELECT Id FROM Product2 WHERE Name = 'Bookable' LIMIT 1].Id;
        req.resourceSelected = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        req.locationSelected = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        req.reasonForVisit = 'some test';
        req.wtgIdSelected = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        req.discountSelected = discount_all.Id;

        //check that a patient can use a code before booking
        System.assert(DiscountCodeManager.isDiscountAvailableForAccount(req.recordId, req.discountSelected, req.productSelected) == true);


        String ret = OnlBookUI.aura_doBook(JSON.serialize(req));
        System.debug('::doBookWithLimitedDiscount_test:ret:' + ret);
        System.assert(ret != null);
        OnlBookUI.BookResponse resp = (OnlBookUI.BookResponse) JSON.deserialize(ret, OnlBookUI.BookResponse.class);
        System.assert(resp != null);
        System.assert(resp.appId != null);
        System.assert(resp.oppId != null);
        System.assert(resp.quoteId != null);

        List<Opportunity> opps = [SELECT Id, StageName, Patient_comment__c FROM Opportunity WHERE Id = :resp.oppId];
        System.assert(!opps.isEmpty());
        System.assert(opps.get(0).StageName == 'Qualification');
        System.assert(opps.get(0).Patient_comment__c != null);

        String checkResp = OnlBookUI.checkQuoteCalculated(resp.quoteId, resp.appId);
        System.assert(checkResp != null);

        OnlBookUI.CheckQuoteResponse cqr = (OnlBookUI.CheckQuoteResponse) JSON.deserialize(checkResp, OnlBookUI.CheckQuoteResponse.class);
        System.assert(cqr != null);
        System.assert(cqr.amount != null);
        System.assert(cqr.quoteCalculated != null);

        System.assert(resp.oppId == OnlBookUI.closeOpportunity(resp.oppId, false));
        System.assert(null != OnlBookUI.aura_closeAndGetOpportunity(resp.oppId, false));

        OnlBookUI.closeOpportunityIfPaymentPaid(resp.oppId);
        OnlBookUI.aura_closeAndGetOpportunityIfPaymentPaid(resp.oppId);

        List<Discount_Code_Usage__c> usages = [
                SELECT Id, Opportunity__r.Name, Opportunity__r.Account.Name, Discount_Code__r.Name, Product__r.Name
                FROM Discount_Code_Usage__c
        ];

        System.debug('::doBookWithLimitedDiscount_test:usages:' + usages);

        //check that a patient can not use a this limited code after booking
        System.assert(DiscountCodeManager.isDiscountAvailableForAccount(req.recordId, req.discountSelected, req.productSelected) == false);

    }

    @IsTest
    static void testNewAuraHandledException() {
        DiscountCodeManager.newAuraHandledException('test');
    }

    @IsTest
    static void aura_getDiscountCodes() {

        Discount_Code__c discount_forGroup = new Discount_Code__c(Start_date__c = Date.today().addYears(-1), End_date__c = Date.today().addYears(1));
        discount_forGroup.Name = 'GROUP';
        discount_forGroup.Coupon_Code__c = 'GROUP';
        insert discount_forGroup;

        Product2 p1 = [SELECT Id FROM Product2 WHERE Name = 'P1' LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 WHERE Name = 'P2' LIMIT 1];

        System.debug('::testDiscount_forProductGroup: T00');
        List<OnlBookDomain.OptionWrapper> opts = DiscountCodeManager.getDiscountCodesForProduct(p1.Id, null);
        System.assert(opts.size() == 1);

        opts = DiscountCodeManager.getDiscountCodesForProduct(p2.Id, null);
        System.assert(opts.size() == 1);

        Discount_Product_Member__c dpm = new Discount_Product_Member__c();
        dpm.Discount_Code__c = discount_forGroup.Id;
        dpm.Product__c = p2.Id;
        insert dpm;

        System.debug(DiscountCodeManager.aura_getDiscountCodes(p1.Id, null, null, null));
    }
}