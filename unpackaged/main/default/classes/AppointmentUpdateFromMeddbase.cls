@RestResource(urlMapping='/appointment/*')
global with sharing class AppointmentUpdateFromMeddbase{
    @HttpPost
    global static String doPost(String body) {
        try{
            AppointmentParser objAppointmentParser = (AppointmentParser) JSON.deserialize(body.replace('"Event":"','"Event":{"x_0":"').replace('"},"AppointmentID"','"}},"AppointmentID"').replace('"1":','"x_1":').replace('"2":','"x_2":').replace('"3":','"x_3":').replace('"4":','"x_4":'),AppointmentParser.class);
            if(objAppointmentParser.msg.EventIds.Event.x_3 != null && objAppointmentParser.msg.EventIds.Event.x_3 == 'AppointmentBooked'){
                updateAppointmentTime(objAppointmentParser);
            }
            list<Proposed_Appointment__c> objPA = [Select Id,Patient__c From Proposed_Appointment__c WHERE Clinician__r.Meddbase_Key__c =:Integer.valueOf(objAppointmentParser.msg.Consultants.Item) 
                                            AND Site__r.Meddbase_Key__c =: Integer.valueOf(objAppointmentParser.msg.AppointmentSiteId) 
                                            AND Appointment_Type__r.Name =: objAppointmentParser.msg.AppointmentType 
                                            AND Start__c=:AppointmentUpdateFromMeddbase.converToDatetime(objAppointmentParser.msg.AppointmentDate ,objAppointmentParser.msg.AppointmentTime)];
            system.debug(Integer.valueOf(objAppointmentParser.msg.Consultants.Item)+'>>>>'+Integer.valueOf(objAppointmentParser.msg.AppointmentSiteId)+'>>>>'+objAppointmentParser.msg.AppointmentType +'>>>>'+AppointmentUpdateFromMeddbase.converToDatetime(objAppointmentParser.msg.AppointmentDate ,objAppointmentParser.msg.AppointmentTime));
            String appointmentId;
            if(objPA.size() > 0){
                appointmentId = createProposedAppointment(objAppointmentParser,objPA.get(0).Id);
            }else{
                appointmentId = createProposedAppointment(objAppointmentParser,null);
            }
            return '{"status":"Success","appointmentId":"'+appointmentId+'"}';
        }catch(Exception e){
            DatabaseUtility.creatErrorlog('','AppointmentUpdateFromMeddbase',
                                         ''+e.getLineNumber(),e.getMessage(),'',
                                         '','','','','');
            return '{"status":"Failed","appointmentId":'+e.getMessage()+'}';
        }
    }
    public static void updateAppointmentTime(AppointmentParser objAppointmentParser){
        list<Proposed_Appointment__c> objPA = new list<Proposed_Appointment__c>();
        for(Proposed_Appointment__c pa: [Select Id,Patient__c,State__c,Meddbase_Key__c 
                                                From Proposed_Appointment__c 
                                                WHERE Meddbase_Key__c=:objAppointmentParser.msg.AppointmentID]){
            Proposed_Appointment__c p = new Proposed_Appointment__c(Id=pa.Id);
            p.Patient__c = null;
            p.State__c = null;
            p.Meddbase_Key__c = null;
            objPA.add(p);
        }
        if(!objPA.IsEmpty()) update objPA;      
    }
    public static Datetime converToDatetime(string strDate,string strTime){
        list<string> strTimeList = strTime.split(':');
        Time myTime = Time.newInstance(Integer.ValueOf(strTimeList[0]), Integer.ValueOf(strTimeList[1]), 0, 0);
        DateTime dt = DateTime.newInstance(Date.parse(strDate), myTime);
        return dt;        
    }
    /*@future(callout=true)
    public static void syncAppointments(string aType,string sDate){
        list<Proposed_Appointment__c> obPA2Sync = new list<Proposed_Appointment__c>();
        obPA2Sync = MeddbaseCalloutUtility.syncAppointments(aType, sDate,null);
        if(!obPA2Sync.IsEmpty()) update obPA2Sync;
    }*/
    public static string createProposedAppointment(AppointmentParser objAppointmentParser,string sfAppointmentId){
        Proposed_Appointment__c p = new Proposed_Appointment__c();
        system.debug('>>>>>>>>>>>>>>>>>>>--'+sfAppointmentId);
        system.debug('>>>>>>--'+objAppointmentParser);
        if(sfAppointmentId != '' && sfAppointmentId != null){
            p.Id = sfAppointmentId;
        }             
        p.Start__c = AppointmentUpdateFromMeddbase.converToDatetime(objAppointmentParser.msg.AppointmentDate ,objAppointmentParser.msg.AppointmentTime); 
        p.Finish__c = AppointmentUpdateFromMeddbase.converToDatetime(objAppointmentParser.msg.AppointmentDate ,objAppointmentParser.msg.AppointmentTime).addMinutes(Integer.ValueOf(objAppointmentParser.msg.AppointmentDuration));             
        p.Site__c = (objAppointmentParser.msg.AppointmentSiteId!=''?sitesMap.get(objAppointmentParser.msg.AppointmentSiteId):null);
        p.MeddBase_key__c = objAppointmentParser.msg.AppointmentID;
        p.Clinician__c = (objAppointmentParser.msg.AppointmentConsultantId!=''?clinicianMap.get(objAppointmentParser.msg.AppointmentConsultantId):null); 
        p.Appointment_Type__c = (objAppointmentParser.msg.AppointmentType!=''?appointmentTypeMap.get(objAppointmentParser.msg.AppointmentType):null);    
        p.Patient__c = getPatienByEmailAndName(objAppointmentParser);
        string state = (objAppointmentParser.msg.EventIds.Event.x_1 != null && objAppointmentParser.msg.EventIds.Event.x_1 != '')?objAppointmentParser.msg.EventIds.Event.x_1.replace('Appointment',''):null; 
        if(objAppointmentParser.msg.AppointmentStatus == 'Cancelled'){ 
            p.Patient__c = null;
            p.State_Color__c = null;
            p.State_Display_Name__c = null;  
        }
        system.debug('------------'+state);
        p.State__c = (state != null && state == 'Booked')?state:objAppointmentParser.msg.AppointmentStatus;
        
        p.Appointment_Notes__c = objAppointmentParser.msg.AppointmentNotes;
        if(sfAppointmentId == null || sfAppointmentId == ''){
            blob eKey = blob.valueOf(p.MeddBase_key__c+p.Start__c+p.Finish__c+p.Site__c+p.Clinician__c+p.Appointment_Type__c);
            p.External_Key__c = EncodingUtil.base64Encode(eKey);
        }
        /*if(sfAppointmentId != '' && sfAppointmentId != null){
            update p;
            return p.Id;
        }else{
            Schema.SObjectField meddKey = Proposed_Appointment__c.Fields.External_Key__c;
            Database.UpsertResult cr = Database.upsert(p,meddKey); 
            system.debug(sfAppointmentId+'>>>>>>>>>>>>>>>>>>>>>>>>>===='+cr);
            pId = cr.getId();
        }*/
        upsert p;
        if(sfAppointmentId == null || sfAppointmentId == ''){
            Appointment_Module__c a = new Appointment_Module__c();
            a.Name = objAppointmentParser.msg.AppointmentBookedServices;
            a.CurrencyCode__c = 'GBP';
            //a.GrossPrice__c = null;
            //a.Key__c = null;
            //a.NetPrice__c = null; 
            a.Notes__c = objAppointmentParser.msg.AppointmentNotes;
            a.Meddbase_Key__c = p.Id+''+p.External_Key__c;
            a.Proposed_Appointment__c = p.Id;
            //a.Tax__c = null;
            Schema.SObjectField meddKeym = Appointment_Module__c.Fields.Meddbase_Key__c;
            Database.UpsertResult crm = Database.upsert(a,meddKeym); 
            //insert a;
            Appointment_Slot__c s = new Appointment_Slot__c();
            s.Start__c = p.Start__c;
            s.Site__c = p.Site__c;
            //s.Resource_Key__c = null;
            s.Finish__c = p.Finish__c;
            s.Clinician__c = p.Clinician__c; 
            s.Appointment_Type__c = p.Appointment_Type__c;
            s.External_Key__c = a.Meddbase_Key__c;
            s.Proposed_Appointment__c = p.Id;
            Schema.SObjectField meddKey = Appointment_Slot__c.Fields.External_Key__c;
            Database.UpsertResult cr = Database.upsert(s,meddKey); 
            //insert s;  
        }
        Integer duration = Integer.valueOf((p.Finish__c.getTime() - p.Start__c.getTime())/(1000*60));//(p.Finish__c-p.Start__c)*24*60;
        if(duration != null){ 
            updateSameTimeOtherAppointment(p.Clinician__c,p.Start__c,duration);
        }       
        return p.Id;
    }
    
    public static void updateSameTimeOtherAppointment(String clinicianId,DateTime satrtDate,Integer duration){
        list<DateTime> updateDT = new list<DateTime>();
        for(Integer i=0;i<duration/10;i++){
            updateDT.add(satrtDate.addMinutes(i*10));
        }
        list<Proposed_Appointment__c> objPAsToUpdate = new list<Proposed_Appointment__c>(); 
        for(Proposed_Appointment__c p:[Select Id,State__c,Start__c From Proposed_Appointment__c WHERE (State__c = null OR State__c = 'Cancelled') AND Patient__c=null AND Clinician__c = :clinicianId AND Start__c IN: updateDT]){
            p.State__c = 'Not Available';
            objPAsToUpdate.add(p);
        }
        update objPAsToUpdate;
        system.debug('>>>>>>>>>>>>>>'+objPAsToUpdate.size());
    }
    
    public static string getPatienByEmailAndName(AppointmentParser objAppointmentParser){        
        Account objAccount = new Account();
        objAccount.LastName = objAppointmentParser.msg.PatientSurname.trim();
        objAccount.FirstName = ((objAppointmentParser.msg.PatientForename!= null && objAppointmentParser.msg.PatientForename!='')?objAppointmentParser.msg.PatientForename.replace(objAppointmentParser.msg.PatientSurname,'').trim():''); 
        list<Account> objAccounts = [SELECT Id FROM Account WHERE PersonEmail=:objAppointmentParser.msg.PatientEmail AND FirstName=:objAccount.FirstName AND LastName=:objAccount.LastName];
        if(objAccounts.size() > 0){
            objAccount.Id = objAccounts.get(0).Id; 
            objAccount.PersonEmail = objAppointmentParser.msg.PatientEmail;               
            objAccount.Date_of_Birth__c = date.parse(objAppointmentParser.msg.PatientDateOfBirth.split(' ')[0]);
            objAccount.PersonMobilePhone = objAppointmentParser.msg.PatientMobileNumber;
            objAccount.Gender__c = objAppointmentParser.msg.PatientSex;
            objAccount.Salutation = objAppointmentParser.msg.PatientTitle; 
            objAccount.MeddBase_Key__c = objAppointmentParser.msg.PatientID;  
            objAccount.BillingStreet = objAppointmentParser.msg.PatientAddressLine1;
            objAccount.BillingCity = objAppointmentParser.msg.PatientAddressCity;
            objAccount.BillingPostalCode= objAppointmentParser.msg.PatientAddressPostCode;
            objAccount.BillingCountry = 'United Kingdom';         
            upsert objAccount;
            return objAccount.Id;
        }else{
            return createLeadAndConvertToAnAccount(objAppointmentParser);
        }
        /*list<Account> accounts = AeronaCalloutUtility.getPatientSearchByFilter(objAccount.Id,'130',objAccount.PersonMobilePhone,objAccount.PersonEmail,objAccount.FirstName,objAccount.LastName,String.valueOf(objAccount.Date_of_Birth__c).substring(0,10),null);
        if(accounts.size() > 0){
            objAccount.Aerona_Patient_Id__c = accounts.get(0).Aerona_Patient_Id__c; 
        }
        update objAccount;*/ 
        //return null;
    }

    public static map<String,String> appointmentBUMap{
        get{
            map<String,String> aBUMap = new map<String,String>{
                'GP Consultation - Video (registered patients only)'=>'GP',
                'GP Consultation In Clinic'=>'GP',
                'GP Consultation In Clinic - New Patient Offer'=>'GP',
                'GP Consultation - Telephone'=>'GP',
                'Home Visit'=>'GP', 
                'Advanced Healthscreen Part 1 - GP consultation'=>'GP',
                'Advanced Healthscreen Part 1 - Nurse consultation'=>'GP',
                'Advanced Healthscreen Part 1 (MEMBER) - Nurse'=>'GP',
                'Advanced Healthscreen Part 2 (MEMBER) - GP'=>'GP',
                'Prescription'=>'GP',
                'Results'=>'GP',
                'STANDARD HEALTHSCREEN (20mins)'=>'GP',
                'STANDARD HEALTHSCREEN OFFER  £149 (20mins)'=>'GP',  
                'Invisalign First Consultation'=>'Ortho',   
                'Nurse Consultation'=>'GP',
                'Nurse Consultation - Telephone'=>'GP',
                'Orthodontic Consultation - New Patient Offer'=>'Ortho', 
                'Routine Dental Examination'=>'Dentist',
                'Sexual Health Advice Telephone Consultation'=>'Sexual Health',
                'Sexual Health Testing Appointment'=>'Sexual Health',
                'Therapists'=>'Therapists',
                'Botox - Filler'=>'Therapists',
                'Diagnostics & OP Procedures'=>'Diagnostics',
                'Ultrasound Scan Appointment'=>'Diagnostics',
                'Pregnancy Scan Appointment'=>'Diagnostics',
                'Airflow (Hygienist)'=>'Dentist',
                'Anti-snoring device fit'=>'Dentist',
                'Anti-snoring device impressions'=>'Dentist',
                'Classic Clean'=>'Dentist',
                'Crowns and Bridge'=>'Dentist',
                'Dentist Consultation'=>'Dentist',
                'Dentist Consultation - New Patient'=>'Dentist',
                'Dentist Consultation - New Patient Offer'=>'Dentist',
                'Dentures'=>'Dentist',
                'Emergency (1st visit to clinic)'=>'Dentist',
                'Emergency (Existing Patient)'=>'Dentist',
                'Filling'=>'Dentist',
                'Hygiene Child'=>'Dentist',
                'Hygiene Treatment Appointment - Member'=>'Dentist',
                'Initial Periodontal Treatment'=>'Dentist',
                'Internal whitening (1st session)'=>'Dentist',
                'Internal whitening (follow-up)'=>'Dentist',
                'Laser Whitening'=>'Dentist',
                'New Patient Veneer Consultation'=>'Dentist',
                'Oral Surgery'=>'Dentist',
                'Oral Surgery - New Patient'=>'Dentist',
                'Periodontal Reassessment'=>'Dentist',
                'Root Canal Treatment'=>'Dentist',
                'Routine Dental Examination'=>'Dentist',
                'Sport or Night Guard fit'=>'Dentist',
                'Sport or Night Guard impressions'=>'Dentist',
                'Ultra Clean'=>'Dentist',
                'Whitening Fit (trays)'=>'Dentist',
                'Whitening Impressions'=>'Dentist', 
                'Fertility Consultation - Female'=>'Fertility',
                'Fertility Consultation - Male'=>'Fertility',
                'Implant Additional Surgery'=>'Implants',
                'Implant Consultation'=>'Implants',
                'Implant Consultation - Follow-up'=>'Implants',
                'Implant Consultation - New Patient Offer'=>'Implants',
                'Implant placement surgery'=>'Implants',
                'Implant Recall'=>'Implants',
                'Implant Restoration'=>'Implants',
                'Medical consultants'=>'Medical consultants',
                'Invisalign Consultation - Follow-up'=>'Ortho',
                'Invisalign First Consultation'=>'Ortho',
                'Invisalign Recall Visit'=>'Ortho',
                'Invisalign Records'=>'Ortho',
                'Ortho Recall'=>'Ortho',
                'Orthodontic bond-up'=>'Ortho',
                'Orthodontic Consultation'=>'Ortho',
                'Orthodontic Consultation - Follow-up'=>'Ortho',
                'Orthodontic Consultation - New Patient Offer'=>'Ortho',
                'Orthodontic Debond'=>'Ortho',
                'Orthodontic Debond + BR'=>'Ortho', 
                'Blood Test Appointment'=>'Pathology & Vaccines',
                'FLU VACCINE APPOINTMENT'=>'Pathology & Vaccines',
                'Free Travel Consultation - Telephone Call'=>'Pathology & Vaccines',
                'Vaccines Consultation'=>'Pathology & Vaccines'    
            };
            return aBUMap;
        }
    }   
    
    public static string createLeadAndConvertToAnAccount(AppointmentParser objAppointmentParser){
        Lead objLead = New lead();
        objLead.LastName = objAppointmentParser.msg.PatientSurname.trim();
        objLead.FirstName = ((objAppointmentParser.msg.PatientForename!= null && objAppointmentParser.msg.PatientForename!='')?objAppointmentParser.msg.PatientForename.replace(objAppointmentParser.msg.PatientSurname,'').trim():''); 
        objLead.Email = objAppointmentParser.msg.PatientEmail;               
        objLead.Date_of_Birth__c = date.parse(objAppointmentParser.msg.PatientDateOfBirth.split(' ')[0]);
        objLead.MobilePhone = objAppointmentParser.msg.PatientMobileNumber;
        objLead.Gender__c = objAppointmentParser.msg.PatientSex;
        objLead.Salutation = objAppointmentParser.msg.PatientTitle; 
        objLead.Business_Unit__c = appointmentBUMap.get(objAppointmentParser.msg.AppointmentBookedServices);
        //objLead.MeddBase_Key__c = objAppointmentParser.msg.PatientID;  
        objLead.Street = objAppointmentParser.msg.PatientAddressLine1;
        objLead.City = objAppointmentParser.msg.PatientAddressCity;
        objLead.PostalCode= objAppointmentParser.msg.PatientAddressPostCode;
        objLead.Country = 'United Kingdom';  
        insert objLead;  
        Database.LeadConvert objLC = new Database.LeadConvert();
        objLC.setLeadId(objLead.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        objLC.setConvertedStatus(convertStatus.MasterLabel); 
        objLC.setDoNotCreateOpportunity(TRUE);
        Database.LeadConvertResult lcr = Database.convertLead(objLC);
        if(lcr.isSuccess()){
            return lcr.getAccountId();
        }else{
            DatabaseUtility.creatErrorlog('','AppointmentUpdateFromMeddbase',
                                         '194','Lead conversion Failure','',
                                         '','','','','');
        } 
        return null;
    }   
    
    public static map<string,string> clinicianMap{
        get{             
            map<string,string> clinicianMap = new map<string,string>();
            for(Clinician__c c:[SELECT Id, Meddbase_Key__c FROM Clinician__c WHERE Meddbase_Key__c <> null limit 999]){
                clinicianMap.put(String.valueOf(c.Meddbase_Key__c),c.Id);
            }
            return clinicianMap;
        }
    }
    public static map<string,string> sitesMap{
        get{             
            map<string,string> siteMap = new map<string,string>();
            for(Site__c c:[SELECT Id, Meddbase_Key__c FROM Site__c WHERE Meddbase_Key__c <> null limit 999]){
                siteMap.put(String.valueOf(c.Meddbase_Key__c),c.Id);
            }
            return siteMap;
        }
    }
    public static map<string,string> appointmentTypeMap{
        get{             
            map<string,string> appointmentTypeMap = new map<string,string>();
            for(Appointment_Type__c c:[SELECT Id, Name FROM Appointment_Type__c WHERE Meddbase_Key__c <> null limit 999]){
                appointmentTypeMap.put(c.Name,c.Id);
            }
            return appointmentTypeMap;
        }
    }
    public class AppointmentParser{
        public msg msg{get;set;}        
    }
    public class msg{
        public String PatientAddressCounty{get;set;}
        public String PatientAddressCity{get;set;}
        public String PatientAddressCountry{get;set;}
        public String PatientAddressLine1{get;set;}
        public String PatientAddressPostCode{get;set;}
        public String PatientDateOfBirth{get;set;}
        public String PatientEmail{get;set;}
        public String PatientSurname{get;set;}
        public String PatientMobileNumber{get;set;}
        public String PatientForename{get;set;}
        public String PatientSex{get;set;}
        public String PatientID{get;set;}
        public String PatientTitle{get;set;}
        public String AppointmentSite{get;set;}
        public String PatientGPId{get;set;}
        public String AppointmentSiteId{get;set;}
        public String InsurerId{get;set;}
        public String AppointmentStatus{get;set;}
        public String AppointmentBookedServices{get;set;}
        public String AppointmentType{get;set;}
        public String AppointmentDuration{get;set;}
        public Consultants Consultants{get;set;}
        public String AppointmentTime{get;set;}
        public String AppointmentConsultantId{get;set;}
        public String AppointmentDate{get;set;}
        public String AppointmentConsultant{get;set;}
        public String AppointmentNotes{get;set;}
        public String AppointmentID{get;set;}
        public String EpisodeId{get;set;}
        public EventIds EventIds{get;set;}
        //public object Invoices{get;set;}
        public String AppointmentUpdatedBy{get;set;}
    }
    public class EventIds{
        public Event Event{get;set;}
    }
    public class Event{
        public String x_4{get;set;}
        public String x_3{get;set;}
        public String x_2{get;set;}
        public String x_1{get;set;}
        public String x_0{get;set;}
    }
    public class Consultants{
        public String Item{get;set;}
    }    
}