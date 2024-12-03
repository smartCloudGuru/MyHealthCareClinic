/**
 * Created 29.10.2021..
 */

public with sharing class onl_OpportunityDeliveryCtrl {

    // get eventual current olis for this opportunity and their product2Is
    @AuraEnabled(Cacheable=true)
    public static String getDeliverableLineItemsForOpportunityId(String recordId) {

        List<OpportunityLineItem> olis = [
                SELECT
                        Id,
                        Product2.Requires_delivery__c,
                        Product2.Name,
                        Product2.Id,
                        Product2Id,
                        Quantity,
                        PricebookEntryId,
                        UnitPrice,
                        Product2.Quantity_of_COVID_Tests__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :recordId AND Product2.Requires_delivery__c = TRUE
        ];

        return JSON.serialize(olis);
    }

    // get opportunity with shipping-related data
    @AuraEnabled(Cacheable=true)
    public static String getDeliverableOpportunity(String recordId) {

        Opportunity ret = [
                SELECT
                        Id,
                        Click_and_Collect__c,
                        Pickup_Location__c,
                        Pickup_Location__r.Name,
                        Fulfillment_status__c,
                        Online_Shipping_First_Name__c,
                        Online_Shipping_Last_Name__c,
                        Online_Shipping_Address_Line_1__c,
                        Online_Shipping_Address_Line_2__c,
                        Online_Shipping_Address_Line_3__c,
                        Online_Shipping_City__c,
                        Online_Shipping_Postcode__c
                FROM Opportunity
                WHERE Id = :recordId
        ];

        return JSON.serialize(ret);
    }

    // get opportunity with shipping-related data
    @AuraEnabled
    public static String markFulfilmentDone(String recordId) {

        Opportunity opp = new Opportunity();
        opp.Id = recordId;
        opp.Fulfillment_status__c = 'Done';
        update opp;
        return opp.Id;
    }


    /**
     * @return Find the list view with the specified name */
    @AuraEnabled(Cacheable=true)
    public static String getMyListLink(String listName) {
        return listViewURL(prefixList(), 'Opportunity', listName);
    }

    public static Map<String, String> prefixList() {
        Map<String, String> PrefixList = new Map<String, String>{};
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String sObj : gd.keySet()) {
            Schema.DescribeSObjectResult r = gd.get(sObj).getDescribe();
            PrefixList.put(r.getName(), r.getKeyPrefix());
        }
        return PrefixList;
    }

    public static  String listViewURL(Map<String, String> prefixList, String objectName, String listViewLabel) {
        String ListViewURL;
        String ListViewId;
        String q = 'SELECT Name FROM ' + objectName + ' LIMIT 1';
        ApexPages.StandardSetController ACC = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        List<SelectOption> ListViews = ACC.getListViewOptions();
        for (SelectOption w : ListViews) {
            if (w.getLabel() == listViewLabel) {
                ListViewId = w.getValue().left(15);
                ListViewURL = '/' + prefixList.get(objectName) + '?fcf=' + ListViewId;
            }
        }
        return ListViewURL;
    }
}