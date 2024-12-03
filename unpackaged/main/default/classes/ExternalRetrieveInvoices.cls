/**
 * Created by Matija on 20.6.2023..
 */

global class ExternalRetrieveInvoices implements Database.AllowsCallouts {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('Ext-RetInv');

    @Future(Callout=true)
    public static void scheduleGetInvoices() {
        getInvoices();
    }

    public static void getInvoices() {

        try {
            //HEYDOC
            HeyDocService.Pagination pagination = new HeyDocService.Pagination();
            pagination.page = 0;
            pagination.pageSize = 200;

            HeyDocService.DateRange dateRange = new HeyDocService.DateRange();
            dateRange.start = Datetime.now().addYears(-1);
            dateRange.end_jsonsafe = Datetime.now().addYears(1);

            HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
            queryOptions.includeDeleted = true;
            queryOptions.updatedAt = new HeyDocService.DateRange();
            queryOptions.updatedAt.start = Datetime.now().addHours(-16); // updated in last 16 hours
            queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);

            Boolean hasMore = true;
            HeyDocService.InvoiceData invoiceData = null;
            List<HeyDocService.Invoice> sembleInvoices = new List<HeyDocService.Invoice>();

            while (hasMore) {
                pagination.page++;
                if (pagination.page >= 99) {
                    logger.addLog(LoggingLevel.ERROR, null, 'Too many invoices to sync from Semble!');
                    break;
                }
                hasMore = false;
                invoiceData = HeyDocService.queryInvoices(dateRange, pagination, queryOptions);

                if (invoiceData != null) {
                    sembleInvoices.addAll(invoiceData.data);
                    hasMore = (invoiceData.pageInfo?.hasMore != null && invoiceData.pageInfo.hasMore);
                }
            }

            // BELOW SPECIFIC FOR PROCESSING OZEMPIC PAYMENTS
            List<HeyDocService.Invoice> ozempicInvoices = new List<HeyDocService.Invoice>();
            Set<String> patientSembleIds = new Set<String>();
            if (sembleInvoices.size() > 0) {
                System.debug('Semble invoices found: ' + sembleInvoices.size());
                logger.addLog(LoggingLevel.INFO, null, 'Semble invoices found: ' + sembleInvoices.size());

                Set<String> ozempicInvoiceIds = new Set<String>();

                for (HeyDocService.Invoice invoice : sembleInvoices) {
                    if (invoice != null) {

                        if (invoice.lineItems != null && !invoice.lineItems.isEmpty()) {
                            for (HeyDocService.LineItem lineItem : invoice.lineItems) {
                                if (lineItem.title.contains('Ozempic') && lineItem.title.contains('supply') && !ozempicInvoiceIds.contains(invoice.invoiceNumber)) {
                                    ozempicInvoices.add(invoice);
                                    ozempicInvoiceIds.add(invoice.invoiceNumber);
                                    patientSembleIds.add(invoice.patientId);
                                    break;
                                }
                            }
                        }
                    }
                }

                if (!ozempicInvoices.isEmpty()) {

                    System.debug('Semble Ozempic Supply invoices found: ' + ozempicInvoices.size());

                    logger.addLog(LoggingLevel.INFO, null, 'Semble Ozempic Supply found: ' + ozempicInvoices.size());

                    //get Treatments for Patients with that semble Id, put them to map
                    List<Treatment__c> existingTreatments = [
                            SELECT
                                    Id, Account__r.HeyDoc_Id__c, Account__c
                            FROM Treatment__c
                            WHERE
                                    Type__c = 'Ozempic'
                                    AND Active__c = TRUE
                                    AND Account__r.HeyDoc_Id__c IN :patientSembleIds
                            ORDER BY CreatedDate ASC
                    ];

                    System.debug('Existing treatments found: ' + existingTreatments.size());
                    logger.addLog(LoggingLevel.INFO, null, 'Existing treatments found: ' + existingTreatments.size());

                    Map<String, Treatment__c> map_semblePatientId_Treatment = new Map<String, Treatment__c>();
                    for (Treatment__c treatment : existingTreatments) {
                        if (treatment?.Account__r?.HeyDoc_Id__c != null) {
                            map_semblePatientId_Treatment.put(treatment.Account__r.HeyDoc_Id__c, treatment);
                        }
                    }

                    List<Treatment_Invoice__c> tInvoices = new List<Treatment_Invoice__c>();
                    for (HeyDocService.Invoice invoice : ozempicInvoices) {
                        if (map_semblePatientId_Treatment.get(invoice.patientId) != null) {
                            Treatment_Invoice__c ti = new Treatment_Invoice__c();
                            ti.Name = 'SEMBLE#' + invoice.invoiceNumber;
                            ti.External_Id__c = 'SEMBLE#' + invoice.id;
                            ti.Total__c = invoice.total;
                            ti.Paid__c = invoice.total - invoice.outstanding;
                            ti.Account__c = map_semblePatientId_Treatment.get(invoice.patientId).Account__c;
                            ti.Treatment__c = map_semblePatientId_Treatment.get(invoice.patientId).Id;
                            ti.Date__c = invoice.date_jsonsafe?.date();
                            tInvoices.add(ti);
                        }
                        else {
                            System.debug(LoggingLevel.WARN, 'no Ozempic Treatment found for Patient by semble Id:' + invoice.patientId);
                            logger.addLog(LoggingLevel.WARN, null, 'no Ozempic Treatment found for Patient by semble Id: ' + existingTreatments.size());
                        }
                    }

                    Schema.SObjectField fexid = Treatment_Invoice__c.Fields.External_Id__c;

                    if (!tInvoices.isEmpty()) {
                        Database.upsert(tInvoices, fexid, false);
                    }


                }
            }
        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to do getInvoices() ' + e.getMessage() + e.getTypeName(), e.getStackTraceString(), null);
        }

        logger.persistLogs();
    }
}