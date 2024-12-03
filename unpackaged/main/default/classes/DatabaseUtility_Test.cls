/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class DatabaseUtility_Test {

    static testMethod void myUnitTest() {
        AppointmentTypeData.result objRes = new AppointmentTypeData.result();
        objRes.Notes = 'vary';
        objRes.CanBookAppointment = true;
        objRes.CancellationPolicy = 'cancle';
        objRes.CanReferPatient= true;
        objRes.Key = 'ram';
        objRes.TelemedicineOption = true;
        objRes.Name = 'joe'; 
        Appointment_Type__c objApp = new Appointment_Type__c();
        objApp.Tele_Medicine_Option__c = objRes.TelemedicineOption;
        objApp.Notes__c = objRes.Notes;
        objApp.Name = objRes.Name;
        objApp.Meddbase_Key__c = objRes.Key;
        objApp.Cancellation_Policy__c = objRes.CancellationPolicy;
        objApp.Can_Refer_Patient__c = objRes.CanReferPatient;
        objApp.Can_Book_Appointment__c = objRes.CanBookAppointment;
        insert objapp;
        AppointmentTypeData objApd = new AppointmentTypeData();
        objApd.status = 'Ok';
        objApd.result = new list<AppointmentTypeData.result>{new AppointmentTypeData.result()};
                   
        SitesData.Address objAdd = new SitesData.Address();
        objAdd.Address3 = 'add';
        objAdd.County = 'India';
        objAdd.City = 'delhi';
        objAdd.PostCode = '1256';
        objAdd.Address2 = 'lebia';
        objAdd.Country = 'India';
        objAdd.Address1 = 'Katr';           
        
        SitesData.result objRelt = new SitesData.result();
        list<String> str = new list<String>{'s','d'};
        objRelt.Locations = str;
        objRelt.Address = objAdd;
        objRelt.Key = 12354;
        objRelt.Name = 'nove';
    
        Site__c objSt = new Site__c(); 
        objSt.City__c = 'Any City';
        objSt.Country__c = 'UK';
        objSt.PostCode__c = '88888888';
        objSt.Name = 'objRelt.Name' ;
        objSt.Meddbase_Key__c= 464546;
        insert objSt;
        
        list<SitesData.result> objListRslt = new list<SitesData.result>();
        objListRslt.add(objRelt);
        
        SitesData objStd = new  SitesData();
        objStd.status='ok';
        objStd.result = objListRslt;   
        
        ClinicianData.result objRel = new ClinicianData.result();
        objRel.Key = 1456;
        objRel.SexType = 1;
        objRel.FullName = 'mo';
        
        
        Clinician__c objCli = new Clinician__c();
        objCli.Name = objRel.FullName;
        
        objCli.Meddbase_Key__c = objRel.Key;
        objCli.Clinician_Sex__c = 'male';
        insert objCli;
        
        Appointment_Type__c objAT = new Appointment_Type__c();
        objAT.Name = 'ala';
        insert objAT;
        
        ClinicianData objSd = new  ClinicianData();
        objSd.status = 'ok';
        objSd.result = new list<ClinicianData.result>{new ClinicianData.result()}; 
        
        Proposed_Appointment__c Pap = new Proposed_Appointment__c();
        Pap.MeddBase_key__c= '12341';
        insert Pap; 
        
        AppointmentData.Type objty = new AppointmentData.Type();
        objty.Notes = 'LOPE';
        objty.Key = '12560';
        objty.Name = 'Steve';
        objty.CanBookAppointment = true;
        objty.CanReferPatient = true;
        objty.TelemedicineOption = true;
    
        AppointmentData.Slots objSlo = new AppointmentData.Slots();
        objSlo.Type = objty;  
        objSlo.Finish = string.valueof(system.now()+10); 
        objSlo.ResourceKey = 1226;
        objSlo.Start = string.valueof(system.now()); 
         
        list<AppointmentData.Slots> objLtSlot = new list<AppointmentData.Slots>();
        objLtSlot.add(objSlo);
        
        AppointmentData.Address objAds = new AppointmentData.Address();
        objAds.City = 'java';
        objAds.County = 'Python';
        objAds.Address3 = 'Php';
        objAds.PostCode = 'C';
        objAds.Address2 = 'cobol';
        objAds.Country = 'fortran';
        objAds.Address1 = 'not';
        
        AppointmentData.Site objSie = new AppointmentData.Site(); 
        objSie.Key= 1233;
        objSie.Address = objAds;
        objSie.Name ='Nortan';
         
        AppointmentData.Clinician objClin = new AppointmentData.Clinician();
        objClin.FullName = 'Narayan';
        objClin.SexType = 1225;
        objClin.Key = 1256;
         
        AppointmentData.PrimaryAttendeeSlot objPta = new AppointmentData.PrimaryAttendeeSlot();
        objPta.Type = objty;
        objPta.Site= objSie;
        objPta.Clinician = objClin; 
        objPta.Finish = string.valueof(system.now()+17); 
        objPta.ResourceKey = 1232;
        objPta.Start = string.valueof(system.now()); 
         
        AppointmentData.Invoice objAppInv = new AppointmentData.Invoice();
        objAppInv.PayableOnline = true;
        objAppInv.TotalNet = 22.10;
        objAppInv.CurrencyCode = '2000';
        objAppInv.Tax = 2.10;
        objAppInv.x_Number = 222222;
        objAppInv.TotalGross = 20000.20;
        objAppInv.x_Date = string.valueof(system.now()); 
        objAppInv.Paid = 1000.20;
        objAppInv.Key = '83883838';
        
        AppointmentData.Modules objMod = new AppointmentData.Modules();
        objMod.Tax = 22.22;
        objMod.NetPrice = 33.66;
        objMod.CurrencyCode ='Mode';
        objMod.GrossPrice =78.2;
        objMod.Key =782;
        objMod.Notes ='Lagre';
        objMod.Name ='smith';
        list<AppointmentData.Modules> Mdu = new list<AppointmentData.Modules>();
        Mdu.add(objMod);
        
        AppointmentData.result objResu = new AppointmentData.result(); 
        objResu.Clinician = objClin;
        objResu.Site = objSie;
        objResu.Telemedicine = true;
        objResu.Finish = string.valueof(system.now()+5); 
        objResu.Start = string.valueof(system.now()+1);  
        objResu.Invoice = objAppInv;
        objResu.Modules = Mdu ; 
        objResu.Clinician = objClin ;
        objResu.Site = objSie ;
        objResu.Telemedicine = true;
        objResu.Finish = string.valueof(system.now()+2); 
        objResu.Slots = objLtSlot ;
        objResu.Start = string.valueof(system.now()); 
        objResu.PrimaryAttendeeSlot = objPta;
        objResu.Type = objty;
        objResu.PayerType = 'test payer';
        objResu.Key = Pap.id;
        list<AppointmentData.result> objListResult = new list<AppointmentData.result>();
        objListResult.add(objResu);
        
        Site__c objt = new Site__c();
        objt.Name = 'Scrum';
        insert objt ;
        
        Clinician__c objclia = new Clinician__c();
        objclia .Name = 'Joke';
        insert objclia;
        
        Appointment_Slot__c objApts = new Appointment_Slot__c();
        objApts.Start__c =  system.now();
        objApts.Site__c =  objt.id; 
        objApts.Finish__c =  system.now();
        objApts.Clinician__c = objclia.id ;    
        insert objApts; 
        
        Proposed_Appointment__c p = new Proposed_Appointment__c();
        p.Telemedicine__c = true; 
        p.Start__c = system.now(); 
        p.Finish__c = system.now()+10;            
        p.Site__c = objSt.id; 
        p.Payer_Type__c = 'Test payer'; 
        p.MeddBase_key__c = Pap.id;  
        p.Clinician__c = objclia.id;  
        p.Appointment_Type__c = objapp.id;
        p.Primary_Attendee_Slot__c = objApts.id;     
        blob eKey = blob.valueOf(p.MeddBase_key__c+p.Start__c+p.Finish__c+p.Site__c+p.Clinician__c+p.Appointment_Type__c);
        p.External_Key__c = EncodingUtil.base64Encode(eKey);  
        database.insert( p,false);      
        AppointmentData objapo = new  AppointmentData();
        objapo.status = 'ok';
        objapo.result = objListResult;
        
        string dateTim = '2017-12-02T22:26:23.7160267+00:00';
        
        
        PatientRequestData.Address objWrpAdd = new PatientRequestData.Address();
        objWrpAdd.City = 'Delhi';
        objWrpAdd.County = 'India';
        objWrpAdd.Address3 = 'TestAddress';
        objWrpAdd.PostCode = '201301';
        objWrpAdd.Address2 = 'TestAddress2';
        objWrpAdd.Country = 'Canada';
        objWrpAdd.Address1 = 'TestAddress1';
        
        PatientRequestData.demog objWrpDemog = new PatientRequestData.demog();
        objWrpDemog.Address = objWrpAdd;
        objWrpDemog.EmailAddress = 'test112test@gmail.com';
        objWrpDemog.Password = 'test@123';
        objWrpDemog.Surname = 'Rawat';
        objWrpDemog.DateOfBirth = '2000-02-01T13:02:25'; //string.valueof(system.now()-400);
        objWrpDemog.Name = 'testName';
        objWrpDemog.Mobile = '9999992222';
        objWrpDemog.Title = 'Mr';
        
        MeddBase_Settings__c objmed = new MeddBase_Settings__c();
        objmed.Client_Key__c = 'api-mhctest';
        objmed.Name = 'meddbase';
        insert objmed;
        
        PatientRequestData objWrpPRT = new PatientRequestData();
        objWrpPRT.regCode = '0020';
        objWrpPRT.isOH = true;
        objWrpPRT.demog = objWrpDemog;
        objWrpPRT.client_key = objmed.Client_Key__c ; 
     
      test.StartTest();
        DatabaseUtility.createClinicians(objSd,objAT.id);
        DatabaseUtility.createApointmentType(objApd);
        DatabaseUtility.getDateTimeByString(dateTim);
        DatabaseUtility.createProposedAppointment(objapo);
        DatabaseUtility.createSites(objStd); 
        try{
          DatabaseUtility.createPatientonMeddBase('TestFName','TestLName','test112test@gmail.com','test@123','2000-02-01T13:02:25','TestAddress1',
                                              'TestAddress2','TestAddress3','Delhi','India','201301','9999992222');                                             
        }Catch(Exception e){
        } 
        DatabaseUtility.createAttendeeSlot(objPta,null,null);    
        DatabaseUtility.updateOldUnusedSlots();
        DatabaseUtility.updatePA2NA(system.now(),'001',new list<AppointmentData.result>());
        DatabaseUtility.updateProposedAppointment([SELECT Id FROM Proposed_Appointment__c limit 1].Id); 
        DatabaseUtility.updateToken2Patient('', '', '','','','');
        try{DatabaseUtility.bookASlot4Patient([SELECT Id FROM Proposed_Appointment__c limit 1].Id,[SELECT Id FROM Proposed_Appointment__c limit 1].Id,null,null,null);
        }Catch(Exception e){
        } 
        DatabaseUtility.createPatient('fname','lname', 'reg_email@test.com', 'reg_password', '12/12/2000', 'add1',
                                   'add2', 'add3','London', 'UK', '201301','9090909090'); 
        DatabaseUtility.creatErrorlog('Related_Appointment_Type','Related_Class_Name',
                                     'Related_Line_Number','Related_Message','Related_Object_Id',
                                     'Related_Patient','Related_Site','Related_Clinician','Related_Status','Related_Module_Name');
        DatabaseUtility.convertAeronaDateTime('123664');
        try{
        DatabaseUtility.createAeronaSlots(null,'objt.id','objclia.id'); }catch(Exception e){}
      test.StopTest(); 
    }   
}