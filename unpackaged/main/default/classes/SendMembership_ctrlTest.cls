@isTest
Public class SendMembership_ctrlTest {
    @testSetup static void test() {
        RecordType personAccountRecordType = AccountManager.getPatientRecordType();
        Account acc = new Account();
        acc.RecordTypeID = personAccountRecordType.id;
        acc.Date_of_Birth__c = system.today();
        acc.Gender__c = 'Male' ;
        acc.FirstName = 'Test FName';
        acc.LastName = 'Test LName';
        acc.Patient_Type__c = 'Member';
        acc.Membership_Level__c = 'Child';
        acc.Membership_Type__c = '2022Sep MHC Premium';
        //acc.Receptionist__c = 'Lily Metaj';
        acc.Clinician__c = 'Akash Patel';
        acc.Payment_Frequency__c = 'Monthly';
        acc.Home_Clinic__c = 'Fulham';
        acc.PersonEmail = 'abhishekanand.sfdc@gmail.com';
        acc.Contract_Sent_Date__c = system.today();
        acc.Signature_Date__c = system.today().AddDays(1);
        acc.BillingStreet = 'illingStreet';
        acc.BillingPostalCode = 'PostalCode';
        acc.BillingState = 'ingState';
        acc.BillingCountry = 'ingCountry';
        acc.BillingCity = 'lingCity';
        insert acc;
        update acc;
    }
    @isTest Public static void test1() {
        Test.StartTest();
        Account acc = [
                Select id, General_Physician__c, Dentist__c, Patient_Type__c, Membership_Level__c, Membership_Type__c,
                        Receptionist__c, Clinician__c, Payment_Frequency__c, Home_Clinic__c, BillingStreet, BillingPostalCode, BillingState, BillingCountry,
                        BillingCity, PersonEmail
                from Account
        ];
        SendMembership_ctrl.getAccount(acc.id);
        List<string> testStringList = SendMembership_ctrl.getPicklistvalues('Account', 'Patient_Type__c', false);
        SendMembership_ctrl.updatePatient(acc, 'Akash Patel', false);
        Test.StopTest();
    }
}