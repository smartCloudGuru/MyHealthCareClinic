@isTest
Private class ResetPassword_Test{
    static testMethod void ResetTest(){ 
    ApexPages.currentPage().getParameters().put('key','io');
    ResetPassword_Ctrl objResetpass = new ResetPassword_Ctrl();
    MeddBase_Settings__c objmed = new MeddBase_Settings__c();
            objmed.Stripe_Public_Key__c = 'loopes';
            objmed.Client_Key__c = 'A12s2w';
            objmed.Name = 'meddbase';
            insert objmed;
    RecordType personAccountRecordType = AccountManager.getPatientRecordType();
    Account acc = new Account(
               RecordTypeID=personAccountRecordType.id,
               FirstName='Test FName',
               LastName='Test LName',  
               PersonMailingPostalCode='12345',  
               PersonEmail='test@yahoo123.com', 
               Date_of_Birth__c = System.today() 
                );
                insert acc;  
        ResetPassword_Ctrl.init('test@yahoo123.com');
        ResetPassword_Ctrl.resetPassword('laxmi','narayan','01/01/2000','123456','201301','abcdef125');
        ResetPassword_Ctrl.genratePassword('laxmi@test.com','laxmi','narayan','01/01/2000');  
    }
}