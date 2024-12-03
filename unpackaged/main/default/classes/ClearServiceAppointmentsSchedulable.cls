/**
 * Created 13.12.2021..
 *
 * Remove (delete) Service Appointments that have been scheduled for Treatments (Online Orders) that have not been paid
 */

global class ClearServiceAppointmentsSchedulable implements Schedulable {

    /**
     * Schedules an apex class (`ClearServiceAppointmentsSchedulable`) to execute using system's scheduler class.
     * This method creates scheduled jobs at two points during the hour i.e. at 5 minutes past and 35 minutes past every hour.
     */
    public static void schedule() {
        for (Integer i = 5; i < 59; i = i + 30) {
            String cronStr = '22 ' + i + ' * * * ?';
            try {
                System.schedule('ClearServiceAppointmentsSchedulable at ' + i, cronStr, new ClearServiceAppointmentsSchedulable());
            }
            catch (Exception ignore) {
            }
        }
    }

    public static void unschedule() {
        List<CronTrigger> listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE (State = 'WAITING' OR State = 'EXECUTING') AND CronJobDetail.Name LIKE 'ClearServiceAppointmentsSchedulable%'
        ];
        System.debug('No of jobs: ' + listCronTrigger.size());

        if (listCronTrigger.size() > 0) {
            for (Integer i = 0; i < listCronTrigger.size(); i++) {
                System.abortJob(listCronTrigger[i].Id);
            }
        }
    }

    /**
     * The global execute method handles the closure of Qualification Opportunities for treatments booked online
     * or via mobile application that have not been resolved within 2 hours.
     *
     * @param ctx A context of type SchedulableContext, the information about this scheduled job provided by Salesforce
     *
     * @global
     **/
    global void execute(SchedulableContext ctx) {

        //[2024-04-02] Changing this to close the Qualification Opportunity only after 2 hours
        Datetime dtFromAppointments = Datetime.now().addMinutes(-120);
        List<ServiceAppointment> serviceAppointmentsToCancel = [
                SELECT Id,
                        Opportunity_Product__c,
                        Opportunity_Product__r.Product2Id,
                        Treatment__r.Downgrade_Or_Upgrade_Done__c,
                        Opportunity_Product__r.Product2.Appointment__c
                FROM ServiceAppointment
                WHERE
                        Treatment__c != NULL
                        AND Treatment__r.Downgrade_Or_Upgrade_Done__c = FALSE
                        AND Treatment__r.StageName = 'Qualification'
                        AND Treatment__r.Mode__c IN ('Online Booking', 'Mobile Application')
                        AND CreatedDate <= :dtFromAppointments AND Treatment__r.IsWon = FALSE
                        AND CreatedDate >= 2023-01-01T00:00:00.000Z
                LIMIT 50
        ];

        List<Opportunity> qualificationOnlineBookingOps = [
                SELECT Id
                FROM Opportunity
                WHERE
                        StageName = 'Qualification'
                        AND Mode__c IN ('Online Booking', 'Mobile Application')
                        AND CreatedDate <= :dtFromAppointments
                        AND CreatedDate >= 2023-01-01T00:00:00.000Z
                ORDER BY CreatedDate DESC
                LIMIT 50
        ];

        // mark opportunities as lost
        Set<Id> opIdsToMarkAsLost = new Set<Id>();
        for (Opportunity opportunity : qualificationOnlineBookingOps) {
            opIdsToMarkAsLost.add(opportunity.Id);
        }

        //delete also any OLIs of the affected Appointments
        List<OpportunityLineItem> olisToDelete = new List<OpportunityLineItem>();

        for (ServiceAppointment serviceAppointment : serviceAppointmentsToCancel) {
            if (serviceAppointment.Opportunity_Product__r?.Product2?.Appointment__c == true) olisToDelete.add(new OpportunityLineItem(Id = serviceAppointment.Opportunity_Product__c));
            if (serviceAppointment.Treatment__c != null) opIdsToMarkAsLost.add(serviceAppointment.Treatment__c);
        }

        for (ServiceAppointment serviceAppointment : serviceAppointmentsToCancel) {
            serviceAppointment.Status = 'Canceled';
            serviceAppointment.CancellationReason = 'Not paid/finalized';
        }

        List<Opportunity> opsToMarkAsLost = new List<Opportunity>();
        for (Id opId : opIdsToMarkAsLost) {
            opsToMarkAsLost.add(new Opportunity(Id = opId, StageName = 'Closed Lost', Reason_for_non_conversion__c = 'Timed-out'));
        }

        Database.update(serviceAppointmentsToCancel, false);

        if (olisToDelete.size() > 0) Database.delete(olisToDelete, false);
        if (opsToMarkAsLost.size() > 0) Database.update(opsToMarkAsLost, false);

    }

}