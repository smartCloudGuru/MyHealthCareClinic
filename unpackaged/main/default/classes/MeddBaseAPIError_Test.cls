@isTest
Private Class MeddBaseAPIError_Test{
    Private Static TestMethod Void myUnitTest(){
        
        MeddBaseAPIError.error objWrpError = new MeddBaseAPIError.error();
            objWrpError.StatusCode = 0001;
            objWrpError.EventType = 0002;
            objWrpError.EventCode = 0003;
            objWrpError.Message = 'test message';
            
        MeddBaseAPIError objCls = new MeddBaseAPIError();
            objCls.error = objWrpError ;
            objCls.status = 'confirmed';
        
    }
}