public class PatientData{
    public result result{get;set;}
    public String status{get;set;}
    public class result{
        public Address Address{get;set;}
        public String EmployeeNumber{get;set;}
        public String EmailAddress{get;set;}
        public String DateOfBirth{get;set;}
        public Integer SexType{get;set;}
        public String Mobile{get;set;}
        public String Surname{get;set;}
        public list<ContactOptions> ContactOptions{get;set;}
        public String Name{get;set;}
        public Boolean TermsAndConditionsAccepted{get;set;}
        public String Title{get;set;}
        public Boolean StatisticalProcessingAccepted{get;set;}
        public String Key{get;set;}
    }
    public class ContactOptions{
        public String Subject{get;set;}
        public Boolean Email{get;set;}
        public Boolean SMS{get;set;}
        public String Key{get;set;}
    }
    public class Address{
        public String County{get;set;}
        public String City{get;set;}
        public String Address3{get;set;}
        public String PostCode{get;set;}
        public String Address2{get;set;}
        public String Country{get;set;}
        public String Address1{get;set;}
    }
}