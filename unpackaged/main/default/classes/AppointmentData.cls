public with sharing class AppointmentData{
    public list<result> result{get;set;}
    public String status{get;set;}
    public class Type{ 
        public String Notes{get;set;} 
        public String Key{get;set;} 
        public String Name{get;set;} 
        public Boolean CanBookAppointment{get;set;}  
        public Boolean CanReferPatient{get;set;} 
        public Boolean TelemedicineOption{get;set;}
    }
    public class Slots{
        public Type Type{get;set;}
        public Site Site{get;set;}
        public String Finish{get;set;}
        public Integer ResourceKey{get;set;}
        public String Start{get;set;}
    }
    public class Site{
        public Integer Key{get;set;} 
        public Address Address{get;set;}
        public String Name{get;set;} 
    }
    public class result{
    	public Invoice Invoice{get;set;}
        public list<Modules> Modules{get;set;}
        public Clinician Clinician{get;set;}
        public Site Site{get;set;}
        public Boolean Telemedicine{get;set;}
        public String Finish{get;set;}
        public list<Slots> Slots{get;set;}
        public String Start{get;set;}
        public PrimaryAttendeeSlot PrimaryAttendeeSlot{get;set;}
        public Type Type{get;set;}
        public String PayerType{get;set;}
        public String Key{get;set;}
    }
    public class PrimaryAttendeeSlot{
        public Type Type{get;set;}
        public Site Site{get;set;}
        public Clinician Clinician{get;set;}
        public String Finish{get;set;}
        public Integer ResourceKey{get;set;}
        public String Start{get;set;}
    }
    public class Modules{
        public Decimal Tax{get;set;}
        public Decimal NetPrice{get;set;}
        public String CurrencyCode{get;set;}
        public Decimal GrossPrice{get;set;}
        public Integer Key{get;set;}
        public String Notes{get;set;}
        public String Name{get;set;}
    }
    public class Clinician{
        public String FullName{get;set;}
        public Integer SexType{get;set;}
        public Integer Key{get;set;}  
    }
    public class Address{
        public String City{get;set;}
        public String County{get;set;}
        public String Address3{get;set;}
        public String PostCode{get;set;}
        public String Address2{get;set;}
        public String Country{get;set;}
        public String Address1{get;set;}
    }
    public class Invoice{
		public Boolean PayableOnline{get;set;}
		public Decimal TotalNet{get;set;}
		public String CurrencyCode{get;set;}
		public Decimal Tax{get;set;}
		public Integer x_Number{get;set;}
		public Decimal TotalGross{get;set;}
		public String x_Date{get;set;}
		public Decimal Paid{get;set;}
		public String Key{get;set;}
	}
}