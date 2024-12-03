/**
 * @author Zoran Zunko
 *
 * @date 10/20/21
 */
@IsTest public class onl_HomeTestCtrlTest {
    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<Opportunity> opps = TestDataFactory.createOpportunities(accounts, 1, true);
        opps[0].StageName = 'Closed Won';
        update opps[0];
        List<COVID_Test__c> tests = TestDataFactory.createCovidTests(accounts, 1, true);
        tests[0].Opportunity__c = opps[0].Id;
        update tests[0];

        Product2 prod = new Product2();
        prod.Name = 'Test';
        prod.Family = 'Membership_Plan';
        prod.IsActive = true;
        insert prod;

        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.UnitPrice = 0;
        pbe2.Product2Id = prod.Id;
        pbe2.Pricebook2Id = Test.getStandardPricebookId();
        pbe2.IsActive = true;
        insert pbe2;

        OnlOTPGenerator og = new OnlOTPGenerator();
        og.generateOTP();
    }

    @IsTest static void getCustomSettings_test() {
        OnlineStoreSettings__c storeSettings = OnlineStoreSettings__c.getInstance();
        storeSettings.IdealPostcodes_API_Key__c = '12345';
        OnlineStoreSettingsManager.storeSettings = storeSettings;

        System.assertEquals('12345', onl_HomeTestCtrl.getCustomSettings());
    }

    @IsTest static void getCovidTestForUUID_test() {
        COVID_Test__c covidTest = [SELECT Id FROM COVID_Test__c];
        covidTest.UUID__c = '12312312';
        update covidTest;

        System.assert(onl_HomeTestCtrl.getCovidTestForUUID('12312312') != null);
    }

    @IsTest static void storeHomeTestResult_test_regular() {
        COVID_Test__c covidTest = [SELECT Id FROM COVID_Test__c];
        covidTest.UUID__c = '12312312';
        update covidTest;
        String covidTestJSON = '{\n' +
                '    "test": {\n' +
                '        "Id": "' + covidTest.Id + '",\n' +
                '        "Name": "COVID-00952",\n' +
                '        "Test_Type__c": "Fit to Fly Rapid (Lateral Flow)",\n' +
                '        "UUID__c": "' + covidTest.UUID__c + '",\n' +
                '        "COVID_Test_Status__c": "New",\n' +
                '        "Is_Home_Kit_Test__c": true,\n' +
                '        "Booking_Reference__c": "MYHCC0000952",\n' +
                '        "Provided_First_Name__c": "FN",\n' +
                '        "Provided_Last_Name__c": "LN",\n' +
                '        "dob_d": "1",\n' +
                '        "dob_m": "3",\n' +
                '        "dob_y": "2018",\n' +
                '        "Provided_Address_Line1__c": "Add1",\n' +
                '        "Provided_Address_Line2__c": "Add2",\n' +
                '        "Provided_City__c": "Ciuty",\n' +
                '        "Provided_Country__c": "1",\n' +
                '        "Provided_Email__c": "text@example.com",\n' +
                '        "Provided_Mobile_Phone__c": "12313",\n' +
                '        "Provided_Phone_Number__c": "123",\n' +
                '        "Provided_Passport_Number__c": "000",\n' +
                '        "check1": "",\n' +
                '        "Flight_Date__c": "2021-10-20T09:38:00.000Z",\n' +
                '        "Destination_Country__c": "1",\n' +
                '        "check2": "",\n' +
                '        "Provided_Date_of_Birth__c": "2018-03-01"\n' +
                '    },\n' +
                '    "uuid": "8e2d13b7-b9e5-4525-ba7a-93c047a29ca3",\n' +
                '    "attachment1": {\n' +
                '        "name": "_att1.jpg",\n' +
                '        "documentId": "0693H000000pDMlQAM",\n' +
                '        "contentVersionId": "0683H000000pL7qQAE"\n' +
                '    },\n' +
                '    "attachment2": {\n' +
                '        "name": "_att2.jpg",\n' +
                '        "documentId": "0693H000000pDMqQAM",\n' +
                '        "contentVersionId": "0683H000000pL7vQAE"\n' +
                '    },\n' +
                '    "attachment3": {\n' +
                '        "name": "_att3.jpg",\n' +
                '        "documentId": "0693H000000pDMvQAM",\n' +
                '        "contentVersionId": "0683H000000pL80QAE"\n' +
                '    }\n' +
                '}';
        try {
            onl_HomeTestCtrl.storeHomeTestResult(covidTestJSON);
        }
        catch (Exception e) {

        }


    }

    @IsTest static void storeHomeTestResult_test_with_otp() {


        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettings__c oss = OnlineStoreSettingsManager.storeSettings;
        oss.Default_Home_Test_Results_Queue__c = OnlineStoreSettingsManager.storeSettings.Default_Home_Test_Results_Queue__c;
        insert oss;

        List<OneTimePassword__c> otps = [SELECT Id,Name From OneTimePassword__c WHERE IsUsed__c = FALSE];

        String ctest_s = onl_HomeTestCtrl.verifyOTP(otps[0].Name);
        COVID_Test__c ctest = (COVID_Test__c) JSON.deserialize(ctest_s, COVID_Test__c.class);

        COVID_Test__c ctest_to_bypass_validation_rule = new COVID_Test__c(Id=ctest.Id);
        ctest_to_bypass_validation_rule.Opportunity__c = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' LIMIT 1].Id;
        update ctest_to_bypass_validation_rule;

        ctest.Provided_First_Name__c = 'fn';
        ctest.Provided_Last_Name__c = 'ln';
        ctest.Provided_Email__c = 'fnln@example.com';

        COVID_Test__c ctest2 = [SELECT Id, OwnerId FROM COVID_Test__c WHERE Id = :ctest.Id];

        onl_HomeTestCtrl.ParamsWrapper wrap = new onl_HomeTestCtrl.ParamsWrapper();
        wrap.test = ctest;
        wrap.otpc = otps[0].Name;

        onl_HomeTestCtrl.storeHomeTestResult(JSON.serialize(wrap));

        ctest = [SELECT Id, One_Time_Password__c, Is_Result_from_Reseller_Test__c FROM COVID_Test__c WHERE Id = :ctest.Id];
        OneTimePassword__c otp = [SELECT Id, IsUsed__c FROM OneTimePassword__c WHERE Name = :otps[0].Name LIMIT 1];

        System.assert(ctest.One_Time_Password__c == otp.Id);
        System.assert(otp.IsUsed__c == true);

    }

    //creates test after submit, no pre-validation
//    @IsTest static void storeHomeTestResult_test_with_manual_otp() {
//
//
//        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
//        OnlineStoreSettings__c oss = OnlineStoreSettingsManager.storeSettings;
//        oss.Default_Home_Test_Results_Queue__c = OnlineStoreSettingsManager.storeSettings.Default_Home_Test_Results_Queue__c;
//        insert oss;
//
//        List<OneTimePassword__c> otps = [SELECT Id,Name From OneTimePassword__c WHERE IsUsed__c = FALSE];
//
//        String ctest_s = onl_HomeTestCtrl.verifyOTP(otps[0].Name);
//        COVID_Test__c ctest = (COVID_Test__c) JSON.deserialize(ctest_s, COVID_Test__c.class);
//
//        COVID_Test__c ctest2 = [SELECT Id, OwnerId FROM COVID_Test__c WHERE Id = :ctest.Id];
//
//        System.debug(ctest2.OwnerId);
//
//        onl_HomeTestCtrl.ParamsWrapper wrap = new onl_HomeTestCtrl.ParamsWrapper();
//        ctest.Id = null;
//        ctest.Provided_First_Name__c = 'fn';
//        ctest.Provided_Last_Name__c = 'ln';
//        ctest.Provided_Email__c = 'fnln@example.com';
//        wrap.test = ctest;
//        wrap.otpc = otps[0].Name;
//
//        onl_HomeTestCtrl.storeHomeTestResult(JSON.serialize(wrap));
//
//        OneTimePassword__c otp = [SELECT Id, IsUsed__c FROM OneTimePassword__c WHERE Name = :otps[0].Name LIMIT 1];
//
//        System.assert(otp.IsUsed__c == true);
//
//    }

    @IsTest static void test_verifyOTP() {
        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();

        OnlOTPGenerator og = new OnlOTPGenerator();
        og.generateOTP();

        List<OneTimePassword__c> otps = [SELECT Id,Name FROM OneTimePassword__c WHERE IsUsed__c = FALSE];

        System.assert(onl_HomeTestCtrl.verifyOTP(otps[0].Name) != null);
    }

    @IsTest static void test_getHomeTestResultTypeOptions()
    {
        Online_Store_Lists_Config__c cfg = new Online_Store_Lists_Config__c();
        cfg.HomeTestListOptions__c = 'Fit to Fly;Day 2 Test;UK Entry Test';
        insert cfg;

        String result = onl_HomeTestCtrl.getHomeTestResultTypeOptions();

        List<onl_HomeTestCtrl.ValueLabelPair> pairs = (List<onl_HomeTestCtrl.ValueLabelPair>) JSON.deserialize(result, List<onl_HomeTestCtrl.ValueLabelPair>.class);

        System.assert(pairs.size()==3);

    }

    @IsTest static void test_storeCovidTestByUUID()
    {
        COVID_Test__c ctest = new COVID_Test__c();
        ctest.UUID__c = '123';
        ctest.Test_Type__c = 'PCR Test';
        System.assert(onl_HomeTestCtrl.storeCovidTestByUUID(JSON.serialize(ctest)));
    }
}