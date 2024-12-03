/**
 * Created 13.12.2021..
 *
 * Remove (delete) Service Appointmetns that have been scheduled for Treatments (Online Orders) that have not been paid
 */

@IsTest public with sharing class ClearServiceAppointmentsSchedulableTest {


    @TestSetup
    static void dataSetup() {
    }

    @IsTest
    static void scheduleUnschedule_test() {

        ClearServiceAppointmentsSchedulable.schedule();
        List<CronTrigger> listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'ClearServiceAppointmentsSchedulable%'
        ];
        System.assert(listCronTrigger.size() > 0);

        ClearServiceAppointmentsSchedulable.unschedule();
        listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'ClearServiceAppointmentsSchedulable%'
        ];
        System.assert(listCronTrigger.size() == 0);
        ClearServiceAppointmentsSchedulable.schedule();
        listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'ClearServiceAppointmentsSchedulable%'
        ];
        System.assert(listCronTrigger.size() > 0);
    }

    @IsTest
    static void execute_test() {
        ClearServiceAppointmentsSchedulable clearServiceAppointmentsSchedulable = new ClearServiceAppointmentsSchedulable();
        clearServiceAppointmentsSchedulable.execute(null);
    }

}