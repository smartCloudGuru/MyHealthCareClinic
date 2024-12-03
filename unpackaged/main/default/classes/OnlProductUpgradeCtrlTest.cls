/**
 * Created 08.02.2022
 */

@IsTest
global class OnlProductUpgradeCtrlTest {

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

        OperatingHours operatingHours = new OperatingHours(Name='OH');
        insert operatingHours;

        ServiceTerritory location = new ServiceTerritory(
                Name = 'Test',
                OperatingHoursId = operatingHours.Id,
                IsActive=true
        );
        insert location;

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
        for (Integer i=0; i<wtgsToInsert.size(); i++) {
            wtgms.add(new WorkTypeGroupMember(WorkTypeGroupId = wtgsToInsert[i].Id, WorkTypeId = workTypes[i].Id));
        }
        insert wtgms;

        List<ServiceTerritoryWorkType> stwts = new List<ServiceTerritoryWorkType>();
        for (Integer i=0; i<workTypes.size(); i++) {
            stwts.add(new ServiceTerritoryWorkType(ServiceTerritoryId=location.Id, WorkTypeId=workTypes[i].Id));
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

        List<Product_Upgrade__c> upgradesToInsert = new List<Product_Upgrade__c>();
        upgradesToInsert.add(new Product_Upgrade__c(
                Upgrade_From__c = productsToInsert[0].Id,
                Upgrade_To__c = productsToInsert[1].Id
        ));

        upgradesToInsert.add(new Product_Upgrade__c(
                Upgrade_From__c = productsToInsert[0].Id,
                Upgrade_To__c = productsToInsert[2].Id
        ));

        upgradesToInsert.add(new Product_Upgrade__c(
                Upgrade_From__c = productsToInsert[1].Id,
                Upgrade_To__c = productsToInsert[2].Id
        ));

        insert upgradesToInsert;


    }

    @IsTest
    static void test_getAvailableUpgradesFor() {

        List<Product2> products = [SELECT Id, Name FROM Product2];
        Map<String, String> productMapByName = new Map<String, String>();
        for (Product2 product : products) {
            productMapByName.put(product.Name, product.Id);
        }

        List<Product2> products1 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableUpgradesFor(productMapByName.get('P1')),
                List<Product2>.class);

        List<Product2> products2 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableUpgradesFor(productMapByName.get('P2')),
                List<Product2>.class);

        List<Product2> products3 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableUpgradesFor(productMapByName.get('P3')),
                List<Product2>.class);

        List<Product2> products4 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableUpgradesFor(productMapByName.get('P4')),
                List<Product2>.class);

        System.assert(products1.size() == 2);
        System.assert(products2.size() == 1);
        System.assert(products3.size() == 0);
        System.assert(products4.size() == 0);

        products1 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableDowngradesFor(productMapByName.get('P1')),
                List<Product2>.class);

        products2 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableDowngradesFor(productMapByName.get('P2')),
                List<Product2>.class);

        products3 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableDowngradesFor(productMapByName.get('P3')),
                List<Product2>.class);

        products4 = (List<Product2>) JSON.deserialize(
                OnlProductUpgradeCtrl.getAvailableDowngradesFor(productMapByName.get('P4')),
                List<Product2>.class);

        System.assert(products1.size() == 0);
        System.assert(products2.size() == 1);
        System.assert(products3.size() == 2);
        System.assert(products4.size() == 0);

    }


    @IsTest
    static void test_upgrade() {

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


        // DO UPGRADE
        String ret = OnlProductUpgradeCtrl.upgrade(opp.Id, line.Id, products[1].Id);

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


}