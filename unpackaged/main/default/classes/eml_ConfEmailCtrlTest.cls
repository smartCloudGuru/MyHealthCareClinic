/**
 * @author Zoran Zunko
 *
 * @date 5/14/21
 */
@IsTest
public class eml_ConfEmailCtrlTest {
    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<Opportunity> opps = TestDataFactory.createOpportunities(accounts, 1, true);
        List<COVID_Test__c> tests = TestDataFactory.createCovidTests(accounts, 1, true);

        OperatingHours oh = new OperatingHours();
        oh.Name = 'OH Name';
        insert oh;

        ServiceTerritory serviceTerritory = new ServiceTerritory();
        serviceTerritory.OperatingHoursId = oh.Id;
        serviceTerritory.Name = 'test';

        insert serviceTerritory;

        Product2 prod = new Product2();
        prod.Name = 'Test';
        prod.Family = 'Membership_Plan';
        prod.IsActive = true;
        prod.Is_Home_Test__c = true;
        insert prod;

        Product2 prod2 = new Product2();
        prod2.Name = 'Test';
        prod2.Family = 'Membership_Plan';
        prod2.IsActive = true;
        prod2.Requires_scheduling__c = true;
        insert prod2;

        PricebookEntry pbe = new PricebookEntry();
        pbe.UnitPrice = 0;
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.isActive = true;
        insert pbe;

        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.UnitPrice = 0;
        pbe2.Product2Id = prod2.Id;
        pbe2.Pricebook2Id = Test.getStandardPricebookId();
        pbe2.isActive = true;
        insert pbe2;

    }

    @IsTest static void testPageLoad() {
        Opportunity opp = [SELECT Id FROM Opportunity];

        String serviceTerritoyId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;

        opp.Pickup_Location__c = serviceTerritoyId;
        opp.Click_and_Collect__c = true;

        update opp;

        COVID_Test__c test = [
                SELECT Id,
                        Scheduled_Appointment__r.SchedStartTime,
                        Scheduled_Appointment__r.SchedEndTime,
                        Booking_Reference__c,
                        Test_Type__c,
                        Scheduled_Appointment__r.ServiceTerritory.Name,
                        Scheduled_Appointment__r.ServiceTerritory.City,
                        Scheduled_Appointment__r.ServiceTerritory.Street,
                        Scheduled_Appointment__r.ServiceTerritory.PostalCode
                FROM COVID_Test__c
        ];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Is_Home_Test__c = TRUE];


        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.UnitPrice = 0.01;
        oli.PricebookEntryId = pbe.Id;
        oli.Member_Price__c = 0;
        oli.Quantity = 1;
        insert oli;

        test.Opportunity__c = opp.Id;
        update test;

        eml_ConfEmailCtrl.TestWrapper tw = new eml_ConfEmailCtrl.TestWrapper(test);
        System.debug(tw.test.Booking_Reference__c);
        System.assert(String.isNotBlank(tw.test.Booking_Reference__c));
        System.assert(tw.test.Booking_Reference__c.indexOf('MYHCC') == 0);

        eml_ConfEmailCtrl confEmailCtrl = new eml_ConfEmailCtrl();
        confEmailCtrl.recId = opp.Id;


    }

    @IsTest static void testPageLoad_reqScheduling() {
        Opportunity opp = [SELECT Id FROM Opportunity];
        COVID_Test__c test = [
                SELECT Id,
                        Scheduled_Appointment__r.SchedStartTime,
                        Scheduled_Appointment__r.SchedEndTime,
                        Booking_Reference__c,
                        Test_Type__c,
                        Scheduled_Appointment__r.ServiceTerritory.Name,
                        Scheduled_Appointment__r.ServiceTerritory.City,
                        Scheduled_Appointment__r.ServiceTerritory.Street,
                        Scheduled_Appointment__r.ServiceTerritory.PostalCode
                FROM COVID_Test__c
        ];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE];

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.UnitPrice = 0.01;
        oli.PricebookEntryId = pbe.Id;
        oli.Member_Price__c = 0;
        oli.Quantity = 1;
        insert oli;

        test.Opportunity__c = opp.Id;
        update test;

        eml_ConfEmailCtrl.TestWrapper tw = new eml_ConfEmailCtrl.TestWrapper(test);
        System.debug(tw.test.Booking_Reference__c);
        System.assert(String.isNotBlank(tw.test.Booking_Reference__c));
        System.assert(tw.test.Booking_Reference__c.indexOf('MYHCC') == 0);

        eml_ConfEmailCtrl confEmailCtrl = new eml_ConfEmailCtrl();
        confEmailCtrl.recId = opp.Id;
    }

}