global class AnonClinicianUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
	global Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator([Select Tele_Medicine_Option__c, Notes__c, Name, Meddbase_Key__c, Cancellation_Policy__c, Can_Refer_Patient__c, Can_Book_Appointment__c From Appointment_Type__c]);
    }

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		for(Appointment_Type__c s : (list<Appointment_Type__c>)scope){
			ClinicianData fatchClinicians = MeddbaseCalloutUtility.getAnonClinicians(s.Meddbase_Key__c);
			DatabaseUtility.createClinicians(fatchClinicians,s.Id);
		}
    }

	global void finish(Database.BatchableContext BC){
    }
}