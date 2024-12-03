public with sharing class AppointmentBookingResponseDataError {
	public error error{get;set;}
	public String status{get;set;}
	public class error{
		public Integer StatusCode{get;set;}
		public Integer EventType{get;set;}
		public Integer EventCode{get;set;}
		public String Message{get;set;}
	}
}