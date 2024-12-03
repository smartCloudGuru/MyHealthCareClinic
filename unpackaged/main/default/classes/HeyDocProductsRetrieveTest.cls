/**
 * Created 15.6.2022..
 */

@IsTest
private class HeyDocProductsRetrieveTest {

    @TestSetup
    public static void setUp() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;
    }

    @IsTest
    static void syncProductsFromHeydoc_test() {

        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeydocProductsRetrieve.syncProductsFromHeydoc(null);
        Test.stopTest();
    }
}