/**
 * Created 1.6.2022..
 */

public without sharing class ExternalSyncInvoice {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('ExtSync-Inv');

    public static final HeyDoc_Integration_Setting__mdt INTEGRATIONS_SETTINGS = [
            SELECT Payment_Type_Credit_Card__c
            FROM HeyDoc_Integration_Setting__mdt
            LIMIT 1
    ];


    @Future(Callout=true)
    public static void syncInvoicesFuture(String ids) {
        List<Custom_Invoice__c> invoices = new List<Custom_Invoice__c>();
        Set<String> hids = (Set<String>) JSON.deserialize(ids, Set<String>.class);
        for (String id : hids) {
            invoices.add(new Custom_Invoice__c (Id = id));
        }
        syncInvoices(invoices);
    }

    @Future(Callout=true)
    public static void syncInvoiceFuture(String id) {
        List<Custom_Invoice__c> invoices = new List<Custom_Invoice__c>();
        invoices.add(new Custom_Invoice__c (Id = id));
        syncInvoices(invoices);
    }

    public static void executeWatchdogCheck1() {
        Datetime dtFrom = Datetime.now().addHours(-24 * 5);
        Datetime dtTo = Datetime.now().addMinutes(-20);

        List <ServiceAppointment> apps = [
                SELECT
                        Id,
                        CreatedDate,
                        Description,
                        Treatment__r.Name,
                        Treatment__c,
                        Treatment__r.SBQQ__PrimaryQuote__c,
                        Treatment__r.Custom_Invoice__c,
                        (SELECT Id FROM Custom_Invoices__r)
                FROM ServiceAppointment
                WHERE
                        CreatedDate > :dtFrom
                        AND CreatedDate < :dtTo
                        AND (NOT Treatment__r.Name LIKE 'RESERV%')
                        AND ((Heydoc_Appointment_Id__c <> '') OR (Aerona_Id__c <> ''))
                ORDER BY CreatedDate ASC
        ];

        List <ServiceAppointment> stucks = new List<ServiceAppointment>();

        Set<Id> potentialOtherTreatments = new Set<Id>();

        for (ServiceAppointment app : apps) {
            if (app.Treatment__c == null) continue;
            if (app.Custom_Invoices__r.size() > 0) continue;
            if (app.Treatment__r.Custom_Invoice__c != null) continue;
            if (app.Description=='ignore') continue;

            //appointment store
            if (app.Treatment__r.SBQQ__PrimaryQuote__c != null) {
                System.debug('no invoice for ' + app.Id);
                logger.addLog(LoggingLevel.WARN, app.Id, 'missing invoice for appointment');
                stucks.add(app);
            }
            else {
                potentialOtherTreatments.add(app.Id);
                logger.addLog(LoggingLevel.WARN, app.Id, 'missing invoice for Treatment');
            }
        }

        System.debug('::watchdog:invoice:stucks:' + stucks.size());

        if (stucks.size() > 0) {
            List<OnlBookUI.InvoiceResponseWrapper> invoiceWrappers = new List<OnlBookUI.InvoiceResponseWrapper>();
            for (ServiceAppointment app : stucks) {
                try {
                    //NOTE: THIS WILL DO UPDATE INVOICES, so we must return ofter this
                    invoiceWrappers.add(OnlBookUI.createInvoice(app.Treatment__c, app.Treatment__r.SBQQ__PrimaryQuote__c));
                }
                catch (Exception ex) {
                    logger.addLog(LoggingLevel.ERROR, app.Id, 'failed creating invoice for app', null, ex.getMessage());
                }
            }
        }

    }

    public static void executeWatchdogCheck2() {
        Datetime dtFrom = Datetime.now().addHours(-24 * 5);
        Datetime dtTo = Datetime.now().addMinutes(-14);

        List<Custom_Invoice__c> invoicesWithoutIDs = [
                SELECT Id
                FROM Custom_Invoice__c
                WHERE
                (
                        ((Heydoc_Doctor_Id__c <> '') AND (Heydoc_Id__c = ''))
                )
                AND CreatedDate > :dtFrom
                AND CreatedDate < :dtTo
                AND Service_Appointment__c <> ''
                AND Service_Appointment__r.Treatment__c <> ''
                AND Service_Appointment__r.Status <> 'Canceled'
        ];

        List<Custom_Invoice__c> aeronaInvoicesVWithoutIds = [
                SELECT Id
                FROM Custom_Invoice__c
                WHERE Aerona_Payment_Id__c = NULL
                AND CreatedDate > :dtFrom
                AND CreatedDate < :dtTo
                AND Service_Appointment__r.Aerona_Id__c != NULL
                AND Amount__c > 0
                AND Service_Appointment__r.Status <> 'Canceled'
        ];

        System.debug('::watchdog:invoice: Semble stucks without ids:' + invoicesWithoutIDs.size());
        System.debug('::watchdog:invoice: Aerona stucks without ids:' + aeronaInvoicesVWithoutIds.size());

        List<Id> ids = new List<Id>();
        for (Custom_Invoice__c customInvoice : invoicesWithoutIDs) {
            ids.add(customInvoice.Id);
        }

        for (Custom_Invoice__c customInvoice : aeronaInvoicesVWithoutIds) {
            ids.add(customInvoice.Id);
        }

        if (!ids.isEmpty()) {
            Watchdog2Queueable wd2q = new Watchdog2Queueable(ids);
            System.enqueueJob(wd2q);
        }

    }


    @InvocableMethod(Category='Custom Invoice' Label='External Sync - sync Invoices' Description='Sync invoices to external systems(s)')
    public static void syncInvoices(List<Custom_Invoice__c> invoices) {

        if (invoices == null) return;
        if (invoices.isEmpty()) return;

        Set<String> invoiceIds = new Set<String>();
        for (Custom_Invoice__c invoice : invoices) {
            //logger.addLog(LoggingLevel.INFO, invoice.Id, 'processing sync for invoice');
            // add ids to list so we can batch select
            invoiceIds.add(invoice.Id);
        }

        invoices = [
                SELECT
                        Id,
                        CreatedDate,
                        Heydoc_Doctor_Id__c,
                        Aerona_Doctor_Id__c,
                        Heydoc_Location_Id__c,
                        Aerona_Location_Id__c,
                        Aerona_Item_Id__c,
                        Service_Appointment__c,
                        Service_Appointment__r.Account.HeyDoc_Id__c,
                        Service_Appointment__r.Account.Aerona_Id__c,
                        Service_Appointment__r.AppointmentNumber,
                        Service_Appointment__r.Heydoc_Appointment_Id__c,
                        Service_Appointment__r.Aerona_Id__c,
                        Service_Appointment__r.Treatment__c,
                        Service_Appointment__r.Treatment__r.StageName,
                        Service_Appointment__r.Treatment__r.Name,
                        Service_Appointment__r.Treatment__r.CloseDate,
                        Service_Appointment__r.Treatment__r.Amount,
                        Service_Appointment__r.Opportunity_Product__r.Product2.Work_Type_Group__r.Aerona_Id__c,
                        Quote_Lines_JSON__c,
                        Quote_JSON__c,
                        Amount__c,
                        (SELECT Id, Name, Account.HeyDoc_Id__c, Account.Aerona_Id__c, Amount FROM Treatments__r)
                FROM Custom_Invoice__c
                WHERE Id IN :invoiceIds
        ];

        Set<String> oppIds = new Set<String>();
        for (Custom_Invoice__c customInvoice : invoices) {
            if (customInvoice?.Service_Appointment__r?.Treatment__c != null) oppIds.add(customInvoice.Service_Appointment__r.Treatment__c);
        }

        // 2023-03-23 adding stripe txid to payment note
        //        List<bt_stripe__Transaction__c> transactions = [SELECT Id, Opportunity__c, bt_stripe__Amount__c, bt_stripe__Transaction_Id__c FROM bt_stripe__Transaction__c WHERE Opportunity__c IN :oppIds];
        //
        //        Map<String, bt_stripe__Transaction__c> map_oppId_tx = new Map<String, bt_stripe__Transaction__c>();
        //        for (bt_stripe__Transaction__c tx : transactions) {
        //            map_oppId_tx.put(tx.Opportunity__c, tx);
        //        }

        List<Custom_Invoice__c> invoicesToUpdate = new List<Custom_Invoice__c>();

        //check if we have any aerona invoices to send, as these require a special callout for saleitemIds
        Boolean hasAeronaInvoices = false;
        if (!invoices.isEmpty()) {
            //iter invoices
            for (Custom_Invoice__c invoice : invoices) {
                if (invoice == null) continue;
                if (invoice.Aerona_Doctor_Id__c != null) {
                    hasAeronaInvoices = true;
                    break;
                }
            }
        }

        Map<String, String> map_aeronaProductId_salesItemId = new Map<String, String>();
        if (hasAeronaInvoices) {
            List<AeronaServiceOASApi.OASAPIAppointmentType> appTypes = AeronaService.getAppointmentTypes();
            for (AeronaServiceOASApi.OASAPIAppointmentType appType : appTypes) {
                map_aeronaProductId_salesItemId.put('' + appType.id, '' + appType.saleItemId);
            }
        }

        if (!invoices.isEmpty()) {

            //iter invoices
            for (Custom_Invoice__c invoice : invoices) {

                if (invoice == null) continue;

                // SEMBLE
                if (invoice.Heydoc_Doctor_Id__c != null) {
                    Custom_Invoice__c sentInvoice = sendInvoiceToSemble(invoice);
                    if (sentInvoice != null) invoicesToUpdate.add(sentInvoice);
                }
                else if (invoice.Aerona_Doctor_Id__c != null) {
                    if (invoice.Aerona_Item_Id__c == null) invoice.Aerona_Item_Id__c = invoice.Service_Appointment__r?.Opportunity_Product__r?.Product2?.Work_Type_Group__r?.Aerona_Id__c;
                    Custom_Invoice__c sentInvoice = sendPaymentToAerona(invoice, map_aeronaProductId_salesItemId.get(invoice.Aerona_Item_Id__c));
                    if (sentInvoice != null) invoicesToUpdate.add(sentInvoice);
                }
            }

            Database.update(invoicesToUpdate, false);
        }
        else {
            System.debug(LoggingLevel.WARN, '::esi:si:invoices empty?');
        }

    }

    public static Custom_Invoice__c sendPaymentToAerona(Custom_Invoice__c invoice, String aeronaSaleItemId) {
        System.debug('::esi:sendPaymentToAerona:invoice:' + invoice.Id);

        //if (opp.Amount==null || opp.Amount==0) return null;

        AeronaServiceOASApi.OASCreatePaymentRequest request_payment = new AeronaServiceOASApi.OASCreatePaymentRequest();
        request_payment.patientId = Long.valueOf(invoice?.Service_Appointment__r?.Account?.Aerona_Id__c);
        request_payment.paymentDate = invoice.CreatedDate;
        if (invoice.Aerona_Location_Id__c != null) request_payment.practiceId = Long.valueOf(invoice.Aerona_Location_Id__c);
        request_payment.paymentTypeId = 1; // hard coded 1 = Payment
        request_payment.paymentMethodId = 10; // payment method hardcoded to 10 = Credit Card - Online ?

        Decimal amount;
        if (invoice?.Service_Appointment__r?.Treatment__r?.Amount != null) {
            amount = invoice?.Service_Appointment__r?.Treatment__r?.Amount;
        }
        else {
            amount = invoice.Amount__c;
        }

        request_payment.amount = '' + amount;
        System.debug('::esi:sendPaymentToAerona:request_payment:' + JSON.serializePretty(request_payment));
        Long result_payment = AeronaService.createPayment(request_payment);
        if (result_payment != null) invoice.Aerona_Payment_Id__c = '' + result_payment;

        return invoice;

    }

    public static Custom_Invoice__c sendInvoiceToSemble(Custom_Invoice__c invoice) {
        HeyDocService.NewInvoiceDataInput invoiceDataInput;
        String patientHeydocId;

        patientHeydocId = invoice?.Service_Appointment__r?.Account?.HeyDoc_Id__c;

        patientHeydocId = invoice.Service_Appointment__r?.Account?.HeyDoc_Id__c;

        if ((Datetime.now().getTime() - invoice.CreatedDate.getTime()) > 1000 * 60 * 4) {
            logger.addLog(LoggingLevel.INFO, invoice.Id, 'WATCHDOG creating invoice on Semble');
        }

        if (validateSyncCanBeDone(invoice)) {
            invoiceDataInput = new HeyDocService.NewInvoiceDataInput();
            invoiceDataInput.date_jsonsafe = invoice.CreatedDate;
            invoiceDataInput.patientId = patientHeydocId;
            invoiceDataInput.doctorId = invoice.Heydoc_Doctor_Id__c;
            invoiceDataInput.locationId = invoice.Heydoc_Location_Id__c;

            invoiceDataInput.extraInfo = 'MHC ' + invoice?.Service_Appointment__r?.Treatment__r?.Name + ' ';

            if (invoice.Service_Appointment__c != null) {
                invoiceDataInput.extraInfo += 'Appointment ' + invoice.Service_Appointment__r?.AppointmentNumber;
            }

            invoiceDataInput.lineItems = quoteLinesToLineItems(invoice);
            if (invoice.Service_Appointment__r?.Treatment__r?.Amount != null &&
                    invoice.Service_Appointment__r.Treatment__r.Amount > 0) {
                invoiceDataInput.payments = paymentsFromInvoice(invoice);
            }

            System.debug('::esi:si:invoiceDataInput:' + JSON.serializePretty(invoiceDataInput));
            HeyDocService.SembleResponseWrapper resp = HeyDocService.createInvoice(invoiceDataInput);
            HeyDocService.Invoice invoiceData = resp?.invoiceData;
            System.debug('::esi:si:invoiceData:' + invoiceData);
            System.debug('::esi:si:sembleResponseBody:' + resp?.sembleResponseBody);
            if (invoiceData != null) {
                invoice.Heydoc_Id__c = invoiceData.id;
                return invoice;
            }
            else {
                logger.addLog(LoggingLevel.ERROR, invoice.Id, 'createInvoice failed (1/2 req)', null, 'SE REQ:' + (invoiceDataInput == null ? 'null' : JSON.serialize(invoiceDataInput)));
                logger.addLog(LoggingLevel.ERROR, invoice.Id, 'createInvoice failed (2/2 resp)', null, 'SE RESP:' + resp?.sembleResponseBody);
            }
        }
        else {
            logger.addLog(LoggingLevel.WARN, invoice.Id, 'sync can not be done, validation returned false');
        }
        return null;
    }

    public static List<HeyDocService.NewInvoicePaymentDataInput> paymentsFromInvoice(Custom_Invoice__c invoice) {
        List<HeyDocService.NewInvoicePaymentDataInput> ret = new List<HeyDocService.NewInvoicePaymentDataInput>();
        HeyDocService.NewInvoicePaymentDataInput payment = new HeyDocService.NewInvoicePaymentDataInput();
        SBQQ__Quote__c quote = (SBQQ__Quote__c) JSON.deserialize(invoice.Quote_JSON__c, SBQQ__Quote__c.class);
        payment.paymentAmount = quote.SBQQ__NetAmount__c;
        payment.paymentTypeId = INTEGRATIONS_SETTINGS.Payment_Type_Credit_Card__c;
        payment.paymentDate = invoice.Service_Appointment__r?.Treatment__r?.CloseDate;
        ret.add(payment);
        return ret;
    }

    public static List<HeyDocService.NewLineItemDataInput> quoteLinesToLineItems(Custom_Invoice__c invoice) {
        List<HeyDocService.NewLineItemDataInput> lineItems = new List<HeyDocService.NewLineItemDataInput>();
        if (invoice.Quote_Lines_JSON__c != null) {
            List<SBQQ__QuoteLine__c> quoteLines = (List<SBQQ__QuoteLine__c>) JSON.deserialize(invoice.Quote_Lines_JSON__c, List<SBQQ__QuoteLine__c>.class);

            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                HeyDocService.NewLineItemDataInput line = new HeyDocService.NewLineItemDataInput();
                line.date_jsonsafe = quoteLine.CreatedDate;
                line.quantity = 1;
                line.referenceId = invoice.Service_Appointment__r?.Heydoc_Appointment_Id__c;
                line.price = quoteLine.SBQQ__NetTotal__c;
                line.productId = quoteLine.SBQQ__Product__r.Work_Type_Group__r.Heydoc_Id__c;
                System.debug('::esi:ql2li:line:' + line);
                lineItems.add(line);
            }
        }
        return lineItems;
    }


    @TestVisible
    private static Boolean validateSyncCanBeDone(Custom_Invoice__c invoice) {

        if (invoice == null) return false;
        if (invoice.Service_Appointment__r == null) {
            logger.addLog(LoggingLevel.WARN, invoice.Service_Appointment__c, 'unable to sync without ServiceAppointment');
            return false;
        }
        if (invoice.Service_Appointment__r.Account == null) {
            logger.addLog(LoggingLevel.WARN, invoice.Service_Appointment__c, 'unable to sync without Account on ServiceAppointment');
            return false;
        }
        if (invoice.Service_Appointment__r.Account.HeyDoc_Id__c == null) {
            logger.addLog(LoggingLevel.WARN, invoice.Service_Appointment__c, 'unable to sync without HeydocPatientId Account on ServiceAppointment');
            return false;
        }
        if (invoice.Heydoc_Doctor_Id__c == null) {
            logger.addLog(LoggingLevel.WARN, invoice.Service_Appointment__c, 'unable to sync without Heydoc_Doctor_Id__c on Invoice');
            return false;
        }
        if (invoice.Heydoc_Location_Id__c == null) {
            logger.addLog(LoggingLevel.WARN, invoice.Service_Appointment__c, 'unable to sync without Heydoc_Location_Id__c on Invoice');
            return false;
        }

        return true;

    }


}