@isTest
Private class AeronaCalloutUtility_Test{
    static testMethod void AeronaCallTest(){
       Test.startTest();
        MeddBase_Settings__c objme = new MeddBase_Settings__c();
        objme.Client_Key__c = 'api-mhctest';
        objme.Name = 'meddbase';
        insert objme; 
        
        Account acc = new Account();
        acc.Name = 'test';
        acc.Gender__c = 'male';
        acc.Date_of_Birth__c = system.today();
        acc.Patient_Type__c= 'New';
        acc.Aerona_Patient_Id__c = 123;
        insert acc;
           
        Site__c st = new Site__c();
        st.Name = 'test';
        st.Aerona_Key__c =10;
        insert st;
        
        Clinician__c cl = new Clinician__c();
        cl.Name = 'Test';
        insert cl;
        
        Proposed_Appointment__c objPap = new Proposed_Appointment__c();
        objPap.MeddBase_key__c = '12341';
        objPap.Payer_Type__c= 'Rajwara'; 
        objPap.Site__c = st.id;
        objPap.Clinician__c = cl.id;
        //objpap.Appointment_Slot__c = objSlt.id;
        insert objPap;
       
        Aerona_Site__c ars  = new Aerona_Site__c (); 
        ars.Aerona_Clinician_key__c = 4925;
        ars.Aerona_Site_Key__c = 250;
        ars.Clinician__c = cl.Id;
        ars.Site__c = st.Id; 
        insert ars;
         
        AeronaCalloutUtility.loginHandler();  
        AeronaCalloutUtility.createAppointment(null,'test','test1',98987,'test3','test4','test5',1029,'test6','adsdsa2@dsd.com','Test','My Name','2010-01-01',null);
        AeronaCalloutUtility.updateAppointment(null,String.ValueOf('p.Aerona_Key__c'),String.ValueOf('p.Site__r.Aerona_Key__c'),String.ValueOf('objAeronaSite.get(0).Aerona_Clinician_key__c'),String.ValueOf('p.Appointment_Type__r.Aerona_Key__c'),String.ValueOf('p.Start__c.getTime()'),String.ValueOf('p.Duration__c'),null);
        AeronaCalloutUtility.getPatientSearch('token'); 
        AeronaCalloutUtility.getClinicians(130,'Aeronatoken');
        AeronaCalloutUtility.getListByName('lst','token');
        try{ 
           AeronaCalloutUtility.getAppointmentTypes();
           }catch(Exception e){
        }
        try{
           AeronaCalloutUtility.findSlots(456,852,123,'Str');
           }catch(Exception e){
        }  
         try{
            AeronaCalloutUtility.updateAeronaSite(new list<AeronaCalloutUtility.AeronaSite>(),'test');
            }catch(Exception e){
        }
         try{
            AeronaCalloutUtility.result objre = new AeronaCalloutUtility.result();
            objre.clinicianName = 'test';
            AeronaCalloutUtility.AeronaClinician objAaeronacli = new AeronaCalloutUtility.AeronaClinician();
            objAaeronacli.result = new list<AeronaCalloutUtility.result>{objre};
            AeronaCalloutUtility.updateAeronaClinician(objAaeronacli, 130);
            }catch(Exception e){
        }
        AeronaCreatedPatientResult acp = new  AeronaCreatedPatientResult();
        acp.errorResult = '';
        acp.result = new List<AeronaCreatedPatientResult.result>();
        acp.errorCode = 0;
        acp.status = 'ok';        
        AeronaCalloutUtility.createAeronaPatient('9999999900','forename', 'surname', 'practiceId', '2018-09-10', 'emailAddress','test');
        AeronaCalloutUtility.getPatientSearchByFilter(null,null,null,null,null,null,null,null);
        map<String,Id> clinicianMap = AeronaCalloutUtility.clinicianMap;
        map<Integer,Id> sitesMap = AeronaCalloutUtility.sitesMap;
        AeronaCalloutUtility.AeronaCreatedAppointmentResult objAcar = new AeronaCalloutUtility.AeronaCreatedAppointmentResult();
        objAcar.errorResult= 'test';
        objAcar.result = 12;
        objAcar.errorCode = 21;
        objAcar.status = 'booked';
        AeronaCalloutUtility.AeronaSite objAesite = new AeronaCalloutUtility.AeronaSite();
        objAesite.value = 'test';
        objAesite.key = 85;
        list<AeronaCalloutUtility.result> lst = new list<AeronaCalloutUtility.result>();
        AeronaCalloutUtility.AeronaClinician objAeclinician = new AeronaCalloutUtility.AeronaClinician();
        objAeclinician.result = lst;
        objAeclinician.errorResult = 'test';
        objAeclinician.errorCode = 12;
        objAeclinician.status = 'testint';
        AeronaCalloutUtility.result objAeresult = new AeronaCalloutUtility.result();
        objAeresult.clinicianName = 'test';
        objAeresult.id = 12; 
        Test.stopTest();
    } 
 }