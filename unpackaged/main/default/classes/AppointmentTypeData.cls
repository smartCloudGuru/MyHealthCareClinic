public class AppointmentTypeData{
	public list<result> result{get;set;}
	public String status{get;set;}
	public class result{
		public String Notes{get;set;}
		public Boolean CanBookAppointment{get;set;}
		public String CancellationPolicy{get;set;}
		public Boolean CanReferPatient{get;set;}
		public String Key{get;set;}
		public Boolean TelemedicineOption{get;set;}
		public String Name{get;set;}
	}
}