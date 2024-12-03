/**
 * Created by david on 25/03/2021.
 */

trigger AllTransactionTriggers on bt_stripe__Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
			bt_stripe__Transaction__c.SObjectType,
			Trigger.operationType,
			Trigger.isExecuting,
			Trigger.new,
			Trigger.newMap,
			Trigger.old,
			Trigger.oldMap
	));
}