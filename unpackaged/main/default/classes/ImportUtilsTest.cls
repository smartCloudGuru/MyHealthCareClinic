/**
 * Created 21.11.2022..
 */

@IsTest
private class ImportUtilsTest {

    @TestSetup
    public static void setUp() {

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st1 = new ServiceTerritory();
        st1.Aerona_Id__c = '238976';
        st1.Aerona_PIN__c = '0000';
        st1.Name = 'ST1';
        st1.OperatingHoursId = oh.Id;
        st1.IsActive = true;
        insert st1;
    }

    @IsTest
    static void testBehavior() {

        AeronaServiceMock.setAsMock();
        Set<String> excluded = new Set<String>();
        excluded.add('0');
        Test.startTest();
        ImportUtils.aerona_importAllClinicians(excluded);
        Test.stopTest();

        Map<String, Asset> a1 = ImportUtils.getCurrentAssetsByName();
        System.assert(a1 != null);
        System.assert(a1.size() > 0);

        Map<String, ServiceResource> s1 = ImportUtils.getCurrentServiceResourcesByName();
        System.assert(s1 != null);
        System.assert(s1.size() > 0);
    }
}