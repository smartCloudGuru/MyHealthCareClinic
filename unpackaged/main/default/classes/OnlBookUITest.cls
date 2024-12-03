/**
 * Created 3.6.2022..
 */

@IsTest
global class OnlBookUITest {
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
    static void getWorkTypeIdForLocationAndWTGroup_test() {
        String workTypeId = OnlBookUI.getWorkTypeIdForLocationAndWTGroup(
                [SELECT Id FROM ServiceTerritory LIMIT 1].Id,
                [SELECT Id FROM WorkTypeGroup LIMIT 1].Id
        );
        System.debug('::getWorkTypeIdForLocationAndWTGroup_test:workTypeId:' + workTypeId);
        System.assert(workTypeId != null);
        String knownWorkTypeId = [SELECT Id FROM WorkType LIMIT 1].Id;
        System.debug('::getWorkTypeIdForLocationAndWTGroup_test:knownWorkTypeId:' + knownWorkTypeId);
        System.assert(workTypeId == [SELECT Id FROM WorkType LIMIT 1].Id);

    }

    @IsTest
    static void getMedicalProducts_test() {

        List<OnlBookUI.OptionWrapper> med_products = (List<OnlBookUI.OptionWrapper>) JSON.deserialize(OnlBookUI.getMedicalProducts(), List<OnlBookUI.OptionWrapper>.class);
        System.assert(med_products.size() == 1);
        System.assert(med_products.get(0).label == 'GP 1');
    }

    @IsTest
    static void getDentalProducts_test() {

        List<OnlBookUI.OptionWrapper> dent_products = (List<OnlBookUI.OptionWrapper>) JSON.deserialize(OnlBookUI.getDentalProducts(), List<OnlBookUI.OptionWrapper>.class);
        //System.assert(med_products.size() == 1);
        //System.assert(med_products.get(0).label == 'GP 1');
    }

    @IsTest
    static void getAppointmentProducts_test() {

        List<OnlBookUI.OptionWrapper> app_products = (List<OnlBookUI.OptionWrapper>) JSON.deserialize(OnlBookUI.getAppointmentProducts(), List<OnlBookUI.OptionWrapper>.class);
        System.assert(app_products.size() > 0);
    }

    @IsTest
    static void getProducts_test() {

        OnlBookUI.ProductFilter filter = new OnlBookUI.ProductFilter();
        filter.wtgServiceType = 'Medical';
        filter.storeName = 'Appointments';
        String ret = OnlBookUI.getProducts(JSON.serialize(filter));
        System.debug('::getProducts_test:ret:' + ret);
        List<OnlBookUI.ProductWrapper> products =
                (List<OnlBookUI.ProductWrapper>) JSON.deserialize(ret, List<OnlBookUI.ProductWrapper>.class);
        System.assert(products.size() == 1);
        System.assert(products.get(0).product.Name == 'GP 1');
    }


    @IsTest
    static void getWTGForProduct_test() {

        Product2 product = [SELECT Id, Work_Type_Group__c FROM Product2 LIMIT 1];
        System.assert(OnlBookUI.getWTGForProduct(product.Id) == product.Work_Type_Group__c);
    }

    @IsTest
    static void getServiceCentersForWTG_test() {

        WorkTypeGroup wtg = [SELECT Id FROM WorkTypeGroup LIMIT 1];
        List<ServiceTerritory> sts = OnlBookUI.getServiceCentersForWTG(wtg.Id);
        System.debug('::getServiceCentersForWTG_test:sts:' + sts);
        System.assert(sts.size() == 1);

        String ret = OnlBookUI.getServiceCentersForWTGAsJSON(wtg.Id);
        System.assert(ret.length() > 2);
    }

    @IsTest
    static void getServiceCentersForProduct_test() {

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        List<ServiceTerritory> sts = OnlBookUI.getServiceCentersForProduct(product.Id);
        System.debug('::getServiceCentersForProduct_test:sts:' + sts);
        System.assert(sts.size() == 1);
    }

    @IsTest
    static void getAllServiceResources_test() {

        List<ServiceTerritory> srs = (List<ServiceTerritory>) JSON.deserialize(OnlBookUI.getAllServiceResources(), List<ServiceTerritory>.class);
        System.debug('::getAllServiceResources_test:sts:' + srs);
        System.assert(srs.size() == 1);
    }

    @IsTest
    static void checkAccountLogin_test() {
        System.assert(OnlBookUI.checkAccountLogin('emai@example.com', 'pass') != null);
        System.assert(OnlBookUI.checkAccountLogin('emai@example.com', 'wrong') == null);
        System.assert(OnlBookUI.checkAccountLoginWithDOB('emai@example.com', Date.today()) == null);
        System.assert(OnlBookUI.checkAccountLoginWithConnectedAccounts('emai@example.com', 'pass') != null);
    }

    @IsTest
    static void findAccountByEmail_test() {
        System.assert(OnlBookUI.findAccountByEmail('emai@example.com') != null);
        System.assert(OnlBookUI.findAccountByEmail('nosuchemai@example.com') == null);
    }

    @IsTest
    static void getMedicalServiceResourcesIds_test() {

        Set<Id> ret = OnlBookUI.getMedicalServiceResourcesIds();
    }

    @IsTest
    static void getServiceResourcesForTerritory_test() {

        System.assert(OnlBookUI.getServiceResourcesForTerritory([SELECT Id FROM ServiceTerritory LIMIT 1].Id) != null);
    }

    @IsTest
    static void getServiceResourcesForTerritoryWithWTId_test() {

        System.assert(OnlBookUI.getServiceResourcesForTerritoryAndWorkTypeSkill([SELECT Id FROM ServiceTerritory LIMIT 1].Id, [SELECT Id FROM WorkType LIMIT 1].Id) != null);
    }

    @IsTest
    static void getAvailableSlotsByWorkTypeGroup_test() {

        String workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        String serviceCenterId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Date slotDate = Date.today();

        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest.onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        Test.startTest();
        OnlBookDomain.TimeSlotsResponse tsr = (OnlBookDomain.TimeSlotsResponse) JSON.deserialize(OnlBookUI.aura_getAvailableSlotsByWorkTypeGroup(
                workTypeGroupId, serviceCenterId, slotDate, false
        ), OnlBookDomain.TimeSlotsResponse.class);

        OnlBookDomain.TimeSlotsResponse tsr2 = (OnlBookDomain.TimeSlotsResponse) JSON.deserialize(OnlBookUI.getAvailableSlotsByWorkTypeGroup(
                workTypeGroupId, serviceCenterId, slotDate
        ), OnlBookDomain.TimeSlotsResponse.class);
        Test.stopTest();
        System.debug('::getAvailableSlotsByWorkTypeGroup:tsr:' + tsr);
        System.assert(tsr.territorySlots != null);
    }


    @IsTest
    static void getAvailableSlotsByWorkTypeGroup2_test() {

        String workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        String serviceCenterId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Date slotDate = Date.today();

        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest.onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        Test.startTest();
        OnlBookDomain.TimeSlotsResponse tsr = (OnlBookDomain.TimeSlotsResponse) JSON.deserialize(OnlBookUI.getAvailableSlotsByWorkTypeGroup(
                workTypeGroupId, serviceCenterId, slotDate
        ), OnlBookDomain.TimeSlotsResponse.class);
        Test.stopTest();
        System.debug('::getAvailableSlotsByWorkTypeGroup:tsr:' + tsr);
        System.assert(tsr.territorySlots != null);
    }


    @IsTest
    static void doBook_test() {

        OnlBookUI.BookRequest req = new OnlBookUI.BookRequest();
        req.recordId = [SELECT Id FROM Account LIMIT 1].Id;
        req.productSelected = [SELECT Id FROM Product2 LIMIT 1].Id;
        req.resourceSelected = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        req.locationSelected = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        req.reasonForVisit = 'some test';
        req.wtgIdSelected = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;


        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        String referAFriendCode = [SELECT ID, ReferFriendCode__c FROM Account WHERE Id =:accounts[0].Id].ReferFriendCode__c;
        req.discountName = referAFriendCode;

        String ret = OnlBookUI.aura_doBook(JSON.serialize(req));
        System.debug('::doBook_test:ret:' + ret);
        System.assert(ret != null);
        OnlBookUI.BookResponse resp = (OnlBookUI.BookResponse) JSON.deserialize(ret, OnlBookUI.BookResponse.class);
        System.assert(resp != null);
        System.assert(resp.appId != null);
        System.assert(resp.oppId != null);
        System.assert(resp.quoteId != null);

        ServiceAppointment sa = [SELECT Id, WorkTypeId FROM ServiceAppointment WHERE Id = :resp.appId];

        System.debug('::doBook_test:sa:' + JSON.serializePretty(sa));


        List<Opportunity> opps = [SELECT Id, StageName, Patient_comment__c, Referred_By_Account__c FROM Opportunity WHERE Id = :resp.oppId];
        System.assert(!opps.isEmpty());
        System.assert(opps.get(0).StageName == 'Qualification');
        System.debug('::DBG:PTC:' + opps[0]);
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

        List<Lead> leads = [SELECT Id, Business_Unit__c FROM Lead];

        System.assert(!leads.isEmpty());
        System.assert(leads[0].Business_Unit__c == 'GP');

    }

    @IsTest
    static void doBookWithExistingLead_test() {
        OnlBookUI.BookRequest req = new OnlBookUI.BookRequest();
        req.recordId = [SELECT Id FROM Account LIMIT 1].Id;
        req.productSelected = [SELECT Id FROM Product2 LIMIT 1].Id;
        req.resourceSelected = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        req.locationSelected = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        req.reasonForVisit = 'some test';
        req.wtgIdSelected = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;

        Lead existingLead = new Lead();
        existingLead.FirstName = 'TestF';
        existingLead.LastName = 'TestL';
        insert existingLead;

        req.existingLeadId = existingLead.Id;

        String ret = OnlBookUI.aura_doBook(JSON.serialize(req));
        System.debug('::doBook_test:ret:' + ret);
        System.assert(ret != null);
        OnlBookUI.BookResponse resp = (OnlBookUI.BookResponse) JSON.deserialize(ret, OnlBookUI.BookResponse.class);
        System.assert(resp != null);
        System.assert(resp.appId != null);
        System.assert(resp.oppId != null);
        System.assert(resp.quoteId != null);

        ServiceAppointment sa = [SELECT Id, WorkTypeId FROM ServiceAppointment WHERE Id = :resp.appId];

        System.debug('::doBook_test:sa:' + JSON.serializePretty(sa));

        List<Opportunity> opps = [SELECT Id, StageName, Patient_comment__c FROM Opportunity WHERE Id = :resp.oppId];
        System.assert(!opps.isEmpty());
        System.assert(opps.get(0).StageName == 'Qualification');
        System.debug('::DBG:PTC:' + opps[0]);
        System.assert(opps.get (0).Patient_comment__c != null);


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

        List<Lead> leads = [SELECT Id, Business_Unit__c, IsConverted FROM Lead WHERE Id = :existingLead.Id];

        System.assert(!leads.isEmpty());
        System.assert(leads[0].Business_Unit__c == 'GP');
        System.assert(leads[0].IsConverted);

    }

    @IsTest
    static void doGetHTTPRequest_test() {
        OnlBookUI.getHTTPRequest('https://example.com', 'sessionid', 'GET');
    }

    @IsTest
    static void doBookByProxy_test() {
        try {
            OnlBookUI.doBookByProxy(null);
        }
        catch (Exception ignore) {

        }
    }

    @IsTest
    static void getSpecialInstructionsForProduct_test() {
        OnlBookUI.getSpecialInstructionsForProduct([SELECT Id FROM Product2 LIMIT 1].Id);
    }

    @IsTest
    static void newAuraHandledExceptiont_test() {
        System.assert(OnlBookUI.newAuraHandledException('test') != null);
    }
    @IsTest
    static void doSimpleReservation_test() {
        try {
            OnlBookUI.BookRequest req = new OnlBookUI.BookRequest();
            req.productSelected = [SELECT Id FROM Product2 LIMIT 1].Id;
            OnlBookUI.doSimpleReservation(JSON.serialize(req));
        }
        catch (Exception ignore) {

        }
    }

    @IsTest
    static void registerAndLogin_test() {

        OnlBookUI.RegisterRequest req = new OnlBookUI.RegisterRequest();
        req.firstName = 'fn';
        req.lastName = 'ln';
        req.dob = Date.today();
        req.email = 'unittest13209@example.com';
        req.phone = '123123123';
        System.assert(OnlBookUI.registerAndLogin(JSON.serialize(req)) != null);
    }

    @IsTest
    static void changePassword_test() {
        try {
            OnlBookUI.changePassword(null, null, null);
        }
        catch (MHCException ignore) {
        }
        catch (AuraHandledException ignore) {
        }
        catch (Exception ignore) {
        }

        String code = new Uuid().getValue().replaceAll('-', '');
        Account acc = [SELECT Id, PersonEmail FROM Account LIMIT 1];
        Patient_Password_Change__c ppc = new Patient_Password_Change__c();
        ppc.UUID__c = code;
        ppc.Patient__c = acc.Id;
        insert ppc;

        System.assert(OnlBookUI.changePassword(code, acc.PersonEmail, '123') == true);
        acc = [SELECT Id, PersonEmail, Store_password__c FROM Account WHERE Id = :acc.Id LIMIT 1];
        System.assert(acc.Store_password__c == '123');

    }

    @IsTest
    static void queuePassChange_test() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.PersonEmail = 'test@example.com';
        acc.Store_password__c = '123';
        update acc;
        try {
            OnlBookUI.queuePassChange('test@example.com');
            System.assert([SELECT Id FROM Patient_Password_Change__c].size() > 0);
        }
        catch (qsyd_InvocableEmailBase.InvocableEmailException e) {
            //ignore
        }
    }


    @IsTest
    static void queueRegister_activateRegistration_test() {
        OnlBookUI.RegisterRequest req = new OnlBookUI.RegisterRequest();
        req.password = '123';
        req.lastName = 'Last Name';
        OnlBookUI.queueRegister(JSON.serialize(req));

        Patient_Registration_Request__c prr = [SELECT Id, Request_Hash__c, UUId__c FROM Patient_Registration_Request__c LIMIT 1];

        OnlBookUI.activateRegistration(prr.UUId__c, prr.Request_Hash__c);
    }

    @IsTest
    static void queueRegister_activateRegistrationByCode_test() {
        OnlBookUI.RegisterRequest req = new OnlBookUI.RegisterRequest();
        req.password = '123';
        req.email = 'e@example.com';
        req.lastName = 'Last Name';
        req.gender = 'Female';

        OnlBookUI.queueRegister(JSON.serialize(req));

        Patient_Registration_Request__c prr = [SELECT Id, Request_Hash__c, UUId__c, Activation_Code__c FROM Patient_Registration_Request__c LIMIT 1];

        String uid = OnlBookUI.activateRegistrationByCode(req.email, prr.Activation_Code__c);

        System.assert(uid != null);

        Account acc = [SELECT Id, PersonEmail, Gender__c FROM Account WHERE Store_UUID__c = :uid];
        System.debug(JSON.serializePretty(acc));

        System.assert(acc.PersonEmail == req.email);
        System.assert(acc.Gender__c == req.gender);

    }

    @IsTest
    static void findAccountsByEmail_test() {
        OnlBookUI.findAccountsByEmail('10');
    }

    @IsTest
    static void findAccountsByEmailAndDob_test() {
        OnlBookUI.findAccountByEmailAndDob('10', Date.today());
    }

    @IsTest
    static void findAccountsByEmailOfAccount_test() {
        Account acc = [SELECT Id, Store_UUID__c FROM Account LIMIT 1];
        acc.Store_UUID__c = 'to_find';
        update acc;
        System.assert(OnlBookUI.findAccountsByEmailOfAccount('to_find') != null);
    }

    @IsTest
    static void validateRegistrationRequest_test() {
        OnlBookUI.validateRegistrationRequest('10test11@example.com', Date.today());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        acc.PersonEmail = '10test11@example.com';
        acc.Store_password__c = '123';
        acc.Date_of_Birth__c = Date.newInstance(1970, 1, 1);
        update acc;
        try {
            OnlBookUI.validateRegistrationRequest('10test11@example.com', Date.today());
        }
        catch (MHCException ignore) {
        }
        catch (Exception ignore) {
        }
        try {
            OnlBookUI.validateRegistrationRequest('10test11@example.com', Date.newInstance(1970, 1, 1));
        }
        catch (MHCException ignore) {
        }
        catch (Exception ignore) {
        }

        acc.Store_password__c = null;
        update acc;
        try {
            OnlBookUI.validateRegistrationRequest('10test11@example.com', Date.today());
        }
        catch (MHCException ignore) {
        }
        catch (Exception ignore) {
        }
        try {
            OnlBookUI.validateRegistrationRequest('10test11@example.com', Date.newInstance(1970, 1, 1));
        }
        catch (MHCException ignore) {
        }
        catch (Exception ignore) {
        }
    }

    //    @IsTest
    //    static void aura_getEarliestFreeSlotsForProduct_test() {
    //        Map<String, MockConfig> mockConfigs = new Map<String, MockConfig>{
    //                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
    //                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
    //                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false)
    //        };
    //
    //
    //        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));
    //        Test.startTest();
    //        try {
    //            OnlBookUI.aura_getEarliestFreeSlotsForProduct([SELECT Id FROM Product2 LIMIT 1].Id);
    //        }
    //        catch (Exception ignore) {
    //        }
    //        Test.stopTest();
    //    }

    //    @IsTest
    //    static void aura_aura_getNextFreeSlotsForProduct_test() {
    //        Map<String, MockConfig> mockConfigs = new Map<String, MockConfig>{
    //                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
    //                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
    //                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false)
    //        };
    //
    //
    //        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));
    //        Test.startTest();
    //        try {
    //            OnlBookUI.aura_getNextFreeSlotsForProduct(
    //                    [SELECT Id FROM Product2 LIMIT 1].Id,
    //                    Date.today(),
    //                    null,
    //                    3
    //            );
    //        }
    //        catch (Exception ignore) {
    //        }
    //        Test.stopTest();
    //    }

    @IsTest
    static void getServiceCentersWithHeydocId_test() {
        List<ServiceTerritory> sts = (List<ServiceTerritory>) (JSON.deserialize(OnlBookUI.getServiceCentersWithHeydocId(), List<ServiceTerritory>.class));
        System.assert(sts.size() > 0);
    }

    //    @IsTest
    //    static void storeOnlineSession_test() {
    //        String retSessionId = OnlBookUI.storeOnlineSession('context', 'store', 'details');
    //        System.assert(retSessionId != null);
    //        String loaded = OnlBookUI.loadOnlineSession(retSessionId);
    //        System.assert(loaded == 'context');
    //        loaded = OnlBookUI.loadOnlineSession('nosession');
    //        System.assert(loaded == null);
    //    }

    @IsTest
    static void checkPassCodeValidity_test() {
        OnlBookUI.checkPassCodeValidity('code', 'email');
    }


    global class MockConfig {
        public String body;
        public String status;
        public Integer code;
        public Boolean throwException;

        public MockConfig(
                String body,
                String status,
                Integer code,
                Boolean throwException
        ) {
            this.body = body;
            this.status = status;
            this.code = code;
            this.throwException = throwException;
        }
    }

    global class onl_CheckoutCtrlTest_ServiceMock implements HttpCalloutMock {

        public Map<String, MockConfig> mockConfigs;

        global onl_CheckoutCtrlTest_ServiceMock(Map<String, MockConfig> mockConfigs) {
            this.mockConfigs = mockConfigs;
        }

        global HttpResponse respond(HttpRequest req) {
            for (String str : mockConfigs.keySet()) {
                if (req.getEndpoint().contains(str)) {
                    MockConfig mConfig = mockConfigs.get (str);
                    if (mConfig.throwException) {
                        Integer divideByZero = 2 / 0;
                    }
                    HttpResponse res = new HttpResponse();

                    System.assert(req != null);
                    //			System.assertEquals(method, req.getMethod());
                    res.setBody(mConfig.body);
                    res.setStatusCode(mConfig.code);
                    res.setStatus(mConfig.status);
                    return res;
                }
            }
            return null;

        }
    }

    @IsTest
    static void aura_getPatientType_test() {
        System.assert('New' == OnlBookUI.aura_getPatientType([SELECT Id FROM Account LIMIT 1].Id));
    }

    @IsTest
    static void getRandomString_test() {
        System.assert(OnlBookUI.getRandomString(5).length() == 5);
    }

    @IsTest
    static void cProductWrapper_test() {
        OnlBookUI.ProductWrapper pw1 = new OnlBookUI.ProductWrapper();
        OnlBookUI.ProductWrapper pw2 = new OnlBookUI.ProductWrapper(null, 0, null);
    }

    @IsTest
    static void getContactIdForUUID() {
        Account acc = [SELECT Id, Store_UUID__c FROM Account LIMIT 1];
        acc.Store_UUID__c = 'to_find';
        update acc;
        System.debug(OnlBookUI.getContactIdForUUID(acc.Store_UUID__c));
    }


    @IsTest
    static void getAvailableCategories_Test() {

        String cats = OnlBookUI.getAvailableCategories('Appointments', null);
        System.assert(cats != null);
        Set<String> ret = (Set<String>) JSON.deserialize(cats, Set<String>.class);
        System.assert(ret.size() > 0);

    }

    @IsTest
    static void aura_findProductForDirect_Test() {
        Product2 p = [SELECT Id, ProductCode, Available_in_Stores__c FROM Product2 LIMIT 1];
        OnlBookUI.aura_findProductForDirect(p.ProductCode, p.Available_in_Stores__c);
    }

    @IsTest
    static void ctor_OptionWrapper_Test() {
        OnlBookUI.OptionWrapper ow = new OnlBookUI.OptionWrapper(null, null, null, null);
    }


//    @IsTest
//    static void getPPBEForAccountAndProductAndDate_NonMember_Test() {
//        Account acc = [SELECT Id FROM Account LIMIT 1];
//        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
//        PricebookEntry defaultPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product.Id LIMIT 1];
//        Date dte = Date.today();
//
//        System.assert(acc != null);
//        System.assert(product != null);
//        System.assert(defaultPBE != null);
//
//        //default, non-member, no promotions
//
//        System.debug('::------------ T1');
//        PricebookEntry pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//        //add a Promotion
//        Period_Promotion__c ppromo = new Period_Promotion__c(
//                Name = 'Test',
//                Appointments_Start_Date__c = Date.today().addDays(-1),
//                Appointments_End_Date__c = Date.today().addDays(1)
//        );
//
//        insert ppromo;
//
//        System.debug('::------------ T2');
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//        // make a new PB
//
//        System.debug('::------------ T3');
//        Pricebook2 pbNonMemberPromotion = new Pricebook2(IsActive = true, Name = 'NonMember Promotion');
//        insert pbNonMemberPromotion;
//
//        ppromo.NonMember_Price_Book__c = pbNonMemberPromotion.Id;
//        update ppromo;
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//        // make a new PBEntry
//
//        System.debug('::------------ T4');
//        PricebookEntry pbeNonMemberPromotion = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = pbNonMemberPromotion.Id, UnitPrice = 1);
//        insert pbeNonMemberPromotion;
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == pbeNonMemberPromotion.Id);
//
//    }

//    @IsTest
//    static void periodPromotionsWithDiscountCode_Test() {
//        Account acc = [SELECT Id FROM Account LIMIT 1];
//        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
//        PricebookEntry defaultPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product.Id LIMIT 1];
//        Date dte = Date.today();
//
//        System.assert(acc != null);
//        System.assert(product != null);
//        System.assert(defaultPBE != null);
//
//        Discount_Code__c dCode = new Discount_Code__c();
//        dCode.Coupon_Code__c = 'BLACKFRIDAY23';
//        dCode.Start_date__c = Date.today().addDays(-1);
//        dCode.End_date__c = Date.today().addDays(2);
//        dCode.Name = 'Test black friday 2023 thing';
//        dCode.Discount_Amount__c = 0;
//        insert dCode;
//
//
//        //default, non-member, no promotions
//
//        System.debug('::------------ T1');
//        PricebookEntry pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//        //add a Promotion
//        Period_Promotion__c ppromo = new Period_Promotion__c(
//                Name = 'Test',
//                Appointments_Start_Date__c = Date.today().addDays(-1),
//                Appointments_End_Date__c = Date.today().addDays(1)
//        );
//
//        insert ppromo;
//
//        System.debug('::------------ T2');
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//        // make a new PB
//
//        System.debug('::------------ T3');
//        Pricebook2 pbNonMemberPromotion = new Pricebook2(IsActive = true, Name = 'NonMember Promotion');
//        insert pbNonMemberPromotion;
//
//        ppromo.NonMember_Price_Book__c = pbNonMemberPromotion.Id;
//        update ppromo;
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//        // make a new PBEntry
//
//        System.debug('::------------ T4');
//        PricebookEntry pbeNonMemberPromotion = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = pbNonMemberPromotion.Id, UnitPrice = 1);
//        insert pbeNonMemberPromotion;
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == pbeNonMemberPromotion.Id);
//
//        //test with discount code
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, dCode.Id);
//        System.assert(pbeRet.Id == pbeNonMemberPromotion.Id);
//
//        //add periodpromotion discount code
//        PeriodPromotion_Code_Member__c ppcm = new PeriodPromotion_Code_Member__c();
//        ppcm.Discount_Code__c = dCode.Id;
//        ppcm.Period_Promotion__c = ppromo.Id;
//        insert ppcm;
//
//        //test with discount code
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, dCode.Id);
//        System.assert(pbeRet.Id == pbeNonMemberPromotion.Id);
//
//        //test without discount code
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == defaultPBE.Id);
//
//
//    }


//    @IsTest
//    static void getPPBEForAccountAndProductAndDate_Member_Test() {
//        Account acc = [SELECT Id FROM Account LIMIT 1];
//
//        Pricebook2 memPriceBook = new Pricebook2();
//        memPriceBook.IsActive = true;
//        memPriceBook.Name = '2022Sep MHC GP';
//        insert memPriceBook;
//
//        Pricebook2 memPriceBookPromotion = new Pricebook2();
//        memPriceBookPromotion.IsActive = true;
//        memPriceBookPromotion.Name = 'Promotion MHC GP';
//        insert memPriceBookPromotion;
//
//        Membership_Tier__c gpMemTier = new Membership_Tier__c();
//        gpMemTier.Tier_Level__c = 'GP';
//        gpMemTier.Price_Book__c = memPriceBook.Id;
//        gpMemTier.Name = '2022 gp mem tier';
//        gpMemTier.Available_From__c = Date.today().addYears(-1);
//        insert gpMemTier;
//
//        //create account member
//        acc.Date_of_Birth__c = Date.today().addYears(-44);
//        acc.Membership_Tier__c = gpMemTier.Id;
//        acc.Membership_Level__c = 'Adult - Main Payer';
//        acc.Patient_Type__c = 'Member';
//        acc.Member_Status__c = 'Member';
//        acc.Membership_Start_Date__c = Date.today().addMonths(-10);
//        acc.Home_Clinic__c = 'Fulham';
//        update acc;
//
//        Account accMem = [SELECT Id, Is_Active_Member__c, Membership_Tier__c, Patient_Type__c, Member_Status__c FROM Account WHERE Id = :acc.Id];
//        System.debug('accmem:' + accMem + '. tier: ' + accMem.Membership_Tier__c);
//        System.assert(accMem.Is_Active_Member__c == true);
//
//        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
//
//        PricebookEntry defaultPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product.Id LIMIT 1];
//
//        PricebookEntry pbeGPMember = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = memPriceBook.Id, UnitPrice = 2);
//        PricebookEntry pbeGPMemberPromotion = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = memPriceBookPromotion.Id, UnitPrice = 2);
//        insert pbeGPMember;
//        insert pbeGPMemberPromotion;
//
//        Date dte = Date.today();
//
//        System.assert(acc != null);
//        System.assert(product != null);
//        System.assert(defaultPBE != null);
//
//        //we should get beck the default for GP member, no promotions
//
//        System.debug('::------------ TM1');
//        PricebookEntry pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == pbeGPMember.Id);
//
//        // make a new PB for promotion
//        System.debug('::------------ TM2');
//        Pricebook2 pbGPPromotion = new Pricebook2(IsActive = true, Name = 'GP Member Promotion');
//        insert pbGPPromotion;
//
//        //add a Promotion
//        Period_Promotion__c ppromo = new Period_Promotion__c(
//                Name = 'Test',
//                Appointments_Start_Date__c = Date.today().addDays(-1),
//                Appointments_End_Date__c = Date.today().addDays(1),
//                GP_Member_Price_Book__c = pbGPPromotion.Id
//        );
//
//        insert ppromo;
//
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == pbeGPMember.Id);
//
//
//        // make a new PBEntry
//
//        System.debug('::------------ TM3');
//        PricebookEntry pbeGPPromotion = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = pbGPPromotion.Id, UnitPrice = 1);
//        insert pbeGPPromotion;
//
//        pbeRet = OnlBookUI.getPriceBookEntryForAccountAndProductAndDate(acc.Id, product.Id, dte, null);
//        System.assert(pbeRet.Id == pbeGPPromotion.Id);
//
//    }
    @IsTest
    static void getCustomSettings_Test() {
        OnlBookUI.OptionWrapper ow = new OnlBookUI.OptionWrapper('l', 'v');
        System.assert(ow.label == 'l');
        System.assert(ow.value == 'v');
        OnlBookUI.getCustomSettings();
    }

    @IsTest
    static void resolveAccount_Test() {
        OnlBookUI.TheoFormRequest request = new OnlBookUI.TheoFormRequest();
        request.firstName = 'FN';
        request.lastName = 'LN';
        request.theoEmail = 'newEmailToAdd@example.com';
        request.dob_d = '1';
        request.dob_m = '1';
        request.dob_y = '2000';

        String ret = OnlBookUI.resolveAccount(JSON.serialize(request));

        System.assert([SELECT ID FROM Account WHERE PersonEmail = :request.theoEmail].isEmpty() == false);
    }

    @IsTest
    static void testTrackOnlineOpportunity() {

        Opportunity op = new Opportunity();
        op.Name = 'Test Opportunity';
        op.StageName = 'Qualification';
        op.CloseDate = Date.today().addMonths(1);
        insert op;

        // Call the method to test
        Test.startTest();
        OnlBookUI.trackOnlineOpportunity(op.Id, 'New State');
        Test.stopTest();

        // After the test, validate that the Opportunity
        // has been updated with the expected state
        Opportunity updatedOp = [SELECT Id, Online_Store_Tracker__c FROM Opportunity WHERE Id = :op.Id];

        System.assertNotEquals(updatedOp, null, 'The updated Opportunity should not be null');
        System.assertEquals('New State', updatedOp.Online_Store_Tracker__c, 'The Opportunity should have been updated with the expected state');
    }

    @IsTest
    static void testSafeConcatWithDash() {
        // Both strings have values so it will return concatenated string
        String result1 = OnlBookUI.safeConcatWithDash('Hello', 'World');
        System.assertEquals('Hello - World', result1);

        // One string is blank so it will return only non-blank string
        String result2 = OnlBookUI.safeConcatWithDash('Hello', '');
        System.assertEquals('Hello', result2);

        // One string is blank so it will return only non-blank string
        String result3 = OnlBookUI.safeConcatWithDash('', 'World');
        System.assertEquals('World', result3);

        // Both strings are blank so it will return empty string
        String result4 = OnlBookUI.safeConcatWithDash('', '');
        System.assertEquals('', result4);
    }

}