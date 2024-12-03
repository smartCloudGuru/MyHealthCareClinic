/**
 * Created by Matija on 18.9.2023..
 */

trigger AllOpportunityTriggers on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
            Opportunity.SObjectType,
            Trigger.operationType,
            Trigger.isExecuting,
            Trigger.new,
            Trigger.newMap,
            Trigger.old,
            Trigger.oldMap
    ));
}