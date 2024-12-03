/**
 * Created 2.3.2023..
 */

public without sharing class emailBookingConfirmationCtrl {

    public ServiceAppointment sa { get; set; }

    public Boolean isMedical { get; set; }
    public Boolean isDental { get; set; }
    public Boolean isVideo { get; set; }
    public Boolean isTelephone { get; set; }
    public Boolean isInclinic { get; set; }

    public String appointmentName { get; set; }

    public String formattedSchedStartTime { get; set; }

    public String emailInstructions { get; set; }
    public String locationEmailInstructions { get; set; }

    public emailBookingConfirmationCtrl() {
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
            this.sa = [
                    SELECT Id,
                            AppointmentNumber,
                            SchedStartTime,
                            SchedEndTime,
                            WorkType.Name,
                            WorkTypeId,
                            Resource_Names__c,
                            Heydoc_Appointment_Id__c,
                            Aerona_Id__c,
                            Video_URL__c,
                            ServiceTerritory.Name,
                            ServiceTerritory.Street,
                            ServiceTerritory.City,
                            ServiceTerritory.PostalCode,
                            ServiceTerritory.State,
                            ServiceTerritory.Confirmation_Email_Instructions__c,
                            Account.FirstName,
                            Account.LastName,
                            Account.Salutation,
                            Opportunity_Product__r.Name,
                            Opportunity_Product__r.Product2.Name,
                            Opportunity_Product__r.Product2.Confirmation_Email_Instructions__c,
                            Opportunity_Product__r.Product2.Store_Subtitle__c,
                            Opportunity_Product__r.Product2.Store_Title__c,
                            Opportunity_Product__r.Product2.Marketing_Name__c
                    FROM ServiceAppointment
                    WHERE Id = :this.recId
            ];

            this.formattedSchedStartTime = sa.SchedStartTime?.format('dd/MM/yyyy \'at\' HH:mm', 'Europe/London');

            this.isMedical = String.isNotBlank(sa.Heydoc_Appointment_Id__c);
            this.isDental = String.isNotBlank(sa.Aerona_Id__c);

            if (sa.Opportunity_Product__r?.Product2?.Confirmation_Email_Instructions__c != null) {
                this.emailInstructions = sa.Opportunity_Product__r?.Product2?.Confirmation_Email_Instructions__c?.replaceAll('\n', '<br/>');
            }
            if (sa.ServiceTerritory?.Confirmation_Email_Instructions__c != null) {
                this.locationEmailInstructions = sa.ServiceTerritory.Confirmation_Email_Instructions__c.replaceAll('\n', '<br/>');
            }
            if (sa.ServiceTerritory?.Street != null) {
                sa.ServiceTerritory.Street = sa.ServiceTerritory.Street.replaceAll('\n', '<br/>');
            }

            List<WorkTypeGroupMember> wtgms = [SELECT Id, WorkTypeGroup.Service_Type__c, WorkTypeGroup.Appointment_Type__c FROM WorkTypeGroupMember WHERE WorkTypeId = :sa.WorkTypeId LIMIT 1];

            isVideo = false;
            isTelephone = false;
            if (!wtgms.isEmpty()) {
                isVideo = wtgms[0].WorkTypeGroup?.Appointment_Type__c == 'VIDEO';
                isTelephone = wtgms[0].WorkTypeGroup?.Appointment_Type__c == 'TELEPHONE';
            }

            isInclinic = !isVideo && !isTelephone;

            //make an appointment name from Product Data
            if (String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Marketing_Name__c)) {
                appointmentName = sa.Opportunity_Product__r?.Product2?.Marketing_Name__c;
            }
            else if (
                    String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Store_Title__c) && String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Store_Subtitle__c)
            ) {
                appointmentName = sa.Opportunity_Product__r?.Product2?.Store_Title__c + ' - ' + sa.Opportunity_Product__r?.Product2?.Store_Subtitle__c;
            }
            else if (
                    String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Store_Title__c)
            ) {
                appointmentName = sa.Opportunity_Product__r?.Product2?.Store_Title__c;
            }
            else {
                appointmentName = sa.Opportunity_Product__r?.Product2?.Name;
            }


        }


    }
}