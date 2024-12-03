public with sharing class MeddbaseCalloutUtility {    
    public static AppointmentTypeData getAnonAppointmentTypes(){
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/anon-appointment/types?payer-type='+CommonUtility.objMeddBaseSettings.Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('POST');
        req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){return (AppointmentTypeData)JSON.deserialize(res.getBody(),AppointmentTypeData.Class);}}
        return new AppointmentTypeData();
    }
    public static SitesData getAnonSites(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/anon-appointment/sites?payer-type='+CommonUtility.objMeddBaseSettings.Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('POST');
        req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){return (SitesData)JSON.deserialize(res.getBody(),SitesData.Class);}}
        return new SitesData();
    }
    public static ClinicianData getAnonClinicians(string appointmentType){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/anon-appointment/clinicians?appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('POST');
        req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        Http http = new Http();        
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){return (ClinicianData)JSON.deserialize(res.getBody(),ClinicianData.Class);}}
        return new ClinicianData();
    }
    public static AppointmentData getProposedAppointments(string appointmentType){
        list<Proposed_Appointment__c> dt = [Select Id,State__c,Start__c From Proposed_Appointment__c WHERE Appointment_Type__r.Meddbase_Key__c=:appointmentType AND Start__c > :system.now() order by Start__c desc limit 1];
        String stringDate = string.valueOf(system.today()).substring(0,10);
        if(dt.size() > 0){ stringDate = string.valueOf(dt[0].Start__c).substring(0,10);
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/anon-appointment/proposed?appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Payer_Type__c+'&from-date='+stringDate+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('POST');
        req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){string jsonResult = res.getBody();jsonResult = jsonResult.replace('Number','x_Number').replace('Date','x_Date');return (AppointmentData)JSON.deserialize(jsonResult,AppointmentData.Class);}}
        return new AppointmentData();
    }
    public static PatientResponseData createPatient(string patientData){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/register-patient?regCode='+CommonUtility.objMeddBaseSettings.Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('POST');
        req.setTimeout(60000);
        req.setBody(patientData);//{"demog":{"Title": "Mr","Name": "namemo","Surname": "surnamemo","EmailAddress": "usman.sfdc@gmal.com","Password": "Areg_@123password","DateOfBirth": "2011-02-01T13:02:25","Address": { "Address1": "add1", "Address2": "add2", "Address3": "add3", "City": "city", "County": "UK", "PostCode": "12345", "Country": "UK"},"Mobile": "+918802413311"},"isOH":false,"regCode":"MHCTEST","client-key":"api-mhctest"}
        Http http = new Http();
        if(!Test.isRunningTest()){
            HttpResponse res = http.send(req);
            PatientResponseData objPatientResponseData = new PatientResponseData();   
            if(res.getStatus() == 'OK'){PatientResponseData.PatientResponOk okResult = (PatientResponseData.PatientResponOk)JSON.deserialize(res.getBody(),PatientResponseData.PatientResponOk.class);   if(okResult.status == 'ok'){objPatientResponseData.status = 'ok';objPatientResponseData.PatientResponOk = okResult;}else{objPatientResponseData.status = 'error';objPatientResponseData.PatientResponError = (PatientResponseData.PatientResponError)JSON.deserialize(res.getBody(),PatientResponseData.PatientResponError.class);}return objPatientResponseData;}}
        return new PatientResponseData();
    }
    public static string varifyBySMS(string code,string phonenumber){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/submit-validation-sms?code='+code+'&mobile='+EncodingUtil.urlEncode(phonenumber, 'UTF-8')+'&is-oh='+CommonUtility.objMeddBaseSettings.IS_OH__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('POST');
        req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);return res.getBody();}
        return '';
    }
    public static string resetPassword(string email, string fname, string lname, string dob){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/send-password-reset-email?email='+email.trim()+'&name='+EncodingUtil.urlEncode(fname.trim(), 'UTF-8')+'&surname='+EncodingUtil.urlEncode(lname.trim(), 'UTF-8')+'&date-of-birth='+dob.trim()+'&is-oh='+CommonUtility.objMeddBaseSettings.IS_OH__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
        req.setMethod('GET');
        //req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);return res.getBody();}
        return '';
    }
    public static string loginMeddbase(string username,string password,string paId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/login?is-oh='+CommonUtility.objMeddBaseSettings.IS_OH__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c); 
        req.setMethod('POST');
        //req.setHeader('Content-Length', '0'); 
        req.setTimeout(60000);
        req.setBody('{"username": "'+username+'","password":"'+password+'"}');
        Http http = new Http();
        if(!Test.isRunningTest()){
            HttpResponse res = http.send(req);
            Authentication objAuthentication = (Authentication)JSON.deserialize(res.getBody(),Authentication.Class); 
            if(res.getStatus() == 'OK'){if(objAuthentication.status == 'ok'){return '{"success":true,"token":"'+objAuthentication.result.Token+'","sid":"'+objAuthentication.result.sessionId+'","patient":'+JSON.serialize(CommonUtility.getPatientByEmail(username))+'}';}else{MeddBaseAPIError objMeddBaseAPIError = (MeddBaseAPIError)JSON.deserialize(res.getBody(),MeddBaseAPIError.Class);return objMeddBaseAPIError.error.Message;}}return 'Error:'+res.getBody();}
        return '';
    }
    public static list<string> integrationUserloginHandler(){
        string result = '';
        try{
            HttpRequest req1 = new HttpRequest();
            req1.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/login?is-oh='+CommonUtility.objMeddBaseSettings.IS_OH__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c); 
            req1.setMethod('POST');
            //req.setHeader('Content-Length', '0'); 
            req1.setTimeout(60000);
            req1.setBody('{"username": "'+CommonUtility.objMeddBaseSettings.Integration_Username__c+'","password":"'+CommonUtility.objMeddBaseSettings.Integration_User_Password__c+'"}');
            Http http1 = new Http();
            Authentication objAuthentication;
            if(!Test.isRunningTest()){HttpResponse res1 = http1.send(req1);result=res1.getBody();objAuthentication = (Authentication)JSON.deserialize(res1.getBody(),Authentication.Class);return new list<String>{objAuthentication.result.token,objAuthentication.result.sessionId};
            }else{
                objAuthentication = new Authentication();
                objAuthentication.status = 'ok';
                objAuthentication.result = new Authentication.result();          
            }
        }catch(Exception e){DatabaseUtility.creatErrorlog('','MeddbaseCalloutUtility.integrationUserloginHandler',''+e.getLineNumber(),e.getMessage()+'\n\n'+result+'\n\n'+CommonUtility.objMeddBaseSettings.Integration_Username__c+'\n\n'+CommonUtility.objMeddBaseSettings.Integration_User_Password__c,'','','','','','');}return null;    
    }
    public static AppointmentBookingResponseData bookAnAppointment(string paId,string token,string sessionId){        
        string bodyData = CommonUtility.createBookingRequest(paId);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/book?client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+token); 
        req.setMethod('POST');
        req.setHeader('Content-Length', ''+bodyData.length()); 
        req.setHeader('Cookie','ASP.NET_SessionId='+sessionId); 
        req.setTimeout(60000); 
        req.setBody(bodyData);//'{"proposedAppointment":{"Key":"1eefcde7d689d617f6530c9d552a67c6","Type":{"Name":"*Initial Consultation","Key":"000000004f5f836a","Notes":"","CanBookAppointment":true,"CanReferPatient":false,"TelemedicineOption":false},"Start":"2017-11-21T11:00:00","Finish":"2017-11-21T12:00:00","Site":{"Key":110,"Name":"Test Site","Address":{"Address1":"","Address2":"","Address3":"","City":"","County":"","PostCode":"","Country":""}},"Clinician":{"FullName":"MMS Support (MHC)","Key":1376,"SexType":1},"Telemedicine":false,"Modules":[{"Name":"*Initial Consultation","Key":1344,"CurrencyCode":"GBP","NetPrice":10,"Tax":0,"GrossPrice":10,"Notes":""}],"Invoice":{"Key":"1eefcde7d689d617f6530c9d552a67c6","Date":"2017-11-18T18:27:08.5851006 00:00","Number":0,"CurrencyCode":"GBP","TotalNet":10,"Tax":0,"TotalGross":10,"Paid":0,"PayableOnline":false},"Slots":[{"Type":{"Name":"*Initial Consultation","Key":"000000004f5f836a","Notes":"","CanBookAppointment":true,"CanReferPatient":false,"TelemedicineOption":false},"Start":"2017-11-21T11:00:00","Finish":"2017-11-21T12:00:00","Site":{"Key":110},"ResourceKey":20592}],"PrimaryAttendeeSlot":{"Type":{"Name":"*Initial Consultation","Key":"000000004f5f836a","Notes":"","CanBookAppointment":true,"CanReferPatient":false,"TelemedicineOption":false},"Start":"2017-11-21T11:00:00","Finish":"2017-11-21T12:00:00","Site":{"Key":110,"Name":"Test Site","Address":{"Address1":"","Address2":"","Address3":"","City":"","County":"","PostCode":"","Country":""}},"Clinician":{"FullName":"MMS Support (MHC)","Key":1376,"SexType":1},"ResourceKey":20592},"PayerType":"PA","$$hashKey":"object:111"}}');
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req);system.debug('>>>>>>'+res.getBody()); AppointmentBookingResponseData resulSet = new AppointmentBookingResponseData(); resulSet.status = ''; if(res.getStatus() == 'OK'){AppointmentBookingResponseDataOk okResult = (AppointmentBookingResponseDataOk)JSON.deserialize(res.getBody(),AppointmentBookingResponseDataOk.class);if(okResult.status == 'error'){AppointmentBookingResponseDataError errorResult = (AppointmentBookingResponseDataError)JSON.deserialize(res.getBody(),AppointmentBookingResponseDataError.class);resulSet.status = 'error';resulSet.error = errorResult;}else{resulSet.status = 'ok';resulSet.ok = okResult;}}return resulSet;}
        return new AppointmentBookingResponseData();
    }
    public static PatientData retrivePatientInfo(string token, string sessionId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/patient/demographic-data?client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+token);
        req.setMethod('GET'); 
        req.setHeader('Cookie','ASP.NET_SessionId='+sessionId); 
        req.setTimeout(60000);
        Http http = new Http();
        if(!Test.isRunningTest()){HttpResponse res = http.send(req); return (PatientData)JSON.deserialize(res.getBody(),PatientData.class);}
        return new PatientData();
    }
    public static string retriveProposedAppointment(string token, string sessionId,string appointmentType,string fromDate,string clinicianId,string siteId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/proposed?site='+siteId+'&clinician='+clinicianId+'&from-date='+fromDate+'&appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Booking_Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+token);
        req.setMethod('GET'); 
        req.setHeader('Cookie','ASP.NET_SessionId='+sessionId); 
        req.setTimeout(60000);
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        if(!Test.isRunningTest()){  res = http.send(req);
        }  
        return res.getBody();
    }
    public static string retriveAppointment(string token, string sessionId,string appointmentType){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/appointments?appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Booking_Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+token); //start-to=2018-03-05T11:00:00& start-from=2018-08-29T00:00:00&
        req.setMethod('GET'); 
        req.setHeader('Cookie','ASP.NET_SessionId='+sessionId); 
        req.setTimeout(60000);
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        if(!Test.isRunningTest()){ res = http.send(req); 
        } 
        return res.getBody();
    }
    public static ClinicianData getCliniciansBySite(string appointmentType, string site,list<string> tokenSessionId){
        if(tokenSessionId == null){
            tokenSessionId = integrationUserloginHandler();
        }
        if(tokenSessionId.size() > 1){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/clinicians?appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Booking_Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+tokenSessionId.get(0)); 
            req.setMethod('POST');
            //string s = '{"Key": 788, "Name":"MyHealthcare Clinic - WANDSWORTH"}';
            string s = '{"sites":['+site+']}';//'{"Key": 1312, "Name":"MyHealthcare Clinic - FULHAM"}';
            req.setHeader('Content-Length', ''+s.length()); 
            req.setHeader('Cookie','ASP.NET_SessionId='+tokenSessionId.get(1)); 
            req.setTimeout(60000); 
            if(site != ''){
                req.setBody(s);
            }
            Http http = new Http();               
            if(!Test.isRunningTest()){HttpResponse res = http.send(req);system.debug('>>>>>'+res.getBody());
            //system.debug('>>>>>>>-------->>>>>>'+retriveProposedAppointmentByIntUser(objAuthentication.result.token,objAuthentication.result.sessionId,appointmentType,null,'2775582'));
            if(res.getStatus() == 'OK'){return (ClinicianData)JSON.deserialize(res.getBody(),ClinicianData.Class);}}
            return new ClinicianData();
        }   return null;
    } 
    
    public static AppointmentData retriveProposedAppointmentByIntUser(string appointmentType,string clinicianId,list<String> tokenSessionId){
        if(tokenSessionId == null){
            tokenSessionId = integrationUserloginHandler();            
        }
        system.debug('-----------'+tokenSessionId);
        if((tokenSessionId != null && tokenSessionId.size() > 1) || Test.IsRunningTest()){
            list<Proposed_Appointment__c> dt = [Select Id,State__c,Start__c From Proposed_Appointment__c WHERE Patient__c=null AND Appointment_Type__r.Meddbase_Key__c=:appointmentType AND Clinician__r.Meddbase_Key__c =: Integer.ValueOf(clinicianId) AND Start__c <> null AND State__c In ('Not Available','Cancelled') order by Start__c desc limit 1];
            list<Proposed_Appointment__c> adt = [Select Id,State__c,Start__c From Proposed_Appointment__c WHERE Patient__c=null AND Appointment_Type__r.Meddbase_Key__c=:appointmentType AND Clinician__r.Meddbase_Key__c =: Integer.ValueOf(clinicianId) AND Start__c <> null AND State__c In ('Not Available','Cancelled') order by Start__c asc limit 1];
            Integer numberDaysDue = 0;
            if(adt.size() > 0 && dt.size() > 0){
                Date startDate = Date.newInstance(adt[0].Start__c.year(), adt[0].Start__c.month(), adt[0].Start__c.day());
                if(adt[0].Start__c <= System.Now()){
                    startDate = System.Today();
                }
                Date dueDate = Date.newInstance(dt[0].Start__c.year(), dt[0].Start__c.month(), dt[0].Start__c.day());
                if(dt[0].Start__c <= System.Now()){
                    dueDate = System.Today();
                }
                numberDaysDue = startDate.daysBetween(dueDate);
            }
            if(numberDaysDue < Integer.valueOf(System.Label.Number_Of_Days_To_be_Link_Appointment)){
                String stringDate = string.valueOf(system.today()).substring(0,10);
                if(dt.size() > 0 && dt[0].Start__c > System.Now()){   stringDate = string.valueOf(dt[0].Start__c).substring(0,10);} 
                HttpRequest req = new HttpRequest();
                req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/proposed?clinician='+clinicianId+'&from-date='+stringDate+'&appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Booking_Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+tokenSessionId.get(0));
                req.setMethod('GET'); 
                req.setHeader('Cookie','ASP.NET_SessionId='+tokenSessionId.get(1)); 
                req.setTimeout(60000);
                Http http = new Http();
                if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){string jsonResult = res.getBody();system.debug('>>>>>>>>>>'+jsonResult);jsonResult = jsonResult.replace('Number','x_Number').replace('Date','x_Date');return (AppointmentData)JSON.deserialize(jsonResult,AppointmentData.Class);}}            
            }
        } 
        return new AppointmentData();
    }
    
    public static AppointmentData syncTransferedWeeklyAppointments(string appointmentType,string stringDate,list<string> tokenSessionId){
        stringDate = stringDate.split(' ')[0];
        AppointmentData objAppointmentData = new AppointmentData();
        if(tokenSessionId == null){
            tokenSessionId = integrationUserloginHandler();
        }
        if(tokenSessionId != null && tokenSessionId.size() > 1){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/proposed?from-date='+stringDate+'&appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Booking_Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+tokenSessionId.get(0));
            req.setMethod('GET'); 
            req.setHeader('Cookie','ASP.NET_SessionId='+tokenSessionId.get(1)); 
            req.setTimeout(60000);
            Http http = new Http();
            if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){string jsonResult = res.getBody();system.debug('----'+jsonResult);jsonResult = jsonResult.replace('Number','x_Number').replace('Date','x_Date');objAppointmentData = (AppointmentData)JSON.deserialize(jsonResult,AppointmentData.Class);return objAppointmentData;}}            
        }
        return new AppointmentData();
        //if(objAppointmentData !=null && objAppointmentData.result.size() > 0){upsertMissingSlots(date.valueOf(stringDate),appointmentType,objAppointmentData.result);} 
    }
    
    public static void upsertMissingSlots(Date startDate, string aTypeKey, list<AppointmentData.result> objAD){
        system.debug('>>>>>>>>>>>'+objAD);
        //AppointmentData objAppointmentData
        //list<Proposed_Appointment__c> toUpdateProposedAppointment = new list<Proposed_Appointment__c>(); 
        list<Proposed_Appointment__c> paList = [Select Start__c,Id,State__c,Clinician__r.Meddbase_Key__c,Clinician__r.Name,Appointment_Type__r.Name From Proposed_Appointment__c 
                                                WHERE State__c <> 'Booked' AND Appointment_Type__r.Meddbase_Key__c = :aTypeKey AND DAY_ONLY(Start__c) <=:startDate limit 100];
        
        map<String,AppointmentData.result> paMap = new map<String,AppointmentData.result>();
        list<AppointmentData.result> objAD2Upsert = new list<AppointmentData.result>();
        for(AppointmentData.result c: objAD){
            paMap.put(getDateTimeByString(c.Start).getTime()+String.valueOf(c.Clinician.Key),c);            
        } 
        for(AppointmentData.result c: objAD){
            for(Proposed_Appointment__c p:paList){
                if(getDateTimeByString(c.Start).getTime()+String.valueOf(c.Clinician.Key) == p.Start__c.getTime()+String.valueOf(p.Clinician__r.Meddbase_Key__c)){
                    /*Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=p.Id);
                    objPA.State__c = ''; 
                    toUpdateProposedAppointment.add(objPA);*/ 
                }else{  
                    objAD2Upsert.add(c);
                    /*Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=p.Id);
                    objPA.State__c = 'Not Available'; 
                    toUpdateProposedAppointment.add(objPA);*/
                    //system.debug(p.Clinician__r.Name+'|||||||||||||===============>'+p.Start__c.addHours(1)+'------'+p.Id); 
                }             
            }
        }
        AppointmentData objSingleApptData = new AppointmentData();
        objSingleApptData.status = 'ok';
        objSingleApptData.result = objAD2Upsert;
        DatabaseUtility.createProposedAppointment(objSingleApptData);
        system.debug('------>>>>'+objSingleApptData);
        system.debug('------'+objAD2Upsert);
        //return toUpdateProposedAppointment;     
    }
    
    public static list<Proposed_Appointment__c> syncAppointments(string appointmentType,string stringDate,list<string> tokenSessionId){
        stringDate = stringDate.split(' ')[0];
        AppointmentData objAppointmentData = new AppointmentData();
        if(tokenSessionId == null){
            tokenSessionId = integrationUserloginHandler();
        }
        if(tokenSessionId != null && tokenSessionId.size() > 1){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/appointment/proposed?from-date='+stringDate+'&appointment-type='+appointmentType+'&payer-type='+CommonUtility.objMeddBaseSettings.Booking_Payer_Type__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&token='+tokenSessionId.get(0));
            req.setMethod('GET'); 
            req.setHeader('Cookie','ASP.NET_SessionId='+tokenSessionId.get(1)); 
            req.setTimeout(60000);
            Http http = new Http();
            if(!Test.isRunningTest()){HttpResponse res = http.send(req);if(res.getStatus() == 'OK'){string jsonResult = res.getBody();system.debug('----'+jsonResult);jsonResult = jsonResult.replace('Number','x_Number').replace('Date','x_Date');objAppointmentData = (AppointmentData)JSON.deserialize(jsonResult,AppointmentData.Class);}}            
        }
        if(objAppointmentData !=null && objAppointmentData.result.size() > 0){  return updatePA2NA(date.valueOf(stringDate),appointmentType,objAppointmentData.result);
        } return new list<Proposed_Appointment__c>(); 
    }
    
    public static list<Proposed_Appointment__c> updatePA2NA(Date startDate, string aTypeKey, list<AppointmentData.result> objAD){
        system.debug('>>>>>>>>>>>'+objAD);
        list<Proposed_Appointment__c> toUpdateProposedAppointment = new list<Proposed_Appointment__c>(); 
        list<Proposed_Appointment__c> paList = [Select Start__c,Id,State__c,Clinician__r.Meddbase_Key__c,Clinician__r.Name,Appointment_Type__r.Name From Proposed_Appointment__c 
                                                WHERE State__c <> 'Booked' AND Appointment_Type__r.Meddbase_Key__c = :aTypeKey AND DAY_ONLY(Start__c) =:startDate];
        
        map<string,string> paMap = new map<string,string>();
        for(AppointmentData.result c: objAD){
            paMap.put(getDateTimeByString(c.Start).getTime()+String.valueOf(c.Clinician.Key),c.Clinician.FullName +'-----'+getDateTimeByString(c.Start));
        }        
        for(Proposed_Appointment__c p:paList){
            if(paMap.containsKey(p.Start__c.getTime()+String.valueOf(p.Clinician__r.Meddbase_Key__c))){
                Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=p.Id);
                objPA.State__c = ''; 
                toUpdateProposedAppointment.add(objPA);
                continue;
            }else{                                
                Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=p.Id);
                objPA.State__c = 'Not Available'; 
                toUpdateProposedAppointment.add(objPA);
                system.debug(p.Clinician__r.Name+'|||||||||||||===============>'+p.Start__c.addHours(1)+'------'+p.Id); 
            }             
        }
        system.debug('------>>>>'+toUpdateProposedAppointment);
        /*if(toUpdateProposedAppointment.size() > 0){
            update toUpdateProposedAppointment;
        }*/
        return toUpdateProposedAppointment;
        /*system.debug('-----'+paMap);
        system.debug('>>>>>================'+objAD);
        system.debug('====='+paList);
        system.debug('=====>>>'+objAD);
        for(AppointmentData.result c: objAD){ 
            for(Proposed_Appointment__c pa:paList){
                if(pa.Start__c.getTime() == getDateTimeByString(c.Start).getTime()){
                    
                }
            }
        }
        for(Proposed_Appointment__c pa:paList){ 
            Integer index = 0;
            for(AppointmentData.result c: objAD){                                                
                if(pa.Start__c.getTime() == getDateTimeByString(c.Start).getTime()){ 
                    system.debug(pa.Start__c+'-----------'+getDateTimeByString(c.Start));
                    index += 1;
                    Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=pa.Id);
                    objPA.State__c = ''; 
                    toUpdateProposedAppointment.add(objPA); 
                    break;                    
                }
            } 
            system.debug(pa.Id+'-->>>>---------'+index);                      
            if(index == 0){
                Proposed_Appointment__c objPA = new Proposed_Appointment__c(Id=pa.Id);
                objPA.State__c = 'Not Available'; 
                toUpdateProposedAppointment.add(objPA);       
            }          
        }*/        
    }     
    public static DateTime getDateTimeByString(string datetimestr){
        if(datetimestr != null && datetimestr != ''){
            return DateTime.valueOf(datetimestr.replace('T',' '));  }  return null;
    }
}