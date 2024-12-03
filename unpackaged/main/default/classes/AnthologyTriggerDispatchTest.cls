/**
 * Created by david on 25/03/2021.
 */

@IsTest
private class AnthologyTriggerDispatchTest {

	static testMethod void testTriggerDispatch() {

		AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
				Account.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				false,
				new List<Account>(),
				new Map<Id, Account>(),
				new List<Account>(),
				new Map<Id, Account>()
		));

		AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
				COVID_Test__c.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				false,
				new List<COVID_Test__c>(),
				new Map<Id, COVID_Test__c>(),
				new List<COVID_Test__c>(),
				new Map<Id, COVID_Test__c>()
		));
		AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
				Opportunity.SObjectType,
				System.TriggerOperation.BEFORE_UPDATE,
				false,
				new List<Opportunity>(),
				new Map<Id, Opportunity>(),
				new List<Opportunity>(),
				new Map<Id, Opportunity>()
		));
	}

	static testMethod void testInProgressEntry() {

		anthologyTriggerDispatch.activeFunction = new TH_Transaction_UpdateRelated(
				new AnthologyTriggerHandler.AnthologyTriggerContext(
						Account.SObjectType,
						System.TriggerOperation.BEFORE_INSERT,
						true,
						new List<Account>(),
						new Map<Id, Account>(),
						new List<Account>(),
						new Map<Id, Account>()
				)
		);
		AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
				Account.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				true,
				new List<Account>(),
				new Map<Id, Account>(),
				new List<Account>(),
				new Map<Id, Account>()
		));
	}

	static testMethod void testNoTriggers() {

		anthologyTriggerDispatch.noTriggers = true;
		AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
				Account.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				false,
				new List<Account>(),
				new Map<Id, Account>(),
				new List<Account>(),
				new Map<Id, Account>()
		));
	}
}