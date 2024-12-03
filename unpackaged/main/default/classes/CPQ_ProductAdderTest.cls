/**
 * Created 3.6.2022..
 */

@IsTest
public class CPQ_ProductAdderTest {

    @TestSetup
    static void dataSetup() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical');
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        Product2 product = new Product2(Name = 'GP 1', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true);

        insert product;

        insert new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product.Id, IsActive = true, UnitPrice = 10);
    }

    @IsTest
    static void addProductToQuoteTest() {
        Opportunity opp = new Opportunity();
        opp.Name = 'TEst';
        opp.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
        opp.StageName = 'Qualification';
        opp.CloseDate = Date.today();
        opp.LeadSource = 'Did Not Obtain';
        opp.Call_Back__c = 'Not a call back';
        opp.Mode__c = 'Form';
        opp.Business_Unit__c = 'GP';
        opp.Online_Mobile__c = 'throwaway';
        opp.Date_Appointment_Made__c = Date.today();
        opp.Appointment_Date__c = Date.today();
        opp.Pricebook2Id = Test.getStandardPricebookId();

        insert opp;

        System.debug('inserted opp ' + opp.Id);


        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__PricebookId__c = Test.getStandardPricebookId();
        quote.SBQQ__PriceBook__c = Test.getStandardPricebookId();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = false;

        insert quote;

        CPQ_ProductAdder.QuoteModel quoteModel = new CPQ_ProductAdder.QuoteModel();
        quoteModel.record = quote;

        String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteModel));
        System.debug('quoteJSON: ' + quoteJSON);

        quoteModel = (CPQ_ProductAdder.QuoteModel) JSON.deserialize(quoteJSON, CPQ_ProductAdder.QuoteModel.class);

        CPQ_ProductAdder.QuoteModel qModel = CPQ_ProductAdder.addProductToQuote(
                quote.Id,
                [SELECT Id FROM Product2 LIMIT 1].Id,
                Test.getStandardPricebookId(),
                'GBP');

        System.debug('qModel after addding: ' + qModel);

        CPQ_ProductAdder.calculateQuote(qModel);

        quote.SBQQ__Primary__c = true;
        update quote;
    }
}