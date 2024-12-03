/**
 * Created by Matija on 20.6.2023..
 */
global class RetrieveInvoicesSchedulable implements Schedulable, Database.AllowsCallouts {

    public static String jobName = 'Invoices | Retrieve';

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('S-Inv_Retrieve');

    public static void schedule() {
        String cronStr = '45 20 * * * ?';
        System.schedule(jobName, cronStr, new RetrieveInvoicesSchedulable());
    }

    public static void unschedule() {

        List<CronTrigger> listCronTrigger = geCurrentTriggers();
        System.debug('No of jobs: ' + listCronTrigger.size());

        if (listCronTrigger.size() > 0) {
            for (Integer i = 0; i < listCronTrigger.size(); i++) {
                System.abortJob(listCronTrigger[i].Id);
            }
        }
    }

    public static List<CronTrigger> geCurrentTriggers() {
        String jobsName = jobName + '%';

        List<CronTrigger> listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE (State = 'WAITING' OR State = 'EXECUTING') AND CronJobDetail.Name LIKE :jobsName
        ];
        return listCronTrigger;
    }

    global void execute(SchedulableContext ctx) {
        try { ExternalRetrieveInvoices.scheduleGetInvoices();}
        catch (Exception e) { logger.addLog(LoggingLevel.ERROR, null, 'unable to do scheduleGetInvoices() ' + e.getMessage(), e.getStackTraceString(), null);}
        logger.persistLogs();
    }

}