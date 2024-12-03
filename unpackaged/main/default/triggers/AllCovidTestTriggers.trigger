/**
* @author Zoran Zunko
* @date 4/13/21
*
*/

trigger AllCovidTestTriggers on COVID_Test__c
        (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    AnthologyTriggerDispatch.entry(new AnthologyTriggerHandler.AnthologyTriggerContext(
            COVID_Test__c.SObjectType,
            Trigger.operationType,
            Trigger.isExecuting,
            Trigger.new,
            Trigger.newMap,
            Trigger.old,
            Trigger.oldMap
    ));
}