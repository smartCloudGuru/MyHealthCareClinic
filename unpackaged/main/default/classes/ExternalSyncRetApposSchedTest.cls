/**
 * Created 28.3.2022..
 */

@IsTest
private class ExternalSyncRetApposSchedTest {
    @IsTest
    static void testBehavior() {
        ExternalSyncRetAppointmentsSchedulable.unschedule();
        ExternalSyncRetAppointmentsSchedulable.schedule();
        ExternalSyncRetAppointmentsSchedulable.unschedule();
        ExternalSyncRetAppointmentsSchedulable.schedule();
        System.assert(ExternalSyncRetAppointmentsSchedulable.geCurrentTriggers().size()>0);
    }
}