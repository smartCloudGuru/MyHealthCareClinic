/**
 * Created by Atlas on 3.02.2021.
 */

global class AeronaPatient2 {

    global class RetrieveResponse {
        public String status;
        public Result result;
    }

    global class AeronaPracticeList{
            public string key;
            public string value;
    }

    global class Result {

      //  public String recordType;
      //  public String practiceId;
        public String patientTypeId;
      //  public String sourceId;
      //  public String referrerId;
        public String insRefNumber;
        public String insRefNumber2;
        public String genderId;
        public String titleId;
        public String forename;
        public String surname;
       // public String maidenName;
        public String occupation;
        public String dob;
      //  public String knownAs;
        public String address1;
        public String address2;
        public String address3;
        public String address4;
        public String code;
        public String emailAddress;
        public String mobileNumber;
        public String homeNumber;
        //public String workNumber;
        //public String faxNumber;
        public String allowText;
        public String allowEmail;
        public String allowPrint;
        public String userId;
        public String statusId;
        public String insExpiry1;
        public String insExpiry2;
        public String policyNo;
    }

    global class Patient {

        public string patientId { get; set; }
        public string practiceId { get; set; }
        public string patientTypeId { get; set; }
        public string genderId { get; set; }
        public string gender { get; set; }
        public string statusId { get; set; }
        public string statusName { get; set; }
        public string insRefNumber { get; set; }
        public string insRefNumber2 { get; set; }
        public string siteName { get; set; }
        public string patientType { get; set; }
        public string forename { get; set; }
        public String dob;
        public string surname { get; set; }
        public string maidenName { get; set; }
        public string occupation { get; set; }
        public string address1 { get; set; }
        public string address2 { get; set; }
        public string address3 { get; set; }
        public string address4 { get; set; }
        public string code { get; set; }
        public string emailAddress { get; set; }
        public string mobileNumber { get; set; }
        public string homeNumber { get; set; }
        public String allowPrint;
       // public string worknumber { get; set; }
        public string allowText { get; set; }
        public string allowEmail { get; set; }
        public string insExpiry1 { get; set; }
        public string insExpiry2 { get; set; }


        public Patient(String patientTypeId, String genderId, String statusId) {

            switch on patientTypeId {
                when '1' {
                    this.patientType = 'Private';
                }
                when '3' {
                    this.patientType = 'GMS';
                }
                when '5' {
                    this.patientType = 'PRSI';
                }
                when '7' {
                    this.patientType = 'NHS';
                }
                when '8' {
                    this.patientType = 'DenPlan';
                }
            }

            if (genderId == '1') {
                this.gender = 'Male';
            } else {
                this.gender = 'Female';
            }

            switch on statusId {
                when '1' {
                    this.statusName = 'Active';
                }
                when '3' {
                    this.statusName = 'Inactive';
                }
                when '5' {
                    this.statusName = 'Deceased';
                }
                when '7' {
                    this.statusName = 'Lead';
                }
            }


        }
    }
}