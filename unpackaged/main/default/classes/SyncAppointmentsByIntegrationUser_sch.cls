global class SyncAppointmentsByIntegrationUser_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new SyncAppointmentsByIntegrationUserBatch(), 1);
    }   
}