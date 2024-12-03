/**
 * Created by Matija on 20.6.2023..
 */

@IsTest
private class RetrieveInvoicesSchedulableTest {

    @IsTest
    static void testBehavior() {
        RetrieveInvoicesSchedulable.unschedule();
        RetrieveInvoicesSchedulable.schedule();
        System.assert(RetrieveInvoicesSchedulable.geCurrentTriggers().size()>0);
        RetrieveInvoicesSchedulable.unschedule();
    }
}