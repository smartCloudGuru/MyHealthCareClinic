/**
 * Created 22.6.2022..
 */

@IsTest
private class ExternalAppointmentsWatchdogTest {
    @IsTest
    static void testBehavior() {

        ExternalAppointmentsWatchdog.unschedule();
        ExternalAppointmentsWatchdog.schedule();
        ExternalAppointmentsWatchdog.unschedule();
        ExternalAppointmentsWatchdog.schedule();
        //System.assert(ExternalSyncRetAppointmentsSchedulable.geCurrentTriggers().size() > 0);
    }

}