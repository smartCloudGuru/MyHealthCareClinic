/**
 * Created by Matija on 28.9.2023..
 */

@IsTest
private class ExcludeFromReportingSchedulableTest {
    @TestSetup
    static void dataSetup() {
    }

    @IsTest
    static void scheduleUnschedule_test() {

        ExcludeFromReportingSchedulable.schedule();
        List<CronTrigger> listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'Cleaner | Exclude %'
        ];
        System.assert(listCronTrigger.size() > 0);

        ExcludeFromReportingSchedulable.unschedule();
        listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'Cleaner | Exclude %'
        ];
        System.assert(listCronTrigger.size() == 0);
        ExcludeFromReportingSchedulable.schedule();
        listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'Cleaner | Exclude %'
        ];
        System.assert(listCronTrigger.size() > 0);
    }

    @IsTest
    static void execute_test() {

        Lead l1 = new Lead();
        Lead l2 = new Lead();
        Lead l3 = new Lead();

        l1.FirstName = 'F1';
        l2.FirstName = 'F2';
        l3.FirstName = 'F3';
        l1.LastName = 'L1';
        l2.LastName = 'L2';
        l3.LastName = 'L3';

        insert l1;
        insert l2;
        insert l3;

        LeadStatus convertStatus = [
                SELECT
                        Id,
                        MasterLabel
                FROM LeadStatus
                WHERE IsConverted = TRUE
                LIMIT 1
        ];


        Database.LeadConvert lc1 = new Database.LeadConvert();
        lc1.setLeadId(l1.Id);
        lc1.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr1 = Database.convertLead(lc1);

        Id o1 = lcr1.opportunityId;
        System.assert(o1 != null);

        Database.LeadConvert lc2 = new Database.LeadConvert();
        lc2.setLeadId(l2.Id);
        lc2.setConvertedStatus(convertStatus.MasterLabel);
        lc2.setAccountId(lcr1.accountId);
        Database.LeadConvertResult lcr2 = Database.convertLead(lc2);

        Id o2 = lcr2.opportunityId;
        System.assert(o2 != null);

        Database.LeadConvert lc3 = new Database.LeadConvert();
        lc3.setLeadId(l3.Id);
        lc3.setConvertedStatus(convertStatus.MasterLabel);
        lc3.setAccountId(lcr1.accountId);
        Database.LeadConvertResult lcr3 = Database.convertLead(lc3);

        Id o3 = lcr3.opportunityId;
        System.assert(o3 != null);

        List<Opportunity> allBookingOps = new List<Opportunity>();
        allBookingOps.add(new Opportunity(Id = o1, StageName = 'Closed Lost', Mode__c = 'Online Booking', Reason_for_non_conversion__c = 'Timed-out', Business_Unit__c = 'GP'));
        allBookingOps.add(new Opportunity(Id = o2, StageName = 'Closed Lost', Mode__c = 'Online Booking', Reason_for_non_conversion__c = 'Timed-out', Business_Unit__c = 'GP'));
        allBookingOps.add(new Opportunity(Id = o3, StageName = 'Closed Won', Mode__c = 'Online Booking', Reason_for_non_conversion__c = 'Timed-out', Business_Unit__c = 'GP'));

        update allBookingOps;

        ExcludeFromReportingSchedulable sch = new ExcludeFromReportingSchedulable();
        sch.execute(null);

        List<Opportunity> excludedOpps = [SELECT Id FROM Opportunity WHERE Exclude_From_Reporting__c = TRUE];
        System.assert(excludedOpps.size()==2);
    }
}