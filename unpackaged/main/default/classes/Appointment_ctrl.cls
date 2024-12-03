global without sharing class Appointment_ctrl {
    public list<ProposedAppointment> objProposedAppointment{get;set;}
    public string selectedAppointmentType {get;set;}
    public string selectedSite {get;set;}
    public string selectedAppointmentTypeMeddbaseKey {get;set;}
    public string selectedAppointmentDate{get;set;}
    public dateTime selectedAppointmentDateTime{get;set;}   
    public string stripePublicKey{get;set;} 
    private map<String,String> mapATIdByLabel{get;set;}
    public Appointment_Type__c objAppointmentType{get;set;}
        
    public Appointment_ctrl(){
        objAppointmentType = new Appointment_Type__c();
        getAppoinmentTypes();
        String defaultAppointmentType = apexpages.currentpage().getparameters().get('at');
        if(defaultAppointmentType != null && defaultAppointmentType != ''){
            selectedAppointmentType = mapATIdByLabel.get(EncodingUtil.urlDecode(apexpages.currentpage().getparameters().get('at'),'UTF-8'));
        }
        objProposedAppointment = new list<ProposedAppointment>();
        selectedAppointmentDate = ''+System.now().format('dd/MM/yyyy');
        selectedAppointmentDateTime = System.now();
        stripePublicKey = CommonUtility.objMeddBaseSettings.Stripe_Public_Key__c;        
    }
    
    public void onChangeAppointmentType(){
        DatabaseUtility.updateOldUnusedSlots();
        if(selectedAppointmentType  != null && selectedAppointmentType != ''){
            selectedAppointmentTypeMeddbaseKey = [SELECT id, Name, Meddbase_Key__c FROM Appointment_Type__c WHERE Id=:selectedAppointmentType limit 1].Meddbase_Key__c;
        }else{
            selectedAppointmentTypeMeddbaseKey = '';
        }        
    }
    
    public list<SelectOption> getsites(){ 
        list<SelectOption> site = new list<SelectOption>{new SelectOption('','Select a Clinic Location'),new SelectOption('any','Any Clinic Location')};
        for(Site__c  a:[SELECT id, Name, Meddbase_Key__c FROM Site__c limit 1000]){
            site.add(new SelectOption(a.Id ,a.Name)); 
        }
        return site;
    }
    
    public list<SelectOption> getAppoinmentTypes(){
        mapATIdByLabel = new map<String,String>();
        list<SelectOption> at = new list<SelectOption>{new SelectOption('','Select an Appointment Type')};
        for(Appointment_Type__c a:[SELECT id, Name, Meddbase_Key__c FROM Appointment_Type__c limit 1000]){
            at.add(new SelectOption(a.Id ,a.Name));
            mapATIdByLabel.put(a.Name,a.Id);
        }
        return at;
    }
    @RemoteAction
    public static string resetPassword(string email, string fname, string lname, string dob ){
        string resetResultSet = MeddbaseCalloutUtility.resetPassword(email, fname,lname, dob);
        return resetResultSet;
    }
    
    @RemoteAction
    public static string createPatient(string fname,string lname, string reg_email, string reg_password, string dob, string add1,
                                       string add2, string add3,string city, string country, string postcode,string mobile ){
        string leadId = DatabaseUtility.createPatient(fname,lname, reg_email, reg_password, dob, add1,
                                       add2, add3,city, country, postcode,mobile);
        return leadId; 
    }
    
    @RemoteAction
    public static string convertLead2Account(string leadId){
        return json.serialize(DatabaseUtility.converntLeadById(leadId));
    }
    
    @RemoteAction
    public static PatientResponseData createPatientonMeddBase(string fname,string lname, string reg_email, string reg_password, string dob, string add1,
                                       string add2, string add3,string city, string country, string postcode,string mobile ){
        PatientResponseData patResultSet = DatabaseUtility.createPatientonMeddBase(fname,lname, reg_email, reg_password, dob, add1,
                                       add2, add3,city, country, postcode,mobile);
        return patResultSet;
    }
    
    @RemoteAction
    public static string loginPatient(string username,string password,string paId){
        string login = MeddbaseCalloutUtility.loginMeddbase(username,password,paId);
        return login;
    }
    
    @RemoteAction
    public static string regVarifyBySMS(string code,string phonenumber){
        string confirmationCode = MeddbaseCalloutUtility.varifyBySMS(code,phonenumber);
        return confirmationCode;
    }
    
    @RemoteAction
    public static AppointmentBookingResponseData bookAppointment(string sessionDetails, string paId,string username){
        list<string> sessionD = sessionDetails.split(':'); // success:token:sessionId
        AppointmentBookingResponseData resultSet = MeddbaseCalloutUtility.bookAnAppointment(paId,sessionD.get(1),sessionD.get(2));
        if(resultSet.status == 'ok'){
            DatabaseUtility.updateToken2Patient(username,sessionD.get(1),paId,resultSet.ok.result.State,resultSet.ok.result.StateDisplayName,resultSet.ok.result.StateColor);
        }else{
            DatabaseUtility.updateProposedAppointment(paId);
        }
        return resultSet;
    }
    
    @RemoteAction
    public static Proposed_Appointment__c getBookedAppointment(string paId){
        return [Select Patient__r.PersonMobilePhone,Patient__r.Billing_Address__c, Patient__r.Name, Patient__r.PersonEmail,Start__c, Site__r.Phone_Number__c,Site__r.PostCode__c, Site__r.County__c, Site__r.Country__c, Site__r.City__c, Site__r.Address_1__c, Site__r.Address_2__c,Clinician__r.Name, Appointment_Type__r.Name,Appointment_Type__r.Meddbase_Key__c, (Select NetPrice__c,GrossPrice__c From Appointment_Modules__r) From Proposed_Appointment__c WHERE Id=:paId limit 1];         
    }
    
    @RemoteAction
    public static string createStringCharge(string token,string amount){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.stripe.com/v1/charges');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+CommonUtility.objMeddBaseSettings.Stripe_Secret_Key__c);
        req.setBody('amount='+amount+'&currency=GBP&source='+token+'&capture=true');
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
    
    @RemoteAction
    public static void pay4Booking(string paId,string stripeChargeId,string bookingFee){
        Invoice__c i2Update = new Invoice__c();
        list<Proposed_Appointment__c> objInvoice = [Select p.Invoice__r.Paid__c,p.Invoice__c, p.Id From Proposed_Appointment__c p WHERE p.Id=:paId];
        if(objInvoice.size() > 0){
                i2Update.Id = objInvoice.get(0).Invoice__c;
                i2Update.Paid__c = true;
                i2Update.Total_Gross__c = (String.IsNotBlank(bookingFee)?Decimal.valueof(bookingFee):0.0);
                i2Update.Total_Net__c = (String.IsNotBlank(bookingFee)?Decimal.valueof(bookingFee):0.0);
                i2Update.Stripe_Charge__c = stripeChargeId;
                update i2Update;
        }       
    }
    
    @RemoteAction
    public static void memberInvoiceUpdate(string paId,decimal tn, decimal tg, decimal t){
        Invoice__c i2Update = new Invoice__c();
        list<Appointment_Module__c> m2Update = new list<Appointment_Module__c>();
        list<Proposed_Appointment__c> objInvoice = [Select p.Invoice__r.Paid__c,p.Invoice__c, p.Id, (Select Id,GrossPrice__c, NetPrice__c, Tax__c From Appointment_Modules__r)  From Proposed_Appointment__c p WHERE p.Id=:paId];
        if(objInvoice.size() > 0 && objInvoice.get(0).Invoice__c != null){
            i2Update.Id = objInvoice.get(0).Invoice__c;
            i2Update.Total_Net__c = tn;
            i2Update.Total_Gross__c = tg;
            i2Update.Tax__c = t;
            update i2Update;
            for(Appointment_Module__c am: objInvoice.get(0).Appointment_Modules__r){
                Appointment_Module__c objM = new Appointment_Module__c(Id=am.Id);
                objM.GrossPrice__c = tg;
                objM.NetPrice__c = tn;
                objM.Tax__c = t;
                m2Update.add(objM);
            }
            if(!m2Update.isEmpty()){
                update m2Update;
            }
        }       
    }
    
    public void getAeronaAppointments(){
        /*try{            
            objProposedAppointment = new list<ProposedAppointment>();     
            //list<Proposed_Appointment__c> p2Upsert = new list<Proposed_Appointment__c>();       
            list<Site__c> sites = new list<Site__c>();
            if(selectedSite == 'any'){
                sites.addAll([Select Name ,Id From Site__c]);
            }else{
                sites.addAll([Select Name ,Id From Site__c WHERE Id =:selectedSite]);
            }  
            ------------for(Site__c p:sites){
                for(Aerona_Site__c asi:[SELECT Id, Site__c,Clinician__c,Aerona_Clinician_key__c,Site__r.Name,Aerona_Site_Key__c,Clinician__r.Name FROM Aerona_Site__c WHERE Site__c=:p.Id]){
                    Date selectedDateInDT = date.parse(selectedAppointmentDate);
                    AeronaAvailableSlots objAeronaAvailableSlots = AeronaCalloutUtility.findSlots(Integer.valueOf(asi.Aerona_Site_Key__c),
                                                                   Integer.valueOf(asi.Aerona_Clinician_key__c),10319,
                                                                   String.ValueOf(date.newinstance(selectedDateInDT.year(), 
                                                                                    selectedDateInDT.month(), 
                                                                                    selectedDateInDT.day())));
                    if(objAeronaAvailableSlots.status == 'Success' && objAeronaAvailableSlots.result.size() > 0){
                        list<Proposed_Appointment__c> pResult = DatabaseUtility.createAeronaSlots(objAeronaAvailableSlots,asi.Site__c,asi.Clinician__c);    
                        if(pResult != null){
                            p2Upsert.addAll(pResult);
                        }
                    }
                }
            }       
            if(!p2Upsert.IsEmpty()) update p2Upsert;------------
            map<string,list<Aerona_Site__c>> objAeronaSiteMap = new map<string,list<Aerona_Site__c>>();
            for(Aerona_Site__c asi:[SELECT Id, Site__c,Clinician__c,Aerona_Clinician_key__c,Site__r.Name,Aerona_Site_Key__c,Clinician__r.Name FROM Aerona_Site__c]){
                if(objAeronaSiteMap.containsKey(asi.Site__c)){
                    list<Aerona_Site__c> objAS = objAeronaSiteMap.get(asi.Site__c);
                    objAS.add(asi);
                    objAeronaSiteMap.put(asi.Site__c,objAS);    
                }else{
                    objAeronaSiteMap.put(asi.Site__c,new list<Aerona_Site__c>());
                }
            }                        
            for(Site__c p:sites){
                ProposedAppointment objPA = new ProposedAppointment();
                list<ClinicianWpr> objCWs = new list<ClinicianWpr>();            
                objPA.sitename = p.Name;
                objPA.siteId = ''+Integer.ValueOf(siteMap.get(p.Id).MeddBase_Key__c);                
                for(Aerona_Site__c asi: objAeronaSiteMap.get(p.Id)){//  WHERE Site__c=:p.Id]){
                    system.debug('----------------------'+asi);
                    //for(Clinician__c c:[SELECT Id FROM Clinician__c]){
                    list<SlotWpr> objSWs = new list<SlotWpr>();
                    ClinicianWpr objC = new ClinicianWpr();
                    objC.cName = clinicianMap.get(asi.Clinician__c).Name;   
                    objC.cSpec = appointmentTypeMap.get(selectedAppointmentType).Name;                             
                    objC.cPhoto  = clinicianMap.get(asi.Clinician__c).Picture__c;  
                    objC.cSex  = clinicianMap.get(asi.Clinician__c).Clinician_Sex__c; 
                    objC.cId = ''+Integer.ValueOf(clinicianMap.get(asi.Clinician__c).MeddBase_Key__c);                           
                    for(Proposed_Appointment__c pa:[Select Start__c, Site__c, Primary_Attendee_Slot__c, 
                                                    Finish__c, Clinician__c, Appointment_Type__r.Name 
                                                    From Proposed_Appointment__c 
                                                    WHERE Appointment_Type__c=:selectedAppointmentType  
                                                    AND Clinician__c =:asi.Clinician__c  
                                                    AND DAY_ONLY(Start__c)= :date.parse(selectedAppointmentDate) 
                                                    AND Start__c > :selectedAppointmentDateTime 
                                                    AND Patient__c = null 
                                                    AND State__c != 'Not Available' 
                                                    AND Site__c =:p.Id
                                                    AND Is_Available_On_Aerona__c=true order by Site__c,Clinician__c,Start__c ]){    
                        if(pa.Clinician__c == asi.Clinician__c && pa.Site__c == p.Id){
                            SlotWpr objS = new SlotWpr();  
                            objS.startTime = pa.Start__c.format('HH:mm');
                            objS.finishTime = pa.Finish__c.format('HH:mm'); 
                            objS.slotId = pa.Id;                    
                            objSWs.add(objS);
                        }
                    }                      
                    objC.slots = objSWs;
                    if(objC.slots.size() == 0){
                        list<Proposed_Appointment__c> objPATemp = [Select Start__c From Proposed_Appointment__c 
                                                                   WHERE Appointment_Type__c=:selectedAppointmentType  
                                                                   AND Clinician__c =:asi.Clinician__c 
                                                                   AND DAY_ONLY(Start__c) > :date.parse(selectedAppointmentDate) 
                                                                   AND (State__c = null OR  State__c = 'Cancelled') AND Site__c =:p.Id 
                                                                   AND Appointment_Type__r.Aerona_Key__c <> null 
                                                                   AND Is_Available_On_Aerona__c=true order by Start__c limit 5];
                        if(objPATemp.size() != 0){
                            objC.cNextAvailableAppointment = 'Next appointment ' + objPATemp.get(0).Start__c.format('dd MMMM'); 
                            objC.cNextAvailableAppointmentDate = objPATemp.get(0).Start__c;
                        }else{
                            objC.cNextAvailableAppointment = 'There is no appointment available'; 
                        }
                    }            
                    objCWs.add(objC);
                }
                objPA.objClinician = objCWs;
                if(objPA.objClinician != null && objPA.sitename != 'null' && objPA.sitename != null && objPA.sitename != ''){
                    objProposedAppointment.add(objPA);
                }
            }
            //if(!p2Upsert.IsEmpty()) update p2Upsert;                          
        }catch(Exception e){
            system.debug(e+'-------------'+e.getLineNumber());
        }*/
    }
    
    public static list<string> tokenSessionId{
        get{
            if(tokenSessionId == null){
                tokenSessionId = MeddbaseCalloutUtility.integrationUserloginHandler();
            }
            return tokenSessionId;
        }
    }
    
    public void getProposedAppointmentByAT(){  
        try{
            Appointment_Type__c objAType = appointmentTypeMap.get(selectedAppointmentType);
            /*if(objAType != null && objAType.Aerona_Key__c != null){                
                getAeronaAppointments(); //Aerona Appointments
            }else{*/
                list<string> tokenSessionId = tokenSessionId;//CommonUtility.objMeddBaseSettings.Meddbase_Token_Session__c.split('_@_');//MeddbaseCalloutUtility.integrationUserloginHandler();
                //Meddbase Appointments - sych Appointments               
                /*list<Proposed_Appointment__c> obPA2Sync = new list<Proposed_Appointment__c>();
                if(!Test.IsRunningTest()){
                    obPA2Sync = MeddbaseCalloutUtility.syncAppointments(objAType.Meddbase_Key__c, ''+date.parse(selectedAppointmentDate),tokenSessionId);
                }*/
                objProposedAppointment = new list<ProposedAppointment>();  
                list<Site__c> sites = new list<Site__c>();
                if(selectedSite == 'any'){
                    sites.addAll([Select Name ,Id From Site__c]);
                }else{
                    sites.addAll([Select Name ,Id From Site__c WHERE Id =:selectedSite]);
                }
                /*map<string,list<Integer>> clinicianBySiteMap = new map<string,list<Integer>>();
                for(Site__c s:sites){ 
                    list<Integer> clinicianKeys = new list<Integer>();
                    ClinicianData objClinicianData = new ClinicianData();
                    if(!Test.IsRunningTest()){
                        objClinicianData = MeddbaseCalloutUtility.getCliniciansBySite(objAType.Meddbase_Key__c.trim(),String.valueOf(Integer.ValueOf(siteMap.get(s.Id).MeddBase_Key__c)).trim(),tokenSessionId);                                
                    }else{
                        objClinicianData.status = 'ok';
                        ClinicianData.result objRel = new ClinicianData.result();
                        objRel.Key = 5622;
                        objRel.SexType = 1;
                        objRel.FullName = 'mo';
                        objClinicianData.result = new list<ClinicianData.result>{objRel};
                    }
                    if(null != objClinicianData){
                        for(ClinicianData.result cl:objClinicianData.result){
                            clinicianKeys.add(cl.Key);
                        }  
                        clinicianBySiteMap.put(s.Id,clinicianKeys);
                    }               
                }*/
                //if(!obPA2Sync.IsEmpty()) update obPA2Sync;
                //if(clinicianBySiteMap.size() > 0){
                list<Clinician_Appoinment_Types__c> cATList = [SELECT Id,Clinician__c,Clinician__r.Name,Clinician__r.MeddBase_Key__c,Clinician__r.Clinician_Sex__c,Clinician__r.Picture__c FROM Clinician_Appoinment_Types__c 
                                                              WHERE Appointment_Type__c=:selectedAppointmentType AND Available__c=true];                    
                    for(Site__c p:sites){
                        ProposedAppointment objPA = new ProposedAppointment();
                        list<ClinicianWpr> objCWs = new list<ClinicianWpr>();            
                        objPA.sitename = p.Name;
                        objPA.siteId = ''+Integer.ValueOf(siteMap.get(p.Id).MeddBase_Key__c);
                        for(Clinician_Appoinment_Types__c c:cATList){//Clinician__c c:[SELECT Id FROM Clinician__c WHERE Meddbase_Key__c IN :clinicianBySiteMap.get(p.Id)]){// clinicianKeys]){
                            list<SlotWpr> objSWs = new list<SlotWpr>();
                            ClinicianWpr objC = new ClinicianWpr();
                            string cId = c.Clinician__c;//Id;
                            string aType = '';
                            objC.cName = c.Clinician__r.Name;   
                            objC.cSpec = appointmentTypeMap.get(selectedAppointmentType).Name;                             
                            objC.cPhoto  = c.Clinician__r.Picture__c;  
                            objC.cSex  = c.Clinician__r.Clinician_Sex__c; 
                            objC.cId = ''+Integer.ValueOf(c.Clinician__r.MeddBase_Key__c);                           
                            for(Proposed_Appointment__c pa:[Select Start__c, Site__c, Primary_Attendee_Slot__c, 
                                                            Finish__c, Clinician__c, Appointment_Type__r.Name 
                                                            From Proposed_Appointment__c 
                                                            WHERE Appointment_Type__c=:selectedAppointmentType  
                                                            AND Clinician__c =:cId  
                                                            AND DAY_ONLY(Start__c)= :date.parse(selectedAppointmentDate) 
                                                            AND Start__c > :selectedAppointmentDateTime 
                                                            AND Patient__c = null 
                                                            AND State__c != 'Not Available' 
                                                            AND Site__c =:p.Id order by Site__c,Clinician__c,Start__c ]){                     
                                SlotWpr objS = new SlotWpr();  
                                objS.startTime = pa.Start__c.format('HH:mm');
                                objS.finishTime = pa.Finish__c.format('HH:mm'); 
                                objS.slotId = pa.Id;                    
                                objSWs.add(objS);              
                            }                      
                            objC.slots = objSWs;
                            objC.startDate = Date.newInstance(1960, 1, 1); //default to first order
                            if(objC.slots.size() == 0){
                                list<Proposed_Appointment__c> objPATemp = [Select Start__c From Proposed_Appointment__c 
                                                                           WHERE Appointment_Type__c=:selectedAppointmentType  
                                                                           AND Clinician__c =:cId 
                                                                           AND DAY_ONLY(Start__c) > :date.parse(selectedAppointmentDate) 
                                                                           AND State__c = null 
                                                                           AND Site__c =:p.Id order by Start__c limit 5];
                                if(objPATemp.size() != 0){
                                    objC.cNextAvailableAppointment = 'Next appointment ' + objPATemp.get(0).Start__c.format('EEE dd MMMM'); 
                                    objC.cNextAvailableAppointmentDate = objPATemp.get(0).Start__c;
                                    objC.startDate = Date.newInstance(objPATemp.get(0).Start__c.year(), objPATemp.get(0).Start__c.month(), objPATemp.get(0).Start__c.day());//.getTime().intValue();
                                }else{
                                    objC.cNextAvailableAppointment = 'There is no appointment available'; 
                                }
                            }            
                            objCWs.add(objC);
                        }
                        system.debug('---------------'+objCWs);
                        objPA.objClinician = sortByLatestAvailableClincian(objCWs,'Asc');//objCWs;//
                        if(objPA.objClinician != null && objPA.sitename != 'null' && objPA.sitename != null && objPA.sitename != ''){
                            objProposedAppointment.add(objPA);
                        }
                    } 
               // }
            //}
        }catch(Exception e){
            system.debug(e+'>>>>>>>>>>>>>>>>>>>'+e.getLineNumber());
        }
    }
    
    public void getAppointmentByDate(){
        getProposedAppointmentByAT();
    }
    
    public static map<Id,Clinician__c> clinicianMap{
        get{
            if(clinicianMap == null){
                clinicianMap = new map<Id,Clinician__c>([SELECT c.MeddBase_Key__c,c.Clinician_Sex__c,c.Picture__c, c.Name, c.Appointment_Type__r.Name FROM Clinician__c c limit 9999]);                
            }
            return clinicianMap;
        }
    }
    
    public static map<Id,Site__c> siteMap{
        get{
            if(siteMap == null){
                siteMap = new map<Id,Site__c>([SELECT Id,MeddBase_Key__c,Name FROM Site__c limit 9999]);                
            }
            return siteMap;
        }
    }
    
    public static map<Id,Appointment_Type__c> appointmentTypeMap{
        get{
            if(appointmentTypeMap == null){
                appointmentTypeMap = new map<Id,Appointment_Type__c>([SELECT Id,Name,Meddbase_Key__c,Aerona_Key__c from Appointment_Type__c limit 1000]);
            }
            return appointmentTypeMap;
        }
    }
    
    public class ProposedBookingDetail{
        public string site{get;set;}
        public string siteId{get;set;}
        public list<Clinician> objClinicians{get;set;}
    }
    public class Clinician{
        public string image{get;set;}
        public string sex{get;set;}
        public string specialism{get;set;}
        public string clinicianName{get;set;}
        public string clinicianId{get;set;}
    }
    
    public class ProposedAppointment{
        public string sitename{get;set;}
        public string siteId{get;set;}
        public list<ClinicianWpr> objClinician {get;set;}
    }  
    
    public class ClinicianWpr{
        public string cId{get;set;}
        public string cName{get;set;}
        public string cSpec{get;set;}
        public string cPhoto {get;set;}
        public string cSex {get;set;}
        public string cNextAvailableAppointment {get;set;}
        public datetime cNextAvailableAppointmentDate {get;set;}
        public list<SlotWpr> slots{get;set;} 
        public Date startDate{get;set;}
    }
    
    public class SlotWpr{
        public string startTime{get;set;}
        public string finishTime{get;set;}
        public string slotId{get;set;}
    }
    
    @RemoteAction
    public static string getPatientFromMeddbase(string token,string sid){       
        return JSON.serialize(MeddbaseCalloutUtility.retrivePatientInfo(token,sid));
    }
    // after Login it get proposed appointment
    @RemoteAction
    public static string getProposedAppointment(string token,string sid,string apt,string fromDate, string clinicianId, string siteId){       
        return MeddbaseCalloutUtility.retriveProposedAppointment(token,sid,apt,fromDate, clinicianId,siteId);
    }
    
    @RemoteAction
    public static string createPatientIfNotExist(string strPatientData,string selectedAppointmentType){
        try{
            PatientData objPatientData = (PatientData)JSON.deserialize(strPatientData,PatientData.class);
            list<Account> objAcc = [SELECT Id,MeddBase_Token__c FROM Account WHERE PersonEmail=:objPatientData.result.EmailAddress limit 1];
            if(objAcc.size() > 0){ 
                return 'PatientAlreadyExistInSF';
            }else{
                /*Account objAccount = new Account();
                objAccount.Salutation = objPatientData.result.Title;
                objAccount.LastName = objPatientData.result.SurName; 
                objAccount.FirstName = objPatientData.result.Name.replace(objPatientData.result.SurName,'');
                objAccount.Date_of_Birth__c = date.valueof(objPatientData.result.DateOfBirth);
                objAccount.PersonEmail = objPatientData.result.EmailAddress; 
                objAccount.Patient_Type__c = 'Registered';
                objAccount.Phone = objPatientData.result.Mobile;
                objAccount.BillingCity = objPatientData.result.Address.City; 
                objAccount.BillingPostalCode = objPatientData.result.Address.PostCode; 
                objAccount.BillingCountry = objPatientData.result.Address.Country;
                objAccount.BillingStreet = objPatientData.result.Address.Address1 +' '+(objPatientData.result.Address.Address2!=null?objPatientData.result.Address.Address2:'') +' '+(objPatientData.result.Address.Address3!=null?objPatientData.result.Address.Address3:''); 
                //try{
                //Appointment_Type__c objAType = appointmentTypeMap.get(selectedAppointmentType);
                //if(objAType != null && objAType.Aerona_Key__c != null){                 
                //    objAccount.Aerona_Patient_Id__c = AeronaCalloutUtility.createAeronaPatient(objPatientData.result.Mobile.replace(' ',''),objAccount.FirstName.trim(), objAccount.LastName.trim(),'250', objPatientData.result.DateOfBirth.subString(0,10), objAccount.PersonEmail);//}catch(Exception ce){system.debug('>>>---------------------'+ce);}
                //}
                insert objAccount;
                return objAccount.Id;*/
                Lead objLead = New lead();
                objLead.LastName = objPatientData.result.SurName;
                objLead.FirstName = objPatientData.result.Name.replace(objPatientData.result.SurName,''); 
                objLead.Email = objPatientData.result.EmailAddress;            
                objLead.Date_of_Birth__c = date.valueof(objPatientData.result.DateOfBirth);
                objLead.MobilePhone = objPatientData.result.Mobile;
                objLead.Business_Unit__c = 'GP'; //Hardcoded untill releasing new Appointment type: Todo 
                //objLead.Gender__c = objAppointmentParser.msg.PatientSex;
                objLead.Salutation = objPatientData.result.Title; 
                //objLead.Business_Unit__c = appointmentBUMap.get(objAppointmentParser.msg.AppointmentBookedServices);
                //objLead.MeddBase_Key__c = objAppointmentParser.msg.PatientID;  
                objLead.Street = objPatientData.result.Address.Address1 +' '+(objPatientData.result.Address.Address2!=null?objPatientData.result.Address.Address2:'') +' '+(objPatientData.result.Address.Address3!=null?objPatientData.result.Address.Address3:'');
                objLead.City = objPatientData.result.Address.City;
                objLead.PostalCode = objPatientData.result.Address.PostCode;
                objLead.Country = objPatientData.result.Address.Country; 
                objLead.Mode__c = 'Online Booking'; 
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
                    DatabaseUtility.creatErrorlog('','Appointment_ctrl',
                                                 '491','Lead conversion Failure','',
                                                 '','','','','');
                } 
            }
        }catch(Exception e){ 
            system.debug('Error: '+e.getMessage());
        }
        return null;
    }
    
    public list<selectOption> getPatientTypes(){
       List<SelectOption> options = new List<SelectOption>{new SelectOption('', '')};        
       Schema.DescribeFieldResult fieldResult = Appointment_Type__c.Patient_Type__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();            
       for( Schema.PicklistEntry f : ple) {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
       }       
       return options;
    }
    
    public list<selectOption> getAppointmentTypeCategory(){
       List<SelectOption> options = new List<SelectOption>{new SelectOption('', '')};        
       Schema.DescribeFieldResult fieldResult = Appointment_Type__c.Appointment_Type_Family_Category__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();            
       for( Schema.PicklistEntry f : ple) {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
       } 
       options.sort();      
       return options;
    }
    
    @RemoteAction
    public static list<String> getAppointmentTypesCategory(string selectedPatientType){
        set<string> options = new set<String>{''};
        list<Appointment_Type__c> ats = [SELECT Id,Name,Patient_Type__c,Appointment_Type_Family_Category__c FROM Appointment_Type__c WHERE Patient_Type__c includes (:selectedPatientType) AND Is_Active__c=true];
        for(Appointment_Type__c at : ats ) {
            if(at.Appointment_Type_Family_Category__c.startsWith('GP')){
                options.add(at.Appointment_Type_Family_Category__c);
            }
        }
        for(Appointment_Type__c at : ats ) {
            if(!at.Appointment_Type_Family_Category__c.startsWith('GP')){
                options.add(at.Appointment_Type_Family_Category__c);
            }
        }
        list<string> ops = new list<string>();
        ops.addAll(options);
        ops.sort();
        //options = ops;       
        return ops;//tions;
    }
    
    public static set<Proposed_Appointment__c> updatePA2NA(string aTypeKey, list<AppointmentData.result> objAD){
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
    
    public static DateTime getDateTimeByString(string datetimestr){
        if(datetimestr != null && datetimestr != ''){
            return DateTime.valueOf(datetimestr.replace('T',' '));
        }
        return null;
    }
    
    @RemoteAction
    public static list<string> getAppointmentTypes(string selectedAppointmentType, string selectedPatientType){
        List<string> options = new List<string>{''};
        for(Appointment_Type__c at : [SELECT Id,Name,Patient_Type__c,Appointment_Type_Family_Category__c FROM Appointment_Type__c WHERE Appointment_Type_Family_Category__c =:selectedAppointmentType AND Patient_Type__c includes (:selectedPatientType) AND Is_Active__c=true]) {
            options.add(at.Name+'_@_'+ at.Id);
        }       
        return options;
    }  
    /*@RemoteAction
    public static void syncAppointments(string aType, string selectedDate){
        Appointment_Type__c objAType = appointmentTypeMap.get(aType);
        list<Proposed_Appointment__c> obPA2Sync = new list<Proposed_Appointment__c>();
        obPA2Sync = MeddbaseCalloutUtility.syncAppointments(objAType.Meddbase_Key__c, ''+date.parse(selectedDate),null);
        if(!obPA2Sync.IsEmpty()) update obPA2Sync;
    }*/
    public static list<ClinicianWpr> sortByLatestAvailableClincian(list<ClinicianWpr> wrapperObject,String sortingOrder) {
        if(wrapperObject == null || wrapperObject.size() <= 1){
            return wrapperObject ;
        }
        List<ClinicianWpr> lessSelectOption = new List<ClinicianWpr>();
        List<ClinicianWpr> greaterSelectOption = new List<ClinicianWpr>();
        integer pivot = wrapperObject.size() / 2;
        
        //save the pivot and remove it from the wrapper list
        ClinicianWpr pivotValue = wrapperObject[pivot];
        wrapperObject.remove(pivot);        
        for(ClinicianWpr SO : wrapperObject){           
            if(sortingOrder == 'Desc'){
                if(SO.startDate > pivotValue.startDate){
                    lessSelectOption.add(SO);
                }else if(SO.startDate <= pivotValue.startDate){
                    greaterSelectOption.add(SO);   
                }
            }else{
                if(SO.startDate <= pivotValue.startDate){
                    lessSelectOption.add(SO);
                }else if(SO.startDate > pivotValue.startDate){
                    greaterSelectOption.add(SO);   
                }
            }            
        }
        list<ClinicianWpr> sortedSelectOptions = new list<ClinicianWpr>(); 
        sortedSelectOptions.addAll(sortByLatestAvailableClincian(lessSelectOption,sortingOrder));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(sortByLatestAvailableClincian(greaterSelectOption,sortingOrder));
        system.debug('>>>>>>>>>>>>>>>'+SortedSelectOptions);
        return SortedSelectOptions;
    }
}