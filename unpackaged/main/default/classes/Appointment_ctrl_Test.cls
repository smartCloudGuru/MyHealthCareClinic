@isTest(seeAllData=true)
private class Appointment_ctrl_Test{
    private static testMethod void testApc(){ 
        MeddBase_Settings__c objmed = new MeddBase_Settings__c();
            objmed.Stripe_Public_Key__c = 'loopes';
            objmed.Name = 'meddbase';
            //insert objmed;  
        Appointment_Type__c app = new Appointment_Type__c();
            app.Name = 'Abc';
            app.Can_Book_Appointment__c = true;
            app.Cancellation_Policy__c = 'lop';
            insert app; 
        try{
            Appointment_ctrl.resetPassword( 'ln@gmail.com','Ali','moh','2000-02-01T13:02:25');
        }
        Catch(Exception e){
        }  
        Appointment_ctrl.SlotWpr objWrpSlots = new Appointment_ctrl.SlotWpr();
            objWrpSlots.startTime = '2000-02-01T13:02:25';
            objWrpSlots.finishTime = '2000-03-02T13:03:25';
            objWrpSlots.slotId = '00101';
        list<Appointment_ctrl.SlotWpr> objListSlot = new list<Appointment_ctrl.SlotWpr>();
            objListSlot.add(objWrpSlots);
            
        Appointment_ctrl.ClinicianWpr objWrpClin = new Appointment_ctrl.ClinicianWpr();
            //objWrpClin.cName = objMapClinc.get(app.id).name;//'testName';
            //objWrpClin.cSpec =  objMapApptype.get(app.id).name;//.name;//'testSpec';
            objWrpClin.cPhoto = 'TEstPhoto';
            objWrpClin.cNextAvailableAppointment = 'TestNextAppoint';
            objWrpClin.cNextAvailableAppointmentDate = system.now();//DateTime.parse('1999-03-02T13:03:25'); 
            objWrpClin.slots = objListSlot;
            objWrpClin.cId = '123';
            objWrpClin.cName = 'ABC Dr';
            objWrpClin.cSpec = 'testS';
            objWrpClin.cSex = 'Male';

        list<Appointment_ctrl.ClinicianWpr> objListClini = new list<Appointment_ctrl.ClinicianWpr>();
            objListClini.add(objWrpClin);
            
        Appointment_ctrl.ProposedAppointment objWrpPropAppmnt = new Appointment_ctrl.ProposedAppointment();
            objWrpPropAppmnt.sitename = 'testsite';
            objWrpPropAppmnt.siteId = '12938';
            objWrpPropAppmnt.objClinician = objListClini ;
        
        list<Appointment_ctrl.ProposedAppointment> objlistPAppt = new  list<Appointment_ctrl.ProposedAppointment>();
            objlistPAppt.add(objWrpPropAppmnt);
            
        Appointment_ctrl.Clinician objWrpClic = new Appointment_ctrl.Clinician();
            objWrpClic.image = 'test Image';
            objWrpClic.sex = 'testSe';
            objWrpClic.specialism = 'testSpecialism';
            objWrpClic.clinicianName = 'test Clinic';
            objWrpClic.clinicianId = '123';
        
        list<Appointment_ctrl.Clinician> objListClin = new list<Appointment_ctrl.Clinician>();
             objListClin.add(objWrpClic);
             
        Appointment_ctrl.ProposedBookingDetail objWrpPropBD = new Appointment_ctrl.ProposedBookingDetail();
            objWrpPropBD.site = 'www.testsitess.com';
            objWrpPropBD.objClinicians = objListClin ;
            
        map<Id,Clinician__c> objMapClinician = new   map<Id,Clinician__c>();
        
        Site__c objSite = new Site__c();
            objSite.name = objWrpPropAppmnt.sitename;// 'test site';
            objSite.Meddbase_Key__c = 10001;
            insert objSite;
            
        Clinician__c objClinician = new Clinician__c();
            objClinician.name = 'testName';
            objClinician.Meddbase_Key__c = 5622;
            //objClinician.Site__c = objSite.Id;
            insert objClinician;
            
        Appointment_Slot__c objAps = new Appointment_Slot__c();
            objAps.Finish__c= system.now();
            objAps.Location_Key__c= 5698;
            objAps.Site__c = objSite.id;
            objAps.Start__c = system.today();
            insert objAps;
            
        Proposed_Appointment__c objPap = new Proposed_Appointment__c();
            objPap.MeddBase_key__c = '12341';
            objPap.Payer_Type__c= 'Rajwara';
            objPap.Primary_Attendee_Slot__c = objAps.id;
            objPap.Site__c = objSite.id;
            objPap.Clinician__c = objClinician.id;
            insert objPap;
            
        Appointment_Module__c objApm = new Appointment_Module__c();
            objApm.CurrencyCode__c = 'GBP';
            objApm.GrossPrice__c= 45;
            objApm.Key__c = 119770;
            //objApm.Meddbase_Key__c = 'a1B9E00000175F2UAI119770';
            objApm.NetPrice__c = 45;
            objApm.Notes__c = 'Testing';
            objApm.Proposed_Appointment__c = objPap.id;
            objApm.Tax__c = 0;
            insert objApm;    
        
        Invoice__c Inv = new Invoice__c();
        string Mde = 'a120E0000007UDjQAM-1eefcde7d689d617f6530c9d552a67c6';
        Inv.Meddbase_Key__c= objPap.id;//.split('-')[0];
        insert Inv;
        Inv.Paid__c = true;
        update Inv;
        
        AppointmentBookingResponseDataError.error objWrpError = new AppointmentBookingResponseDataError.error();
            objWrpError.StatusCode = 020;
            objWrpError.EventType = 4440;
            objWrpError.EventCode = 3330;
            objWrpError.Message = 'Test Message';
            
        AppointmentBookingResponseDataError objClsABRDE = new AppointmentBookingResponseDataError();
            objClsABRDE.error = objWrpError ;
            objClsABRDE.status = 'confirmed';
        
        AppointmentBookingResponseDataOk objABRDR = new  AppointmentBookingResponseDataOk();
 
        AppointmentBookingResponseDataOk.Type  objType= new AppointmentBookingResponseDataOk.Type();
             objType.CanReferPatient    = true;
             objType.TelemedicineOption = true;
             objType.CanBookAppointment = true;
             objType.Key = '1256';
             objType.Notes = 'Myheart';
             objType.Name = 'yourheart';    
             objABRDR.status = 'test';
          
        AppointmentBookingResponseDataOk.Address objAdd = new AppointmentBookingResponseDataOk.Address();
             objAdd.Country  = 'India';
             objAdd.City  = 'Delhi';
             objAdd.County = 'Delhi region';
             objAdd.Address3 = 'Okhla';
             objAdd.PostCode = '203102';
             objAdd.Address2 = 'Mumbai';
             objAdd.Address1 = 'Kolkata';   
        AppointmentBookingResponseDataOk.Site objSit = new AppointmentBookingResponseDataOk.Site();
             objSit.Address = objAdd;
             objSit.Name = 'Myhealth';
             objSit.Key = 1236544;
        AppointmentBookingResponseDataOk.Clinician objCli = new AppointmentBookingResponseDataOk.Clinician();
             objCli.SexType  = 12364;
             objCli.Key  = 5622;
             objCli.FullName = 'Mo';
        AppointmentBookingResponseDataOk.BillingAddress objBli = new AppointmentBookingResponseDataOk.BillingAddress();
             
        AppointmentBookingResponseDataOk.Account objAcc = new AppointmentBookingResponseDataOk.Account();
             objAcc.Name='kann';
             objAcc.DateOfBirth = 'Dob';
             objAcc.EmailAddress = 'email';
             objAcc.SexType = 12563;
             objAcc.BillingAddress = objBli;
             objAcc.Surname = 'Sur';
             objAcc.EmployeeNumber = 'Emp';
             objAcc.TermsAndConditionsAccepted  = true;
             objAcc.Title='TTl';
             objAcc.StatisticalProcessingAccepted = true;
             objAcc.Key='Ke';
        AppointmentBookingResponseDataOk.Debtor objDbt = new AppointmentBookingResponseDataOk.Debtor();
             objDbt.IsCompany=true;
             objDbt.Name='yes';
             objDbt.Account= objAcc;
             objDbt.Address=objAdd;
        AppointmentBookingResponseDataOk.Creditor objCdt = new AppointmentBookingResponseDataOk.Creditor(); 
             objCdt.Name='moh';
             objCdt.Account=objAcc;
             objCdt.IsCompany= true;
        AppointmentBookingResponseDataOk.Invoice objInv = new AppointmentBookingResponseDataOk.Invoice();
             list<AppointmentBookingResponseDataOk.Items> Itm = new list<AppointmentBookingResponseDataOk.Items>();
             objInv.Items =Itm;
             objInv.Tax =12.2;
             objInv.TotalNet =32.6;
             objInv.TotalGross =96.2;
             objInv.CurrencyCode= 'curr';
             objInv.Paid= 32.5;
             objInv.I_Number = 566;
             list<String> sti = new list<String>{'w','r'};
             objInv.CreditNotes = sti;
             objInv.I_Date='opps';
             objInv.Debtor= objDbt;
             objInv.Creditor= objCdt;
             objInv.PayableOnline = true;
             objInv.Key = 'Kem';
        AppointmentBookingResponseDataOk.Patient objPtt = new AppointmentBookingResponseDataOk.Patient();   
             objPtt.Key = 'kem';
             objPtt.EmailAddress = 'Email';
             objPtt.DateOfBirth = 'DOB';
             objPtt.BillingAddress = objBli;
             objPtt.SexType = 1233;
             objPtt.EmployeeNumber = 'Emp';
             objPtt.Surname = 'Sur';
             objPtt.TermsAndConditionsAccepted = true;
             objPtt.Name = 'yes';
             objPtt.StatisticalProcessingAccepted =true;
             objPtt.Title='TTl';
             
        AppointmentBookingResponseDataOk.result objRes = new AppointmentBookingResponseDataOk.result();
             objRes.Clinician = objCli;
             objRes.Finish = 'Usam';
             objRes.Site = objSit;
             objRes.Start = 'account';
             objRes.Telemedicine = true;
             objRes.Type = objType;
             objRes.TelemedicineConnection = 'mo';
             objRes.StateColor = 'test';
             list<String> str = new list<string> {'s','d'};
             objRes.Modules = str;
             objRes.StateDisplayName = 'std';
             objRes.Invoice=objInv;
             objRes.State = 'std';
             objRes.Patient = objPtt;
             objPtt.Key = 'Mess';
             objABRDR.result= objRes;
        AppointmentBookingResponseDataOk.Items objItm = new AppointmentBookingResponseDataOk.Items();  
             objItm.Code = 'Cd';
             objItm.CurrencyCode = 'CCD';
             objItm.NetPrice = 123;
             objItm.Name = 'yasmin';
             objItm.Tax = 22.1;
             objItm.TypeName = 'Tyname';
             objItm.GrossPrice = 65.36;
             objPtt.Key = 'yahoo';
             System.assert(objType.CanBookAppointment == true);
              
        
        AppointmentBookingResponseData objClsABRD = new AppointmentBookingResponseData();
            objClsABRD.status = 'ok';
            objClsABRD.error = objClsABRDE;
            objClsABRD.ok = objABRDR;
        
              
        test.StartTest();
            PageReference pageRef = Page.Appointment;
            Test.setCurrentPage(pageRef);
            Appointment_ctrl con = new Appointment_ctrl();
            con.selectedSite = 'any';
            con.selectedAppointmentType = app.Id;
            con.stripePublicKey = objmed.Stripe_Public_Key__c; 
            map<Id,Appointment_Type__c> objMapApptype = Appointment_ctrl.appointmentTypeMap;// new map<Id,Appointment_Type__c>();
            map<Id,Clinician__c> objMapClinc =  Appointment_ctrl.clinicianMap;   //objMapApptype.put(app.id,app); 
            con.getsites();
            //Appointment_ctrl.loginPatient('test@myname','testPassword','0001');
           // objMapApptype     = con.selectedAppointmentType;
            con.getProposedAppointmentByAT();
            //Appointment_ctrl.appointmentTypeMap = objMapApptype ;            
            //Test.setCurrentPageReference(new PageReference('Page.Appointment')); 
            //System.currentPageReference().getParameters().put('id', app.id); 
            con.getAppoinmentTypes();
            con.getAppointmentByDate();
            Appointment_ctrl.clinicianMap = objMapClinician ;
            Appointment_ctrl.pay4Booking(objPap.id,'fdfdsfdsfds','0');
            Appointment_ctrl.getBookedAppointment(objPap.id);
            Appointment_ctrl.memberInvoiceUpdate(objPap.id,0,0,0);
            Appointment_ctrl.getDateTimeByString('2018-10-19T12:50:00');
            Appointment_ctrl.updatePA2NA('00000000bd9491f8',new list<AppointmentData.result>());
            try{
                Appointment_ctrl.bookAppointment('222:322:2221',objPap.id,null);
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.regVarifyBySMS('222','99999999999');
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.loginPatient('testUser','user@123',objPap.id);
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.createPatientonMeddBase('TestFName','TestLName','test112test@gmail.com','test@123','1999-02-01t13:02:25','TestAddress1',
                                                  'TestAddress2','TestAddress3','Delhi','India','201301','9999992222');
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.createPatient('TestFName','TestLName','test112test@gmail.com','test@123','1999-02-01T13:02:25','TestAddress1',
                                                  'TestAddress2','TestAddress3','Delhi','India','201301','9999992222');
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.convertLead2Account('');
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.createStringCharge('00','21');
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.getPatientFromMeddbase('00','21');
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.createPatientIfNotExist('{"status":"ok","result":{"Title":"Mr","Name":"John","Surname":"Lemon","SexType":1,"Initials":"JL","DateOfBirth":"1958-08-02T00:00:00","Mobile":"+444 895 523 411","Telephone":"+444 525 111 555","EmailAddress":"usman.sfdc@gmail.com","WorkEmailAddress":"usman.sfdc@gmail.com","Password":"jon4535lemon","Address":{"Address1":"Studio 99","Address2":"Backlok Street","Address3":"Camden","City":"London","County":"","PostCode":"N1 7NK","Country":"United Kingdom"},"NextOfKin":{"Relationship":"Mam","Name":"Mariel","Surname":"Lemon","Mobile":"+444 895 111 222","WorkTelephone":"+444 525 111 555","Address":{"Address1":"Studio 1","Address2":"Cardwell Roa","Address3":"Camden","City":"London","County":"","PostCode":"N1 7NK","Country":"United Kingdom"}}}}',app.Id);
            }Catch(Exception c){
            }
            try{
                Appointment_ctrl.getProposedAppointment('','','','','','');
            }catch(exception e){}
            try{
                Appointment_ctrl.createPatientIfNotExist('{"status":"ok","result":{"Title":"Mr","Name":"John","Surname":"Lemon","SexType":1,"Initials":"JL","DateOfBirth":"1958-08-02T00:00:00","Mobile":"+444 895 523 411","Telephone":"+444 525 111 555","EmailAddress":"usman.sfdc10019283@gmail.com","WorkEmailAddress":"usman.sfdc10019283@gmail.com","Password":"jon4535lemon","Address":{"Address1":"Studio 99","Address2":"Backlok Street","Address3":"Camden","City":"London","County":"","PostCode":"N1 7NK","Country":"United Kingdom"},"NextOfKin":{"Relationship":"Mam","Name":"Mariel","Surname":"Lemon","Mobile":"+444 895 111 222","WorkTelephone":"+444 525 111 555","Address":{"Address1":"Studio 1","Address2":"Cardwell Roa","Address3":"Camden","City":"London","County":"","PostCode":"N1 7NK","Country":"United Kingdom"}}}}',app.Id);
            }Catch(Exception c){
            }
            list<selectOption> pt = con.getPatientTypes();
            list<selectOption> ptc = con.getAppointmentTypeCategory();
            list<String> atc = Appointment_ctrl.getAppointmentTypesCategory('Member');
            list<String> atc1 = Appointment_ctrl.getAppointmentTypes('GP','Member');
            con.onChangeAppointmentType();
            con.getAeronaAppointments();
            Appointment_ctrl.ClinicianWpr cw = new Appointment_ctrl.ClinicianWpr();
            cw.cId = '123';
            cw.cName = 'Test Clinician';
            cw.cSpec = '';
            cw.cPhoto = '';
            cw.cSex = '1';
            cw.cNextAvailableAppointment = ''; 
            Appointment_ctrl.sortByLatestAvailableClincian(new list<Appointment_ctrl.ClinicianWpr>{cw,cw},'Desc');
            Appointment_ctrl.sortByLatestAvailableClincian(new list<Appointment_ctrl.ClinicianWpr>{cw,cw},'Asc');
        test.StopTest();
         
     
    }
}