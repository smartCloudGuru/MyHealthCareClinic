/**
 * Created 8.4.2024..
 */

global class SembleTokenSchedulable implements Schedulable, Database.AllowsCallouts {

    public static String jobName = 'Token | Semble';

    public static void schedule() {
        String cronStr = '0 8 * * * ?';
        System.schedule(jobName + ' at 8', cronStr, new SembleTokenSchedulable());
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
        scheduleRetrieveToken_F();
    }

    @Future(Callout=true)
    public static void scheduleRetrieveToken_F() {
        scheduleRetrieveToken();
    }

    public static void scheduleRetrieveToken() {
        try {
            String ret = HeyDocService.authenticate_raw();

            System.debug(LoggingLevel.ERROR, 'ret:' + ret);

            if (String.isNotEmpty(ret)) {
                Integration_Token__c token = new Integration_Token__c();
                token.Name = 'SEMBLE';
                token.External_System__c = 'SEMBLE';
                token.Token__c = ret;
                token.Expires__c = Datetime.now().addHours(10);
                upsert token External_System__c;
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
    }
}