/**
 * Created by Matija on 28.8.2023..
 */

@IsTest
private class LeadTriggerHandlerTest {
    private static void insert2Leads() {

        Lead ld1 = new Lead();
        ld1.FirstName = 'Test1';
        ld1.LastName = 'Test1';
        ld1.Status = 'New';
        ld1.Business_Unit__c = 'GP';
        ld1.Mode__c = 'Call';
        ld1.Email = 'test1@example.com';

        Lead ld2 = new Lead();
        ld2.FirstName = 'Test2';
        ld2.LastName = 'Test2';
        ld2.Status = 'New';
        ld2.Business_Unit__c = 'Implants';
        ld2.Mode__c = 'Call';
        ld2.Email = 'test2@example.com';

        List<Lead> leads = new List<Lead>();
        leads.add(ld1);
        leads.add(ld2);

        insert leads;
    }

    private static void insert1Lead() {

        Lead ld1 = new Lead();
        ld1.FirstName = 'Test1';
        ld1.LastName = 'Test1';
        ld1.Status = 'New';
        ld1.Business_Unit__c = 'Implants';
        ld1.Mode__c = 'Call';
        ld1.Email = 'test1@example.com';

        insert ld1;
    }

    @IsTest
    private static void test_01_lead_new() {

        insert2Leads();

        //leads should be reporting category "new patients"
        List<Lead> leads = [SELECT Id, Name, Email, Reporting_Category__c FROM Lead ORDER BY Email];

        LeadStatus convertStatus = [
                SELECT
                        Id,
                        MasterLabel
                FROM LeadStatus
                WHERE IsConverted = TRUE
                LIMIT 1
        ];

        List<Id> lcraids = new List<Id>();
        for (Lead leadObj : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadObj.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.debug('lcraid:' +  lcr.accountId);
            lcraids.add(lcr.accountId);
        }

        List<Patient_Business_Unit__c> pbus = [
                SELECT
                        Id,
                        Account__c,
                        Composite_Key__c,
                        Business_Unit__c,
                        First_Opportunity__c,
                        Latest_Opportunity__c,
                        First_Historical_Record__c,
                        Latest_Historical_Record__c,
                        First_Lead__c,
                        Latest_Lead__c,
                        Won__c
                FROM Patient_Business_Unit__c
                WHERE Account__c in :lcraids
        ];

        System.debug(JSON.serialize(pbus));

        System.assert(pbus.size() == 2);

    }

    @IsTest
    private static void test_02_lead1_existingAccount() {

        Account acc = new Account();
        acc.PersonEmail = 'test1@example.com';
        acc.FirstName = 'fname';
        acc.LastName = 'lname';

        insert acc;

        insert2Leads();

        //leads should be reporting category "new patients"
        List<Lead> leads = [SELECT Id, Name, Email, Reporting_Category__c FROM Lead ORDER BY Email];
        for (Lead lead : leads) {
            System.debug(lead.Reporting_Category__c);
        }
        System.assert(leads[0].Reporting_Category__c == 'New Patient');
        System.assert(leads[1].Reporting_Category__c == 'New Patient');
    }


    @IsTest
    private static void test_03_lead1_repeatBooking() {

        Account acc = new Account();
        acc.PersonEmail = 'test1@example.com';
        acc.FirstName = 'fname';
        acc.LastName = 'lname';

        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'soemname';
        opp.AccountId = acc.Id;
        opp.Business_Unit__c = 'Implants';
        opp.StageName = 'Qualification';
        opp.CloseDate = Date.today().addDays(-1);

        insert opp;

        opp.StageName = 'Closed Won';

        update opp;

        insert1Lead();

        //leads should be reporting category "new patients"
        List<Lead> leads = [SELECT Id, Name, Email, Reporting_Category__c FROM Lead ORDER BY Email];
        for (Lead lead : leads) {
            System.debug('test result lead category: ' + lead.Reporting_Category__c);
        }
        System.assert(leads[0].Reporting_Category__c == 'Repeat Booking');
    }

}