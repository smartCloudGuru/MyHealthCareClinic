/**
* @author Zoran Zunko
* @date 3/26/21
*
*/
public class RandoxAPI {

    public static final String RANDOX_SUCCESS_MESSAGE = 'Registration has been successfully created.';
    public static final String GENDER_MALE = 'Male';
    public static final String GENDER_FEMALE = 'Female';

    @TestVisible
    static final String REGISTER_KIT_URL = '/kit-registration/ManagedKit/SaveRegistration';

    @TestVisible
    static final String REGISTER_KIT_RELEASE_URL = '/kit-registration/ManagedKit/SaveRegistrationWithTestToRelease';

    public class RandoxManagedRegistration {
        public String addressLine1;
        public String addressLine2;
        public Integer country;
        public Integer county;
        public String dateOfBirth;
        public String email;
        public Integer ethnicity;
        public String firstName;
        public String gender;
        public String lastName;
        public String passportNumber;
        public String phone;
        public String postcode;
        public String swabCollectionDate;
        public String town;
        public String urn;
    }

    public class RandoxManagedTestToRelease {
        public String addressLine1;
        public String addressLine2;
        public String town;
        public String postcode;
        public String arrivalDate;
        public String travelNumber;
        public Integer countryTravelledFrom;
        public String otherCountries;
        public String nhsNumber;
        public String dateLeftNonExemptCountry;
        public Integer testingDay;
        public String customerLocatorReference;
        public Boolean vaccinated;
        public String vaccineName;
        public String BookingReference;
        public String internationalTravelColour;
    }

    public class RandoxManagedRegistrationTestToRelease {
        public RandoxManagedRegistration registration;
        public RandoxManagedTestToRelease testToRelease;
        public RandoxManagedRegistrationTestToRelease() {
            registration = new RandoxManagedRegistration();
            testToRelease = new RandoxManagedTestToRelease();
        }
    }

    public class RandoxTokenResponse {
        public String access_token;
        public String token_type;
        public String refresh_token;
        public String id_token;
    }
    /**
     * Gets the access token for the Randox API Server
     * @return access token to be used in Randox API calls
     */
    public static String getAuthToken() {
        Randox_Auth_Provider__mdt randoxAuthProvider = RandoxAuthProviderManager.getRandoxAuthProvider();
        String authUrl = randoxAuthProvider.Token_Endpoint__c;
        authUrl += '&grant_type=' + EncodingUtil.urlEncode(randoxAuthProvider.Grant_Type__c, 'UTF-8');
        authUrl += '&scope=' + EncodingUtil.urlEncode(randoxAuthProvider.Scope__c, 'UTF-8');
        authUrl += '&response_type=' + EncodingUtil.urlEncode(randoxAuthProvider.Response_Type__c, 'UTF-8');
        authUrl += '&client_id=' + EncodingUtil.urlEncode(randoxAuthProvider.Client_Id__c, 'UTF-8');
        authUrl += '&username=' + EncodingUtil.urlEncode(randoxAuthProvider.Username__c, 'UTF-8');
        authUrl += '&password=' + EncodingUtil.urlEncode(randoxAuthProvider.Password__c, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Length', '0');
        req.setMethod('POST');
        req.setTimeout(60000);
        req.setEndpoint(authUrl);
        HttpResponse res = new Http().send(req);
        RandoxTokenResponse tokenResponse = (RandoxTokenResponse) JSON.deserialize(res.getBody(), RandoxTokenResponse.class);
        return tokenResponse.access_token;
    }

    /**
     * @param token auth token
     * @param registerKitRequest contains registartion parameters
     *
     * @return
     */
    public static String registerKit(String token, RandoxManagedRegistration registerKitRequest) {
        Randox_Auth_Provider__mdt randoxAuthProvider = RandoxAuthProviderManager.getRandoxAuthProvider();
        HttpRequest req = getHTTPRequest(randoxAuthProvider.API_Url__c + REGISTER_KIT_URL, token, 'POST');
        req.setTimeout(60000);
        System.debug(LoggingLevel.FINE, 'registerKit - JSON.serialize(registerKitRequest): ' + JSON.serialize(registerKitRequest));
        req.setBody(JSON.serialize(registerKitRequest));
        HttpResponse res = new Http().send(req);
        System.debug(LoggingLevel.FINE, 'registerKit - res.getBody(): ' + res.getBody());
        return res.getBody();
    }

    /**
     * @param token auth token
     * @param registerKitRequest contains registartion parameters
     *
     * @return
     */
    public static String registerKitTestToRelease(String token, RandoxManagedRegistrationTestToRelease registerKitRequest) {
        Randox_Auth_Provider__mdt randoxAuthProvider = RandoxAuthProviderManager.getRandoxAuthProvider();
        HttpRequest req = getHTTPRequest(randoxAuthProvider.API_Url__c + REGISTER_KIT_RELEASE_URL, token, 'POST');
        req.setTimeout(60000);
        System.debug(LoggingLevel.ERROR, 'registerKit - JSON.serialize(registerKitRequest): ' + JSON.serialize(registerKitRequest, true));
        req.setBody(JSON.serialize(registerKitRequest, true));
        HttpResponse res = new Http().send(req);
        System.debug(LoggingLevel.ERROR, 'registerKit - res.getBody(): ' + res.getBody());
        return res.getBody();
    }

    @TestVisible static HttpRequest getHTTPRequest(String endpoint, String sessionId, String method) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json-patch+json');
        req.setHeader('Cache-Control', 'no-cache');
        req.setMethod(method);

        return req;
    }

    public static String formatRandoxDate(Date dateToFormat) {
        return formatRandoxDateTime(Datetime.newInstance(dateToFormat, Time.newInstance(12, 0, 0, 0)));
    }
    @TestVisible static String randoxDateFormat = 'dd/MM/yyyy HH:mm';
    public static String formatRandoxDateTime(Datetime dateTimeToFormat) {
        return dateTimeToFormat.format(randoxDateFormat);
    }
}