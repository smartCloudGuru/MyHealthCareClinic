@IsTest
public class IntegrationErrorReporterTest {
    private static IntegrationErrorReporter errorReporter = new IntegrationErrorReporter();

    @IsTest
    static void logExceptionTest() {
        try {
            insert new Opportunity();
        } catch (Exception e) {
            errorReporter.logException('TEST', e, null);
        }

        System.assertEquals(1, IntegrationErrorReporter.pendingErrorLogs.size());
    }


    @IsTest
    static void logDatabaseInsertError() {
        List<Opportunity> testOpps = new List<Opportunity>{ new Opportunity() };

        List<Database.SaveResult> results = Database.insert(testOpps, false);
        errorReporter.logDatabaseErrors('TEST', results, testOpps);

        System.assertEquals(1, IntegrationErrorReporter.pendingErrorLogs.size());
    }

    @IsTest
    static void logDatabaseUpsertError() {
        List<Opportunity> testOpps = new List<Opportunity>{ new Opportunity() };

        List<Database.UpsertResult> results = Database.upsert(testOpps, false);
        errorReporter.logDatabaseErrors('TEST', results, testOpps);

        System.assertEquals(1, IntegrationErrorReporter.pendingErrorLogs.size());
    }
}