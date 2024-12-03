@isTest
Private Class PatientResponseData_Test{
    Private Static TestMethod Void myUnitTest(){
        
        PatientResponseData.result objWrpResult = new PatientResponseData.result();
            objWrpResult.ActivationType = 0009;
        
        PatientResponseData.PatientResponOk objWrpPatientROK = new PatientResponseData.PatientResponOk();
            objWrpPatientROK.result = objWrpResult ;
            objWrpPatientROK.status = 'Confirmed';
        
        PatientResponseData.error objWrpError = new PatientResponseData.error();
            objWrpError.StatusCode = 001;
            objWrpError.EventType = 002;
            objWrpError.EventCode = 003;
            objWrpError.Message = 'Test message';
        
        PatientResponseData.PatientResponError objWrpPatientRErr = new PatientResponseData.PatientResponError();
            objWrpPatientRErr.error = objWrpError ;
            objWrpPatientRErr.status = 'confirmed';
            
        PatientResponseData objCls = new PatientResponseData();
            objCls.status = 'confirmed';
            objCls.PatientResponOk = objWrpPatientROK;
            objCls.PatientResponError  = objWrpPatientRErr;
            
    }
}