@isTest      
Private class AeronaFindSlotsBatch_test{
    Static testMethod void slotTest(){
        Test.StartTest();
        Site__c st = new Site__c();
        st.Name = 'TestName';
        st.Aerona_Key__c =10;
        insert st;
        
        Clinician__c cl = new Clinician__c();
        cl.Name = 'Test';
        insert cl;
        
        list<Aerona_Site__c> lstAer = new list<Aerona_Site__c>();
        Aerona_Site__c ars  = new Aerona_Site__c (); 
        ars.Aerona_Clinician_key__c = 4925;
        ars.Aerona_Site_Key__c = 250;
        ars.Clinician__c = cl.Id;
        ars.Site__c = st.Id; 
        lstAer.add(ars);
        insert lstAer;
        
        MeddBase_Settings__c objme = new MeddBase_Settings__c();
        objme.Client_Key__c = 'api-mhctest';
        objme.Name = 'meddbase';
        objme.Aerona_Endpoint__c = 'https://aeronadental.com';
        objme.Aerona_Username__c='API';
        objme.Aerona_Password__c='MHCWandsworth';
        objme.Aerona_Pin__c='7551';
        insert objme; 
        
        Appointment_Type__c apt = new Appointment_Type__c();
        apt.Name = 'Dentist';
        apt.Aerona_Key__c = 123;
        insert apt;
        
        list<Proposed_Appointment__c> objPa = new list<Proposed_Appointment__c>(); 
        Proposed_Appointment__c pa = new Proposed_Appointment__c();
        pa.Start__c= system.Today();
        pa.Finish__c = system.Today()+5; 
        pa.Aerona_Key__c=10;
        pa.Is_Available_On_Aerona__c = true;
        pa.Clinician__c = cl.Id;
        pa.Site__c = st.Id;  
        pa.Appointment_Type__c = apt.id;    
        objPa.add(pa);    
        insert objPa;  
        AeronaFindSlotsBatch obj = new AeronaFindSlotsBatch();
        DataBase.executeBatch(obj); 
        Test.stopTest();
    }
}