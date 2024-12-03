@isTest
public class CommonUtility_Test {
    static testMethod void commonUtil() {
        Test.StartTest();
        Site__c ste = new Site__c();
        ste.Name = 'TestSite';
        insert ste;

        Appointment_Slot__c objAps = new Appointment_Slot__c();
        objAps.Location_Key__c = 5698;
        objAps.Resource_Key__c = 0;
        objAps.Site__c = ste.id;
        objAps.Finish__c = system.today() + 5;
        objAps.Start__c = system.today();
        insert objAps;

        MeddBase_Settings__c medb = new MeddBase_Settings__c();
        medb.Name = 'meddbase';
        medb.Payer_Type__c = 'Admin';
        medb.Client_Key__c = 'clientKey';
        medb.Endpoint_URL__c = 'hiohiaabijabsbio';
        medb.Integration_Username__c = 'TestUsername';
        medb.Integration_User_Password__c = 'TestUserPassword';
        medb.IS_OH__c = true;
        medb.Booking_Payer_Type__c = 'TestBookingPayer';
        medb.Stripe_Public_Key__c = 'pk_test_HqQ9waWWVtB9CiBSWifsaePK';
        medb.Stripe_Secret_Key__c = 'sk_test_CuuDNGfbxb23WERDp0DpHoqX';
        insert medb;

        Proposed_Appointment__c objPap = new Proposed_Appointment__c();
        objPap.MeddBase_key__c = 'konno';
        objPap.Payer_Type__c = 'Rajwara';
        objPap.Primary_Attendee_Slot__c = objAps.id;
        objPap.Finish__c = system.today() + 5;
        objPap.Start__c = system.today();
        insert objPap;
        list<Proposed_Appointment__c> obj = new list<Proposed_Appointment__c>();
        obj.add(objPap);

        Appointment_Module__c objApm = new Appointment_Module__c();
        objApm.CurrencyCode__c = 'GBP';
        objApm.GrossPrice__c = 45;
        objApm.Key__c = 119770;
        objApm.Meddbase_Key__c = 'a1B9E00000175F2UAI119770';
        objApm.NetPrice__c = 45;
        objApm.Notes__c = 'Testing';
        objApm.Proposed_Appointment__c = objPap.id;
        objApm.Tax__c = 0;
        insert objApm;
        CommonUtility.dateFormat('01/01/1991');
        CommonUtility.getPatientByEmail('abc@gmail.com');
        CommonUtility.createBookingRequest(objPap.id);
        MeddBase_Settings__c obs = CommonUtility.objMeddBaseSettings;

        RecordType personAccountRecordType = AccountManager.getPatientRecordType();
        Account acc = new Account(
                RecordTypeID = personAccountRecordType.id,
                FirstName = 'Test FName',
                LastName = 'Test LName',
                Patient_Type__c = 'New',
                PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345',
                PersonMailingCity = 'SFO',
                PersonEmail = 'test@yahoo.com',
                PersonHomePhone = '1234567',
                PersonMobilePhone = '12345678'
        );
        insert acc;
        Opportunity ObjListOpp = new Opportunity(
                Name = 'test1',
                AccountID = acc.id,
                CloseDate = System.Today(),
                StageName = 'Qualification'
        );
        insert ObjListOpp;
        CommonUtility.OpporunityDeepClone(ObjListOpp, acc.id);
        CommonUtility.getPatientByEmail(acc.id);
        Test.StopTest();
        System.assert(ObjListOpp.Name != null);
    }
}