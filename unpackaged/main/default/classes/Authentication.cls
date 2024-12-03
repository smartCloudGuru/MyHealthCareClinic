public class Authentication{
    public result result{get;set;}
    public String status{get;set;}
    public class User{
        public Boolean CanViewReferrals{get;set;}
        public Boolean CanManageUsers{get;set;}
        public Boolean CanViewReferralReports{get;set;}
        public Boolean CanViewDocument{get;set;}
        public Boolean CanViewAppointment{get;set;}
        public Boolean CanViewRecall{get;set;}
        public Boolean CanManageQuestionnaires{get;set;}
        public Boolean CanBulkReallocateReferrals{get;set;}
        public Boolean CanReferPatient{get;set;}
    }
    public class result{
        public Config Config{get;set;}
        public String Token{get;set;}
        public String SessionID{get;set;}
    }
    public class Permissions{
        public Patient Patient{get;set;}
        public User User{get;set;}
    }
    public class Patient{
        public Boolean CanViewMedicalHistory{get;set;}
        public Boolean CanPayInvoice{get;set;}
        public Boolean CanManageQuestionnaires{get;set;}
        public Boolean CanViewInvoices{get;set;}
        public Boolean CanManageFeeds{get;set;}
        public Boolean CanCancelAppointment{get;set;}
        public Boolean CanViewCompanyLibrary{get;set;}
        public Boolean CanViewAppointments{get;set;}
        public Boolean CanBookAppointment{get;set;}
    }
    public class Configuration{
        public Boolean OnlinePaymentsEnabled{get;set;}
        public Boolean WellpointEnabled{get;set;}
    }
    public class Config{
        public Permissions Permissions{get;set;}
        public String CompanyWebLink{get;set;}
        public String Phone{get;set;}
        public Boolean ForceContactOptions{get;set;}
        public String CompanyName{get;set;}
        public Boolean ForceTermsAndConditions{get;set;}
        public String Token{get;set;}
        public Configuration Configuration{get;set;}
        public Boolean IsLoggedIn{get;set;}
    }
}