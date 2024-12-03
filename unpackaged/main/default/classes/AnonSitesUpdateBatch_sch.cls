global class AnonSitesUpdateBatch_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new AnonSitesUpdateBatch(), 1);
    }   
}