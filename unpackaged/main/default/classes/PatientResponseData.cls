public class PatientResponseData {
	public String status{get;set;}
	public PatientResponOk PatientResponOk{get;set;}
	public PatientResponError PatientResponError {get;set;}
	
	public class PatientResponError{
		public error error{get;set;}
		public String status{get;set;}
	}
	public class error{
		public Integer StatusCode{get;set;}
		public Integer EventType{get;set;}
		public Integer EventCode{get;set;}
		public String Message{get;set;}
	}
	public class PatientResponOk{
		public result result{get;set;}
		public String status{get;set;}
	}
	public class result{
		public Integer ActivationType{get;set;}
	}
}