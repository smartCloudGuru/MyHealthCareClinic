/**
* @author Zoran Zunko
* @date 4/21/21
*
*/

@IsTest global class Invocable_RandoxRegisterTestToRelTest {
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

        Invocable_RandoxRegisterTestToRelease.RegisterTestRequest registerTestRequest = new Invocable_RandoxRegisterTestToRelease.RegisterTestRequest();
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
        registerTestRequest.arrivalDate = Datetime.now().addDays(-1);
        registerTestRequest.travelNumber = '123d3';
        registerTestRequest.countryTravelledFrom = '1';
        registerTestRequest.otherCountries = 'other';
        registerTestRequest.nhsNumber = 'nhs1';
        registerTestRequest.dateLeftNonExemptCountry = Datetime.now().addDays(-2);
        registerTestRequest.testingDay = '1';
        registerTestRequest.vaccinated = 'No';
        registerTestRequest.vaccineName = null;
        registerTestRequest.internationalTravelColour = 'Amber';
        Map<String, MockConfig> mockConfigs = new Map<String, MockConfig>{
                'oauth2/v2.0' => new MockConfig(TestDataFactory.RANDOX_AUTH_RESPONSE, 'OK', 200, false),
                '/kit-registration/ManagedKit/SaveRegistrationWithTestToRelease' => new MockConfig(TestDataFactory.RANDOX_REGISTER_RESPONSE, 'OK', 200, false)
        };

        Test.setMock(HttpCalloutMock.class, new Randox_ServiceMock(mockConfigs));

        Test.startTest();
        List<Invocable_RandoxRegisterTestToRelease.RegisterTestResponse> responses = Invocable_RandoxRegisterTestToRelease.registerTests(new List<Invocable_RandoxRegisterTestToRelease.RegisterTestRequest> {registerTestRequest});
        Test.stopTest();

        for (Invocable_RandoxRegisterTestToRelease.RegisterTestResponse registerTestResponse : responses) {
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