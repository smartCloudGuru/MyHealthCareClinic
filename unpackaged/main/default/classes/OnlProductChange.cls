/**
 * Created 8.2.2022..
 */

public without sharing class OnlProductChange {

    @AuraEnabled(Cacheable=true)
    public static String getCovidTestData(String ctId) {

        List<COVID_Test__c> cts = [
                SELECT
                        Id,
                        Work_Type_Group__c,
                        Opportunity_Product__r.Product2Id,
                        Opportunity_Product__r.Product2.Name,
                        Scheduled_Appointment__c,
                        Scheduled_Appointment__r.SchedStartTime,
                        Scheduled_Appointment__r.ServiceTerritory.Name
                FROM COVID_Test__c
                WHERE Id = :ctId
        ];

        return JSON.serialize(cts[0]);
    }

    @AuraEnabled(Cacheable=true)
    public static String getCovidTestProducts(String oldId) {

        List<Product2> products = [
                SELECT
                        Id,
                        Name
                FROM Product2
                WHERE IsActive = TRUE
                AND Family = 'Covid Tests'
                AND Is_Home_Test__c = FALSE
                AND Quantity_of_COVID_Tests__c = 1
                AND Id != :oldId
                ORDER BY Name ASC
        ];

        return JSON.serialize(products);
    }

    @AuraEnabled(Cacheable=true)
    public static String getDefaultCovidTestForProduct(String productId) {

        List<Default_COVID_Test__c> dcts = [
                SELECT
                        Id,
                        Work_Type_Group__c
                FROM Default_COVID_Test__c
                WHERE Product__c = :productId
                ORDER BY Sort_Order__c ASC
        ];
        if (dcts.isEmpty()) return null;
        return JSON.serialize(dcts[0]);
    }

    public class ChangeRequest {
        public String ctestId;
        public Boolean doRebook;
        public Boolean doChangeType;
        public String changeToProduct;
        public String locationSelected;
        public Datetime timeSelected;
        public Datetime timeSelectedEnd;
        public String resourceSelected;
        public String newWorkTypeGroupId;
    }

    @AuraEnabled
    public static String doChange(String request) {
        String step = 'a';
        try {
            step = 'b';
            ChangeRequest changeRequest = (ChangeRequest) JSON.deserialize(request, ChangeRequest.class);

            if ((changeRequest.doChangeType != true) && (changeRequest.doRebook != true)) return 'Nothing to change on this Test';

            // load covid test
            System.debug(LoggingLevel.ERROR, '::upgrade:loading covid test...');
            List<COVID_Test__c> ctests = [
                    SELECT
                            Id, Scheduled_Appointment__c, Opportunity_Product__c, Opportunity__c, Opportunity__r.UUID__c, Opportunity_Product__r.Product2Id, Work_Type_Group__c
                    FROM COVID_Test__c
                    WHERE Id = :changeRequest.ctestId
            ];
            if (ctests.isEmpty()) return 'No COVID Test found for this Line Item';

            String oppId = ctests[0].Opportunity__c;
            String oppUUID = ctests[0].Opportunity__r?.UUID__c;
            String old_oliId = ctests[0].Opportunity_Product__c;
            String old_saId = ctests[0].Scheduled_Appointment__c;
            String old_productId = ctests[0].Opportunity_Product__r?.Product2Id;
            String new_productId = changeRequest.changeToProduct;

            String reschedule_new_SaResource = changeRequest.resourceSelected;
            String reschedule_new_location = changeRequest.locationSelected;
            Datetime reschedule_new_startTime = changeRequest.timeSelected;
            Datetime reschedule_new_endTime = changeRequest.timeSelectedEnd;
            String reschedule_new_wtgId = changeRequest.newWorkTypeGroupId;

            if (oppId == null || old_oliId == null) return 'This COVID Test has not Opportunity. Unable to change Product.';

            if (changeRequest.doChangeType == true) {

                // load old line item
                System.debug(LoggingLevel.ERROR, '::upgrade:loading old line item...');
                List<OpportunityLineItem> olis = [SELECT Id, PricebookEntryId, Quantity FROM OpportunityLineItem WHERE Id = :old_oliId];
                if (olis.isEmpty()) return 'Invalid Opportunity Line Item ' + old_oliId;

                //load new Product
                System.debug(LoggingLevel.ERROR, '::upgrade:loading covid test...');
                List<Product2> newProducts = [SELECT Id, Non_Membership_Price__c FROM Product2 WHERE Id = :new_productId];
                if (newProducts.isEmpty()) return 'No appropriate New Product fount';

                // load default tests for the new product
                System.debug(LoggingLevel.ERROR, '::upgrade:loading default tests...');
                List<Default_COVID_Test__c> newDefaultTests = [
                        SELECT Id, COVID_Test_Type__c, Turnaround_Time__c, Work_Type_Group__c
                        FROM Default_COVID_Test__c
                        WHERE Product__c = :new_productId
                ];
                if (newDefaultTests.isEmpty()) return 'Selected New Product does not have a Default COVID Test';
                if (newDefaultTests.size() > 1) return 'Selected New Product has more than 1 Default COVID Test. Changing into Bundle Products is not supported.';

                // load service appointment
                System.debug(LoggingLevel.ERROR, '::change:loading appointment...');
                List<ServiceAppointment> appointments = [SELECT Id, ServiceTerritoryId FROM ServiceAppointment WHERE Id = :old_saId];

                // CHECK IF WE CAN MOVE THE APPOINTMENT TO A NEW WORK TYPE ON SAME LOCATION
                String foundNewWorkTypeId = null;

                if (appointments.size() == 1) {
                    System.debug(LoggingLevel.ERROR, '::change:appointment found...');

                    foundNewWorkTypeId = getWorkTypeIdForLocationAndWTGroup(appointments[0].ServiceTerritoryId, newDefaultTests[0].Work_Type_Group__c);
                    if (foundNewWorkTypeId == null) {
                        return 'Test from the new Product is not available at the same Location. You may need to reschedule to a different location';
                    }
                    System.debug(LoggingLevel.ERROR, '::change:new worktypeid for the appointment will be ...' + foundNewWorkTypeId);
                }
                else {
                    System.debug(LoggingLevel.ERROR, '::change:NO appointment found...');
                }

                step = 'c';
                // CREATE AND INSERT A NEW LINE ITEM
                System.debug(LoggingLevel.ERROR, '::change:creating a new line item...');
                OpportunityLineItem line = new OpportunityLineItem(
                        OpportunityId = oppId,
                        Product2Id = new_productId,
                        Quantity = 1,
                        UnitPrice = newProducts[0].Non_Membership_Price__c
                );
                step = 'd';
                if (olis[0].Quantity == 1) {
                    step = 'e';
                    delete olis[0];
                    //olis[0].Product2 = null;
                    //olis[0].UnitPrice = 0;
                    //update olis[0];
                }
                else {
                    step = 'f';
                    olis[0].Quantity = olis[0].Quantity - 1;
                    update olis[0];
                }
                System.debug(LoggingLevel.ERROR, '::upgrade:inserting a new line item...');
                step = 'g';
                insert line;
                step = 'h';
                onl_CheckoutCtrl.calculateCouponForBasket(oppUUID);

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

                Opportunity opp = new Opportunity(Id = oppId, Downgrade_Or_Upgrade_Done__c = true);
                update opp;

                System.debug(LoggingLevel.ERROR, '::upgrade:doChangeType:finished');

            }


            if (changeRequest.doRebook == true) {

                // load service appointment
                System.debug(LoggingLevel.ERROR, '::upgrade:loading appointment...');
                List<ServiceAppointment> appointments = [SELECT Id, ServiceTerritoryId FROM ServiceAppointment WHERE Id = :old_saId];

                String reschedule_new_wtId = null;

                if (reschedule_new_location != null && reschedule_new_wtgId != null) {
                    reschedule_new_wtId = getWorkTypeIdForLocationAndWTGroup(reschedule_new_location, reschedule_new_wtgId);
                    if (reschedule_new_wtgId == null) return 'Test is not available at the new Location. You may need to reschedule to a different location';
                }

                //update appointment
                appointments[0].SchedStartTime = reschedule_new_startTime;
                appointments[0].SchedEndTime = reschedule_new_endTime;
                if (reschedule_new_wtId != null) appointments[0].WorkTypeId = reschedule_new_wtId;
                if (reschedule_new_location != null) appointments[0].ServiceTerritoryId = reschedule_new_location;
                update appointments[0];

                if (reschedule_new_SaResource != null) {
                    // delete the current resources for that SA and create new ones
                    List<AssignedResource> ars = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :appointments[0].Id];
                    delete ars;
                    AssignedResource ar = new AssignedResource(ServiceAppointmentId = appointments[0].Id, ServiceResourceId = reschedule_new_SaResource, IsRequiredResource = true);
                    insert ar;
                }

                System.debug(LoggingLevel.ERROR, '::change:doRebook:finished');

                return null;
            }

            return null;
        }
        catch (Exception ex)
        {
            throw newAuraHandledException(ex.getMessage() + ':'+step);
        }
    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }

    private static String getWorkTypeIdForLocationAndWTGroup(String territoryId, String wtgId) {

        //list worktypegroup memberes for the work type group
        List<WorkTypeGroupMember> wtgms = [
                SELECT Id, WorkTypeId
                FROM WorkTypeGroupMember
                WHERE WorkTypeGroupId = :wtgId
        ];
        //list ServiceTerritoryWorkType for the given Location in the scheduled appointment
        List<ServiceTerritoryWorkType> stwts = [
                SELECT Id, WorkTypeId
                FROM ServiceTerritoryWorkType
                WHERE ServiceTerritoryId = :territoryId
        ];

        System.debug(LoggingLevel.ERROR, '::upgrade:ServiceTerritoryWorkType for this Location: ' + JSON.serialize(stwts));
        System.debug(LoggingLevel.ERROR, '::upgrade:WorkTypeGroupMembers for this WorkTypeGroup: ' + JSON.serialize(wtgms));

        for (ServiceTerritoryWorkType stwt : stwts) {
            for (WorkTypeGroupMember wtgm : wtgms) {
                if (stwt.WorkTypeId == wtgm.WorkTypeId) {
                    return stwt.WorkTypeId;
                }
            }
        }

        return null;

    }

}