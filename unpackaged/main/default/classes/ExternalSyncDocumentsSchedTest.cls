/**
 * Created by Matija on 13.2.2024..
 */

@IsTest
private class ExternalSyncDocumentsSchedTest {
    @IsTest
    static void testBehavior() {
        ExternalSyncDocumentsSchedulable.unschedule();
        ExternalSyncDocumentsSchedulable.schedule();
        System.assert(ExternalSyncDocumentsSchedulable.geCurrentTriggers().size()>0);
    }
}