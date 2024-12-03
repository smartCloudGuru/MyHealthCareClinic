@isTest(seeAllData=true)
Public class AppointmentUpdateFromMeddbase_test{
   Public static testMethod void updateApt(){  
            
         Site__c objSite = new Site__c();
            objSite.name = 'MyHealthcare Clinic - WANDSWORTH';
            objSite.Meddbase_Key__c = 10001;
            insert objSite;
          
          Clinician__c objClinician = new Clinician__c();
            objClinician.name = 'testName';
            objClinician.Meddbase_Key__c = 5622; 
            insert objClinician;   
              
          Proposed_Appointment__c objPap = new Proposed_Appointment__c();
            objPap.MeddBase_key__c = '12341';
            objPap.Payer_Type__c= 'Rajwara'; 
            objPap.Site__c = objSite.id;
            objPap.Clinician__c = objClinician.id;
            objPap.Start__c = system.now();
            objPap.Finish__c = system.now().addMinutes(10);
            //objpap.Appointment_Slot__c = objSlt.id;
            insert objPap;
          Appointment_Slot__c s= new Appointment_Slot__c();
            s.Start__c = objPap .Start__c;
            s.Site__c = objPap .Site__c;
            s.Resource_Key__c = null;
            s.Finish__c = objPap .Finish__c;
            s.Clinician__c = objPap .Clinician__c; 
            s.Appointment_Type__c = objPap.Appointment_Type__c;
            s.External_Key__c = objPap .External_Key__c;
            s.Proposed_Appointment__c = objPap.Id;
            insert s;    
             
         AppointmentUpdateFromMeddbase.doPost('test'); 
         AppointmentUpdateFromMeddbase.converToDatetime('14/09/2018','15:00');  
         
         AppointmentUpdateFromMeddbase.Consultants objCon = new AppointmentUpdateFromMeddbase.Consultants ();
           objCon.Item = '5555';
           
         AppointmentUpdateFromMeddbase.Event objEve= new AppointmentUpdateFromMeddbase.Event();
           objEve.x_4 = '01';
           objEve.x_3 = '02';
           objEve.x_2 = '03';
           objEve.x_1 = '04';
           objEve.x_0 = '05';
           
         AppointmentUpdateFromMeddbase.EventIds objEvid = new AppointmentUpdateFromMeddbase.EventIds();
           objEvid.Event = objEve;
           
         AppointmentUpdateFromMeddbase.msg objMsg = new AppointmentUpdateFromMeddbase.msg();
           objMsg.Consultants = objCon;
           objMsg.PatientAddressCounty = 'Any Country';
           objMsg.PatientAddressCity = 'London';
           objMsg.PatientAddressCountry = 'Any';
           objMsg.PatientAddressLine1 = 'Any1';
           objMsg.PatientAddressPostCode= 'SW12';
           objMsg.PatientDateOfBirth = '12/12/2000';
           objMsg.PatientEmail= 'Test@test.com';
           objMsg.PatientSurname= 'Narayan';
           objMsg.PatientMobileNumber= '126654';
           objMsg.PatientForename= 'Xyz';
           objMsg.PatientSex= 'Male';
           objMsg.PatientID= 'X122x3';
           objMsg.PatientTitle= 'MHC';
           objMsg.AppointmentSite= 'Fulham';
           objMsg.PatientGPId= '12369';
           objMsg.AppointmentSiteId= '778';
           objMsg.InsurerId= '6965';
           objMsg.AppointmentStatus= 'Arrived';
           objMsg.AppointmentBookedServices= 'Go';
           objMsg.AppointmentType= 'GP';
           objMsg.AppointmentDuration= '30';
           objMsg.AppointmentTime= '12:00';
           objMsg.AppointmentConsultantId= '6965';
           objMsg.AppointmentDate= '10/10/2018';
           objMsg.AppointmentConsultant= 'Jassar';
           objMsg.AppointmentNotes= 'Come Again';
           objMsg.AppointmentID= '8888';
           objMsg.EventIds= objEvid ;
           objMsg.AppointmentUpdatedBy= 'Lily';
           objMsg.EpisodeId= '65478';
         AppointmentUpdateFromMeddbase.AppointmentParser objAptparser = new AppointmentUpdateFromMeddbase.AppointmentParser();
           objAptparser.msg = objMsg;
           Account objAcc = new Account ();
           objAcc.Name = objMsg.PatientSurname;
           objAcc.PersonEmail = objMsg.PatientEmail; 
        
         AppointmentUpdateFromMeddbase.createProposedAppointment(objAptparser,objPap.id); 
         AppointmentUpdateFromMeddbase.updateAppointmentTime(objAptparser); 
         
         AppointmentUpdateFromMeddbase.getPatienByEmailAndName(objAptparser);
         AppointmentUpdateFromMeddbase.updateSameTimeOtherAppointment(objClinician.id,objPap.Start__c,10);
         
   }
       
}