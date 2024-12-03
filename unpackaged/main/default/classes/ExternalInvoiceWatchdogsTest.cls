/**
 * Created 22.6.2022..
 */

@IsTest
private class ExternalInvoiceWatchdogsTest {
    @IsTest
    static void testBehavior() {

        ExternalInvoiceWatchdog1.unschedule();
        ExternalInvoiceWatchdog1.schedule();
        ExternalInvoiceWatchdog1.unschedule();
        ExternalInvoiceWatchdog1.schedule();
        ExternalInvoiceWatchdog2.unschedule();
        ExternalInvoiceWatchdog2.schedule();
        ExternalInvoiceWatchdog2.unschedule();
        ExternalInvoiceWatchdog2.schedule();

    }

    @IsTest
    static void testWatchdog2Queueable() {

        Watchdog2Queueable wq = new Watchdog2Queueable(new List<Id>());

        wq.execute(null);

    }

}