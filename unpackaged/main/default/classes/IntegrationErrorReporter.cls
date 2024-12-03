public without sharing class IntegrationErrorReporter {
    @TestVisible
    private static List<Error_Log__c> pendingErrorLogs = new List<Error_Log__c>();

    private String log_type;

    public IntegrationErrorReporter(String log_type)
    {
        this.log_type = log_type;
    }

    public IntegrationErrorReporter()
    {
        this.log_type = '';
    }

    public void logException(String type, Exception error, SObject relatedRecord) {
        this.addError(
            type,
            relatedRecord?.Id,
            error.getMessage(),
            error.getStackTraceString(),
            relatedRecord != null ? JSON.serialize(relatedRecord) : null
        );
    }

    public void logDatabaseErrors(
        String type,
        List<Database.SaveResult> saveResults,
        List<SObject> relatedRecords
    ) {
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];
            SObject record = relatedRecords[i];

            if (!result.isSuccess()) {
                this.logDatabaseErrors(type, record, result.getErrors());
            }
        }
    }

    public void logDatabaseErrors(
        String type,
        List<Database.UpsertResult> saveResults,
        List<SObject> relatedRecords
    ) {
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.UpsertResult result = saveResults[i];
            SObject record = relatedRecords[i];

            if (!result.isSuccess()) {
                this.logDatabaseErrors(type, record, result.getErrors());
            }
        }
    }

    private void logDatabaseErrors(
        String type,
        SObject relatedRecord,
        List<Database.Error> errors
    ) {
        for (Database.Error errorResult : errors) {
            this.addError(
                type,
                relatedRecord.Id,
                errorResult.getMessage(),
                null,
                JSON.serialize((relatedRecord))
            );
        }
    }

    public void addInfo(
        String type,
        String relatedId,
        String exceptionMessage,
        String stack,
        String additionalDetails
    ) {
        this.addLog('Info', type, relatedId, exceptionMessage, stack, additionalDetails);
    }

    public void addWarning(
        String type,
        String relatedId,
        String exceptionMessage,
        String stack,
        String additionalDetails
    ) {
        this.addLog('Warning', type, relatedId, exceptionMessage, stack, additionalDetails);
    }

    public void addError(
        String type,
        String relatedId,
        String exceptionMessage,
        String stack,
        String additionalDetails
    ) {
        this.addLog('Error', type, relatedId, exceptionMessage, stack, additionalDetails);
    }

    private void addLog(
        String severity,
        String type,
        String relatedId,
        String exceptionMessage,
        String stack,
        String additionalDetails
    ) {
        pendingErrorLogs.add(
            new Error_Log__c(
                Severity__c = severity,
                Type__c = type,
                Related_Object_Id__c = relatedId,
                Exception__c = exceptionMessage,
                Stack__c = stack,
                Details__c = additionalDetails
            )
        );
    }

    public void persistLogs() {
        System.debug('Persisting ' + pendingErrorLogs.size() + ' logs');
        Database.insert(pendingErrorLogs, false);

        System.debug(JSON.serialize(pendingErrorLogs));
        pendingErrorLogs.clear();
    }

    public void addLog(LoggingLevel loggingLevel, Id relatedId, String message) {
        addLog(loggingLevel, relatedId, message, null, null);
    }

    public void addLog(LoggingLevel loggingLevel, Id relatedId, String message, String stack, String details) {

        System.debug(loggingLevel, '::'+log_type+':id=' + relatedId + ':msg=' + message + ':stack=' + stack + ':detail=' + details);
        if (loggingLevel == System.LoggingLevel.WARN) {
            addWarning(log_type, relatedId, message, stack, details);
        }
        else if (loggingLevel == System.LoggingLevel.ERROR) {
            addError(log_type, relatedId, message, stack, details);
        }
        else {
            addInfo(log_type, relatedId, message, stack, details);
        }
    }
}