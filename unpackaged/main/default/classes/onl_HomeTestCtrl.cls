/**
 * Created 14.10.2021..
 */

public without sharing class onl_HomeTestCtrl {

    // get custom settings (in aura enabled function to pass to LWC)
    @AuraEnabled(Cacheable=true)
    public static String getCustomSettings() {
        return OnlineStoreSettingsManager.getStoreSettings().IdealPostcodes_API_Key__c;
    }

    @AuraEnabled(Cacheable=false)
    public static String verifyOTP(String otp) {
        try {
            if (otp == null) return null;
            otp = otp.toUpperCase();
            List<OneTimePassword__c> otps = [SELECT Id FROM OneTimePassword__c WHERE Name = :otp AND IsUsed__c = FALSE LIMIT 1];

            if (otps.size() == 0) return null;

            //preprovision covid test
            COVID_Test__c ctest = new COVID_Test__c();
            ctest.COVID_Test_Status__c = 'New';
            ctest.Swab_Collection_Date__c = Datetime.now();
            ctest.Is_Result_from_Reseller_Test__c = true;
            ctest.Test_Type__c = 'Lateral Flow';
            ctest.Home_Kit_ID__c = otp;
            ctest.One_Time_Password__c = otps[0].Id;
            insert ctest;
            return JSON.serialize(ctest);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString()); AuraHandledException aEx = new AuraHandledException(e.getMessage()); aEx.setMessage(e.getMessage()); throw aEx;
        }
    }

    @AuraEnabled(Cacheable=false)
    public static String getCovidTestForUUID(String uuid) {
        try {
            List<COVID_Test__c> response = [
                    SELECT
                            Id,
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
                            UUID__c,
                            COVID_Test_Status__c,
                            Is_Home_Kit_Test__c,
                            Booking_Reference__c
                    FROM COVID_Test__c
                    WHERE UUID__c = :uuid
            ];

            if (response.isEmpty()) {
                return null;
            }
            else {
                return JSON.serialize(response[0]);
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString()); AuraHandledException aEx = new AuraHandledException(e.getMessage()); aEx.setMessage(e.getMessage()); throw aEx;
        }
    }

    @AuraEnabled
    public static String getHomeTestResultTypeOptions() {
        List<Online_Store_Lists_Config__c> conf = [SELECT Id, HomeTestListOptions__c FROM Online_Store_Lists_Config__c LIMIT 1];
        List<ValueLabelPair> ret = new List<onl_HomeTestCtrl.ValueLabelPair>();
        if (!conf.isEmpty()) {
            if (!String.isEmpty(conf[0].HomeTestListOptions__c)) {
                String[] opts = conf[0].HomeTestListOptions__c.split(';');
                for (String str : opts) {
                    ret.add(new ValueLabelPair(str));
                }
            }
        }
        return JSON.serialize(ret);
    }

    @AuraEnabled(Cacheable=true)
    public static String storeHomeTestResult(String params) {
        try {

            Datetime dtNow = Datetime.now();
            System.debug('storeHomeTestResult:params:' + params);
            ParamsWrapper input = (ParamsWrapper) JSON.deserialize(params, ParamsWrapper.class);

            COVID_Test__c ctest = input.test;

            ctest.COVID_Test_Status__c = 'Received';
            ctest.Swab_Collection_Date__c = dtNow;

            COVID_Test__c existingCovidTest = null;
            if (ctest.Id != null) {
                existingCovidTest = [SELECT Id, Patient__c, Patient__r.FirstName, Patient__r.LastName, Patient__r.Date_of_Birth__c, Home_Kit_ID__c, OwnerId, Booking_Reference__c FROM COVID_Test__c WHERE Id = :ctest.Id];
            }

            Account acc;

            System.debug('storeHomeTestResult:existingCovidTest exists?' + (existingCovidTest != null));

            if (existingCovidTest == null || existingCovidTest.Patient__c == null) {
                System.debug('storeHomeTestResult:no patient or no existingCovidTest');
                //find an eventual preexisting patient by the provided email
                List<Account> accounts = new List<Account>();
                if (ctest.Provided_Email__c != null) accounts = [SELECT Id, FirstName, LastName, Date_of_Birth__c FROM Account WHERE PersonEmail = :ctest.Provided_Email__c];

                if (accounts.isEmpty()) {
                    System.debug('storeHomeTestResult:no account found, creating one');
                    acc = new Account();
                    String rType = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                    acc.RecordTypeId = rType;
                    acc.FirstName = ctest.Provided_First_Name__c;
                    acc.LastName = ctest.Provided_Last_Name__c;
                    acc.PersonEmail = ctest.Provided_Email__c;
                    acc.Phone = ctest.Provided_Phone_Number__c;
                    acc.PersonMobilePhone = ctest.Provided_Mobile_Phone__c;
                    acc.Date_of_Birth__c = ctest.Provided_Date_of_Birth__c;
                    try {
                        acc.BillingPostalCode = ctest.Provided_Postal_Code__c;
                    }
                    catch (Exception ex) {
                    }
                    try {
                        acc.BillingStreet = ctest.Provided_Address_Line1__c;
                    }
                    catch (Exception ex) {
                    }
                    try {
                        acc.BillingCity = ctest.Provided_City__c;
                    }
                    catch (Exception ex) {
                    }
                    insert acc;
                }
                else {
                    System.debug('storeHomeTestResult:account found, using: ' + accounts[0].Id);
                    acc = accounts[0];
                    try {
                        for (Account accToUpdate : accounts) {
                            if ((ctest.Provided_First_Name__c?.toLowerCase() == acc.FirstName?.toLowerCase()) && (ctest.Provided_Last_Name__c?.toLowerCase() == acc.LastName?.toLowerCase())) {
                                accToUpdate.Date_of_Birth__c = ctest.Provided_Date_of_Birth__c;
                                update accToUpdate;
                            }
                        }
                    }
                    catch (Exception ignore) {
                    }
                }
            }
            else {
                System.debug('storeHomeTestResult:creating dummy account with ID ' + existingCovidTest.Patient__c);
                acc = new Account();
                acc.Id = existingCovidTest.Patient__c;
            }

            if (ctest.Id != null) {

                ctest.COVID_Test_Status__c = 'Received';

                if (ctest.UUID__c != null) {
                    upsert ctest UUID__c;
                }
                else {
                    ctest.Is_Result_from_Reseller_Test__c = true;
                    ctest.Patient__c = acc.Id;
                    update ctest;

                    try {
                        OneTimePassword__c otpc = [SELECT Id, Name, IsUsed__c FROM OneTimePassword__c WHERE Name = :existingCovidTest.Home_Kit_ID__c AND IsUsed__c = FALSE LIMIT 1];
                        otpc.IsUsed__c = true;
                        update otpc;
                    }
                    catch (Exception e) {
                    }

                }
            }
            else if (input.otpc != null) {
                //this is possible if the OneTimePassword has been entered manually.

                input.otpc = input.otpc.toUpperCase();
                List<OneTimePassword__c> otps = [SELECT Id, Name, IsUsed__c FROM OneTimePassword__c WHERE Name = :input.otpc AND IsUsed__c = FALSE LIMIT 1];
                if (otps.size() == 0) return 'INVALID_OTP';

                //provision covid test
                ctest.Is_Result_from_Reseller_Test__c = true; ctest.Home_Kit_ID__c = input.otpc;
                ctest.One_Time_Password__c = otps[0].Id; ctest.Patient__c = acc.Id;

                insert ctest;
                otps[0].IsUsed__c = true;
                update otps[0];
            }
            else {
                return null;
            }
            return ctest.Booking_Reference__c;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            AuraHandledException aEx = new AuraHandledException(e.getMessage()); aEx.setMessage(e.getMessage()); throw aEx;
        }
    }

    public static Boolean storeCovidTestByUUID(String covidTestString) {
        COVID_Test__c covidTest = (COVID_Test__c) JSON.deserialize(covidTestString, COVID_Test__c.class);
        upsert covidTest UUID__c;
        return true;
    }

    public class ParamsWrapper {
        public COVID_Test__c test;
        public String uuid;
        public String otpc;
        public String productId;
        //        public UploadedAttachment attachment1;
        //        public UploadedAttachment attachment2;
        //        public UploadedAttachment attachment3;
    }

    public class ValueLabelPair {
        public String value;
        public String label;

        public ValueLabelPair() {

        }

        public ValueLabelPair(String value) {
            this.value = value;
            this.label = value;
        }

    }


}