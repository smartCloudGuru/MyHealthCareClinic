/**
 * Created 1.9.2022..
 */


global class ExternalInvoiceWatchdog2 implements Schedulable, Database.AllowsCallouts {

    public static String jobName = 'Watchdog | Invoice | Check no Id';

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('W-I-CID');

    public static void schedule() {
        for (Integer i = 6; i < 59; i = i + 11) {
            String cronStr = '40 ' + i + ' * * * ?';
            System.schedule(jobName + ' at ' + i, cronStr, new ExternalInvoiceWatchdog2());
        }
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
        try {ExternalSyncInvoice.executeWatchdogCheck2();}catch (Exception e) {logger.addLog(LoggingLevel.ERROR, null, 'unable to do inv executeWatchdogCheck2() ' + e.getMessage(), e.getStackTraceString(), null);}logger.persistLogs();
    }
}