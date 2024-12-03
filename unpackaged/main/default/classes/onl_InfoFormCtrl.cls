/**
 * @author Zoran Zunko
 *
 * @date 4/19/21
 */
public without sharing class onl_InfoFormCtrl {

    // get custom settings (in aura enabled function to pass to LWC)
    @AuraEnabled(Cacheable=true)
    public static String getCustomSettings() {
        return OnlineStoreSettingsManager.getStoreSettings().IdealPostcodes_API_Key__c;
    }

    @AuraEnabled(Cacheable = false)
    public static String getCovidTestForUUID(String uuid) {
        try {
            List<COVID_Test__c> response = [
                    SELECT
                            Countries_Visited__c,
                            Destination_Country__c,
                            Flight_Date__c,
                            Name,
                            Provided_City__c,
                            Provided_Country__c,
                            Provided_Date_of_Birth__c,
                            Provided_Email__c,
                            Provided_Ethnicity__c,
                            Provided_First_Name__c,
                            Provided_Flight_Number__c,
                            Provided_Gender__c,
                            Provided_Isolation_Address__c,
                            Provided_Last_Name__c,
                            Provided_Mobile_Phone__c,
                            Provided_NHS_Number__c,
                            Provided_Passport_Number__c,
                            Provided_Phone_Number__c,
                            Provided_Postal_Code__c,
                            Provided_Address_Line1__c,
                            Provided_Address_Line2__c,
                            Provided_Flat_House_No__c,
                            Provided_Street__c,
                            Provided_Transit_Date__c,
                            Provided_Vaccination_Status__c,
                            Provided_Vaccine__c,
                            Randox_arrivalDate__c,
                            Test_Type__c,
                            UUID__c
                    FROM COVID_Test__c
                    WHERE UUID__c = :uuid
            ];

            if (response.isEmpty()) return null;
            else {
                response[0].Id = null;
                return JSON.serialize(response[0]);
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            AuraHandledException aEx = new AuraHandledException(e.getMessage());aEx.setMessage(e.getMessage());throw aEx;
        }
    }

    @AuraEnabled
    public static Boolean storeCovidTest(String covidTestString) {
        try {

            COVID_Test__c covidTest = (COVID_Test__c) JSON.deserialize(covidTestString, COVID_Test__c.class);
            upsert covidTest UUID__c;
            return true;

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            AuraHandledException aEx = new AuraHandledException(e.getMessage());aEx.setMessage(e.getMessage());throw aEx;
        }
    }
}