@isTest
private class PA_Booked_Online_Appt_tgr_Test{    
    public static testMethod void testPA(){  
       Account acc = new Account();
        acc.Name = 'TestAcc';
        acc.Aerona_Patient_Id__c =12;
        acc.Site__c = 'Wandsworth';
        acc.Date_of_Birth__c = system.today();        
        insert acc;
               
        Site__c st = new Site__c();
        st.Name = 'TestName';
        st.Aerona_Key__c =10;
        insert st;
        
        Clinician__c cl = new Clinician__c();
        cl.Name = 'Test';
        insert cl;
        
        Appointment_Type__c apt = new Appointment_Type__c();
        apt.Name = 'Dentist';
        apt.Aerona_Key__c = 123;
        insert apt;
              
        Proposed_Appointment__c pa = new Proposed_Appointment__c ();   
        pa.Start__c= system.Today();
        pa.Finish__c = system.Today()+5; 
        pa.Aerona_Key__c=10;
        pa.Appointment_Type__c = apt.id;     
        insert pa;
        pa.state__c ='Booked';
        pa.Patient__c=acc.id;
        pa.Site__c= st.id;
        pa.Clinician__c = cl.id;  
        update pa;
    }
  }