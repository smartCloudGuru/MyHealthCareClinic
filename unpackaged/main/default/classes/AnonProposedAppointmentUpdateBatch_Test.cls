@isTest
private class AnonProposedAppointmentUpdateBatch_Test{
    static testMethod void unitTest(){
        Test.startTest();
        MeddBase_Settings__c objmed = new MeddBase_Settings__c();
        objmed.Client_Key__c = 'api-mhctest';
        objmed.Name = 'meddbase';
        objmed.Meddbase_Token_Session__c = 'af24f488-a0a6-4c0b-bca8-396458ca42c1_@_uriscm043bv4biy50pvqa2vb';
        insert objmed;
        /*Appointment_Type__c objapt = new Appointment_Type__c ();
        objapt.Name='laxmi';
        insert objapt;
        Clinician__c objC = new Clinician__c();
        insert objC; 
        Clinician_Appoinment_Types__c objCAT = new Clinician_Appoinment_Types__c();
        objCAT.Appointment_Type__c = objapt.Id;
        objCAT.Clinician__c = objC.Id;
        objCAT.Available__c = true;
        insert objCAT;*/
        Appointment_Type__c objapt = new Appointment_Type__c ();
        objapt.Name='Dentist Consultation';
        objapt.Meddbase_Key__c = '212345';
        insert objapt; 
        Clinician__c cl = new Clinician__c();
        cl.Name = 'Test Dr';
        cl.Meddbase_Key__c = 123456;
        insert cl;
        Clinician_Appoinment_Types__c objCAT = new Clinician_Appoinment_Types__c();
        objCAT.Appointment_Type__c = objapt.Id;
        objCAT.Clinician__c = cl.Id;
        objCAT.Available__c = true;
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
        Proposed_Appointment__c objPap1 = new Proposed_Appointment__c();
        objPap1.MeddBase_key__c = '123411';
        objPap1.Payer_Type__c= 'PA'; 
        objPap1.Site__c = st.id;
        objPap1.Clinician__c = cl.id;
        objPap1.Appointment_Type__c = objapt.Id;
        objPap1.Start__c = system.now();
        //objpap.Appointment_Slot__c = objSlt.id;
        insert objPap1;    
        Aerona_Site__c ars  = new Aerona_Site__c (); 
        ars.Aerona_Clinician_key__c = 4925;
        ars.Aerona_Site_Key__c = 250;
        ars.Clinician__c = cl.Id;
        ars.Site__c = st.Id; 
        insert ars;   
        AnonProposedAppointmentUpdateBatch obj = new AnonProposedAppointmentUpdateBatch();
        DataBase.executeBatch(obj);   
    }
}