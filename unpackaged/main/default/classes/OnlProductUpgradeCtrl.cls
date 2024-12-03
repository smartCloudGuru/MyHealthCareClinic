/**
 * Created 8.2.2022..
 */

public with sharing class OnlProductUpgradeCtrl {

    @AuraEnabled(Cacheable=true)
    public static String getProductsForOpportunity(String oppId) {
        List<OpportunityLineItem> olis = [SELECT Id, Product2Id, Product2.Name, Product2.Id, Product2.Family FROM OpportunityLineItem WHERE OpportunityId = :oppId];

        List<Product2> products = new List<Product2>();
        for (OpportunityLineItem opportunityLineItem : olis) {
            if (opportunityLineItem.Product2Id != null && (opportunityLineItem.Product2.Family != 'Discount')) {
                opportunityLineItem.Product2.Description = opportunityLineItem.Id;
                products.add(opportunityLineItem.Product2);
            }
        }
        return JSON.serialize(products);
    }

    @AuraEnabled(Cacheable=true)
    public static String getAvailableUpgradesFor(String productId) {
        List <Product_Upgrade__c> upgrades = [SELECT Upgrade_To__c, Upgrade_To__r.Id, Upgrade_To__r.Name FROM Product_Upgrade__c WHERE Upgrade_From__c = :productId];

        List<Product2> ret = new List<Product2>();
        for (Product_Upgrade__c pu : upgrades) {
            if (pu.Upgrade_To__c != null) ret.add(pu.Upgrade_To__r);
        }

        return JSON.serialize(ret);
    }

    @AuraEnabled(Cacheable=true)
    public static String getAvailableDowngradesFor(String productId) {
        List <Product_Upgrade__c> upgrades = [SELECT Upgrade_To__c, Upgrade_From__r.Id, Upgrade_From__r.Name, Upgrade_From__c FROM Product_Upgrade__c WHERE Upgrade_To__c = :productId];

        List<Product2> ret = new List<Product2>();
        for (Product_Upgrade__c pu : upgrades) {
            if (pu.Upgrade_From__c != null) ret.add(pu.Upgrade_From__r);
        }

        return JSON.serialize(ret);
    }

    @AuraEnabled
    public static String getAppointmentForLineItem(String lineItemId) {

        List<ServiceAppointment> apps = [
                SELECT
                        Id, Turnaround_Time__c, SchedStartTime, ServiceTerritory.Name
                FROM ServiceAppointment
                WHERE Opportunity_Product__c = :lineItemId
        ];

        return JSON.serialize(apps);
    }

    @AuraEnabled(Cacheable=false)
    public static String upgrade(String opportunityId, String lineItemId, String toProductId) {

        // load opportunity
        System.debug(LoggingLevel.ERROR, '::upgrade:loading opportunity...');
        List<Opportunity> opps = [SELECT Id, UUID__c FROM Opportunity WHERE Id = :opportunityId];
        if (opps.isEmpty()) return 'Invalid Opportunity';

        // load old line item
        System.debug(LoggingLevel.ERROR, '::upgrade:loading old line item...');
        List<OpportunityLineItem> olis = [SELECT Id, PricebookEntryId, Quantity FROM OpportunityLineItem WHERE Id = :lineItemId];
        if (olis.isEmpty()) return 'Invalid Opportunity Line Item ' + lineItemId;

        // load covid test
        System.debug(LoggingLevel.ERROR, '::upgrade:loading covid test...');
        List<COVID_Test__c> ctests = [SELECT Id, Scheduled_Appointment__c FROM COVID_Test__c WHERE Opportunity_Product__c = :lineItemId];
        if (ctests.isEmpty()) return 'No COVID Test found for this Line Item';

        //load new Product
        System.debug(LoggingLevel.ERROR, '::upgrade:loading covid test...');
        List<Product2> newProducts = [SELECT Id, Non_Membership_Price__c FROM Product2 WHERE Id = :toProductId];
        if (newProducts.isEmpty()) return 'No appropriate New Product fount';

        //load default tests for the new product
        System.debug(LoggingLevel.ERROR, '::upgrade:loading default tests...');
        List<Default_COVID_Test__c> newDefaultTests = [SELECT Id, COVID_Test_Type__c, Turnaround_Time__c, Work_Type_Group__c FROM Default_COVID_Test__c WHERE Product__c = :toProductId];
        if (newDefaultTests.isEmpty()) return 'Selected New Product does not have a Default COVID Test';
        if (newDefaultTests.size() > 1) return 'Selected New Product has more than 1 Default COVID Test. Upgrading/Downgrading Bundles is not supported.';

        //load service appointment
        System.debug(LoggingLevel.ERROR, '::upgrade:loading appointment...');
        List<ServiceAppointment> appointments = [SELECT Id, ServiceTerritoryId FROM ServiceAppointment WHERE Id = :ctests[0].Scheduled_Appointment__c];

        // CHECK IF WE CAN MOVE THE APPOINTMENT TO A NEW WORK TYPE ON SAME LOCATION
        String foundNewWorkTypeId = null;
        if (appointments.size() == 1) {
            System.debug(LoggingLevel.ERROR, '::upgrade:appointment found...');
            //list worktypegroup memberes for the work type group of the new default covid test
            List<WorkTypeGroupMember> wtgms = [
                    SELECT Id, WorkTypeId
                    FROM WorkTypeGroupMember
                    WHERE WorkTypeGroupId = :newDefaultTests[0].Work_Type_Group__c
            ];
            //list ServiceTerritoryWorkType for the given Location in the scheduled appointment
            List<ServiceTerritoryWorkType> stwts = [
                    SELECT Id, WorkTypeId
                    FROM ServiceTerritoryWorkType
                    WHERE ServiceTerritoryId = :appointments[0].ServiceTerritoryId
            ];

            System.debug(LoggingLevel.ERROR, '::upgrade:ServiceTerritoryWorkType for this Location: ' + JSON.serialize(stwts));
            System.debug(LoggingLevel.ERROR, '::upgrade:WorkTypeGroupMembers for this WorkTypeGroup: ' + JSON.serialize(wtgms));

            for (ServiceTerritoryWorkType stwt : stwts) {
                for (WorkTypeGroupMember wtgm : wtgms) {
                    if (stwt.WorkTypeId == wtgm.WorkTypeId) {
                        foundNewWorkTypeId = stwt.WorkTypeId;
                        break;
                    }
                }
                if (foundNewWorkTypeId != null) {
                    break;
                }
            }

            if (foundNewWorkTypeId == null) {
                return 'Test from the new Product is not available at the same Location';
            }

            System.debug(LoggingLevel.ERROR, '::upgrade:new worktypeid for the appointment will be ...' + foundNewWorkTypeId);
        }
        else {
            System.debug(LoggingLevel.ERROR, '::upgrade:NO appointment found...');
        }

        // CREATE AND INSERT A NEW LINE ITEM
        System.debug(LoggingLevel.ERROR, '::upgrade:creating a new line item...');
        OpportunityLineItem line = new OpportunityLineItem(
                OpportunityId = opportunityId,
                Product2Id = toProductId,
                Quantity = 1,
                UnitPrice = newProducts[0].Non_Membership_Price__c
        );
        if (olis[0].Quantity == 1) {
            delete olis[0];
        }
        else {
            olis[0].Quantity = olis[0].Quantity - 1;
            update olis[0];
        }
        System.debug(LoggingLevel.ERROR, '::upgrade:inserting a new line item...');
        insert line;

        // recalculate discounts !
        onl_CheckoutCtrl.calculateCouponForBasket(opps[0].Id);

        // MODIFY THE COVID TEST
        ctests[0].Opportunity_Product__c = line.Id;
        ctests[0].Test_Type__c = newDefaultTests[0].COVID_Test_Type__c;
        ctests[0].Turnaround_Time_Global__c = newDefaultTests[0].Turnaround_Time__c;
        ctests[0].Work_Type_Group__c = newDefaultTests[0].Work_Type_Group__c;
        System.debug(LoggingLevel.ERROR, '::upgrade:updating the covid test... ' + JSON.serialize(ctests[0]));
        update ctests[0];

        //update appointment
        if (foundNewWorkTypeId != null) {
            appointments[0].Turnaround_Time__c = ctests[0].Turnaround_Time_Global__c;
            appointments[0].WorkTypeId = foundNewWorkTypeId;
            System.debug(LoggingLevel.ERROR, '::upgrade:updating appointment... ');
            appointments[0].Opportunity_Product__c = line.Id;
            update appointments[0];
        }

        onl_CheckoutCtrl.calculateCouponForBasket(opps[0].UUID__c);

        opps[0].Downgrade_Or_Upgrade_Done__c = true;
        update opps[0];

        System.debug(LoggingLevel.ERROR, '::upgrade:successful');


        return null;

    }

}