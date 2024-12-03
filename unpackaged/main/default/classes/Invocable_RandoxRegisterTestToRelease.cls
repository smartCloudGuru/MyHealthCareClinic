/**
* Registers a test to release with Randox using the api @see RandoxAPI
* @author Zoran Zunko
* @date 4/21/21
*
*/
public with sharing class Invocable_RandoxRegisterTestToRelease {
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
        //extra ttr parameters we can nest objects - i think
        @InvocableVariable(Label = 'Arrival Date' Required = true Description = 'Arrival date and time')
        public Datetime arrivalDate;
        @InvocableVariable(Label = 'Travel Number' Required = true Description = 'Flight number, etc.')
        public String travelNumber;
        @InvocableVariable(Label = 'Country Travelled From' Required = true Description = 'Country of origin')
        public String countryTravelledFrom;
        @InvocableVariable(Label = 'Other Countries' Required = true Description = 'Other countries visited')
        public String otherCountries;
        @InvocableVariable(Label = 'NHS Number' Required = true Description = 'NHS')
        public String nhsNumber;
        @InvocableVariable(Label = 'Date Left Non Exempt Country' Required = true Description = '?')
        public Datetime dateLeftNonExemptCountry;
        @InvocableVariable(Label = 'Test Day' Required = true Description = '2,5,8')
        public String testingDay;
//        @InvocableVariable(Label = 'Customer Reference' Required = true Description = 'Randox Customer Locator Reference')
//        public String customerLocatorReference;
        @InvocableVariable(Label = 'Vaccinated?' Description = 'Vaccinated')
        public String vaccinated;
        @InvocableVariable(Label = 'Vaccine Name' Description = 'Vaccine Name')
        public String vaccineName;
//        @InvocableVariable(Label = 'Booking Reference' Description = 'Booking Reference')
//        public String BookingReference;
        @InvocableVariable(Label = 'internationalTravelColour' Description = '?')
        public String internationalTravelColour;

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
                    testResponse.message = RandoxAPI.registerKitTestToRelease(token, createRegisterRequest(testRequest));
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

    @TestVisible static RandoxAPI.RandoxManagedRegistrationTestToRelease createRegisterRequest(RegisterTestRequest testRequest) {
        RandoxAPI.RandoxManagedTestToRelease testToRelease = new RandoxAPI.RandoxManagedTestToRelease();
        testToRelease.addressLine1 = testRequest.addressLine1;
        testToRelease.town = testRequest.town;
        testToRelease.postcode = testRequest.postcode;
        testToRelease.arrivalDate = RandoxAPI.formatRandoxDateTime(testRequest.arrivalDate);
        testToRelease.travelNumber = testRequest.travelNumber;
        testToRelease.countryTravelledFrom = Integer.valueOf(testRequest.countryTravelledFrom);
        testToRelease.otherCountries = testRequest.otherCountries;
        testToRelease.nhsNumber = testRequest.nhsNumber;
        testToRelease.dateLeftNonExemptCountry = RandoxAPI.formatRandoxDateTime(testRequest.dateLeftNonExemptCountry);
        testToRelease.testingDay = Integer.valueOf(testRequest.testingDay);
//        testToRelease.customerLocatorReference = testRequest.customerLocatorReference;
        testToRelease.customerLocatorReference = testRequest.covidTestId;
        testToRelease.vaccinated = testRequest.vaccinated == 'Yes';
        testToRelease.vaccineName = testRequest.vaccineName;
//        testToRelease.BookingReference = testRequest.BookingReference;
        testToRelease.BookingReference = testRequest.travelNumber;
        testToRelease.internationalTravelColour = testRequest.internationalTravelColour;

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

        RandoxAPI.RandoxManagedRegistrationTestToRelease testToReleaseFull = new RandoxAPI.RandoxManagedRegistrationTestToRelease();
        testToReleaseFull.testToRelease = testToRelease;
        testToReleaseFull.registration = registerKitRequest;

        return testToReleaseFull;
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
            //test to release part
            covidTest.Randox_arrivalDate__c = testRequest.arrivalDate;
            covidTest.Provided_Flight_Number__c = testRequest.travelNumber;
            covidTest.Test_To_Release_Type__c = testRequest.testingDay;
            covidTest.Provided_Vaccination_Status__c = testRequest.vaccinated;
            covidTest.Provided_Vaccine__c = testRequest.vaccineName;
            covidTest.Randox_internationalTravelColour__c = testRequest.internationalTravelColour;
            covidTest.Randox_otherCountries__c = testRequest.otherCountries;
            covidTest.Randox_dateLeftNonExemptCountry__c = testRequest.dateLeftNonExemptCountry;
            covidTest.Provided_NHS_Number__c = testRequest.nhsNumber;

            covidTestsToUpdate.put(testRequest.covidTestId, covidTest);
        }
        return covidTestsToUpdate;
    }
}