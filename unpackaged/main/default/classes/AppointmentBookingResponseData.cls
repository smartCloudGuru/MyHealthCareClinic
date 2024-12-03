public with sharing class AppointmentBookingResponseData {
    public string status{get;set;} 
    public AppointmentBookingResponseDataError error{get;set;}
    public AppointmentBookingResponseDataOk ok{get;set;}
}