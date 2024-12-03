public class AeronaAvailableSlots { 
    public list<result> result{get;set;}
    public String errorResult{get;set;}
    public Integer errorCode{get;set;}
    public String status{get;set;}
    public class result{
        public Decimal slotStartTime{get;set;}
        public String clinicianName{get;set;}
        public Integer clinicianId{get;set;}
    }
}