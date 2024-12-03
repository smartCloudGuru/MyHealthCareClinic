global class AeronaFindSlotsBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Site__c,Clinician__c,Aerona_Clinician_key__c,Site__r.Name,Aerona_Site_Key__c,Clinician__r.Name 
                                        FROM Aerona_Site__c 
                                        WHERE Aerona_Clinician_key__c <> null 
                                        AND Aerona_Site_Key__c <> null]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){     
        for(Aerona_Site__c asi : (list<Aerona_Site__c>)scope){
            list<Proposed_Appointment__c> objPAs = [Select id,Clinician__c,Site__c ,Start__c 
                                                    FROM Proposed_Appointment__c 
                                                    WHERE Clinician__c =: asi.Clinician__c
                                                    AND Site__c =: asi.Site__c
                                                    AND Site__c <> null
                                                    AND Clinician__c <> null
                                                    AND Is_Available_On_Aerona__c=true 
                                                    AND Start__c <> null order by Start__c DESC];
            String slotStartDate = String.ValueOf(system.today());
            if(objPAs.size() > 0){
                DateTime startDateTime = objPAs.get(0).Start__c;
                slotStartDate = String.ValueOf(date.newinstance(startDateTime.year(), 
                                                                startDateTime.month(), 
                                                                startDateTime.day()));
            }
            AeronaAvailableSlots objAeronaAvailableSlots = AeronaCalloutUtility.findSlots(Integer.valueOf(asi.Aerona_Site_Key__c),
                                                            Integer.valueOf(asi.Aerona_Clinician_key__c),10319,
                                                            slotStartDate);
            if(objAeronaAvailableSlots.status == 'Success'){
                list<Proposed_Appointment__c> p2Upsert =  DatabaseUtility.createAeronaSlots(objAeronaAvailableSlots,asi.Site__c,asi.Clinician__c); 
                if(p2Upsert != null){
                    update p2Upsert;
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){}
}