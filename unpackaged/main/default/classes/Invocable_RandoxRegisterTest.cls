/**
 * Registers a test with Randox using the api @see RandoxAPI
* @author Zoran Zunko
* @date 3/31/21
*/
public with sharing class Invocable_RandoxRegisterTest {
    /**
     * Invocable method response for registering test with Randox
     */
    public class RegisterTestRequest {
        @InvocableVariable(Label = 'Street Address' Required = true Description = 'Street address of the person being tested')
        public String addressLine1;
        @InvocableVariable(Label = 'Country' Required = true Description = 'Country of residence of the person being tested')
        public String country;
        @InvocableVariable(Label = 'Date of Birth' Required = true Description = 'Date of Birth of the person being tested')
        public Date dateOfBirth;
        @InvocableVariable(Label = 'Email' Required = true Description = 'Email of the person being tested')//todo check if Mt HC email goes here
        public String email;
        @InvocableVariable(Label = 'Ethnicity' Required = true Description = 'Ethnicity of the person being tested')
        public String ethnicity;
        @InvocableVariable(Label = 'First Name' Required = true Description = 'First name of the person being tested')
        public String firstName;
        @InvocableVariable(Label = 'Gender' Required = true Description = 'Gender of the person being tested')
        public String gender;
        @InvocableVariable(Label = 'Last Name' Required = true Description = 'Last name of the person being tested')
        public String lastName;
        @InvocableVariable(Label = 'Passport Number' Required = false Description = 'Passport Number of the person being tested')
        public String passportNumber;
        @InvocableVariable(Label = 'Phone Number' Required = true Description = 'Phone Number of the person being tested')
        public String phone;
        @InvocableVariable(Label = 'Postal Code' Required = true Description = 'Postal Code of the person being tested')
        public String postcode;
        @InvocableVariable(Label = 'Sample Collection Date' Required = true Description = 'Sample collection date and time')
        public Datetime swabCollectionDate;
        @InvocableVariable(Label = 'City' Required = true Description = 'City of the person being tested')
        public String town;
        @InvocableVariable(Label = 'URN' Required = true Description = 'Test unique identifier given by Randox')
        public String urn;
        @InvocableVariable(Label = 'COVID Test Id' Required = true Description = 'Salesforce Id of the test being Registered')
        public String covidTestId;
    }
    public class RegisterTestResponse {
        @InvocableVariable(Label = 'Operation successful?' Required = false Description = 'True if test was successfully registered')
        public Boolean success;
        @InvocableVariable(Label = 'Error Message' Required = false Description = 'Message explaining the error if existing')
        public String message;
        @InvocableVariable(Label = 'COVID Test Id' Required = true Description = 'Salesforce Id of the test being Registered')
        public String covidTestId;
    }

    @InvocableMethod(Label='Randox - Register Test' Description='Register a test with URN previously assigned by Randox')
    public static List<RegisterTestResponse> registerTests(List<RegisterTestRequest> testData) {
        List<RegisterTestResponse> response = new List<RegisterTestResponse>();
        Map<Id, COVID_Test__c> covidTestsToUpdate = populateCovidTestData(testData);

        //master try catch for any authentication errors
        try {
            String token = RandoxAPI.getAuthToken();
            for (RegisterTestRequest testRequest : testData) {
                RegisterTestResponse testResponse = new RegisterTestResponse();
                testResponse.covidTestId = testRequest.covidTestId;
                try {
                    testResponse.message = RandoxAPI.registerKit(token, createRegisterRequest(testRequest));
                    testResponse.success = (testResponse.message == RandoxAPI.RANDOX_SUCCESS_MESSAGE);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, ex.getMessage() + ' - ' + ex.getStackTraceString());
                    testResponse.success = false;
                    testResponse.message = 'Randox registration error: ' + ex.getMessage();

                }
                response.add(testResponse);
                if (testResponse.success) {
                    covidTestsToUpdate.get(testRequest.covidTestId).COVID_Test_Status__c = 'Registered';
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage() + ' - ' + ex.getStackTraceString());
            String errorMessage = 'Randox authentication error: ' + ex.getMessage();
            for (RegisterTestRequest testRequest : testData) {
                RegisterTestResponse testResponse = new RegisterTestResponse();
                testResponse.success = false;
                testResponse.message = errorMessage;
                testResponse.covidTestId = testRequest.covidTestId;

                response.add(testResponse);
            }
        }
        if (!covidTestsToUpdate.isEmpty()) {
            update covidTestsToUpdate.values();
        }
        return response;
    }

    @TestVisible static RandoxAPI.RandoxManagedRegistration createRegisterRequest(RegisterTestRequest testRequest) {
        RandoxAPI.RandoxManagedRegistration registerKitRequest = new RandoxAPI.RandoxManagedRegistration();

        registerKitRequest.country = Integer.valueOf(testRequest.country);
        registerKitRequest.firstName = testRequest.firstName;
        registerKitRequest.lastName = testRequest.lastName;
        registerKitRequest.email = OnlineStoreSettingsManager.getRegistrationEmail();
        registerKitRequest.phone = OnlineStoreSettingsManager.getRegistrationPhone().replace('+', '').replace(' ', '');
        registerKitRequest.postcode = testRequest.postcode;
        registerKitRequest.addressLine1 = testRequest.addressLine1;
        registerKitRequest.dateOfBirth = RandoxAPI.formatRandoxDate(testRequest.dateOfBirth);
        registerKitRequest.ethnicity = Integer.valueOf(testRequest.ethnicity);
        registerKitRequest.gender = testRequest.gender;
        registerKitRequest.passportNumber = testRequest.passportNumber;
        registerKitRequest.swabCollectionDate = RandoxAPI.formatRandoxDateTime(testRequest.swabCollectionDate);
        registerKitRequest.town = testRequest.town;
        registerKitRequest.urn = testRequest.urn;

        return registerKitRequest;
    }

    @TestVisible static Map<Id, COVID_Test__c> populateCovidTestData(List<RegisterTestRequest> testData) {
        Map<Id, COVID_Test__c> covidTestsToUpdate = new Map<Id, COVID_Test__c>();
        for (RegisterTestRequest testRequest : testData) {
            COVID_Test__c covidTest = new COVID_Test__c(Id = testRequest.covidTestId);

            covidTest.Provided_Country__c = testRequest.country;
            covidTest.Provided_First_Name__c = testRequest.firstName;
            covidTest.Provided_Last_Name__c = testRequest.lastName;
            covidTest.Provided_Email__c = testRequest.email;
            covidTest.Provided_Phone_Number__c = testRequest.phone;
            covidTest.Provided_Postal_Code__c = testRequest.postcode;
            covidTest.Provided_Street__c = testRequest.addressLine1;
            covidTest.Provided_Date_of_Birth__c = testRequest.dateOfBirth;
            covidTest.Provided_Ethnicity__c = testRequest.ethnicity;
            covidTest.Provided_Gender__c = testRequest.gender;
            covidTest.Provided_Passport_Number__c = testRequest.passportNumber;
            covidTest.Swab_Collection_Date__c = testRequest.swabCollectionDate;
            covidTest.Provided_City__c = testRequest.town;
            covidTest.Test_URN__c = testRequest.urn;

            covidTestsToUpdate.put(testRequest.covidTestId, covidTest);
        }
        return covidTestsToUpdate;
    }
}