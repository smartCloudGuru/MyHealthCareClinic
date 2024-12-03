global class AnonSitesUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
	global Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator([Select Id FROM User limit 1]);
    }

	global void execute(Database.BatchableContext BC, List<sObject> scope){		
		SitesData fatchSites = MeddbaseCalloutUtility.getAnonSites();
		DatabaseUtility.createSites(fatchSites);
    }

	global void finish(Database.BatchableContext BC){
    }
}