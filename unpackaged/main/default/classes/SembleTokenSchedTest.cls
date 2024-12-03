/**
 * Created 8.4.2024..
 */

@IsTest
private class SembleTokenSchedTest {
    @IsTest
    static void testBehavior() {
        SembleTokenSchedulable.unschedule();
        SembleTokenSchedulable.schedule();
        System.assert(ExternalSyncDocumentsSchedulable.geCurrentTriggers().size() > 0);
    }

    @IsTest
    static void testToken() {
        Test.startTest();

        HeyDocServiceMock.setAsMock();

        SembleTokenSchedulable.scheduleRetrieveToken();

        Test.stopTest();
    }
}