public class AppointmentBookingResponseDataOk {
    public result result{get;set;}
    public String status{get;set;}
    public class Type{
        public Boolean CanReferPatient{get;set;}
        public Boolean TelemedicineOption{get;set;}
        public Boolean CanBookAppointment{get;set;}
        public String Key{get;set;}
        public String Notes{get;set;}
        public String Name{get;set;}
    }
    public class Site{
        public Integer Key{get;set;}
        public Address Address{get;set;}
        public String Name{get;set;}
    }
    public class result{
        public Clinician Clinician{get;set;}
        public String Finish{get;set;}
        public Site Site{get;set;}
        public String Start{get;set;}
        public Boolean Telemedicine{get;set;}
        public Type Type{get;set;}
        public String TelemedicineConnection{get;set;}
        public String StateColor{get;set;}
        public list<String> Modules{get;set;}
        public String StateDisplayName{get;set;}
        public Invoice Invoice{get;set;}
        public String State{get;set;}
        public Patient Patient{get;set;}
        public String Key{get;set;}
    }
    public class Patient{
        public String Key{get;set;}
        public String EmailAddress{get;set;}
        public String DateOfBirth{get;set;}
        public BillingAddress BillingAddress{get;set;}
        public Integer SexType{get;set;}
        public String EmployeeNumber{get;set;}
        public String Surname{get;set;}
        public Boolean TermsAndConditionsAccepted{get;set;}
        public String Name{get;set;}
        public Boolean StatisticalProcessingAccepted{get;set;}
        public String Title{get;set;}
    }
    public class Items{
        public String Code{get;set;}
        public String CurrencyCode{get;set;}
        public Decimal NetPrice{get;set;}
        public String Name{get;set;}
        public Decimal Tax{get;set;}
        public String TypeName{get;set;}
        public Decimal GrossPrice{get;set;}
        public String Key{get;set;}
    }
    public class Invoice{
        public list<Items> Items{get;set;}
        public Decimal Tax{get;set;}
        public Decimal TotalNet{get;set;}
        public Decimal TotalGross{get;set;}
        public String CurrencyCode{get;set;}
        public Decimal Paid{get;set;}
        public Integer I_Number{get;set;}
        public list<String> CreditNotes{get;set;}
        public String I_Date{get;set;}
        public Debtor Debtor{get;set;}
        public Creditor Creditor{get;set;}
        public Boolean PayableOnline{get;set;}
        public String Key{get;set;}
    }
    public class Debtor{
        public Boolean IsCompany{get;set;}
        public String Name{get;set;}
        public Account Account{get;set;}
        public Address Address{get;set;}
    }
    public class Creditor{
        public String Name{get;set;}
        public Account Account{get;set;}
        public Boolean IsCompany{get;set;}
    }
    public class Clinician{
        public Integer SexType{get;set;}
        public Integer Key{get;set;}
        public String FullName{get;set;}
    }
    public class Address{
        public String Country{get;set;}
        public String City{get;set;}
        public String County{get;set;}
        public String Address3{get;set;}
        public String PostCode{get;set;}
        public String Address2{get;set;}
        public String Address1{get;set;}
    }
    public class Account{
        public String Name{get;set;}
        public String DateOfBirth{get;set;}
        public String EmailAddress{get;set;}
        public Integer SexType{get;set;}
        public BillingAddress BillingAddress{get;set;}
        public String Surname{get;set;}
        public String EmployeeNumber{get;set;}
        public Boolean TermsAndConditionsAccepted{get;set;}
        public String Title{get;set;}
        public Boolean StatisticalProcessingAccepted{get;set;}
        public String Key{get;set;}
    }
    public class BillingAddress{
    
    }
}