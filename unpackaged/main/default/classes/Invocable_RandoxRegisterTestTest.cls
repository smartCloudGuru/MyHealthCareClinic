/**
* @author Zoran Zunko
* @date 4/16/21
*
*/

@IsTest global class Invocable_RandoxRegisterTestTest {
    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<COVID_Test__c> covidTests = TestDataFactory.createCovidTests(accounts, 1, false);
        covidTests[0].Test_URN__c = 'R123456789';
        covidTests[0].COVID_Test_Status__c = 'Negative';
        AnthologyTriggerDispatch.noTriggers = true;
        insert covidTests;
    }

    @IsTest static void registerKit_test() {
        COVID_Test__c covidTest = [SELECT Id FROM COVID_Test__c];

        RandoxAuthProviderManager.randoxAuthProvider = TestDataFactory.getRandoxAuthProviders();

        Invocable_RandoxRegisterTest.RegisterTestRequest registerTestRequest = new Invocable_RandoxRegisterTest.RegisterTestRequest();
        registerTestRequest.addressLine1 = '123123';
        registerTestRequest.country = '1';
        registerTestRequest.dateOfBirth = Date.today();
        registerTestRequest.email = 'some@example.com';
        registerTestRequest.ethnicity = '1';
        registerTestRequest.firstName = '123123';
        registerTestRequest.gender = 'Male';
        registerTestRequest.lastName = '123123';
        registerTestRequest.passportNumber = '123123';
        registerTestRequest.phone = '123123';
        registerTestRequest.postcode = '123123';
        registerTestRequest.swabCollectionDate = Datetime.now();
        registerTestRequest.town = '123123';
        registerTestRequest.urn = '123123';
        registerTestRequest.covidTestId = covidTest.Id;
        Map<String, MockConfig> mockConfigs = new Map<String, MockConfig>{
                'oauth2/v2.0' => new MockConfig(TestDataFactory.RANDOX_AUTH_RESPONSE, 'OK', 200, false),
                '/kit-registration/ManagedKit/SaveRegistration' => new MockConfig(TestDataFactory.RANDOX_REGISTER_RESPONSE, 'OK', 200, false)
        };

        Test.setMock(HttpCalloutMock.class, new Randox_ServiceMock(mockConfigs));

        Test.startTest();
        List<Invocable_RandoxRegisterTest.RegisterTestResponse> responses = Invocable_RandoxRegisterTest.registerTests(new List<Invocable_RandoxRegisterTest.RegisterTestRequest> {registerTestRequest});
        Test.stopTest();

        for (Invocable_RandoxRegisterTest.RegisterTestResponse registerTestResponse : responses) {
            System.assert(registerTestResponse.success);
        }
    }

    global class MockConfig {
        public String body ;
        public String status ;
        public Integer code ;
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
    global class Randox_ServiceMock implements HttpCalloutMock {

        public Map<String, MockConfig> mockConfigs;

        global Randox_ServiceMock(Map<String, MockConfig> mockConfigs) {
            this.mockConfigs = mockConfigs;
        }

        global HttpResponse respond(HttpRequest req) {
            for (String str : mockConfigs.keySet()) {
                if (req.getEndpoint().contains(str)) {
                    MockConfig mConfig = mockConfigs.get(str);
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

}