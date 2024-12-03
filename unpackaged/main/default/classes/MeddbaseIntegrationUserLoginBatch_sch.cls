global class MeddbaseIntegrationUserLoginBatch_sch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchJobId = Database.executeBatch(new MeddbaseIntegrationUserLoginBatch(),1);  
    }   
}