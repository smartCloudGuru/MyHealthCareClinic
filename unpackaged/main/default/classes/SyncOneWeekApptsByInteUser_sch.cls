global class SyncOneWeekApptsByInteUser_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new SyncOneWeekApptsByInteUserBatch(), 1);
    }   
}