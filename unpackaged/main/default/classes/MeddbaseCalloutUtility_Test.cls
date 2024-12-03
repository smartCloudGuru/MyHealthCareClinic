@isTest
Private Class MeddbaseCalloutUtility_Test{
    Static TestMethod Void myUnitTest(){
        Test.startTest();
            MeddBase_Settings__c objmed = new MeddBase_Settings__c();
            objmed.Client_Key__c = 'api-mhctest';
            objmed.Name = 'meddbase';
            insert objmed;
            
            Appointment_Type__c objapt = new Appointment_Type__c ();
            objapt.Name='Dentist Consultation';
            objapt.Meddbase_Key__c = '212345';
            insert objapt;
             
            Clinician__c cl = new Clinician__c();
            cl.Name = 'Test Dr';
            cl.Meddbase_Key__c = 123456;
            insert cl;
            
            Site__c st = new Site__c();
            st.Name = 'FH';
            st.Aerona_Key__c =10;
            insert st;
              
            Proposed_Appointment__c objPap = new Proposed_Appointment__c();
            objPap.MeddBase_key__c = '12341';
            objPap.Payer_Type__c= 'PA';
            objPap.Patient__c = null; 
            objPap.Site__c = st.id;
            objPap.Clinician__c = cl.id;
            objPap.Appointment_Type__c = objapt.Id;
            objPap.Meddbase_Key__c = '123456';
            objPap.Start__c = System.today(); 
            insert objPap;    
            MeddbaseCalloutUtility.getAnonAppointmentTypes();
            MeddbaseCalloutUtility.getAnonSites();
            MeddbaseCalloutUtility.getAnonClinicians('Test');
            MeddbaseCalloutUtility.GetProposedAppointments('Test');
            try {
                    MeddbaseCalloutUtility.getCliniciansBySite('Test','Test',null);
                } catch (Exception e) {
            }
            try {
                    MeddbaseCalloutUtility.retriveProposedAppointmentByIntUser('212345','123456',null);
                } catch (Exception e) {
            }
            try {
                    MeddbaseCalloutUtility.syncAppointments('Test','Test',null);
                } catch (Exception e) {
            }
            try {
                    MeddbaseCalloutUtility.getDateTimeByString('2018-10-19T12:50:00');
                } catch (Exception e) {
            }
            try {
                    MeddbaseCalloutUtility.updatePA2NA(system.today(),'00000000bd9491f8',new list<AppointmentData.result>());
                } catch (Exception e) {
            }
            
            MeddbaseCalloutUtility.createPatient('Test');
            MeddbaseCalloutUtility.varifyBySMS('Test','Test');
            MeddbaseCalloutUtility.resetPassword('Test','Test','Test','Test');
            MeddbaseCalloutUtility.loginMeddbase('Test','Test','Test');
            MeddbaseCalloutUtility.bookAnAppointment('Test','Test','Test');
            MeddbaseCalloutUtility.retriveAppointment('Test','Test','Test');
            MeddbaseCalloutUtility.retrivePatientInfo('Test','Test'); 
            MeddbaseCalloutUtility.retriveProposedAppointment('Test','Test','Test','Test','Test','Test'); 
            MeddbaseCalloutUtility.syncTransferedWeeklyAppointments('Test','Test',null); 
             list<AppointmentData.result> objAptresult = new  list<AppointmentData.result>();
            MeddbaseCalloutUtility.upsertMissingSlots(system.today(),'00000000bd9491f8',objAptresult);
            
            
        Test.stopTest();
    }    
}