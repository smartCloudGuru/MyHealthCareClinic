global class SyncAppointmentsByIntegrationUserBatch implements Database.Batchable<AggregateResult>,Database.AllowsCallouts{
	global Iterable<AggregateResult> start(Database.batchableContext info){ 
        return new AggregateResultIterable();
    } 

    global void execute(Database.BatchableContext BC, List<Sobject> scope){
        for (Sobject so : scope)  {
          AggregateResult ar = (AggregateResult) so;
          Integer counter = Integer.valueOf(ar.get('expr0'));
          String aType = String.valueOf(ar.get('key'));
          String startDate = String.valueOf(ar.get('st')).substring(0,10);
          system.debug(aType+'---------------------'+startDate);
          try{list<Proposed_Appointment__c> obPA2Sync = MeddbaseCalloutUtility.syncAppointments(aType, startDate,null);if(obPA2Sync.size() > 0) update obPA2Sync;}catch(Exception e){}
        }        
    }

    global void finish(Database.BatchableContext BC){}     
}