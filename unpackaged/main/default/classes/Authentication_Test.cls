@isTest 
Private Class Authentication_Test{
    Private Static TestMethod Void myUnitTest(){
        
        Authentication.Configuration objWrpConfr = new Authentication.Configuration();
            objWrpConfr.OnlinePaymentsEnabled = true;
            objWrpConfr.WellpointEnabled = true;
            
        Authentication.Patient objWrpPatient = new Authentication.Patient();
            objWrpPatient.CanViewMedicalHistory = true; 
            objWrpPatient.CanPayInvoice = true;
            objWrpPatient.CanManageQuestionnaires = true;
            objWrpPatient.CanViewInvoices = true;
            objWrpPatient.CanManageFeeds = true;
            objWrpPatient.CanCancelAppointment = true;
            objWrpPatient.CanViewCompanyLibrary = true;
            objWrpPatient.CanViewAppointments = true;
            objWrpPatient.CanBookAppointment = true;
        
        Authentication.User objWrpUser = new Authentication.User();
            objWrpUser.CanViewReferrals = true;
            objWrpUser.CanManageUsers = true;
            objWrpUser.CanViewReferralReports = true;
            objWrpUser.CanViewDocument = true;
            objWrpUser.CanViewAppointment = true;
            objWrpUser.CanViewRecall = true; 
            objWrpUser.CanManageQuestionnaires = true;
            objWrpUser.CanBulkReallocateReferrals = true;
            objWrpUser.CanReferPatient = true;
        
        Authentication.Permissions objWrpPermsn = new Authentication.Permissions();
            objWrpPermsn.Patient = objWrpPatient ;
            objWrpPermsn.User = objWrpUser ; 
         
        Authentication.Config objWrpConfig = new Authentication.Config();
            objWrpConfig.Permissions = objWrpPermsn ;
            objWrpConfig.CompanyWebLink = 'testLink';
            objWrpConfig.Phone = '99999999999';
            objWrpConfig.ForceContactOptions = true;
            objWrpConfig.CompanyName = 'TestCompName';
            objWrpConfig.ForceTermsAndConditions = true;
            objWrpConfig.Token = '0010';
            objWrpConfig.Configuration = objWrpConfr;
            objWrpConfig.IsLoggedIn = true;
        
        Authentication.result objWrpResult = new Authentication.result();
            objWrpResult.Config = objWrpConfig ;
            objWrpResult.Token = '00202';
            objWrpResult.SessionID = '0001';
            
        Authentication objClsAuth = new Authentication();
            objClsAuth.result = objWrpResult ;
            objClsAuth.status = 'Confirmed';
    }
}