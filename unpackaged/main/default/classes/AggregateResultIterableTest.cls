@isTest
private class AggregateResultIterableTest {
	static testMethod void unitTest(){
        Test.startTest();
        MeddBase_Settings__c objmed = new MeddBase_Settings__c();
        objmed.Client_Key__c = 'api-mhctest';
        objmed.Name = 'meddbase';
        objmed.Meddbase_Token_Session__c = 'af24f488-a0a6-4c0b-bca8-396458ca42c1_@_uriscm043bv4biy50pvqa2vb';
        insert objmed;
        Account acc = new Account();
        acc.Name = 'test';
        acc.Gender__c = 'male';
        acc.Date_of_Birth__c = system.today();
        acc.Patient_Type__c= 'New';
        acc.Aerona_Patient_Id__c = 123;
        insert acc;        
        Appointment_Type__c objapt = new Appointment_Type__c ();
        objapt.Name='Dentist Consultation';
        objapt.Meddbase_Key__c = '212345';
        insert objapt;
        Clinician__c objC = new Clinician__c();
        insert objC; 
        Clinician__c cl = new Clinician__c();
        cl.Name = 'Test Dr';
        insert cl;
        Clinician_Appoinment_Types__c objCAT = new Clinician_Appoinment_Types__c();
        objCAT.Appointment_Type__c = objapt.Id;
        objCAT.Clinician__c = cl.Id;
        insert objCAT;        
        Site__c st = new Site__c();
        st.Name = 'FH';
        st.Aerona_Key__c =10;
        insert st;        
        Proposed_Appointment__c objPap = new Proposed_Appointment__c();
        objPap.MeddBase_key__c = '12341';
        objPap.Payer_Type__c= 'PA'; 
        objPap.Site__c = st.id;
        objPap.Clinician__c = cl.id;
        objPap.Appointment_Type__c = objapt.Id;
        objPap.Start__c = system.now().addDays(1);
        //objpap.Appointment_Slot__c = objSlt.id;
        insert objPap;       
        Aerona_Site__c ars  = new Aerona_Site__c (); 
        ars.Aerona_Clinician_key__c = 4925;
        ars.Aerona_Site_Key__c = 250;
        ars.Clinician__c = cl.Id;
        ars.Site__c = st.Id; 
        insert ars;         
        SyncAppointmentsByIntegrationUserBatch obj = new SyncAppointmentsByIntegrationUserBatch();
        DataBase.executeBatch(obj);   
    }
}