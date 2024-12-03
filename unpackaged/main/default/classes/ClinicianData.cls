public class ClinicianData{ 
    public list<result> result{get;set;}
    public String status{get;set;}
    public class result{
        public Integer Key{get;set;}
        public Integer SexType{get;set;}
        public String FullName{get;set;}
    }
}