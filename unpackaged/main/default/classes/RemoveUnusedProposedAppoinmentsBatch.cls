global class RemoveUnusedProposedAppoinmentsBatch implements Database.Batchable<sObject>{     
    global Database.QueryLocator start(Database.BatchableContext BC){        
        return Database.getQueryLocator([select id,State__c from Proposed_Appointment__c WHERE State__c = 'Not Available']);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){  
        delete scope;
        Database.emptyRecycleBin(scope);
    }

    global void finish(Database.BatchableContext BC){
    }
}