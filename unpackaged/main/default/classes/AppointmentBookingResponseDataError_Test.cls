@isTest
Private class AppointmentBookingResponseDataError_Test{
 private static testMethod void dataErrorTest()
 {
 AppointmentBookingResponseDataError objABRDR = new  AppointmentBookingResponseDataError();
 
 AppointmentBookingResponseDataError.error objError = new AppointmentBookingResponseDataError.error();
 objError.StatusCode=12365;
 objError.EventType= 36598;
 objError.EventCode= 98566;
 objError.Message='Query';
 objABRDR.error = objError;
 objABRDR.status = 'test';
 }
}