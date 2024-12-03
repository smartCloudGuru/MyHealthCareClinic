/**
* @author Zoran Zunko
* @date 4/20/21
*
*/

@IsTest class  onl_InfoFormCtrlTest {
    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<COVID_Test__c> covidTests = TestDataFactory.createCovidTests(accounts, 1, false);
        covidTests[0].Test_URN__c = 'R123456789';
        insert covidTests;
    }

    @IsTest static void getCovidTestForUUID_test() {
        COVID_Test__c covidTest = [SELECT Id, UUID__c FROM COVID_Test__c];

        System.assert(null != onl_InfoFormCtrl.getCovidTestForUUID(covidTest.UUID__c));
    }

    @IsTest static void getCustomSettings_test() {
        onl_InfoFormCtrl.getCustomSettings();
    }

    @IsTest static void storeCovidTest_test() {
        String covidTestString = JSON.serialize([
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
                        Provided_Street__c,
                        Provided_Transit_Date__c,
                        Provided_Vaccination_Status__c,
                        Provided_Vaccine__c,
                        Randox_arrivalDate__c,
                        Test_Type__c,
                        UUID__c
                FROM COVID_Test__c][0]);

        System.assert(null != onl_InfoFormCtrl.storeCovidTest(covidTestString));
        try {
            onl_InfoFormCtrl.storeCovidTest('asd');
        } catch (Exception e) {

        }
    }
}