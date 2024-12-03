public class CommonUtility{
    public static MeddBase_Settings__c objMeddBaseSettings{
        get{
            if(objMeddBaseSettings == null){
                objMeddBaseSettings = MeddBase_Settings__c.getvalues('meddbase');
            }
            return objMeddBaseSettings;
        }
    } 
    public static string createBookingRequest(String paId){
        list<Proposed_Appointment__c> objPAs = [Select p.Invoice__r.Total_Net__c, p.Invoice__r.Total_Gross__c, p.Invoice__r.Tax__c, p.Invoice__r.Payable_Online__c, p.Invoice__r.Paid__c, p.Invoice__r.Number__c, p.Invoice__r.Key__c, p.Invoice__r.Date__c, p.Invoice__r.Currency_Code__c,p.Primary_Attendee_Slot__r.Finish__c,p.Primary_Attendee_Slot__r.Resource_Key__c,p.Primary_Attendee_Slot__r.Start__c,p.Clinician__r.Name, p.Clinician__r.MeddBase_Key__c, p.Clinician__r.Clinician_Sex__c,p.Site__r.PostCode__c, p.Site__r.Name, p.Site__r.MeddBase_Key__c, p.Site__r.County__c, p.Site__r.Country__c, p.Site__r.City__c, p.Site__r.Address_3__c, p.Site__r.Address_2__c, p.Site__r.Address_1__c,p.Appointment_Type__r.Tele_Medicine_Option__c, p.Appointment_Type__r.Notes__c, p.Appointment_Type__r.Name, p.Appointment_Type__r.Meddbase_Key__c, p.Appointment_Type__r.Cancellation_Policy__c, p.Appointment_Type__r.Can_Refer_Patient__c, p.Appointment_Type__r.Can_Book_Appointment__c,p.Telemedicine__c, p.Start__c, p.Site__c, p.Primary_Attendee_Slot__c, p.Payer_Type__c, p.Patient__c, p.OwnerId, p.Name, p.MeddBase_key__c, p.Id, p.Finish__c, p.External_Key__c, p.Clinician__c, p.Appointment_Type__c, (Select Id, Name, Start__c, Finish__c, Location_Key__c, Resource_Key__c, Clinician__c, Appointment_Type__c, Site__c, Proposed_Appointment__c, External_Key__c From Appointment_Slots__r), (Select Id, Name, Notes__c, CurrencyCode__c, NetPrice__c, Tax__c, GrossPrice__c, Proposed_Appointment__c, Key__c, Meddbase_Key__c From Appointment_Modules__r) From Proposed_Appointment__c p WHERE Id=:paId];
        if(objPAs.size() > 0){
            Proposed_Appointment__c objPA = objPAs.get(0);
            AppointmentBookingRequestData reqData = new AppointmentBookingRequestData();
            AppointmentBookingRequestData.proposedAppointment proposedAppointment = new AppointmentBookingRequestData.proposedAppointment();
            list<AppointmentBookingRequestData.Modules> modules = new list<AppointmentBookingRequestData.Modules>();
            list<AppointmentBookingRequestData.Slots> slots = new list<AppointmentBookingRequestData.Slots>(); 
            AppointmentBookingRequestData.Type atype = new AppointmentBookingRequestData.Type();
            atype.CanBookAppointment = objPA.Appointment_Type__r.Can_Book_Appointment__c;
            atype.Notes = objPA.Appointment_Type__r.Notes__c;
            atype.CanReferPatient = objPA.Appointment_Type__r.Can_Refer_Patient__c;
            atype.Key = objPA.Appointment_Type__r.Meddbase_Key__c;
            atype.TelemedicineOption = objPA.Appointment_Type__r.Tele_medicine_Option__c;
            atype.Name = objPA.Appointment_Type__r.Name; 
            AppointmentBookingRequestData.Address siteAddress = new AppointmentBookingRequestData.Address();
            siteAddress.Address1 = objPA.Site__r.Address_1__c;
            siteAddress.Address2 = objPA.Site__r.Address_2__c;
            siteAddress.Address3 = objPA.Site__r.Address_3__c;
            siteAddress.PostCode = objPA.Site__r.PostCode__c;
            siteAddress.Country = objPA.Site__r.Country__c;
            siteAddress.County = objPA.Site__r.County__c;
            siteAddress.City = objPA.Site__r.City__c;
            AppointmentBookingRequestData.Site aSite = new AppointmentBookingRequestData.Site();
            aSite.Name = objPA.Site__r.Name;
            aSite.Address = siteAddress;
            aSite.Key = (objPA.Site__r.MeddBase_Key__c!=null?Integer.ValueOf(objPA.Site__r.MeddBase_Key__c):0);
            AppointmentBookingRequestData.Clinician clinician = new AppointmentBookingRequestData.Clinician();
            clinician.FullName = objPA.Clinician__r.Name;
            clinician.SexType = (objPA.Clinician__r.Clinician_Sex__c == 'Male'?1:(objPA.Clinician__r.Clinician_Sex__c == 'Female'?2:3));
            clinician.Key = (objPA.Clinician__r.MeddBase_Key__c!=null?Integer.ValueOf(objPA.Clinician__r.MeddBase_Key__c):0);
            AppointmentBookingRequestData.Invoice invoice = new AppointmentBookingRequestData.Invoice();
            invoice.I_Number = objPA.Invoice__r.Number__c!= null?Integer.valueOf(objPA.Invoice__r.Number__c):0; //1;
            invoice.Tax = objPA.Invoice__r.Tax__c; //1;
            invoice.TotalNet = objPA.Invoice__r.Total_Net__c; //1;
            invoice.TotalGross = objPA.Invoice__r.Total_Gross__c; //2;
            invoice.CurrencyCode = 'GBP';
            invoice.Paid = (objPA.Invoice__r.Paid__c == true?1:0);
            invoice.I_Date = '2017-11-18T18:27:08.5851006 00:00';
            invoice.PayableOnline = objPA.Invoice__r.Payable_Online__c;
            invoice.Key = objPA.Invoice__r.Key__c;  
            AppointmentBookingRequestData.PrimaryAttendeeSlot PrimaryAttendeeSlot = new AppointmentBookingRequestData.PrimaryAttendeeSlot();
            PrimaryAttendeeSlot.Type = atype;
            PrimaryAttendeeSlot.Site = aSite;
            PrimaryAttendeeSlot.Clinician = clinician;
            PrimaryAttendeeSlot.Finish = dateFormat(''+objPA.Finish__c);//dateFormat(''+objPA.Primary_Attendee_Slot__r.Finish__c);
            PrimaryAttendeeSlot.ResourceKey = 0;//1855077;//null;//(objPA.Primary_Attendee_Slot__r.Resource_Key__c!= null?Integer.Valueof(objPA.Primary_Attendee_Slot__r.Resource_Key__c):0);
            PrimaryAttendeeSlot.Start = dateFormat(''+objPA.Start__c);//dateFormat(''+objPA.Primary_Attendee_Slot__r.Start__c);         
            for(Appointment_Module__c am:objPA.Appointment_Modules__r){
                AppointmentBookingRequestData.Modules module = new AppointmentBookingRequestData.Modules();
                module.Notes = am.Notes__c;
                module.NetPrice = am.NetPrice__c;
                module.Tax = am.Tax__c;
                module.CurrencyCode = am.CurrencyCode__c;
                module.GrossPrice = am.GrossPrice__c;
                module.Key = (am.Key__c!= null?Integer.valueof(am.Key__c):0);
                module.Name = am.Name;
                modules.add(module);
            }
            for(Appointment_Slot__c s:objPA.Appointment_Slots__r){
                AppointmentBookingRequestData.Slots slot = new AppointmentBookingRequestData.Slots();
                slot.Site = aSite;
                slot.Type = atype;
                slot.Finish = dateFormat(''+s.Finish__c);
                slot.ResourceKey = Integer.valueof(s.Resource_Key__c);
                slot.Start = dateFormat(''+s.Start__c);
            }
            proposedAppointment.Invoice = invoice;
            proposedAppointment.Telemedicine = objPA.Telemedicine__c;
            proposedAppointment.Clinician = clinician;
            proposedAppointment.Modules = modules;
            proposedAppointment.Site = aSite;
            proposedAppointment.Slots = slots;
            proposedAppointment.Finish = dateFormat(''+objPA.Finish__c);
            proposedAppointment.PrimaryAttendeeSlot = primaryAttendeeSlot;
            proposedAppointment.Start = dateFormat(''+objPA.Start__c);
            proposedAppointment.PayerType = objPA.Payer_Type__c;
            proposedAppointment.Type = aType;
            proposedAppointment.Key = objPA.Meddbase_Key__c;    
            reqData.proposedAppointment = proposedAppointment;
            return JSON.serialize(reqData);     
        }
        return '';
    }
    public static string dateFormat(string dateFormat){
        return dateFormat.replace(' ','T');
    }
    public static Account getPatientByEmail(string email){
        list<Account> bjAcc = [Select a.PersonMobilePhone, a.PersonEmail, a.Name, a.Gender__c, a.Date_of_Birth__c, a.Billing_Address__c From Account a WHERE a.PersonEmail=:email];
        if(bjAcc.size() > 0){
            return bjAcc.get(0);
        }
        return new Account();
    }
    public static void OpporunityDeepClone(Opportunity objOpp, String accId){
         Savepoint sp = Database.setSavepoint();
         Opportunity newOpp;
         try{             
             newOpp = objOpp.clone(false);
             newOpp.AccountId = accId;
             newOpp.name = objOpp.name;
             newOpp.Business_Unit__c = objOpp.Business_Unit__c;
             insert newOpp;

             // copy over the line items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             List<OpportunityLineItem> items = new List<OpportunityLineItem>();
             for (OpportunityLineItem oli: objOpp.OpportunityLineItems) {
                  OpportunityLineItem newOLI = oli.clone(false);
                  newOLI.OpportunityId = newOpp.id;
                  items.add(newOLI);
             }
             insert items;
         }catch (Exception e){
            Database.rollback(sp);
            throw e;
         }
    }
}