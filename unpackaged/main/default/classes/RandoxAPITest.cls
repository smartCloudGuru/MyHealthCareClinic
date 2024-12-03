/**
* @author Zoran Zunko
* @date 4/16/21
*
*/

@IsTest global class RandoxAPITest {

    @IsTest static void getAuthToken_test() {
        RandoxAuthProviderManager.randoxAuthProvider = TestDataFactory.getRandoxAuthProviders();
        Test.setMock(HttpCalloutMock.class, new Randox_ServiceMock(TestDataFactory.RANDOX_AUTH_RESPONSE, 200, 'OK', 'POST'));

        Test.startTest();
        String token = RandoxAPI.getAuthToken();
        Test.stopTest();

        System.assertEquals('adsdasda', token);
    }
    @IsTest static void registerKit_test() {
        RandoxAuthProviderManager.randoxAuthProvider = TestDataFactory.getRandoxAuthProviders();
        Test.setMock(HttpCalloutMock.class, new Randox_ServiceMock(TestDataFactory.RANDOX_REGISTER_RESPONSE, 200, 'OK', 'POST'));

        RandoxAPI.RandoxManagedRegistration registerKitRequest = new RandoxAPI.RandoxManagedRegistration();

        registerKitRequest.country = 1;
        registerKitRequest.firstName = 'data';
        registerKitRequest.lastName = 'data';
        registerKitRequest.email = 'data';
        registerKitRequest.phone = 'data';
        registerKitRequest.postcode = 'data';
        registerKitRequest.addressLine1 = 'data';
        registerKitRequest.dateOfBirth = 'data';
        registerKitRequest.ethnicity = 1;
        registerKitRequest.gender = 'data';
        registerKitRequest.passportNumber = 'data';
        registerKitRequest.swabCollectionDate = 'data';
        registerKitRequest.town = 'data';
        registerKitRequest.urn = 'data';
        Test.startTest();
        String message = RandoxAPI.registerKit('12312312', registerKitRequest);
        Test.stopTest();

        System.assertEquals(RandoxAPI.RANDOX_SUCCESS_MESSAGE, message);
    }
    @IsTest static void registerKit_ttr_test() {
        RandoxAuthProviderManager.randoxAuthProvider = TestDataFactory.getRandoxAuthProviders();
        Test.setMock(HttpCalloutMock.class, new Randox_ServiceMock(TestDataFactory.RANDOX_REGISTER_RESPONSE, 200, 'OK', 'POST'));

        RandoxAPI.RandoxManagedTestToRelease testToRelease = new RandoxAPI.RandoxManagedTestToRelease();
        testToRelease.addressLine1 = '58 Grove Road';
        testToRelease.town = 'London';
        testToRelease.postcode = 'N40 9NP';
        testToRelease.arrivalDate = '16/04/2021 10:01';
        testToRelease.travelNumber = '123d3';
        testToRelease.countryTravelledFrom = 1;
        testToRelease.otherCountries = 'countries';
        testToRelease.nhsNumber = '12212';
        testToRelease.dateLeftNonExemptCountry = '15/04/2021 10:01';
        testToRelease.testingDay = 1;
        testToRelease.customerLocatorReference = 'Test';
        testToRelease.vaccinated = false;
        testToRelease.vaccineName = '';
        testToRelease.BookingReference = 'TestB';
        testToRelease.internationalTravelColour = 'internationalTravelColour';

        RandoxAPI.RandoxManagedRegistration registerKitRequest = new RandoxAPI.RandoxManagedRegistration();
        registerKitRequest.country = 1;
        registerKitRequest.firstName = 'Test';
        registerKitRequest.lastName = 'Tester';
        registerKitRequest.email = 'someone@example.com';
        registerKitRequest.phone = '23144324234234';
        registerKitRequest.postcode = 'N40 9NP';
        registerKitRequest.addressLine1 = '58 Grove Road';
        registerKitRequest.dateOfBirth = '06/12/1979 00:01';
        registerKitRequest.ethnicity = 10;
        registerKitRequest.gender = 'Male';
//registerKitRequest.passportNumber = '12312312312312';
        registerKitRequest.swabCollectionDate = '26/03/2021 12:43';
        registerKitRequest.town = 'London';
        registerKitRequest.urn = 'R300001026';

        RandoxAPI.RandoxManagedRegistrationTestToRelease testToReleaseFull = new RandoxAPI.RandoxManagedRegistrationTestToRelease();
        testToReleaseFull.testToRelease = testToRelease;
        testToReleaseFull.registration = registerKitRequest;
        Test.startTest();
        String message = RandoxAPI.registerKitTestToRelease('12312312', testToReleaseFull);
        Test.stopTest();

        System.assertEquals(RandoxAPI.RANDOX_SUCCESS_MESSAGE, message);
    }

    global class Randox_ServiceMock implements HttpCalloutMock {

        public String body { get; private set; }
        public String method { get; private set; }
        public String status { get; private set; }
        public Integer code { get; private set; }
        public Boolean throwException { get; private set; }

        global Randox_ServiceMock(String body, Integer code, String status, String method) {
            this(body, code, status, method, false);
        }
        global Randox_ServiceMock(String body, Integer code, String status, String method, Boolean throwException) {
            this.body = body;
            this.code = code;
            this.method = method;
            this.status = status;
            this.throwException = throwException;
        }

        global HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (throwException) {
                Integer divideByZero = 2 / 0;
            }
            System.assert(req != null);
//			System.assertEquals(method, req.getMethod());
            res.setBody(body);
            res.setStatusCode(code);
            res.setStatus(status);
            return res;
        }
    }
}