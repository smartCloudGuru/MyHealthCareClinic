global class AnonProposedAppointmentUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{     
    global Database.QueryLocator start(Database.BatchableContext BC){        
        return Database.getQueryLocator([select id, Clinician__r.MeddBase_Key_String__c, Appointment_type__r.Meddbase_Key__c from Clinician_Appoinment_Types__c WHERE Available__c=true]);//Select Tele_Medicine_Option__c, Notes__c, Name, Meddbase_Key__c, Cancellation_Policy__c, Can_Refer_Patient__c, Can_Book_Appointment__c From Appointment_Type__c]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){  
        list<String> tokenSessionId = CommonUtility.objMeddBaseSettings.Meddbase_Token_Session__c.split('_@_');//MeddbaseCalloutUtility.integrationUserloginHandler();
        for(Clinician_Appoinment_Types__c cat : (list<Clinician_Appoinment_Types__c>)scope){            
            AppointmentData fatchATD = MeddbaseCalloutUtility.retriveProposedAppointmentByIntUser(cat.Appointment_type__r.Meddbase_Key__c,cat.Clinician__r.MeddBase_Key_String__c,tokenSessionId);
            if(fatchATD != null && fatchATD.status != 'error'){
                DatabaseUtility.createProposedAppointment(fatchATD);
            }
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}