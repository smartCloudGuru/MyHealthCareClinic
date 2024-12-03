/**
 * Created 3.6.2022..
 */

@IsTest
private class ExternalSyncInvoiceTest {

    @IsTest
    static void testBehavior_Heydoc() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        accounts[0].HeyDoc_Id__c = 'test_acc_hd_id';

        update accounts[0];

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st = new ServiceTerritory();
        st.Name = 'unit test location';
        st.Heydoc_Id__c = null;
        st.IsActive = true;
        st.OperatingHoursId = oh.Id;
        insert st;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = accounts[0].Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(sa) == false);

        insert sa;

        Custom_Invoice__c invoice = new Custom_Invoice__c();
        invoice.Service_Appointment__c = sa.Id;

        invoice.Heydoc_Doctor_Id__c = 'test_doc_hd_id';
        invoice.Heydoc_Location_Id__c = 'test_loc_hd_id';

        invoice.Quote_JSON__c = '{"attributes":{"type":"SBQQ__Quote__c","url":"/services/data/v55.0/sobjects/SBQQ__Quote__c/a3m26000000E74fAAC"},"Id":"a3m26000000E74fAAC","SBQQ__NetAmount__c":86.00}';
        invoice.Quote_Lines_JSON__c = '[{"attributes":{"type":"SBQQ__QuoteLine__c","url":"/services/data/v55.0/sobjects/SBQQ__QuoteLine__c/a3i26000000YGXlAAO"},"Id":"a3i26000000YGXlAAO","CreatedDate":"2022-05-02T14:33:11.000+0000","SBQQ__NetTotal__c":86.00}]';

        insert invoice;

        List<Custom_Invoice__c> invoices = new List<Custom_Invoice__c>();
        invoices.add(invoice);

        HeyDocServiceMock.setAsMock();
        Test.startTest();

        ExternalSyncInvoice.syncInvoiceFuture(invoice.Id);
        ExternalSyncInvoice.syncInvoicesFuture('["' + invoice.Id + '"]');
        IntegrationErrorReporter loggerTest = new IntegrationErrorReporter('test');
        ExternalSyncInvoice.syncInvoices(invoices);
        ExternalSyncInvoice.paymentsFromInvoice(invoice);

        Test.stopTest();

        invoice = [SELECT Id, Heydoc_Id__c FROM Custom_Invoice__c LIMIT 1];
        System.assert(invoice.Heydoc_Id__c != null);

    }

    @IsTest
    static void testBehavior_Aerona() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        accounts[0].Aerona_Id__c = '1000';

        update accounts[0];

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st = new ServiceTerritory();
        st.Name = 'unit test location';
        st.Heydoc_Id__c = null;
        st.Aerona_Id__c = null;
        st.IsActive = true;
        st.OperatingHoursId = oh.Id;
        insert st;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = accounts[0].Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.Aerona_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(sa) == false);

        insert sa;

        Custom_Invoice__c invoice = new Custom_Invoice__c();
        invoice.Service_Appointment__c = sa.Id;

        invoice.Aerona_Doctor_Id__c = '2000';
        invoice.Aerona_Doctor_Id__c = '3000';
        invoice.Amount__c = 175.64;

        invoice.Quote_JSON__c = '{"attributes":{"type":"SBQQ__Quote__c","url":"/services/data/v55.0/sobjects/SBQQ__Quote__c/a3m26000000E74fAAC"},"Id":"a3m26000000E74fAAC","SBQQ__NetAmount__c":86.00}';
        invoice.Quote_Lines_JSON__c = '[{"attributes":{"type":"SBQQ__QuoteLine__c","url":"/services/data/v55.0/sobjects/SBQQ__QuoteLine__c/a3i26000000YGXlAAO"},"Id":"a3i26000000YGXlAAO","CreatedDate":"2022-05-02T14:33:11.000+0000","SBQQ__NetTotal__c":86.00}]';

        insert invoice;

        List<Custom_Invoice__c> invoices = new List<Custom_Invoice__c>();
        invoices.add(invoice);

        AeronaServiceMock.setAsMock();
        Test.startTest();

        ExternalSyncInvoice.syncInvoiceFuture(invoice.Id);
        ExternalSyncInvoice.syncInvoicesFuture('["' + invoice.Id + '"]');
        IntegrationErrorReporter loggerTest = new IntegrationErrorReporter('test');
        ExternalSyncInvoice.syncInvoices(invoices);
        ExternalSyncInvoice.paymentsFromInvoice(invoice);

        Test.stopTest();

        invoice = [SELECT Id, Aerona_Payment_Id__c FROM Custom_Invoice__c LIMIT 1];
        System.debug('Invoice at end of testBehavior_Aerona: ' + JSON.serialize(invoice));
        System.assert(invoice.Aerona_Payment_Id__c != null);

    }

    @IsTest
    static void testWatchdog1() {
        ExternalSyncInvoice.executeWatchdogCheck1();
    }

    @IsTest
    static void testWatchdog2() {
        ExternalSyncInvoice.executeWatchdogCheck2();
    }

}