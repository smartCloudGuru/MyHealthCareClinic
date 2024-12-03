/**
 * Created by david on 25/03/2021.
 */

@IsTest
private class TH_Transaction_UpdateRelated_Test {
	@IsTest
	static void testUpdateRelated() {
		bt_stripe__Transaction__c tran = new bt_stripe__Transaction__c();
		String jsonData = '{"OpportunityId":"0064H00001IcjUuQAJ","ContactId":"0034H00002LQGxH","AccountId":"0014H00003Cqnz3QAB"}';
		tran.bt_stripe__Metadata__c = jsonData;

		List<SObject> newList = new List<SObject>();

		newList.add(tran);

		AnthologyTriggerHandler.AnthologyTriggerContext context = new AnthologyTriggerHandler.AnthologyTriggerContext(
				bt_stripe__Transaction__c.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				false,
				newList,
				null,
				null,
				null
				);

		TH_Transaction_UpdateRelated triggerHandler = new TH_Transaction_UpdateRelated(context);
		triggerHandler.beforeInsert(tran);
		System.assertEquals('0064H00001IcjUuQAJ', tran.Opportunity__c);
		System.assertEquals('0014H00003Cqnz3QAB', tran.bt_stripe__Related_Account__c);
	}

	@IsTest
	static void testNullData() {
		bt_stripe__Transaction__c tran = new bt_stripe__Transaction__c();

		List<SObject> newList = new List<SObject>();

		newList.add(tran);

		AnthologyTriggerHandler.AnthologyTriggerContext context = new AnthologyTriggerHandler.AnthologyTriggerContext(
				bt_stripe__Transaction__c.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				false,
				newList,
				null,
				null,
				null
		);

		TH_Transaction_UpdateRelated triggerHandler = new TH_Transaction_UpdateRelated(context);
		triggerHandler.beforeInsert(tran);
		System.assert(tran.Opportunity__c == null);
		System.assert(tran.bt_stripe__Related_Account__c == null);
	}

	@IsTest
	static void testUpdateRelatedBEFORE_UPDATE() {
		bt_stripe__Transaction__c tran = new bt_stripe__Transaction__c();

		List<SObject> newList = new List<SObject>();

		newList.add(tran);

		AnthologyTriggerHandler.AnthologyTriggerContext context = new AnthologyTriggerHandler.AnthologyTriggerContext(
				bt_stripe__Transaction__c.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				false,
				newList,
				null,
				null,
				null
		);

		TH_Transaction_UpdateRelated triggerHandler = new TH_Transaction_UpdateRelated(context);
		triggerHandler.beforeInsert(tran);

		System.assert(tran.Opportunity__c == null);
		System.assert(tran.bt_stripe__Related_Account__c == null);

		String jsonData = '{"OpportunityId":"0064H00001IcjUuQAJ","ContactId":"0034H00002LQGxH","AccountId":"0014H00003Cqnz3QAB"}';
		tran.bt_stripe__Metadata__c = jsonData;
		triggerHandler.beforeUpdate(tran,tran);


		System.assertEquals('0064H00001IcjUuQAJ', tran.Opportunity__c);
		System.assertEquals('0014H00003Cqnz3QAB', tran.bt_stripe__Related_Account__c);
	}
}