/**
 * Created 16.9.2022..
 */

@IsTest
public class memSignUpCtrlTest {


    public static String signupRequest = '{"tier":"Dental","gender":"Female","firstName":"Main","lastName":"Payer","email":"testpayer1@example.com","phone":"9234567896","dob_d":"1","dob_m":"1","dob_y":"2001","address1":"Shipping address","address2":"2","address3":"3","city":"London","postalCode":"D1","ddselected":"0","checkToc":true,"checkNews":false,' +
            '"adultMembers":[{"isAdult":true,"isAdd":true,"dob":"2002-02-02","firstName":"Additional","lastName":"Adult1","email":"add1@example.com","phone":"1231231","dob_d":"2","dob_m":"2","dob_y":"2002","address1":"21","address2":"22","address3":"23","city":"London","postalCode":"D2","id":"A01663332287020"},{"isAdult":true,"isAdd":true,"dob":"2003-03-03","firstName":"Additional","lastName":"Adult2","email":"add2@example.com","phone":"312312313","dob_d":"3","dob_m":"3","dob_y":"2003","address1":"31","address2":"32","address3":"33","city":"London","postalCode":"D3","id":"A11663332321796"}],"childMembers":[{"isChild":true,"isAdd":true,"dob":"2020-10-10","firstName":"Additional","lastName":"Child1","email":"addchild1@example.com","phone":"65465432","dob_d":"10","dob_m":"10","dob_y":"2020","address1":"c11","address2":"c12","address3":"c13","city":"London","postalCode":"C1","id":"C01663332375307"},{"isChild":true,"isAdd":true,"dob":"2021-11-11","firstName":"Additional","lastName":"Child 2","email":"addChild2@example.com","phone":"53543683","dob_d":"11","dob_m":"11","dob_y":"2021","address1":"c21","address2":"c22","address3":"c23","city":"London","postalCode":"C2","id":"C11663332416274"}]}';

    @TestSetup
    public static void setUp() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 standardPB = new Pricebook2(Id = pbid);
        standardPB.IsActive = true;
        update standardPB;

        Pricebook2 pbTest = new Pricebook2();
        pbTest.Name = '2022Sep MHC Dental';
        pbTest.IsActive = true;
        insert pbTest;

        Product2 p1 = new Product2();
        p1.Name = 'Adult - Main Payer';
        p1.Family = 'Membership_Plan';
        p1.IsActive = true;
        insert p1;

        Product2 p2 = new Product2();
        p2.Name = 'Adult';
        p2.Family = 'Membership_Plan';
        p2.IsActive = true;
        insert p2;

        Product2 p3 = new Product2();
        p3.Name = 'Child';
        p3.Family = 'Membership_Plan';
        p3.IsActive = true;
        insert p3;


        PricebookEntry pbe1s = new PricebookEntry();
        pbe1s.Product2Id = p1.Id;
        pbe1s.Pricebook2Id = standardPB.Id;
        pbe1s.UnitPrice = 3;
        pbe1s.IsActive = true;
        insert pbe1s;

        PricebookEntry pbe2s = new PricebookEntry();
        pbe2s.Product2Id = p2.Id;
        pbe2s.Pricebook2Id = standardPB.Id;
        pbe2s.UnitPrice = 2;
        pbe2s.IsActive = true;
        insert pbe2s;

        PricebookEntry pbe3s = new PricebookEntry();
        pbe3s.Product2Id = p3.Id;
        pbe3s.Pricebook2Id = standardPB.Id;
        pbe3s.UnitPrice = 1;
        pbe3s.IsActive = true;
        insert pbe3s;


        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Product2Id = p1.Id;
        pbe1.Pricebook2Id = pbTest.Id;
        pbe1.UnitPrice = 3;
        pbe1.IsActive = true;
        insert pbe1;

        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Product2Id = p2.Id;
        pbe2.Pricebook2Id = pbTest.Id;
        pbe2.UnitPrice = 2;
        pbe2.IsActive = true;
        insert pbe2;

        PricebookEntry pbe3 = new PricebookEntry();
        pbe3.Product2Id = p3.Id;
        pbe3.Pricebook2Id = pbTest.Id;
        pbe3.UnitPrice = 1;
        pbe3.IsActive = true;
        insert pbe3;

        Membership_Tier__c mt = new Membership_Tier__c();
        mt.Price_Book__c = pbTest.Id;
        mt.Tier_Level__c = 'Dental';
        mt.Available_From__c = Date.today();
        mt.Welcome_Email_Template__c = 'Corporate_TLC_Welcome_Email';


        insert mt;
    }

    @IsTest
    static void processSignupRequest_noDD_Test() {

        String ret = memSignUpCtrl.processSignupRequest(signupRequest);
        System.debug('processSignupRequest_noDD_Test:ret:' + ret);

        List<MembershipSignupForm__c> forms = [SELECT Id, Patient__c, Provided_Gender__c FROM MembershipSignupForm__c];
        List<Additional_Member__c> amds = [SELECT Id FROM Additional_Member__c];

        System.assert(forms.size() == 1);
        System.assert(forms[0].Patient__c != null);
        System.assert(forms[0].Provided_Gender__c == 'Female');
        System.assert(amds.size() == 4);
    }

    @IsTest
    static void processSignupRequest_withDD_Test() {

        String request2 = signupRequest.replaceAll('"ddselected":"0"', '"ddselected":"1"');

        GoCardlessServiceMock.setAsMock();

        Test.startTest();
        String ret = memSignUpCtrl.processSignupRequest(request2);
        System.debug('processSignupRequest_withDD_Test:[1]process:ret:' + ret);
        Test.stopTest();

        System.assert(ret != null);
        List<MembershipSignupForm__c> forms = [SELECT Id, Patient__c, GC_RedirectFlow_Id__c, Membership_PriceBook__c FROM MembershipSignupForm__c];
        List<Additional_Member__c> amds = [SELECT Id FROM Additional_Member__c];

        System.assert(forms.size() == 1);
        System.assert(forms[0].Patient__c != null);
        System.assert(forms[0].GC_RedirectFlow_Id__c != null);
        System.assert(forms[0].Membership_PriceBook__c != null);
        System.assert(amds.size() == 4);
    }

    @IsTest
    static void completeRedirectFlow_Test() {

        GoCardlessServiceMock.setAsMock();

        MembershipSignupForm__c form = new MembershipSignupForm__c();
        form.GC_RedirectFlow_Id__c = 'mockflowid-t2';
        form.Session_Id__c = 'mocksessionid-t2';
        form.Patient__c = [SELECT Id FROM Account LIMIT 1].Id;
        form.Membership_PriceBook__c = [SELECT Id FROM Pricebook2 WHERE Name = '2022Sep MHC Dental' LIMIT 1].Id;
        form.Subscription_Amount__c = 15;
        form.All_Accounts_Provisioned__c = true;
        insert form;

        Test.startTest();
        String flow = memSignUpCtrl.completeRedirectFlow(form.GC_RedirectFlow_Id__c);
        System.debug('completeRedirectFlow_Test:[2]complete:flow:' + flow);
        Test.stopTest();

        System.assert(flow != null);

    }

    @IsTest
    static void testSendActivationEmail() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Membership_Tier__c tier = [SELECT Id FROM Membership_Tier__c LIMIT 1];

        Contract contract = new Contract();
        contract.StartDate = Date.today();
        contract.AccountId = acc.Id;
        insert contract;

        Membership_Contract__c mContract = new Membership_Contract__c(Membership_Tier__c = tier.Id, Contract__c = contract.Id);
        insert mContract;

        Test.startTest();
        memSignUpCtrl.sendActivationEmail(acc.Id, mContract);
        Test.stopTest();


    }

    @IsTest
    static void completeAndActivate_Test() {

        GoCardlessServiceMock.setAsMock();

        MembershipSignupForm__c form = new MembershipSignupForm__c();
        form.GC_RedirectFlow_Id__c = 'mockflowid-t2';
        form.Session_Id__c = 'mocksessionid-t2';
        form.Patient__c = [SELECT Id FROM Account LIMIT 1].Id;
        form.Membership_PriceBook__c = [SELECT Id FROM Pricebook2 WHERE Name = '2022Sep MHC Dental' LIMIT 1].Id;
        form.Subscription_Amount__c = 15;
        form.All_Accounts_Provisioned__c = true;
        insert form;

        Test.startTest();
        String flow = memSignUpCtrl.completeRedirectFlow(form.GC_RedirectFlow_Id__c);
        System.debug('completeRedirectFlow_Test:[2]complete:flow:' + flow);

        System.assert(flow != null);
        Membership_Contract__c mContract = memSignUpCtrl.activateMembershipFromSignupForm(form.Id);
        System.assert(mContract != null);
        Test.stopTest();

    }

    @IsTest
    static void processSignupRequest_noDD_match_toExisting_payer_with_email_and_dob_Test() {

        Account acc = new Account();
        acc.PersonEmail = 'testpayer1@example.com';
        acc.Date_of_Birth__c = Date.newInstance(2001, 1, 1);
        acc.FirstName = 'Main';
        acc.LastName = 'Payer';
        insert acc;

        String ret = memSignUpCtrl.processSignupRequest(signupRequest);
        System.debug('processSignupRequest_noDD_match_toExisting_payer_with_email_and_dob_Test:ret:' + ret);

        List<MembershipSignupForm__c> forms = [SELECT Id, Patient__c FROM MembershipSignupForm__c];
        List<Additional_Member__c> amds = [SELECT Id, Patient__c, Patient__r.FirstName, Patient__r.Date_of_Birth__c, Provided_First_Name__c, Provided_Email__c, Provided_DOB__c FROM Additional_Member__c];

        System.assert(forms.size() == 1);
        System.assert(forms[0].Patient__c == acc.Id);

        System.assert(amds.size() == 4);
        for (Additional_Member__c additionalMember : amds) {
            System.assert(additionalMember.Patient__c != null);
            System.assert(additionalMember.Patient__r.FirstName == additionalMember.Provided_First_Name__c);
            System.assert(additionalMember.Patient__r.Date_of_Birth__c == additionalMember.Provided_DOB__c);
        }
    }

    @IsTest
    static void processSignupRequest_noDD_match_toExisting_payer_and_existing_additional_Test() {

        memSignUpCtrl.MemSignUpRequest req = (memSignUpCtrl.MemSignUpRequest) JSON.deserialize(signupRequest, memSignUpCtrl.MemSignUpRequest.class);

        Account acc = new Account();
        acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
        acc.PersonEmail = req.email;
        acc.Date_of_Birth__c = req.getDOB();
        acc.FirstName = req.firstName;
        acc.LastName = req.lastName;
        insert acc;

        Account accAdd1 = new Account();
        accAdd1.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
        accAdd1.PersonEmail = req.adultMembers[0].email;
        accAdd1.Date_of_Birth__c = req.adultMembers[0].getDOB();
        accAdd1.FirstName = req.adultMembers[0].firstName;
        accAdd1.LastName = req.adultMembers[0].lastName;
        insert accAdd1;

        Account accAdd2 = new Account();
        accAdd2.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
        accAdd2.PersonEmail = req.childMembers[0].email;
        accAdd2.Date_of_Birth__c = req.childMembers[0].getDOB();
        accAdd2.FirstName = req.childMembers[0].firstName;
        accAdd2.LastName = req.childMembers[0].lastName;
        insert accAdd2;

        String ret = memSignUpCtrl.processSignupRequest(signupRequest);
        System.debug('processSignupRequest_noDD_match_toExisting_payer_with_email_and_dob_Test:ret:' + ret);

        List<MembershipSignupForm__c> forms = [SELECT Id, Patient__c FROM MembershipSignupForm__c];
        List<Additional_Member__c> amds = [
                SELECT
                        Id,
                        Patient__c,
                        Patient__r.FirstName,
                        Patient__r.Date_of_Birth__c,
                        Provided_First_Name__c,
                        Provided_Email__c,
                        Provided_DOB__c
                FROM Additional_Member__c
                WHERE Membership_Signup_Form__c = :forms[0].Id
        ];

        System.assert(forms.size() == 1);
        System.assert(forms[0].Patient__c == acc.Id);

        System.assert(amds.size() == 4);
        System.debug('additionalMembers:' + JSON.serializePretty(amds));
        for (Additional_Member__c additionalMember : amds) {
            System.assert(additionalMember.Patient__c != null);
            System.assert(additionalMember.Patient__r.FirstName == additionalMember.Provided_First_Name__c);
            System.assert(additionalMember.Patient__r.Date_of_Birth__c == additionalMember.Provided_DOB__c);
            if (additionalMember.Provided_Email__c == accAdd1.PersonEmail) System.assert(additionalMember.Patient__c == accAdd1.Id);
            if (additionalMember.Provided_Email__c == accAdd2.PersonEmail) System.assert(additionalMember.Patient__c == accAdd2.Id);
        }
    }

    //    @IsTest
    //    static void createSubscription_Test()
    //    {
    //        GoCardlessServiceMock.setAsMock();
    //
    //        MembershipSignupForm__c form = new MembershipSignupForm__c();
    //        form.GC_RedirectFlow_Id__c = 'mockflowid-t2';
    //        form.Session_Id__c = 'mocksessionid-t2';
    //        form.Patient__c = [SELECT Id FROM Account LIMIT 1].Id;
    //        form.Membership_PriceBook__c = [SELECT Id FROM Pricebook2 WHERE Name = '2022Sep MHC Dental' LIMIT 1].Id;
    //        form.GoCardless_Mandate__c = mandate.Id;
    //        form.Subscription_Amount__c = 123;
    //        insert form;
    //
    //
    //
    //        Test.startTest();
    //        memSignUpCtrl.createSubscription(form.Id, 'mandateextid');
    //        Test.stopTest();
    //        //todo asserts
    //    }

    @IsTest
    static void aura_getPrices_test() {
        memSignUpCtrl.aura_getPrices();
    }

    @IsTest
    static void aura_checkDiscountCode_test() {
        System.assert(memSignUpCtrl.aura_checkDiscountCodeForMonths('not there') == 'Not a valid code');
    }


    @IsTest
    static void aura_createNewNote_test() {

        MembershipSignupForm__c form = new MembershipSignupForm__c();
        form.GC_RedirectFlow_Id__c = 'mockflowid-t2';
        form.Session_Id__c = 'mocksessionid-t2';
        form.Patient__c = [SELECT Id FROM Account LIMIT 1].Id;
        form.Membership_PriceBook__c = [SELECT Id FROM Pricebook2 WHERE Name = '2022Sep MHC Dental' LIMIT 1].Id;
        form.Subscription_Amount__c = 15;
        insert form;

        memSignUpCtrl.createNewNote('title', 'body', form.Id);
    }

    private static void setupTestData() {


    }

    @IsTest
    static void testGenerateMembershipSignupUrl_ValidId() {
        // Setup test data
        setupTestData();

        String signupUrl = memSignUpCtrl.generateMembershipSignupUrl([SELECT Id FROM Account LIMIT 1].Id);

        // Perform the assertion
        System.assert(signupUrl != null, 'The signup URL should not be null');
    }

    @IsTest
    static void testGenerateMembershipSignupUrl_InvalidId() {
        String signupUrl = memSignUpCtrl.generateMembershipSignupUrl('invalidId');

        // Perform the assertion
        System.assertEquals(null, signupUrl, 'The signup URL should be null');
    }

    @IsTest
    static void testGenerateMembershipSignupUrl_NullId() {
        String signupUrl = memSignUpCtrl.generateMembershipSignupUrl(null);

        // Perform the assertion
        System.assertEquals(null, signupUrl, 'The signup URL should be null');
    }

    @IsTest
    static void testObfuscateId() {
        String id = 'sampleId';

        // Test obfuscateId method
        Test.startTest();
        String obfuscatedId = memSignUpCtrl.obfuscateId(id);
        Test.stopTest();

        // Verify the obfuscated id is not null
        System.assertNotEquals(null, obfuscatedId);

        // Confirm that the obfuscated id is not equals to the original id
        System.assertNotEquals(id, obfuscatedId);
    }
}