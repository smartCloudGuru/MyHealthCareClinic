/**
 * Created by Matija on 8.2.2024..
 */

global class ExternalSyncDocumentsSchedulable implements Schedulable, Database.AllowsCallouts {

    public static String jobName = 'Sync | Documents';
    public static String logName = 'S-Doc';

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter(logName);

    public static void schedule() {
        for (Integer i = 9; i <= 59; i = i + 8) {
            String cronStr = '0 ' + i + ' * * * ?';
            System.schedule(jobName + ' at ' + i, cronStr, new ExternalSyncDocumentsSchedulable());
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
                SELECT Id,
                        CronExpression,
                        EndTime,
                        NextFireTime,
                        OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE (State = 'WAITING' OR State = 'EXECUTING') AND CronJobDetail.Name LIKE :jobsName
        ];
        return listCronTrigger;
    }

    global void execute(SchedulableContext ctx) {
        try { ExternalSyncDocuments.scheduleSyncDocuments();}
        catch (Exception e) { logger.addLog(LoggingLevel.ERROR, null, 'unable to do syncDocuments() ' + e.getMessage(), e.getStackTraceString(), null);}
        logger.persistLogs();
    }
}