/**
 * Created by Matija on 4.9.2023..
 */

@IsTest
private class AppIntegrationControllerTest {
    @IsTest
    static void aeronaGetAllClinicians_test() {
        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st1 = new ServiceTerritory(IsActive= true, Name = 'ST1', Aerona_PIN__c = '1111', Aerona_Id__c = '1112');
        st1.OperatingHoursId = oh.Id;
        ServiceTerritory st2 = new ServiceTerritory(IsActive= true, Name = 'ST1', Aerona_PIN__c = '2111', Aerona_Id__c = '2112');
        st2.OperatingHoursId = oh.Id;
        insert st1;
        insert st2;
        AeronaServiceMock.setAsMock();
        Test.startTest();
        String ret  = AppIntegrationController.aeronaGetAllClinicians();
        Test.stopTest();
        System.debug(ret);
    }
}