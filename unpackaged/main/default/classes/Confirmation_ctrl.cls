public with sharing class Confirmation_ctrl {
    public Proposed_Appointment__c bookedAppointment{get;set;}
    public Confirmation_ctrl(){
        bookedAppointment = [Select Name,Patient__r.LastName,Patient__r.FirstName,Patient__r.PersonMobilePhone,Patient__r.Name, Patient__r.PersonEmail,Start__c,Finish__c, Site__r.PostCode__c, 
                        Site__r.County__c, Site__r.Country__c, Site__r.City__c,Site__r.Phone_Number__c, Site__r.Address_1__c, Site__r.Address_2__c,Clinician__r.Name, 
                        Appointment_Type__r.Name, (Select NetPrice__c,GrossPrice__c From Appointment_Modules__r) 
                        From Proposed_Appointment__c WHERE Id=:Apexpages.currentpage().getparameters().get('paId') limit 1];             
    }
}