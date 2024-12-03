/**
 * Created 28.3.2022..
 */

@IsTest
private class ExternalSyncRetPatientsSchedulableTest {
    @IsTest
    static void testBehavior() {
        ExternalSyncRetPatientsSchedulable.unschedule();
        ExternalSyncRetPatientsSchedulable.schedule();
        System.assert(ExternalSyncRetPatientsSchedulable.geCurrentTriggers().size()>0);
    }
}