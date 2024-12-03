public class AeronaPatient{
    public list<result> result{get;set;}
    public String errorResult{get;set;}
    public Integer errorCode{get;set;}
    public String status{get;set;}
    public class result{
        public Decimal dob{get;set;}
        public String patientFullAddress{get;set;}
        public String patientFullName{get;set;}
        public Integer patientId{get;set;}
    }
}