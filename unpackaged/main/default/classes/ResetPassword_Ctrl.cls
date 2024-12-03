public with sharing class ResetPassword_Ctrl {
    public String meddbasekey{get;set;} 
    public ResetPassword_Ctrl(){
          meddbasekey = ApexPages.currentPage().getParameters().get('key'); 
    }
    @RemoteAction
    public static Account init(String email){
        return [SELECT Id, LastName, FirstName, Date_of_Birth__c, PersonEmail, PersonMailingPostalCode 
               FROM Account WHERE PersonEmail=:email limit 1];
    }
     
    @RemoteAction
    public static string resetPassword(string fname, string lname, string dob,string key, string postcode, string newpassword){
       return resetpasswordHandler(fname, lname, dob, key, postcode, newpassword);       
    } 
    
    @RemoteAction
    public static string genratePassword(string email, string fname, string lname, string dob){
        return genratePasswordHandler(email, fname, lname, dob);
    } 
    
    private static string genratePasswordHandler(string email, string fname, string lname, string dob){
        try{
            String strDob = String.ValueOf(Date.parse(dob)).split(' ')[0];
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/send-password-reset-email?email='+EncodingUtil.urlEncode(email.trim(), 'UTF-8')+'&name='+EncodingUtil.urlEncode(fname.trim(), 'UTF-8')+'&surname='+EncodingUtil.urlEncode(lname.trim(), 'UTF-8')+'&date-of-birth='+strDob.trim()+'&is-oh='+CommonUtility.objMeddBaseSettings.IS_OH__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c);
            req.setMethod('GET'); 
            req.setTimeout(60000);
            Http http = new Http();
            if(!Test.isRunningTest()){HttpResponse res = http.send(req);return res.getBody();}
            return 'success';
        }catch(Exception e){
            return 'failed';
        }
    }

    private  static string resetpasswordHandler(string fname, string lname, string dob, string key, string postcode,string newpassword){
        try{
            String strDob = String.ValueOf(Date.parse(dob)).split(' ')[0]; 
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CommonUtility.objMeddBaseSettings.Endpoint_URL__c+'/patientportalapi/auth/submit-password-reset-email?name='+EncodingUtil.urlEncode(fname.trim(), 'UTF-8')+'&surname='+EncodingUtil.urlEncode(lname.trim(), 'UTF-8')+'&date-of-birth='+strDob.trim()+'&is-oh='+CommonUtility.objMeddBaseSettings.IS_OH__c+'&client-key='+CommonUtility.objMeddBaseSettings.Client_Key__c+'&postcode='+EncodingUtil.urlEncode(postcode.trim(),'UTF-8')+'&new-password='+newpassword+'&Key='+key);
            req.setMethod('GET');
            //req.setHeader('Content-Length', '0'); http://www.yourportal.com/#/confirmemail?key=<key>
            req.setTimeout(60000);
            Http http = new Http();
            if(!Test.isRunningTest()){HttpResponse res = http.send(req);return res.getBody();}
            return 'success';
        }catch(Exception e){
            return 'failed';
        }
    } 
}