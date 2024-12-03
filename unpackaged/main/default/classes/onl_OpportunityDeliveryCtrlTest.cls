@IsTest class  onl_OpportunityDeliveryCtrlTest {
    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        Account acc = accounts[0];
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        insert opp;
    }

    @IsTest static void getDeliverableOpportunity_test() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        System.assert(opp != null);
        String json = onl_OpportunityDeliveryCtrl.getDeliverableOpportunity(opp.Id);
        System.assert(json != null);
    }

    @IsTest static void markFulfilmentDone_test() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        System.assert(opp != null);
        onl_OpportunityDeliveryCtrl.markFulfilmentDone(opp.Id);
        opp = [SELECT Id, Fulfillment_status__c FROM Opportunity WHERE Id=:opp.Id LIMIT 1];
        System.assert(opp.Fulfillment_status__c == 'Done');
    }

    @IsTest static void getMyListLink_test() {
        String listId = onl_OpportunityDeliveryCtrl.getMyListLink('My Online Orders with Delivery');
        System.debug(listId);
    }


}