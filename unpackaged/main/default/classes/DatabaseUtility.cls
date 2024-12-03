public with sharing class DatabaseUtility {
    public static string createApointmentType(AppointmentTypeData objAppointmentTypeData){
        if(objAppointmentTypeData.status != null){
            list<Appointment_Type__c> at2Upsert = new list<Appointment_Type__c>();
            if(objAppointmentTypeData.status == 'ok'){
                for(AppointmentTypeData.result r:objAppointmentTypeData.result){
                    Appointment_Type__c a = new Appointment_Type__c();
                    a.Tele_Medicine_Option__c = r.TelemedicineOption;
                    a.Notes__c =  r.Notes;
                    a.Name = r.Name; 
                    a.Meddbase_Key__c = r.Key;
                    a.Cancellation_Policy__c = r.CancellationPolicy;  
                    a.Can_Refer_Patient__c = r.CanReferPatient; 
                    a.Can_Book_Appointment__c = r.CanBookAppointment;
                    at2Upsert.add(a);
                }       
            }else{
                throw new MHCException('Meddbase Server Error: '+objAppointmentTypeData);
            }
            if(!at2Upsert.IsEmpty()){
                Schema.SObjectField meddKey = Appointment_Type__c.Fields.Meddbase_Key__c;
                Database.UpsertResult [] cr = Database.upsert(at2Upsert,meddKey,false);
                return 'SUCCESS';           
            }
        }
        return 'FAILED';
    }
    
    public static string createSites(SitesData objSitesData){
        if(objSitesData.status != null){
            list<Site__c> s2Upsert = new list<Site__c>();
            if(objSitesData.status == 'ok'){
                for(SitesData.result s:objSitesData.result){
                    Site__c a = new Site__c();
                    a.Name = s.Name; 
                    a.Meddbase_Key__c = s.Key;
                    a.Address_1__c = s.Address.Address1;  
                    a.Address_2__c = s.Address.Address2;  
                    a.Address_3__c = s.Address.Address3;
                    a.City__c = s.Address.City;
                    a.Country__c = s.Address.Country;
                    a.County__c = s.Address.Country;
                    a.PostCode__c = s.Address.County;  
                    s2Upsert.add(a);
                }       
            }else{
                throw new MHCException('Meddbase Server Error: '+objSitesData);
            }
            if(!s2Upsert.IsEmpty()){
                Schema.SObjectField meddKey = Site__c.Fields.Meddbase_Key__c;
                Database.UpsertResult [] cr = Database.upsert(s2Upsert,meddKey,false);
                return 'SUCCESS';           
            }
        }
        return 'FAILED';
    }
    
    public static string createClinicians(ClinicianData objClinicianData,Id appType){
        if(objClinicianData.status != null){
            list<Clinician__c> s2Upsert = new list<Clinician__c>();
            list<Clinician_Appoinment_Types__c> cat2Upsert = new list<Clinician_Appoinment_Types__c>();
            if(objClinicianData.status == 'ok'){
                for(ClinicianData.result c: objClinicianData.result){
                    Clinician__c a = new Clinician__c();
                    a.Name = c.FullName; 
                    a.Meddbase_Key__c = c.Key;  
                    a.Clinician_Sex__c = (c.SexType == 1?'Male':(c.SexType == 2?'Female':'Any Sex'));
                    s2Upsert.add(a);
                }       
            }else{
                throw new MHCException('Meddbase Server Error: '+objClinicianData);
            }
            if(!s2Upsert.IsEmpty()){
                Schema.SObjectField meddKey = Clinician__c.Fields.Meddbase_Key__c;
                Database.UpsertResult [] cr = Database.upsert(s2Upsert,meddKey,false);
                for(Database.UpsertResult c: cr){
                    Clinician_Appoinment_Types__c objCAT= new Clinician_Appoinment_Types__c();
                    objCAT.Appointment_Type__c = appType;
                    objCAT.Clinician__c = c.getId();
                    objCAT.MeddBase_Key__c = appType+'_'+c.getId();
                    cat2Upsert.add(objCAT);
                }
                Schema.SObjectField meddKeycat = Clinician_Appoinment_Types__c.Fields.Meddbase_Key__c;
                Database.UpsertResult [] crcat = Database.upsert(cat2Upsert,meddKeycat,false);
                return 'SUCCESS';           
            }
        }
        return 'FAILED';
    }
    
    public static string createProposedAppointment(AppointmentData objAppointmentData){        
        if(objAppointmentData.status != null){  
            Integer i = 0;
            list<Invoice__c> inv2Upsert = new list<Invoice__c>(); 
            set<Proposed_Appointment__c> p2Upsert = new set<Proposed_Appointment__c>();
            list<Appointment_Module__c> am2insert = new list<Appointment_Module__c>();
            list<Appointment_Slot__c> as2insert = new list<Appointment_Slot__c>();
            if(objAppointmentData.status == 'ok'){                
                for(AppointmentData.result c: objAppointmentData.result){                     
                    if(c.Clinician != null && c.site != null){
                        Proposed_Appointment__c p = new Proposed_Appointment__c();
                        p.Telemedicine__c = c.Telemedicine;
                        p.Start__c = getDateTimeByString(c.Start);     
                        p.Finish__c = getDateTimeByString(c.Finish);             
                        p.Site__c = (c.site!=null?sitesMap.get(''+c.site.Key):null);
                        p.Payer_Type__c = c.PayerType;
                        p.MeddBase_key__c = c.Key;
                        p.Clinician__c = (c.Clinician!=null?clinicianMap.get(''+c.Clinician.Key):null); 
                        p.Appointment_Type__c = (c.Type!=null?apointmentTypeMap.get(c.Type.Key):null);  
                        blob eKey = blob.valueOf(p.MeddBase_key__c+p.Start__c+p.Finish__c+p.Site__c+p.Clinician__c+p.Appointment_Type__c);
                        p.External_Key__c = EncodingUtil.base64Encode(eKey); 
                        Schema.SObjectField meddKey = Proposed_Appointment__c.Fields.External_Key__c;
                        Database.UpsertResult cr = Database.upsert(p,meddKey,false); 
                        as2insert.addAll(createSlots(c.Slots,p.Clinician__c,cr.getId(),p.External_Key__c));
                        am2insert.addAll(createModules(JSON.serialize(c.Modules),cr.getId()));
                        inv2Upsert.addAll(createInvoice(JSON.serialize(c.Invoice),cr.getId()));
                    }
                }
                if(!am2insert.isEmpty()){           
                    Schema.SObjectField meddKey = Appointment_Module__c.Fields.Meddbase_Key__c;
                    Database.UpsertResult[] cr = Database.upsert(am2insert,meddKey,false);
                }  
                if(!as2insert.isEmpty()){
                    Schema.SObjectField meddKey = Appointment_Slot__c.Fields.External_Key__c;
                    Database.UpsertResult[] cr = Database.upsert(as2insert,meddKey,false);
                }
                if(!inv2Upsert.isEmpty()){
                    Schema.SObjectField meddKey = Invoice__c.Fields.Meddbase_Key__c;
                    Database.UpsertResult[] cr = Database.upsert(inv2Upsert,meddKey,false);
                } 
                list<Proposed_Appointment__c> updatePA = new list<Proposed_Appointment__c>();
                updatePA.addAll(p2Upsert); 
                if(!updatePA.IsEmpty()){ 
                    update updatePA;
                } 
            }else{ 
                throw new MHCException('Meddbase Server Error: '+objAppointmentData);
            } 
        }
        return 'SUCCESS'; 
    }    
   
    public static set<Proposed_Appointment__c> updatePA2NA(Datetime startDateTime, string aTypeKey, list<AppointmentData.result> objAD){
        set<Proposed_Appointment__c> toUpdateProposedAppointment = new set<Proposed_Appointment__c>();        
        datetime currectDateTime = System.Now();
        list<Proposed_Appointment__c> paList = [Select Start__c,Id,State__c,Clinician__r.Name,Appointment_Type__r.Name From Proposed_Appointment__c 
                                                WHERE Patient__c = null AND (State__c= null OR State__c= 'Not Available')
                                                AND Appointment_Type__r.Meddbase_Key__c = :aTypeKey];
        for(Proposed_Appointment__c pa:paList){ 
            Integer index = 0;
            for(AppointmentData.result c: objAD){                              
                if(pa.Start__c.getTime() == getDateTimeByString(c.Start).getTime() && pa.Start__c == getDateTimeByString(c.Start)){ 
                    index += 1;
                    Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=pa.Id);
                    objPA.State__c = ''; 
                    toUpdateProposedAppointment.add(objPA); 
                    break;                    
                }
            }                       
            if(index == 0){
                Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=pa.Id);
                objPA.State__c = 'Not Available'; 
                toUpdateProposedAppointment.add(objPA);       
            }          
        }
        return toUpdateProposedAppointment;
    }
    
    public static void updateOldUnusedSlots(){
        list<Proposed_Appointment__c> toUpdateProposedAppointment = new list<Proposed_Appointment__c>();
        Datetime currectDateTime = System.Now();
        for(Proposed_Appointment__c pa:[Select Start__c,Id,State__c,Clinician__r.Name,Appointment_Type__r.Name From Proposed_Appointment__c 
                                        WHERE Start__c < :currectDateTime AND Patient__c = null AND State__c = null]){ 
            Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=pa.Id);
            objPA.State__c = 'Not Available'; 
            toUpdateProposedAppointment.add(objPA);   
        }
        if(!toUpdateProposedAppointment.IsEmpty()) update toUpdateProposedAppointment;
    }
    
    public static list<Invoice__c> createInvoice(string invoice,Id proposedAppId){
        list<Invoice__c> inv2insert = new list<Invoice__c>();
        AppointmentData.Invoice inv = (AppointmentData.Invoice)JSON.deserialize(invoice,AppointmentData.Invoice.class);
        if(inv != null){
            Invoice__c a = new Invoice__c();
            a.Currency_Code__c = inv.CurrencyCode;
            a.Total_Gross__c = inv.TotalGross;
            a.Key__c = inv.Key;
            a.Total_Net__c = inv.TotalNet; 
            a.Meddbase_Key__c = proposedAppId+'-'+inv.Key;
            a.Payable_Online__c = inv.PayableOnline;
            a.Tax__c = inv.Tax;
            a.Number__c = inv.x_Number;
            a.Total_Gross__c = inv.TotalGross;
            a.Date__c = datetime.valueOf(inv.x_Date.replace('T',' '));
            a.Paid__c = (inv.Paid == 0?false:true);
            inv2insert.add(a);
        }
        return inv2insert;
    }
      
    public static list<Appointment_Module__c> createModules(string modules,Id proposedAppId){
        list<Appointment_Module__c> am2insert = new list<Appointment_Module__c>();
        for(AppointmentData.Modules am:(list<AppointmentData.Modules>)JSON.deserialize(modules,list<AppointmentData.Modules>.class)){
            if(am != null){
                Appointment_Module__c a = new Appointment_Module__c();
                a.Name = am.Name;
                a.CurrencyCode__c = 'GBP';
                a.GrossPrice__c = am.GrossPrice;
                a.Key__c = am.Key;
                a.NetPrice__c = am.NetPrice; 
                a.Notes__c = am.Notes;
                a.Meddbase_Key__c = proposedAppId+''+am.Key;
                a.Proposed_Appointment__c = proposedAppId;
                a.Tax__c = am.Tax;
                am2insert.add(a);
            }
        }
        return am2insert; 
    }
    
    public static map<string,Id> apointmentTypeMap{
        get{
            if(apointmentTypeMap == null){
                apointmentTypeMap = new map<string,Id>();
                for(Appointment_Type__c t: [SELECT Id,Meddbase_Key__c from Appointment_Type__c limit 1000]){
                    apointmentTypeMap.put(t.Meddbase_Key__c,t.Id);
                }
            }
            return apointmentTypeMap;
        }
    }
    
    public static map<string,Id> clinicianMap{
        get{
            if(clinicianMap == null){
                clinicianMap = new map<string,Id>();
                for(Clinician__c t: [SELECT Id,Meddbase_Key__c from Clinician__c limit 1000]){
                    clinicianMap.put(''+t.Meddbase_Key__c,t.Id);
                }
            }
            return clinicianMap;
        }
    }
    
    public static map<string,Id> sitesMap{
        get{
            if(sitesMap == null){
                sitesMap = new map<string,Id>();
                for(Site__c t: [SELECT Id,Meddbase_Key__c from Site__c limit 1000]){
                    sitesMap.put(''+t.Meddbase_Key__c,t.Id);
                }
            }
            return sitesMap;
        }
    }
    
    public static Id createAttendeeSlot(AppointmentData.PrimaryAttendeeSlot objPS,Id clinician,string externalKey){
        if(objPS != null){
            Appointment_Slot__c a = new Appointment_Slot__c();
            a.Start__c = getDateTimeByString(objPS.Start);
            a.Site__c = (objPS.site!=null?sitesMap.get(''+objPS.site.Key):null);
            a.Resource_Key__c = objPS.ResourceKey;
            a.Finish__c = getDateTimeByString(objPS.Finish);
            a.Clinician__c = clinician; 
            a.Appointment_Type__c = (objPS.Type!=null?apointmentTypeMap.get(objPS.Type.Key):null);
            a.External_Key__c = externalKey; 
            Schema.SObjectField meddKey = Appointment_Slot__c.Fields.External_Key__c;
            Database.UpsertResult cr = Database.upsert(a,meddKey,false);
            return cr.getId(); 
        }
        return null;
    }
    
    public static list<Appointment_Slot__c> createSlots(list<AppointmentData.Slots> objADS,Id clinician,Id proposedAppId,string externalKey){
        list<Appointment_Slot__c> as2insert = new list<Appointment_Slot__c>();
        for(AppointmentData.Slots objPS:objADS){
            if(objPS != null){
                Appointment_Slot__c a = new Appointment_Slot__c();
                a.Start__c = getDateTimeByString(objPS.Start);
                a.Site__c = (objPS.site!=null?sitesMap.get(''+objPS.site.Key):null);
                a.Resource_Key__c = objPS.ResourceKey;
                a.Finish__c = getDateTimeByString(objPS.Finish);
                a.Clinician__c = clinician; 
                a.Appointment_Type__c = (objPS.Type!=null?apointmentTypeMap.get(objPS.Type.Key):null);
                a.Proposed_Appointment__c = proposedAppId;
                a.External_Key__c = externalKey;
                as2insert.add(a);
            }
        }
        return as2insert; 
    }
    
    public static DateTime getDateTimeByString(string datetimestr){
        if(datetimestr != null && datetimestr != ''){
            return DateTime.valueOf(datetimestr.replace('T',' '));
        }
        return null;
    }
    
    public static string createPatient(string fname,string lname, string reg_email, string reg_password, string dob, string add1,
                                       string add2, string add3,string city, string country, string postcode,string mobile  ){
        try{
            Lead objLead = new Lead();
            objLead.LastName = lname;
            objLead.FirstName= fname;
            objLead.Email= reg_email;
            objLead.Date_of_birth__c = date.parse(dob);
            objLead.Address1__c= add1;
            objLead.Address2__c= add2;
            objLead.Address3__c= add3;
            objLead.City= city;
            objLead.Country=country;
            objLead.PostalCode=postcode;
            objLead.MobilePhone=mobile;
            insert objLead; 
            return objLead.Id;
        }catch(Exception e){
             DatabaseUtility.creatErrorlog('','DatabaseUtility',
                                         ''+e.getLineNumber(),e.getMessage(),'',
                                         '','','','','');
            return e.getMessage();
        }
        return '';
    }
    
    public static Database.LeadConvertResult converntLeadById(String leadId){
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(leadId);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        return lcr;
    } 
     
    public static PatientResponseData createPatientonMeddBase(string fname,string lname, string reg_email, string reg_password, string dob, string add1,
                                       string add2, string add3,string city, string country, string postcode,string mobile){ 
        PatientRequestData objPatientRequestData = new PatientRequestData();
        PatientRequestData.Address ptdAddress = new PatientRequestData.Address();
        ptdAddress.City = city;
        ptdAddress.County = country;
        ptdAddress.Address3 = add3;
        ptdAddress.PostCode = postcode;
        ptdAddress.Address2 = add2;
        ptdAddress.Country = country;
        ptdAddress.Address1 = add1;        
        PatientRequestData.demog ptdDemog = new PatientRequestData.demog();
        ptdDemog.Address = ptdAddress;
        ptdDemog.EmailAddress = reg_email;
        ptdDemog.Password = reg_password;
        ptdDemog.Surname = lname;
        ptdDemog.DateOfBirth = string.valueof(Date.parse(dob)).substring(0,10)+'T00:00:01';//'2000-02-01T13:02:25';
        ptdDemog.Name = fname;//+' '+lname;
        ptdDemog.Mobile = mobile; 
        objPatientRequestData.isOH = false;
        objPatientRequestData.client_key = CommonUtility.objMeddBaseSettings.Client_Key__c;
        objPatientRequestData.demog = ptdDemog;
        objPatientRequestData.regCode = CommonUtility.objMeddBaseSettings.Payer_Type__c;
        String patientRequestdataJSON = JSON.serialize(objPatientRequestData);
        patientRequestdataJSON = patientRequestdataJSON.replace('client_key','client-key');
        PatientResponseData resultset = MeddbaseCalloutUtility.createPatient(patientRequestdataJSON);
        return resultSet;
    }
    
    public static string updateToken2Patient(string email, string token, string paId,string state,string stateDisplay, string stateColor){
        list<Account> objAcc = [SELECT Id,MeddBase_Token__c FROM Account WHERE PersonEmail=:email limit 1];
        if(objAcc.size() > 0){
            objAcc.get(0).MeddBase_Token__c = token;
            update objAcc;
            bookASlot4Patient(objAcc.get(0).Id,paId,state,stateDisplay,stateColor);
            return objAcc.get(0).Id;
        }
        return null;
    }
    
    public static string bookASlot4Patient(string patientId,string paId,string state,string stateDisplay, string stateColor){
        if(patientId != null && patientId != '' && paId != null && paId != ''){
            Proposed_Appointment__c ObjPA2Update = new Proposed_Appointment__c();
            list<Proposed_Appointment__c> objPA = [Select Patient__c, Id From Proposed_Appointment__c WHERE Id=:paId];
            if(objPA.size() > 0){
                ObjPA2Update.Id = objPA.get(0).Id;
                ObjPA2Update.Patient__c = patientId;
                ObjPA2Update.State__c = state;
                ObjPA2Update.Online_Booked__c = true;
                ObjPA2Update.State_Color__c = stateColor;
                ObjPA2Update.State_Display_Name__c = stateDisplay;
                ObjPA2Update.Booking_DateTime__c = system.Now();
                update ObjPA2Update;
                return ObjPA2Update.Id;
            }           
        }
        return null;
    }
    
    public static string updateProposedAppointment(string paId){
        if(paId != null && paId != ''){
            Proposed_Appointment__c ObjPA2Update = new Proposed_Appointment__c();
            list<Proposed_Appointment__c> objPA = [Select State_Display_Name__c,State_Color__c,State__c, Id From Proposed_Appointment__c WHERE Id=:paId];
            if(objPA.size() > 0){
                ObjPA2Update.Id = objPA.get(0).Id;
                ObjPA2Update.State__c = 'Not Available'; 
                update ObjPA2Update;
                return ObjPA2Update.Id;
            }           
        }
        return null;
    }
    public static void creatErrorlog(string Related_Appointment_Type,string Related_Class_Name,
                                        string Related_Line_Number,string Related_Message,string Related_Object_Id,
                                        string Related_Patient,string Related_Site,string Related_Clinician,string Related_Status,string Related_Module_Name){
        Error_Log__c objLog = new Error_Log__c();
        objLog.Related_Appointment_Type__c = Related_Appointment_Type ;
        objLog.Related_Class_Name__c = Related_Class_Name;
        objLog.Related_Clinician__c = Related_Clinician;
        objLog.Related_Line_Number__c = Related_Line_Number;
        objLog.Related_Message__c = Related_Message;
        objLog.Related_Object_Id__c = Related_Object_Id;
        objLog.Related_Patient__c = Related_Patient;
        objLog.Related_Site__c = Related_Site;
        objLog.Related_Status__c = Related_Status;
        objLog.Related_Module_Name__c = Related_Module_Name;
        insert objLog;
    }
    /*method for aerona*/
    public static list<Proposed_Appointment__c> createAeronaSlots(AeronaAvailableSlots objAeronaAvailableSlots,string siteId,string clinicianId){    
        //To update aerona slots to synchronize 
        if(restAeronaSlotsByClinicianAndSite(siteId, clinicianId)){
            list<Proposed_Appointment__c> p2Upsert = new list<Proposed_Appointment__c>();
            list<DateTime> slotsDateTimes  = new list<DateTime>();
            for(AeronaAvailableSlots.result c: objAeronaAvailableSlots.result){
                system.debug(siteId+'>>>>>>>>>>>>>>------'+clinicianId+'------>>>>>>>>>>>>>>>>'+convertAeronaDateTime(''+c.slotStartTime));
                //boolean flag = true;
                //Proposed_Appointment__c tempPA = new Proposed_Appointment__c();
                slotsDateTimes.addAll(new list<DateTime>{convertAeronaDateTime(''+c.slotStartTime),
                                                                   convertAeronaDateTime(''+c.slotStartTime).addMinutes(5),
                                                                   convertAeronaDateTime(''+c.slotStartTime).addMinutes(10)});
            }
                                                                       
            for(Proposed_Appointment__c pa :[SELECT Id,Start__c,Is_Available_On_Aerona__c FROM Proposed_Appointment__c 
                                             WHERE Start__C IN:slotsDateTimes AND Clinician__c=:clinicianId 
                                             AND Site__c=:siteId AND Is_Available_On_Aerona__c = false 
                                             order by Start__c ASC]){
                                                 //if(pa.Start__c == convertAeronaDateTime(''+c.slotStartTime)){
                                                 system.debug('>>>>>>>>>>>>-----------'+pa); 
                                                 Proposed_Appointment__c p = pa;   
                                                 p.Is_Available_On_Aerona__c = true;
                                                 p2Upsert.add(p); 
                                                 //flag  = false;
                                                 //break;
                                                 //}
                                                 //tempPA = pa;
                                             }
            /*if(flag){
            Proposed_Appointment__c p = new Proposed_Appointment__c();   
            p.Is_Available_On_Aerona__c = true;
            p2Upsert.add(p);
            }*/
            //}
            //if(!p2Upsert.IsEmpty()) upsert p2Upsert;
            return p2Upsert;//'SUCCESS'; 
        }
        return null;//'FAILED because DatabaseUtility.restAeronaSlotsByClinicianAndSite failed';
    }
    public static boolean restAeronaSlotsByClinicianAndSite(string siteId, string clinicianId){
        try{
            list<Proposed_Appointment__c> p2Upsert = new list<Proposed_Appointment__c>();
            for(Proposed_Appointment__c pa :[SELECT Id,Start__c,Is_Available_On_Aerona__c FROM Proposed_Appointment__c 
                                                 WHERE Clinician__c=:clinicianId 
                                                 AND Site__c=:siteId AND Is_Available_On_Aerona__c = true 
                                                 order by Start__c ASC]){
                Proposed_Appointment__c p = pa;   
                p.Is_Available_On_Aerona__c = false;
                p2Upsert.add(p);    
            }
            if(!p2Upsert.IsEmpty()) upsert p2Upsert;
            return true;
        }catch(Exception e){
            system.debug('Error in DatabaseUtility.restAeronaSlotsByClinicianAndSite '+e);
            return false;
        }
    }
    /*public static list<Proposed_Appointment__c> restAeronaSlotsByClinicianAndSiteForBF(string siteId, string clinicianId){
        try{
            list<Proposed_Appointment__c> p2Upsert = new list<Proposed_Appointment__c>();
            for(Proposed_Appointment__c pa :[SELECT Id,Start__c,Is_Available_On_Aerona__c FROM Proposed_Appointment__c 
                                                 WHERE Clinician__c=:clinicianId 
                                                 AND Site__c=:siteId AND Is_Available_On_Aerona__c = true 
                                                 order by Start__c ASC]){
                Proposed_Appointment__c p = pa;   
                p.Is_Available_On_Aerona__c = false;
                p2Upsert.add(p);    
            } 
            return p2Upsert;
        }catch(Exception e){
            system.debug('Error in DatabaseUtility.restAeronaSlotsByClinicianAndSite '+e);
            return new list<Proposed_Appointment__c>();
        }
    }*/
    /*method for aerona*/
    public static DateTime convertAeronaDateTime(string unixTime){
        Long L1 = long.valueOf(unixTime);
        return datetime.newInstance(L1).addHours(1);
    }
}