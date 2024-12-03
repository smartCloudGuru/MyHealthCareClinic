/**
 * Created 22.6.2022..
 */


global class ExternalAppointmentsWatchdog implements Schedulable, Database.AllowsCallouts {

    public static String jobName = 'Watchdog | Appointments';

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('W-Apps');

    public static void schedule() {
        for (Integer i = 3; i < 59; i = i + 5) {
            String cronStr = '0 ' + i + ' * * * ?';
            System.schedule(jobName + ' at ' + i, cronStr, new ExternalAppointmentsWatchdog());
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
        try {
            ExternalSyncAppointments.executeWatchdogCheck();
        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to do app executeWatchdogCheck() ' + e.getMessage(), e.getStackTraceString(), null);
        }
    }

}