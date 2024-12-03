/**
 * Created by Matija on 28.9.2023..
 *
 * Performs general data cleanup for reporting purposes
 */

global class ExcludeFromReportingSchedulable implements Schedulable {

    public static String jobName = 'Cleaner | Exclude From Reporting';

    public static Integer days = 3;

    public static void schedule() {
        for (Integer i = 10; i < 59; i = i + 60) {
            String cronStr = '50 ' + i + ' * * * ?';
            try {
                System.schedule(jobName, cronStr, new ExcludeFromReportingSchedulable());
            }
            catch (Exception ignore) {
            }
        }
    }

    public static void unschedule() {

        String jobsName = jobName + '%';

        List<CronTrigger> listCronTrigger = [
                SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId,
                        PreviousFireTime, StartTime, State, TimesTriggered, TimeZoneSidKey, CronJobDetail.Name
                FROM CronTrigger
                WHERE (State = 'WAITING' OR State = 'EXECUTING') AND CronJobDetail.Name LIKE :jobsName
        ];
        System.debug('No of jobs: ' + listCronTrigger.size());

        if (listCronTrigger.size() > 0) {
            for (Integer i = 0; i < listCronTrigger.size(); i++) {
                System.abortJob(listCronTrigger[i].Id);
            }
        }
    }

    global void execute(SchedulableContext ctx) {

        // 1) find any recent Leads that have converted opportunities where the Accounts do not match
        fixMismatchedAccountsOnLeadsAndOpportunities();

        // 2) fix mismatched Reporting Categories on Leads ant their converted opportunities
        fixMismatchedReportingCategories();

        // 3 find candidates to exclude from reporting, where leads or opportunities are duplicated
        findReportingExclusions();

    }

    @TestVisible
    private static void fixMismatchedAccountsOnLeadsAndOpportunities() {
        List<Lead> leads = [
                SELECT Id, Existing_Patient__c, CreatedDate, ConvertedOpportunityId, Mode__c, LeadSource, ConvertedOpportunity.AccountId
                FROM Lead
                WHERE CreatedDate > :Datetime.now().addDays(-1)
                AND ConvertedOpportunityId != NULL
                AND ConvertedOpportunity.AccountId != NULL
        ];

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead lead : leads) {
            if (lead.Existing_Patient__c != lead.ConvertedOpportunity.AccountId) {
                lead.Existing_Patient__c = lead.ConvertedOpportunity.AccountId;
                leadsToUpdate.add(lead);
            }
        }
        System.debug('found mismatched lead accounts: ' + leadsToUpdate.size());
        Database.update(leadsToUpdate, false);

    }

    @TestVisible
    private static void fixMismatchedReportingCategories() {

        List<Lead> mismatchedLeads = [
                SELECT Id, CreatedDate, ConvertedOpportunityId
                FROM Lead
                WHERE Reporting_Category__c LIKE 'New%' AND ConvertedOpportunity.Reporting_Category__c = 'Repeat Booking'
                AND CreatedDate > :Datetime.now().addHours(-2)
                AND CreatedDate < :Datetime.now().addMinutes(-15)
                AND ConvertedOpportunity.IsWon = TRUE
                ORDER BY CreatedDate DESC
        ];

        Set<Id> mismatchedOpIds = new Set<Id>();
        for (Lead lead : mismatchedLeads) {
            mismatchedOpIds.add(lead.ConvertedOpportunityId);
        }
        List<Opportunity> mismatchedOpps = [SELECT Id FROM Opportunity WHERE ID IN :mismatchedOpIds];

        System.debug('found mismatched opps: ' + mismatchedOpps.size());
        Database.update(mismatchedOpps, false);
    }

    @TestVisible
    private static void findReportingExclusions() {
        // Find Opportunities to exclude in last N days
        Datetime fromDT = Datetime.now().addDays(-days);

        // look at ops where mode is online booking and they timed-out
        List<Opportunity> opps = [
                SELECT Id, CreatedDate, AccountId, Business_Unit__c, Exclude_From_Reporting__c, StageName
                FROM Opportunity

                WHERE
                        CreatedDate > :fromDT
                        AND Reason_for_non_conversion__c = 'Timed-out'
                        AND Mode__c = 'Online Booking'
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opportunity : opps) {
            accountIds.add(opportunity.AccountId);
        }

        // get all opportunities for these accounts, on online booking
        // important: sort by created date, accountId, Business Unit
        List<Opportunity> oppsWithWon = [
                SELECT Id, CreatedDate, AccountId, Business_Unit__c, Exclude_From_Reporting__c, StageName
                FROM Opportunity
                WHERE
                        CreatedDate > :fromDT
                        AND
                        (
                                (Reason_for_non_conversion__c = 'Timed-out' AND Mode__c = 'Online Booking')
                                OR
                                (AccountId IN :accountIds AND StageName = 'Closed Won')
                        )

                ORDER BY AccountId, Business_Unit__c, CreatedDate ASC
        ];

        System.debug('Lost Timed-out opps found to process:' + oppsWithWon.size());

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        // go through them all and find those that should be excluded from reporting
        // opp is excluded if it's lost and there are other opportunities later that are for the same Account Id and BU
        if (oppsWithWon.size() > 1) {
            for (Integer i = 0; i < oppsWithWon.size() - 1; i++) {
                if (oppsWithWon[i].StageName == 'Closed Lost') {
                    if (
                            (oppsWithWon[i + 1].AccountId == oppsWithWon[i].AccountId)
                                    &&
                                    (oppsWithWon[i + 1].Business_Unit__c == oppsWithWon[i].Business_Unit__c)
                                    &&
                                    ((oppsWithWon[i + 1].CreatedDate.date() == oppsWithWon[i].CreatedDate.date())
                                            ||
                                            (oppsWithWon[i + 1].CreatedDate.date() == oppsWithWon[i].CreatedDate.date().addDays(1))
                                            ||
                                            (oppsWithWon[i + 1].CreatedDate.date() == oppsWithWon[i].CreatedDate.date().addDays(2))
                                    )
                    ) {
                        if (oppsWithWon[i].Exclude_From_Reporting__c == false) {
                            oppsWithWon[i].Exclude_From_Reporting__c = true;
                            oppsToUpdate.add(oppsWithWon[i]);
                        }
                    }
                }
            }
        }


        System.debug('Ops to mark as Excluded:' + oppsToUpdate.size());

        if (oppsToUpdate.size() > 0) Database.update(oppsToUpdate, false);

        // Now also exclude leads whose opportunity is excluded
        List<Lead> lds = [
                SELECT Id, Mode__c, LeadSource, ConvertedOpportunity.Exclude_From_Reporting__c, Exclude_From_Reporting__c
                FROM Lead
                WHERE
                        CreatedDate > :fromDT
                        AND ConvertedOpportunity.Exclude_From_Reporting__c = TRUE
                        AND Exclude_From_Reporting__c = FALSE
        ];

        for (Lead lead : lds) {
            lead.Exclude_From_Reporting__c = TRUE;
        }

        System.debug('Leads to mark as Excluded:' + lds.size());

        if (lds.size() > 0) Database.update(lds, false);

        // now remove online non-unique leads and opportunities lost on Online Store

        List<Opportunity> oppos = [
                SELECT Id, CreatedDate, Exclude_From_Reporting__c, AccountId
                FROM Opportunity
                WHERE CreatedDate > :Datetime.now().addDays(-1)
                AND Mode__c = 'Online Booking'
                AND Exclude_From_Reporting__c = FALSE
                AND IsWon = FALSE
                ORDER BY CreatedDate DESC
        ];

        //group them by account
        Map<String, List<Opportunity>> map_acc_opp = new Map<String, List<Opportunity>>();

        for (Opportunity opportunity : oppos) {
            if (map_acc_opp.get(opportunity.AccountId) == null) {
                map_acc_opp.put(opportunity.AccountId, new List<Opportunity>());
            }

            map_acc_opp.get(opportunity.AccountId).add(opportunity);
        }

        List<Opportunity> excludeOpps = new List<Opportunity>();
        Set<String> oppIdsToExclude = new Set<String>();
        for (String accId : map_acc_opp.keySet()) {
            List<Opportunity> oppsFound = map_acc_opp.get(accId);
            if ((oppsFound != null) && (oppsFound.size() > 1)) {
                for (Integer i = 0; i < oppsFound.size() - 1; i++) {
                    oppsFound[i].Exclude_From_Reporting__c = true;
                    excludeOpps.add(oppsFound[i]);
                    oppIdsToExclude.add(oppsFound[i].Id);
                }
            }
        }


        List<Lead> excludeLeads = [SELECT Id FROM Lead WHERE ConvertedOpportunityId IN :oppIdsToExclude];

        for (Lead lead : excludeLeads) {
            lead.Exclude_From_Reporting__c = true;
        }

        System.debug('to exclude leads:' + excludeLeads.size());
        System.debug('to exclude opps:' + excludeOpps.size());

        Database.update (excludeLeads, false);
        Database.update (excludeOpps, false);
    }

}