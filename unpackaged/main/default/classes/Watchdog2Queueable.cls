/**
 * Created 17.10.2022..
 */

public class Watchdog2Queueable implements Queueable, Database.AllowsCallouts {

    private static IntegrationErrorReporter logger2 = new IntegrationErrorReporter('ExtSync-Inv');

    List<Id> invoices;
    public Watchdog2Queueable(List<Id> invoices) {
        this.invoices = invoices;
    }

    public void execute(QueueableContext context) {
        List<Custom_Invoice__c> invoicesWithoutIDs = [
                SELECT Id
                FROM Custom_Invoice__c
                WHERE Id IN :invoices
        ];
        if (invoicesWithoutIDs.size() > 0) ExternalSyncInvoice.syncInvoices(invoicesWithoutIDs);

        logger2.persistLogs();
    }
}