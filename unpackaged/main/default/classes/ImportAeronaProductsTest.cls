/**
 * Created 18.11.2022..
 */

@IsTest
private class ImportAeronaProductsTest {

    @TestSetup
    public static void setUp() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;
    }

    @IsTest
    static void syncProductsFromAerona_test() {

        AeronaServiceMock.setAsMock();
        Test.startTest();
        ImportAeronaProducts.syncProducts(null);
        Test.stopTest();
    }
}