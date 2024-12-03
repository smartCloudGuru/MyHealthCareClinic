public without sharing class AnthologyTriggerDispatch {

    // Holds a reference to the currently executing trigger
    public static AnthologyTriggerHandler.Delegate activeFunction = null;

    /// Code control of no triggers
    public static Boolean noTriggers = false;

    // Code control of no triggers variable;
    public static No_Triggers__c noUserTriggers;

    public static void entry(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
        // Check if triggers have been disabled by another class
        if (noTriggers) {
            System.debug(LoggingLevel.WARN, 'Triggers are disabled by code control - exiting from AnthologyTriggerDispatch');
            return;
        }

        // Check if triggers are disabled for this user
        if (noUserTriggers == null) {
            noUserTriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
        }
        if (noUserTriggers.Flag__c) {
            System.debug(LoggingLevel.WARN, 'Triggers are disabled for this user - exiting from AnthologyTriggerDispatch');
            return;
        }

        debugContext(anthTriggerContext.triggerObject, anthTriggerContext.triggerOperation);

        // If we were called as the result of an already executing trigger, pass control to the InProgressEntry method of that
        // trigger and let it decide what to do.
        if (activeFunction != null && activeFunction.getAnthologyTriggerContext().triggerObject == anthTriggerContext.triggerObject) {
            System.debug(LoggingLevel.DEBUG, 'AnthologyTriggerDispatch::entry - Executing In Progress triggers');
            AnthologyTriggerHandler.AnthologyTriggerContext oldContext = activeFunction.getAnthologyTriggerContext();
            activeFunction.setAnthologyTriggerContext(anthTriggerContext);
            AnthologyTriggerHandler.executeInProgress(activeFunction);
            activeFunction.setAnthologyTriggerContext(oldContext);
            return;
        }

        // Otherwise call the triggers we want to execute
        if (anthTriggerContext.triggerObject == bt_stripe__Transaction__c.SObjectType) {
            activeFunction = new TH_Transaction_UpdateRelated(anthTriggerContext);
            AnthologyTriggerHandler.execute(activeFunction);
            activeFunction = null;
        }
        else if (anthTriggerContext.triggerObject == COVID_Test__c.SObjectType) {
            activeFunction = new TH_CovidTest_GenerateCertificate(anthTriggerContext); AnthologyTriggerHandler.execute(activeFunction);
            activeFunction = new TH_CovidTest_GenerateUUID(anthTriggerContext); AnthologyTriggerHandler.execute(activeFunction);
			activeFunction = new TH_CovidTest_CalculateDates(anthTriggerContext); AnthologyTriggerHandler.execute(activeFunction);
            activeFunction = null;
        }
        else if (anthTriggerContext.triggerObject == Opportunity.SObjectType) {
            activeFunction = new TH_Opportunity_ExistingPatientFlags(anthTriggerContext);
            AnthologyTriggerHandler.execute(activeFunction);
            activeFunction = new TH_Opportunity_UpsertPatientBusinessUnit(anthTriggerContext);
            AnthologyTriggerHandler.execute(activeFunction);

            activeFunction = null;
        }

    }

	/**
     * Debug the context for the trigger call
     * <p/>
     * Helps us to know which triggers are forwarded by what
     *
     * @param triggerObject
     * @param triggerOperation
     */
    public static void debugContext(Schema.SObjectType triggerObject, System.TriggerOperation triggerOperation) {

        if (activeFunction != null) {
            System.debug('*** TRIGGER: ' + triggerOperation + ' trigger on ' + triggerObject + ' caused by ' + activeFunction.getTriggerContext().get('name'));
            return;
        }
        else {
            System.debug('*** TRIGGER: ' + triggerOperation + ' trigger on ' + triggerObject);
        }

    }

}