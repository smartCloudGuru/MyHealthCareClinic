/**
 * Created 4.4.2024..
 */

public without sharing class emailTLPCtrl {
    public Booking_Detail__c bd { get; set; }

    public Boolean isVideo { get; set; }
    public Boolean isTelephone { get; set; }
    public Boolean isInclinic { get; set; }

    public String appointmentName { get; set; }

    public String formattedSchedStartTime { get; set; }
    public String formattedOldSchedStartTime { get; set; }

    public SubmitRequest originalRequest { get; set; }

    public emailTLPCtrl() {
        setAllItems();
    }

    public Id recId {
        get;
        set {
            this.recId = value;
            setAllItems();
        }
    }

    public void setAllItems() {
        if (this.recId != null) {
            this.bd = [
                    SELECT Id,
                            Scheduled_Start__c,
                            Work_Type_Group__c,
                            Work_Type_Group__r.Name,
                            Work_Type_Group__r.Appointment_Type__c,
                            Service_Resource__r.Name,
                            External_Booking_Id__c,
                            External_Patient_Id__c,
                            Cancelled__c,
                            UUID__c,
                            Request__c,
                            Cancellation_URL__c,
                            Reschedule_URL__c,
                            Video_URL__c,
                            Team__c,
                            Patient_First_Name__c,
                            Patient_Last_Name__c,
                            Patient_Email__c,
                            Patient_Reference__c,
                            Appointment_Reference__c
                    FROM Booking_Detail__c
                    WHERE Id = :this.recId
            ];

            this.formattedSchedStartTime = bd.Scheduled_Start__c?.format('dd/MM/yyyy \'at\' HH:mm', 'Europe/London');

            this.appointmentName = bd.Work_Type_Group__r.Name;

            isVideo = false;
            isTelephone = false;
            isVideo = bd.Work_Type_Group__r?.Appointment_Type__c == 'VIDEO';
            isTelephone = bd.Work_Type_Group__r?.Appointment_Type__c == 'TELEPHONE';

            isInclinic = !isVideo && !isTelephone;

            this.originalRequest = (SubmitRequest) JSON.deserialize(this.bd.Request__c, SubmitRequest.class);
            this.originalRequest.dateOfBirth = this.originalRequest.dob_d + '/' + this.originalRequest.dob_m + '/' + this.originalRequest.dob_y;

            this.formattedOldSchedStartTime = this.originalRequest.timeSelected?.format('dd/MM/yyyy \'at\' HH:mm', 'Europe/London');

            if (bd.Team__c == '1') bd.Team__c = 'Self-Pay Team';
            else if (bd.Team__c == '2') bd.Team__c = 'Insurance Team';
        }

    }

    public class SubmitRequest {
        public String addons { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String dob_d { get; set; }
        public String dob_m { get; set; }
        public String dob_y { get; set; }
        public String gender { get; set; }
        public String email { get; set; }
        public String phone { get; set; }
        public String postalCode { get; set; }
        public String city { get; set; }
        public String address1 { get; set; }
        public String address2 { get; set; }
        public String address3 { get; set; }
        public String county { get; set; }
        public String notes { get; set; }
        public String selectedDate { get; set; }
        public Datetime timeSelected { get; set; }
        public Datetime timeSelectedEnd { get; set; }

        public String dateOfBirth { get; set; }

        public Date getDOB() {
            return Date.newInstance(Integer.valueOf(dob_y), Integer.valueOf(dob_m), Integer.valueOf(dob_d));
        }

    }
}