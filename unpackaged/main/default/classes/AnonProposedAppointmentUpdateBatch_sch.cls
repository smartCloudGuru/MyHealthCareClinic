global class AnonProposedAppointmentUpdateBatch_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new AnonProposedAppointmentUpdateBatch(), 1);
    }   
}