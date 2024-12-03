@isTest()
private class AppointmentBookingRequestData_Test{
 private static testMethod void testApt(){ 
 
  AppointmentBookingRequestData objABRDR = new  AppointmentBookingRequestData();

  AppointmentBookingRequestData.Type objType = new AppointmentBookingRequestData.Type();
    objType.CanReferPatient    = true;
     objType.TelemedicineOption = true;
     objType.CanBookAppointment = true;
     objType.Key = '1256';
     objType.Notes = 'Myheart';
     objType.Name = 'yourheart';
     
  AppointmentBookingRequestData.Address objAdd = new AppointmentBookingRequestData.Address();
     objAdd.Country  = 'India';
     objAdd.City  = 'Delhi';
     objAdd.County = 'Delhi region';
     objAdd.Address3 = 'Okhla';
     objAdd.PostCode = '203102';
     objAdd.Address2 = 'Mumbai';
     objAdd.Address1 = 'Kolkata';
     
  AppointmentBookingRequestData.Site objsite = new AppointmentBookingRequestData.Site();
     objsite.Name = 'kanya';
     objsite.Address=objAdd  ;
     objsite.Key= 5266;
     
  AppointmentBookingRequestData.Slots objslots = new AppointmentBookingRequestData.Slots();
     objslots.Type = objType;
     objslots.Site=  objsite   ;
     objslots.Finish = 'kaol';
     objslots.ResourceKey=1236;
     objslots.Start='opop';
  AppointmentBookingRequestData.Invoice objInv = new AppointmentBookingRequestData.Invoice();
     objInv.Tax =12.2;
     objInv.TotalNet =32.6;
     objInv.TotalGross =96.2;
     objInv.CurrencyCode= 'curr';
     objInv.Paid= 32;
     objInv.I_Number = 566;
     objInv.I_Date='opps';
     objInv.PayableOnline = true;
     objInv.Key = 'Kem';
  AppointmentBookingRequestData.Clinician objCli = new AppointmentBookingRequestData.Clinician();
     objCli.SexType  = 12364;
     objCli.Key  = 5622;
     objCli.FullName = 'Mo';
     
     
  AppointmentBookingRequestData.Modules objMod = new AppointmentBookingRequestData.Modules();
     objMod.Tax = 22.22;
     objMod.NetPrice = 33.66;
     objMod.CurrencyCode ='Mode';
     objMod.GrossPrice =78.2;
     objMod.Key =782;
     objMod.Notes ='Lagre';
     objMod.Name ='smith';
     list<AppointmentBookingRequestData.Modules> Mdu = new list<AppointmentBookingRequestData.Modules>();
     Mdu.add(objMod);
        
  AppointmentBookingRequestData.Site objSie = new AppointmentBookingRequestData.Site(); 
     objSie.Key= 1233;
     objSie.Address = objAdd;
     objSie.Name ='Nortan';
        
  AppointmentBookingRequestData.Slots objSlo = new AppointmentBookingRequestData.Slots();
     objSlo.Type = objType;
     objSlo.Site = objSie;
     objSlo.Finish = string.valueof(system.now()+10);//'Jordan';
     objSlo.ResourceKey = 1226;
     objSlo.Start = string.valueof(system.now());//'Joe';
         
    list<AppointmentBookingRequestData.Slots> objLtSlot = new list<AppointmentBookingRequestData.Slots>();
    objLtSlot.add(objSlo);    
        
  AppointmentBookingRequestData.PrimaryAttendeeSlot objpri = new AppointmentBookingRequestData.PrimaryAttendeeSlot();
     objpri.Type= objType;
     objpri.Site=objSie; 
     objPri.Clinician = objCli;
     objpri.Finish = 'wowp';
     objPri.ResourceKey=1256;
     objPri.Start='ok';       
  AppointmentBookingRequestData.proposedAppointment objProp = new AppointmentBookingRequestData.proposedAppointment();
     objProp.Invoice = objInv;
     objProp.Telemedicine = true;
     objProp.Clinician = objCli;
     objProp.Modules = Mdu;
     objProp.Site= objSie;
     objProp.slots = objLtSlot;
     objProp.Finish = 'lop';
     objProp.PrimaryAttendeeSlot = objpri;
     objProp.Start='pwp';
     objProp.PayerType='kopl';
     objProp.Type = objType;
     objProp.Key = 'won';
       
  }
}