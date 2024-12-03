global class SyncOneWeekApptsByInteUserBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Tele_Medicine_Option__c, Notes__c, Name, Meddbase_Key__c, 
                                        Cancellation_Policy__c, Can_Refer_Patient__c, Can_Book_Appointment__c 
                                        From Appointment_Type__c]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for(Appointment_Type__c s : (list<Appointment_Type__c>)scope){
            for(String d:convertDatetoString()){
                list<String> tokenSessionId = null;
                if(Test.IsRunningTest()){
                    tokenSessionId  = new list<String>{'0fdfnejrfuey8393ujeje_@_dsdsdsd'};
                }
                AppointmentData fatchATD = MeddbaseCalloutUtility.syncTransferedWeeklyAppointments(s.Meddbase_Key__c,d,tokenSessionId);
                if(fatchATD != null && fatchATD.status != 'error'){
                    DatabaseUtility.createProposedAppointment(fatchATD);
                }
            }
        }
    }
    public list<String> convertDatetoString(){ 
        list<String> weekDays = new list<String>();
        for(Integer i=0;i<=7;i++){
            weekDays.add(String.valueOf(system.today().addDays(i)).substring(0,10));
        }
        return weekDays;
    } 

    global void finish(Database.BatchableContext BC){
    }
}