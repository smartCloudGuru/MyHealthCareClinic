global class AeronaFindSlots_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchJobId = Database.executeBatch(new AeronaFindSlotsBatch(),1);  
    }   
}