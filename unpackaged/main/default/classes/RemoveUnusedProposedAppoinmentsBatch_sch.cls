global class RemoveUnusedProposedAppoinmentsBatch_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new RemoveUnusedProposedAppoinmentsBatch(), 1);
    }   
}