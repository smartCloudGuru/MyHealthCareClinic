global class AnonAppointmentTypesUpdateBatch_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
         Database.executeBatch(new AnonAppointmentTypesUpdateBatch(), 1);
    }   
}