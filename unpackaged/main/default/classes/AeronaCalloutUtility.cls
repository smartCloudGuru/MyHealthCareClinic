public with sharing class AeronaCalloutUtility {
    public static string loginHandler(){
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/login');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        req.setTimeout(60000);
        req.setBody('{"username":"'+CommonUtility.objMeddBaseSettings.Aerona_Username__c+'","password":"'+CommonUtility.objMeddBaseSettings.Aerona_Password__c+'","pin":"'+CommonUtility.objMeddBaseSettings.Aerona_Pin__c+'"}');
        Http http = new Http();
        if(!Test.isRunningTest()){
            HttpResponse res = http.send(req);system.debug('>>>>>>>>>>'+res.getBody());return res.getHeader('AERONA-AUTH-TOKEN');
        }
        return null;
    }
    @future(callout=true)
    public static void createAppointment(string accountId,string proposedId,string sitePracticeId,Decimal patientId,string clinicianUserId,string appointmentTime,string duration,Decimal aeronaAppointmentTypeId,string mobileNumber,string emailAddress,string forename,string surname,string dob,string aeronaToken){
        list<Account> accounts = new list<Account>();
        string auth_token = loginHandler();
        if(patientId == null){
            accounts = AeronaCalloutUtility.getPatientSearchByFilter(accountId,sitePracticeId,mobileNumber,emailAddress,forename,surname,dob,auth_token);
            if(accounts.size() > 0){
                patientId = accounts.get(0).Aerona_Patient_Id__c;
            }
        }
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/CreateAppointment');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        if(aeronaToken != null && aeronaToken != ''){
            req.setHeader('AERONA-AUTH-TOKEN', aeronaToken); 
        }else{ if(!Test.isRunningTest()){req.setHeader('AERONA-AUTH-TOKEN', auth_token);}
        }
        req.setBody('{ "practiceId": "'+sitePracticeId+'", "patientId": "'+patientId+'", "userId": "'+clinicianUserId+'", "appointmentTypeId": "'+aeronaAppointmentTypeId+'", "appointmentStatusId": "2", "appointmentTime": "'+appointmentTime+'", "duration": "'+duration+'", "sourceId": "1" }');
        req.setTimeout(60000);
        Http http = new Http();
        HttpResponse res;
        if(!Test.isRunningTest()){  
            res = http.send(req);string resultBody = res.getBody();system.debug('>>>>>>>>>>>>>>----->>>>>>>>>>>>>>>>>>---'+resultBody );AeronaCreatedAppointmentResult objAeronaCreatedAppointmentResult = (AeronaCreatedAppointmentResult)JSON.deserialize(resultBody,AeronaCreatedAppointmentResult.class);
            Proposed_Appointment__c objProposedAppointment = [SELECT Id,Aerona_Key__c FROM Proposed_Appointment__c WHERE id=:proposedId];objProposedAppointment.Aerona_Key__c = objAeronaCreatedAppointmentResult.result;//[0].patientId;
            update objProposedAppointment; 
        }
        if(accounts.size() > 0) upsert accounts;
    }
    
    @future(callout=true)
    public static void updateAppointment(Id proposedId,string appointmentId,string sitePracticeId,string clinicianUserId,string aeronaAppointmentTypeId,string appointmentDateTime,string duration,string aeronaToken){
        list<Account> accounts = new list<Account>();
        string auth_token = loginHandler();
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/UpdateAppointment');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        if(aeronaToken != null && aeronaToken != ''){
            req.setHeader('AERONA-AUTH-TOKEN', aeronaToken); 
        }else{ if(!Test.isRunningTest()){req.setHeader('AERONA-AUTH-TOKEN', auth_token);}
        } 
        req.setBody('{"appointmentId": "'+appointmentId+'","practiceId": "'+sitePracticeId+'","userId": "'+clinicianUserId+'","appointmentTypeId": "'+aeronaAppointmentTypeId+'","appointmentStatusId": "13","appointmentTime": "'+appointmentDateTime+'","duration": "'+duration+'"}');
        req.setTimeout(60000);
        Http http = new Http();
        HttpResponse res;
        if(!Test.isRunningTest()){  
            res = http.send(req);string resultBody = res.getBody();system.debug('>>>>>>>>>>>>>>----->>>>>>>>>>>>>>>>>>---'+resultBody );AeronaCreatedAppointmentResult objAeronaCreatedAppointmentResult = (AeronaCreatedAppointmentResult)JSON.deserialize(resultBody,AeronaCreatedAppointmentResult.class);
            Proposed_Appointment__c objProposedAppointment = [SELECT Id,Aerona_Key__c,State__c FROM Proposed_Appointment__c WHERE id=:proposedId];
            objProposedAppointment.State__c = null;
            update objProposedAppointment;
        } 
    }
    
    public static string getPatientSearch(string aeronaToken){        
        try{
            list<Account> accToUpdateAeronaId = new list<Account>();
            map<string,AeronaPatient.result> patientMap = new map<string,AeronaPatient.result>();
            for(Integer i=1;i<3;i++){
                HttpRequest req = new HttpRequest(); 
                req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/PatientSearch');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json'); 
                if(aeronaToken != null && aeronaToken != ''){
                    req.setHeader('AERONA-AUTH-TOKEN', aeronaToken);  }else{ req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
                }
                req.setBody('{"genderId":"'+i+'"}');
                req.setTimeout(60000);
                Http http = new Http();
                if(!Test.isRunningTest()){ HttpResponse res = http.send(req);  AeronaPatient objAeronaPatient = (AeronaPatient)JSON.deserialize(res.getBody(),AeronaPatient.class);  for(AeronaPatient.result ap:objAeronaPatient.result){  string n = ap.patientFullName.replace('(','').replace(')','').replace('Mrs','').replace('Mr','').replace('Miss','').replace('Master','').replace('Dr','').replace('Mister','').replace('M','').replace('child','').replace('baby','').trim(); patientMap.put(n,ap);
                    }
                }
            }          
            for(Account a: [SELECT Id, Name, Date_of_Birth__c,Aerona_Patient_Id__c FROM Account WHERE Name IN :patientMap.keyset()]){
                if(patientMap.containsKey(a.Name)){
                    Account objA = new Account(Id=a.Id);
                    objA.Aerona_Patient_Id__c = patientMap.get(a.Name).patientId;
                    accToUpdateAeronaId.add(objA); 
                }
            }
            if(accToUpdateAeronaId.size() > 0) update accToUpdateAeronaId;   
            return '{"status":"success","result":'+JSON.serialize(accToUpdateAeronaId)+'}';  }catch(Exception e){  return e.getMessage();
        } 
    }
    public static list<Account> getPatientSearchByFilter(string accountId,string practiceId,string mobileNumber,string emailAddress,string forename,string surname,string dob,string aeronaToken){        
        try{
            list<Account> accToUpdateAeronaId = new list<Account>();
            /*map<string,AeronaPatient.result> patientMap = new map<string,AeronaPatient.result>();
            //Integer aeronPatientId;
            //for(Integer i=1;i<3;i++){
                HttpRequest req = new HttpRequest(); 
                req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/PatientSearch');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json'); 
                if(aeronaToken != null && aeronaToken != ''){
                    req.setHeader('AERONA-AUTH-TOKEN', aeronaToken);  }else{ if(!Test.isRunningTest()) req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
                }
                req.setBody('{"forename":"'+forename+'","surname":"'+surname+'","dob":"'+dob+'"}');
                req.setTimeout(60000);
                Http http = new Http();
                if(!Test.isRunningTest()){ 
                    HttpResponse res = http.send(req); 
                    system.debug('>>>>>>>>>>>>>--------<<<<<<<<<'+res.getBody()); 
                    AeronaPatient objAeronaPatient = (AeronaPatient)JSON.deserialize(res.getBody(),AeronaPatient.class);  
                    for(AeronaPatient.result ap:objAeronaPatient.result){  
                        string n = ap.patientFullName.replace('null','').trim();                        
                        patientMap.put(n,ap);}
                }
            //}
            if(patientMap.size() > 0){
                system.debug('-----------------------'+patientMap);
                for(Account a: [SELECT Id, Name, Date_of_Birth__c,Aerona_Patient_Id__c FROM Account WHERE Id=:accountId]){//Name IN :patientMap.keyset()]){
                    //if(patientMap.containsKey(a.Name)){
                        Account objA = new Account(Id=a.Id);
                        objA.Aerona_Patient_Id__c = patientMap.values()[0].patientId;//get(a.Name).patientId;
                        accToUpdateAeronaId.add(objA); 
                        //aeronPatientId = patientMap.get(a.Name).patientId;
                    //}
                }
                //if(accToUpdateAeronaId.size() > 0) update 
                return accToUpdateAeronaId;   
                //return aeronPatientId;//'{"status":"success","result":'+JSON.serialize(accToUpdateAeronaId)+'}';
            }else{*/                
                Integer patientId;
                if(!Test.isRunningTest()){
                    patientId = createAeronaPatient(mobileNumber,forename, surname, practiceId, dob, emailAddress,aeronaToken); 
                }
                for(Account a: [SELECT Id, Name, Date_of_Birth__c,Aerona_Patient_Id__c FROM Account WHERE Id=:accountId]){//Name IN :patientMap.keyset()]){
                    system.debug('-------------->>'+a.Name);
                    //if(patientMap.containsKey(a.Name)){
                        Account objA = new Account(Id=a.Id);
                        objA.Aerona_Patient_Id__c = patientId;
                        accToUpdateAeronaId.add(objA); 
                        //aeronPatientId = patientId;
                    //}
                }
                if(accToUpdateAeronaId.size() > 0){ return accToUpdateAeronaId;      
                }else{ Account objAccount = new Account();
                       objAccount.FirstName = forename;
                       objAccount.PersonEmail = emailAddress; 
                       objAccount.LastName = surname;
                       objAccount.Date_of_Birth__c = date.valueOf(dob);
                       objAccount.PersonMobilePhone = mobileNumber;
                       objAccount.Aerona_Patient_Id__c = patientId;
                       objAccount.BillingCountry = 'United Kingdom';
                    //insert objAccount;
                    return new list<Account>{objAccount};
                    //return patientId;//'{"status":"success","result":'+JSON.serialize(objAccount)+'}'; 
                }  
                //return null;//aeronPatientId;//'{"status":"success","result":'+JSON.serialize(accToUpdateAeronaId)+'}';                
            //}               
        }catch(Exception e){ system.debug('>>>>>>>>>>'+e); return new list<Account>();}//'{"status":"failed","result":"'+e.getMessage()+'"}';} 
    }
    public static set<Aerona_Site__c> getClinicians(Integer aeronaSiteKey,string aeronaToken){
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/GetClinicians');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        if(aeronaToken != null && aeronaToken != ''){
            req.setHeader('AERONA-AUTH-TOKEN', aeronaToken); 
        }else{   req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
        }
        req.setBody('{"practiceId":'+aeronaSiteKey+'}');
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){
            HttpResponse res = http.send(req);
            AeronaClinician aClinician = (AeronaClinician)JSON.deserialize(res.getBody(),AeronaClinician.class);
            return updateAeronaClinician(aClinician,aeronaSiteKey);
        }
        return new set<Aerona_Site__c>();
    }
    public static string getAppointmentTypes(){
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/GetAppointmentTypes');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        if(!Test.isRunningTest()) req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
        req.setBody('{}');
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);return res.getBody();}
        return null;
    }
    public static AeronaAvailableSlots findSlots(Integer siteId, Integer clinicianId, Integer appointmentTypeId,string searchStartDate){
        string body = '{"practiceId": '+siteId+', "appointmentTypeId": '+appointmentTypeId+', "timeOfDay": 0, "searchStart": "'+searchStartDate+'", "clinicianId": '+clinicianId+'}';
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/FindAppointmentSlot');//FindAppointmentSlotPatientPortal');//
        req.setMethod('POST');
        req.setHeader('Content-Length',''+body.length());
        req.setHeader('Content-Type', 'application/json'); 
        if(!Test.isRunningTest()){  req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
        }
        req.setBody(body);
        req.setTimeout(60000);
        Http http = new Http();              
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){system.debug('-------------------'+res.getBody());return (AeronaAvailableSlots)JSON.deserialize(res.getBody(),AeronaAvailableSlots.Class);
            }
        }    
        return new AeronaAvailableSlots(); 
    }
    public static string getListByName(String listName,String aeronaToken){
        try{
            HttpRequest req = new HttpRequest(); 
            req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/KeyValueList/'+listName);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json'); 
            if(aeronaToken != null && aeronaToken != ''){
                req.setHeader('AERONA-AUTH-TOKEN', aeronaToken); 
            }else{ req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
            } 
            req.setBody('{}');
            req.setTimeout(60000);
            Http http = new Http();
            if(!Test.isRunningTest()){
                HttpResponse res = http.send(req);system.debug('------------->>>>'+res.getBody());list<AeronaSite> aSites = (list<AeronaSite>)JSON.deserialize(res.getBody(),list<AeronaSite>.class);updateAeronaSite(aSites,aeronaToken); 
            }
            return 'SUCCESS';
        }catch(Exception e){ return e.getMessage();
        }
    }    
    public static Integer createAeronaPatient(string mobileNumber,string forename, string surname, string practiceId, string dob, string emailAddress,string aeronaToken){
        string body = '{ "mobileNumber":"'+mobileNumber+'","practiceId": "'+practiceId+'", "patientTypeId": "1", "forename": "'+forename+'", "surname": "'+surname+'", "dob": "'+dob+'", "emailAddress": "'+emailAddress+'" }';//{"practiceId": '+siteId+', "appointmentTypeId": '+appointmentTypeId+', "timeOfDay": 0, "searchStart": "'+searchStartDate+'", "clinicianId": '+clinicianId+'}';
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Aerona_Endpoint__c+'/AeronaAPI/rest/CreatePatient'); 
        req.setMethod('POST');
        req.setHeader('Content-Length',''+body.length());
        req.setHeader('Content-Type', 'application/json'); 
        if(aeronaToken != null && aeronaToken != ''){
            req.setHeader('AERONA-AUTH-TOKEN', aeronaToken); 
        }else{
            req.setHeader('AERONA-AUTH-TOKEN', loginHandler()); 
        }
        req.setBody(body);
        req.setTimeout(60000);
        Http http = new Http(); 
        system.debug('>>>>>>>>>>>>>>-----'+body);
        if(!Test.isRunningTest()){ HttpResponse res = http.send(req);
            system.debug('-------------------'+res.getBody());
            if(res.getStatus() == 'OK'){ 
                string resultBody = res.getBody();
                if(!resultBody.contains('Warning')){
                    resultBody = res.getBody().replace('result":','result":[{"patientId":').replace(',"errorResult"','}],"errorResult"');
                }
                AeronaCreatedPatientResult objAeronaCreatedPatientResult = (AeronaCreatedPatientResult)JSON.deserialize(resultBody,AeronaCreatedPatientResult.Class);
                return objAeronaCreatedPatientResult.result[0].patientId;
            }
        }
        return null;
    }
    public static void updateAeronaSite(list<AeronaSite> aSites,String aeronaToken){
        map<String,Integer> siteNames = new map<String,Integer>();
        list<Aerona_Site__c> update2AS = new list<Aerona_Site__c>();
        for(AeronaSite a:aSites){ siteNames.put(a.value.toLowerCase(),a.key);
        }
        list<Site__c> updateSites = new list<Site__c>();
        for(Site__c site:[SELECT Id, Name, Aerona_Key__c FROM Site__c WHERE Name=:siteNames.keySet()]){
            site.Aerona_Key__c = siteNames.get(site.Name.toLowerCase());
            updateSites.add(site);
        }
        for(AeronaSite a:aSites){
            update2AS.addAll(getClinicians(a.key,aeronaToken));
        } 
        if(!updateSites.IsEmpty()) update updateSites;
        if(!update2AS.IsEmpty()) upsert update2AS;
    }
    public static set<Aerona_Site__c> updateAeronaClinician(AeronaClinician aClincian, Integer aeronaSiteKey){
        map<String,Integer> clinicianNames = new map<String,Integer>();
        map<String,Aerona_Site__c> aeronaSiteMap = new map<String,Aerona_Site__c>();
        set<Aerona_Site__c> updateClinician = new set<Aerona_Site__c>();
        for(result c:aClincian.result){
            clinicianNames.put(c.clinicianName.toLowerCase(),c.id);
        }
        for(Aerona_Site__c asi:[SELECT Id, Clinician__r.Name,Clinician__c, Site__c FROM Aerona_Site__c 
                               WHERE Clinician__r.Name=:clinicianNames.keySet()]){
            aeronaSiteMap.put(asi.Clinician__r.Name.toLowerCase(),asi);
        } 
        for(result aci:aClincian.result){
            if(clinicianMap.containsKey(aci.clinicianName) && sitesMap.containsKey(aeronaSiteKey)){
                Aerona_Site__c objAS = new Aerona_Site__c();
                if(aeronaSiteMap.containsKey(aci.clinicianName.toLowerCase())){
                    objAS.Id = aeronaSiteMap.get(aci.clinicianName.toLowerCase()).Id;
                }
                objAS.Aerona_Clinician_Key__c = aci.id;            
                objAS.Clinician__c = clinicianMap.get(aci.clinicianName);
                objAS.Site__c = sitesMap.get(aeronaSiteKey);
                objAS.Aerona_Site_Key__c = aeronaSiteKey;            
                updateClinician.add(objAS); 
            }
        }
        return updateClinician; 
    }
    public static map<String,Id> clinicianMap{
        get{
            map<String,Id>clinicianMap = new map<String,Id>();
            for(Clinician__c t: [SELECT Id,Name from Clinician__c limit 1000]){
                clinicianMap.put(t.Name,t.Id);
            } 
            return clinicianMap;
        }
    }
    
    public static map<Integer,Id> sitesMap{
        get{            
            map<Integer,Id> sitesMap = new map<Integer,Id>();
            for(Site__c t: [SELECT Id,Aerona_Key__c from Site__c limit 1000]){
                sitesMap.put(Integer.ValueOf(t.Aerona_Key__c),t.Id);
            }
            return sitesMap;
        }
    }
    /*public class AeronaCreatedPatientResult{
        public String errorResult{get;set;}
        public Integer result{get;set;}
        public Integer errorCode{get;set;}
        public String status{get;set;}
    }*/
    public class AeronaCreatedAppointmentResult{
        public String errorResult{get;set;}
        public Integer result{get;set;}
        public Integer errorCode{get;set;}
        public String status{get;set;}
    }
    public class AeronaSite{
        public String value{get;set;}
        public Integer key{get;set;}
    }
    public class AeronaClinician{
        public list<result> result{get;set;}
        public String errorResult{get;set;}
        public Integer errorCode{get;set;}
        public String status{get;set;}
    }
    public class result{
        public String clinicianName{get;set;}
        public Integer id{get;set;}
    }    
}