/**
 * Created 25.10.2022..
 */

@IsTest
global class OnlAeronaAvailabilityTest {

    @TestSetup
    static void dataSetup() {

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Aerona_Id__c = '101', Service_Type__c = 'Dental', IsActive = true);
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        OperatingHours oh1 = new OperatingHours();
        oh1.Name = 'test Opening Hours';
        insert oh1;

        ServiceTerritory st1 = new ServiceTerritory();
        st1.Name = 'unit test location';
        st1.Aerona_Id__c = '202';
        st1.IsActive = true;
        st1.OperatingHoursId = oh1.Id;
        insert st1;

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        insert sr1;

        ServiceTerritoryWorkType stwt = new ServiceTerritoryWorkType(ServiceTerritoryId = st1.Id, WorkTypeId = wt1.Id);
        insert stwt;

        ServiceTerritoryMember stm = new ServiceTerritoryMember();
        stm.ServiceResourceId = sr1.Id;
        stm.ServiceTerritoryId = st1.Id;
        stm.Aerona_Clinician_Id__c = '1555';
        stm.EffectiveStartDate = Datetime.now().addDays(-1);
        insert stm;
    }

    @IsTest
    static void getAvailability_test() {
        AeronaService.FORCE_ENABLED = true;
        Id workTypeId = [SELECT Id FROM WorkType LIMIT 1].Id;
        List<Id> serviceTerritoryIds = null;
        List<Id> serviceResourceIds = null;
        Datetime fromDate = Date.today();
        Datetime toDate = Date.today();

        AeronaServiceMock.setAsMock();

        Test.startTest();
        OnlBookDomain.ExtendedTimeSlotsResponse ret = OnlAeronaAvailability.getAvailability(
                workTypeId, serviceTerritoryIds, serviceResourceIds, fromDate, toDate
        );
        Test.stopTest();
    }
}