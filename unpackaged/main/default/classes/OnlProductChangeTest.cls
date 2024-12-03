/**
 * Created 23.2.2022..
 */


@IsTest
global class OnlProductChangeTest {

    @TestSetup
    public static void setUp() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        List<WorkTypeGroup> wtgsToInsert = new List<WorkTypeGroup>();
        for (Integer i = 1; i <= 4; i++) {
            wtgsToInsert.add(new WorkTypeGroup(Name = 'WTG' + i));
        }

        insert wtgsToInsert;

        OperatingHours operatingHours = new OperatingHours(Name = 'OH');
        insert operatingHours;

        ServiceTerritory location1 = new ServiceTerritory(
                Name = 'ST1',
                OperatingHoursId = operatingHours.Id,
                IsActive = true
        );
        insert location1;

        ServiceTerritory location2 = new ServiceTerritory(
                Name = 'ST2',
                OperatingHoursId = operatingHours.Id,
                IsActive = true
        );
        insert location2;


        Asset asset1 = new Asset(Name = 'A1');
        Asset asset2 = new Asset(Name = 'A2');
        insert asset1;
        insert asset2;


        //        ServiceResource sr1 = new ServiceResource();
        //        sr1.Name = 'SR1';
        //        sr1.IsActive = true;
        ////        sr1.ResourceType = 'Asset';
        //        sr1.AssetId = asset1.Id;
        //        insert sr1;
        //
        //        ServiceResource sr2 = new ServiceResource();
        //        sr2.Name = 'SR1';
        //        sr2.IsActive = true;
        ////        sr2.ResourceType = 'Asset';
        //        sr2.AssetId = asset2.Id;
        //        insert sr2;


        //create WTGMembers for WTGS
        List<WorkType> workTypes = new List<WorkType>();
        for (WorkTypeGroup wtg : wtgsToInsert) {
            workTypes.add(new WorkType(
                    Name = 'Type_' + wtg.Name,
                    EstimatedDuration = 10
            ));
        }
        insert workTypes;

        List<WorkTypeGroupMember> wtgms = new List<WorkTypeGroupMember>();
        for (Integer i = 0; i < wtgsToInsert.size(); i++) {
            wtgms.add(new WorkTypeGroupMember(WorkTypeGroupId = wtgsToInsert[i].Id, WorkTypeId = workTypes[i].Id));
        }
        insert wtgms;

        List<ServiceTerritoryWorkType> stwts = new List<ServiceTerritoryWorkType>();
        for (Integer i = 0; i < workTypes.size(); i++) {
            stwts.add(new ServiceTerritoryWorkType(ServiceTerritoryId = location1.Id, WorkTypeId = workTypes[i].Id));
            stwts.add(new ServiceTerritoryWorkType(ServiceTerritoryId = location2.Id, WorkTypeId = workTypes[i].Id));
        }
        insert stwts;


        List<Product2> productsToInsert = new List<Product2>();
        Decimal price = 1;
        for (Integer i = 1; i <= 4; i++) {
            productsToInsert.add(new Product2(Name = 'P' + i, Non_Membership_Price__c = price));
            price++;
        }
        insert productsToInsert;

        // add pricebook entries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        price = 1;
        for (Product2 prod : productsToInsert) {
            pricebookEntries.add(new PricebookEntry(
                    Product2Id = prod.Id,
                    UnitPrice = price,
                    Pricebook2Id = pb.Id,
                    IsActive = true));
            price++;
        }
        insert pricebookEntries;


        List<Default_COVID_Test__c> defaultCOVIDTests = new List<Default_COVID_Test__c>();
        for (Integer i = 0; i < 4; i++) {
            defaultCOVIDTests.add(new Default_COVID_Test__c(
                    Number_of_Tests__c = 1,
                    Work_Type_Group__c = wtgsToInsert[i].Id,
                    First_Available__c = true,
                    Product__c = productsToInsert[i].Id,
                    COVID_Test_Type__c = 'PCR Test',
                    Turnaround_Time__c = 'Next Day'
            ));
        }

        insert defaultCOVIDTests;

    }

    @IsTest
    static void test_doChange_productOnly() {

        List<Account> acc = [SELECT Id FROM Account];
        String priceBookId = [SELECT Id FROM Pricebook2 LIMIT 1].Id;

        Opportunity opp = new Opportunity(
                AccountId = acc[0].Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Pricebook2Id = priceBookId
        );

        List<Product2> products = [SELECT Id, Name, Non_Membership_Price__c FROM Product2 WHERE Name IN ('P1', 'P2', 'P3', 'P4') ORDER BY Name ASC];
        insert opp;

        OpportunityLineItem line = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Product2Id = products[0].Id,
                UnitPrice = products[0].Non_Membership_Price__c
        );

        insert line;

        line = [SELECT Id, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE Id = :line.Id];

        String oldLineNewPricebookEntryId = line.PricebookEntryId;
        System.debug('::old item PricebookEntryId: ' + oldLineNewPricebookEntryId);

        ServiceAppointment appointment = new ServiceAppointment(
                Opportunity_Product__c = line.Id,
                ParentRecordId = acc[0].Id,
                ServiceTerritoryId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id
        );

        insert appointment;
        appointment = [SELECT Id, WorkTypeId FROM ServiceAppointment WHERE Id = :appointment.Id];
        String oldAppointmentWorkTypeId = appointment.WorkTypeId;

        COVID_Test__c ctest = new COVID_Test__c(
                Scheduled_Appointment__c = appointment.Id,
                Opportunity_Product__c = line.Id,
                Opportunity__c = opp.Id,
                Test_Type__c = 'PCR Test',
                Work_Type_Group__c = [SELECT Id FROM WorkTypeGroup WHERE Name = 'WTG1'].Id
        );

        insert ctest;

        ctest = [SELECT Id, Opportunity_Product__c, Test_Type__c, Turnaround_Time__c, Turnaround_Time_Global__c, Work_Type_Group__c, Work_Type_Group__r.Name FROM COVID_Test__c WHERE Id = :ctest.Id];
        System.assert(ctest.Work_Type_Group__r.Name == 'WTG1');


        // DO CHANGE

        // parameters
        OnlProductChange.ChangeRequest changeRequest = new OnlProductChange.ChangeRequest();
        changeRequest.doChangeType = true;
        changeRequest.ctestId = ctest.Id;
        changeRequest.changeToProduct = products[1].Id;

        String ret = OnlProductChange.doChange(JSON.serialize(changeRequest));

        System.debug('::upgrade resp: ' + ret);
        System.assert(ret == null);

        // reload the line after changes
        OpportunityLineItem lineNew = [
                SELECT
                        Id, Product2Id, Sales_Value__c, Quantity, TotalPrice, PricebookEntryId
                FROM OpportunityLineItem
                WHERE OpportunityId = :opp.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        System.debug('::new line item: ' + JSON.serialize(lineNew));
        System.assert(lineNew.PricebookEntryId != oldLineNewPricebookEntryId);

        System.debug('::new line item Product2Id: ' + lineNew.Product2Id);
        System.assert(lineNew.Product2Id == products[1].Id);

        ctest = [SELECT Id, Opportunity_Product__c, Test_Type__c, Turnaround_Time__c, Work_Type_Group__c, Work_Type_Group__r.Name FROM COVID_Test__c WHERE Id = :ctest.Id];
        System.assert(ctest.Opportunity_Product__c == lineNew.Id);
        System.assert(ctest.Work_Type_Group__r.Name == 'WTG2');

        appointment = [SELECT Id, WorkTypeId, WorkType.Name FROM ServiceAppointment WHERE Id = :appointment.Id];
        System.debug('::new appointment: ' + JSON.serialize(appointment));
        System.assert(appointment.WorkTypeId != oldAppointmentWorkTypeId);
    }


    @IsTest
    static void test_doChange_rebookOnly() {

        List<Account> acc = [SELECT Id FROM Account];
        String priceBookId = [SELECT Id FROM Pricebook2 LIMIT 1].Id;

        Opportunity opp = new Opportunity(
                AccountId = acc[0].Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Pricebook2Id = priceBookId
        );

        List<Product2> products = [SELECT Id, Name, Non_Membership_Price__c FROM Product2 WHERE Name IN ('P1', 'P2', 'P3', 'P4') ORDER BY Name ASC];
        insert opp;

        OpportunityLineItem line = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Product2Id = products[0].Id,
                UnitPrice = products[0].Non_Membership_Price__c
        );

        insert line;

        line = [SELECT Id, Product2Id, PricebookEntryId FROM OpportunityLineItem WHERE Id = :line.Id];

        String oldLineNewPricebookEntryId = line.PricebookEntryId;
        System.debug('::old item PricebookEntryId: ' + oldLineNewPricebookEntryId);

        ServiceAppointment appointment = new ServiceAppointment(
                Opportunity_Product__c = line.Id,
                ParentRecordId = acc[0].Id,
                ServiceTerritoryId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id
        );

        insert appointment;
        appointment = [SELECT Id, WorkTypeId FROM ServiceAppointment WHERE Id = :appointment.Id];
        String oldAppointmentWorkTypeId = appointment.WorkTypeId;

        COVID_Test__c ctest = new COVID_Test__c(
                Scheduled_Appointment__c = appointment.Id,
                Opportunity_Product__c = line.Id,
                Opportunity__c = opp.Id,
                Test_Type__c = 'PCR Test',
                Work_Type_Group__c = [SELECT Id FROM WorkTypeGroup WHERE Name = 'WTG1'].Id
        );

        insert ctest;

        ctest = [SELECT Id, Opportunity_Product__c, Test_Type__c, Turnaround_Time__c, Turnaround_Time_Global__c, Work_Type_Group__c, Work_Type_Group__r.Name FROM COVID_Test__c WHERE Id = :ctest.Id];
        System.assert(ctest.Work_Type_Group__r.Name == 'WTG1');


        // DO CHANGE

        // parameters
        OnlProductChange.ChangeRequest changeRequest = new OnlProductChange.ChangeRequest();
        changeRequest.doRebook = true;
        changeRequest.ctestId = ctest.Id;
        //        changeRequest.resourceSelected = [SELECT Id FROM ServiceResource where Name = 'SR2' LIMIT 1].Id;
        changeRequest.locationSelected = [SELECT Id FROM ServiceTerritory WHERE Name = 'ST2' LIMIT 1].Id;
        changeRequest.timeSelected = Datetime.newInstance(2022, 2, 2, 10, 0, 0);
        changeRequest.timeSelectedEnd = Datetime.newInstance(2022, 2, 2, 10, 10, 0);
        changeRequest.newWorkTypeGroupId = null; //todo


        String ret = OnlProductChange.doChange(JSON.serialize(changeRequest));

        System.debug('::upgrade resp: ' + ret);
        System.assert(ret == null);

        ctest = [SELECT Id, Opportunity_Product__c, Test_Type__c, Turnaround_Time__c, Work_Type_Group__c, Work_Type_Group__r.Name FROM COVID_Test__c WHERE Id = :ctest.Id];
        System.assert(ctest.Work_Type_Group__r.Name == 'WTG1');

        appointment = [SELECT Id, WorkTypeId, WorkType.Name, SchedStartTime, SchedEndTime, ServiceTerritory.Name FROM ServiceAppointment WHERE Id = :appointment.Id];
        System.debug('::new appointment: ' + JSON.serialize(appointment));

    }

    @IsTest
    static void test_doChange_except() {

        OnlProductChange.newAuraHandledException('test');
    }

}