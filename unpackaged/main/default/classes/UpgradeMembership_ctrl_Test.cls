@IsTest
private class UpgradeMembership_ctrl_Test {
    @IsTest
    static void testCancelMembership() {
        Account objAccount = new Account();

        objAccount.FirstName = 'Test FName';
        objAccount.LastName = 'Test LName';
        objAccount.PersonMailingStreet = 'test@yahoo.com';
        objAccount.PersonMailingPostalCode = '12345';
        objAccount.PersonMailingCity = 'SFO';
        objAccount.PersonEmail = 'test@yahoo.com';
        objAccount.PersonHomePhone = '1234567';
        objAccount.PersonMobilePhone = '12345678';
        objAccount.Relation_With_Payer__c = 'Brother';
        objAccount.Cancelled_membership__c = true;
        objAccount.Patient_Type__c = 'Member';
        objAccount.Membership_Type__c = '2019 MHC GP';
        objAccount.Membership_Level__c = 'Adult - Main Payer';
        objAccount.Membership_Add_On__c = 'Healthscreen';
        objAccount.Member_Status__c = 'Member';
        objAccount.Cancellation_Date__c = System.today();
        objAccount.Signature_Date__c = system.today();
        objAccount.Cancellation_Reason__c = 'Deceased';
        objAccount.Date_of_Birth__c = Date.newInstance(1990, 12, 9);
        objAccount.Gender__c = 'Male';
        objAccount.Home_Clinic__c = 'Home';
        objAccount.Payment_Frequency__c = 'Monthly';
        upsert objAccount;

        System.assertNotEquals(objAccount.Id, null, 'Assertion Failed : Account Not Inserted');

        try {
            Test.startTest();
            UpgradeMembership_ctrl.getAccount(objAccount.Id);
            Test.stopTest();
        }
        catch (DmlException e) {
        }

    }

    @IsTest
    static void testNewAuraHandledException() {
        UpgradeMembership_ctrl.newAuraHandledException('test');
    }

}