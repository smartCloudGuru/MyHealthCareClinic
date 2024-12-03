@isTest
Private Class MeddbaseStdBtnCallout_Test{
    static TestMethod Void myUnitTest(){
        Test.startTest();
            MeddBase_Settings__c objmed = new MeddBase_Settings__c();
            objmed.Client_Key__c = 'api-mhctest';
            objmed.Name = 'meddbase';
            insert objmed;
            MeddbaseStdBtnCallout.getAnonAppointmentTypes();
            MeddbaseStdBtnCallout.getAnonSites();
            MeddbaseStdBtnCallout.getAnonClinicians();
            MeddbaseStdBtnCallout.getAnonProposedAppointment();
        	MeddbaseStdBtnCallout.syncAppointmentsByIntegrationUser();
        Test.stopTest();
    }
}