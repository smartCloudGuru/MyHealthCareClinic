global class AnonAppointmentTypesUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id FROM User WHERE IsActive=true limit 1]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for(User s : (list<User>)scope){
            AppointmentTypeData fatchATD = MeddbaseCalloutUtility.getAnonAppointmentTypes();
            DatabaseUtility.createApointmentType(fatchATD); 
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}