public class PatientRequestData{
    public String regCode{get;set;}
    public Boolean isOH{get;set;}
    public String client_key{get;set;}
    public demog demog{get;set;}
    public class demog{
        public Address Address{get;set;}
        public String EmailAddress{get;set;}
        public String Password{get;set;}
        public String Surname{get;set;}
        public String DateOfBirth{get;set;}
        public String Name{get;set;}
        public String Mobile{get;set;}
        public String Title{get;set;}
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
}