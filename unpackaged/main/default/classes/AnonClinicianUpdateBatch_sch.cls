global class AnonClinicianUpdateBatch_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new AnonClinicianUpdateBatch(), 1);
    }   
}