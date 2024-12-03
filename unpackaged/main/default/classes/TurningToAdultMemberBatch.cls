global class TurningToAdultMemberBatch implements Database.Batchable<sObject>, Database.Stateful{
    String emailBody;
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id, Name, PersonEmail, Phone, PersonMobilePhone FROM Account Where Turning_18_Year_Old__c = True]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        emailBody = TurningToAdultMemberUtil.prepareEmailBody((list<Account>)scope);
    }

    global void finish(Database.BatchableContext BC){
        TurningToAdultMemberUtil.pushNotification(emailBody);
    }
}