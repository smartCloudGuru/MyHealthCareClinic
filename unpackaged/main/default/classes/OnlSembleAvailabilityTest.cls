/**
 * Created 29.8.2022..
 */

@IsTest
global class OnlSembleAvailabilityTest {

    @TestSetup
    static void dataSetup() {

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical', IsActive = true);
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 0.5); //1/2 hours
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;


        OperatingHours oh1 = new OperatingHours();
        oh1.Name = 'test Opening Hours';
        insert oh1;

        ServiceTerritory st1 = new ServiceTerritory();
        st1.Name = 'unit test location';
        st1.Heydoc_Id__c = 'test_st_hd_id';
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
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;

        ServiceTerritoryWorkType stwt = new ServiceTerritoryWorkType(ServiceTerritoryId = st1.Id, WorkTypeId = wt1.Id);
        insert stwt;
    }

    @IsTest
    static void classDateTimeRange_Test() {

        OnlSembleAvailability.DateTimeRange drt = new OnlSembleAvailability.DateTimeRange(Datetime.now(), Datetime.now().addDays(1));

        System.assert(false == drt.hasResources());

        drt.addResourceAtLocation('rid','lid');

        System.assert(true == drt.hasResources());

        System.assert(true == drt.isInsideRange(Datetime.now().addDays(-1), Datetime.now().addDays(2)));

        System.assert(false == drt.isInsideRange(Datetime.now().addDays(-2), Datetime.now().addDays(-1)));

    }

    @IsTest
    static void getIntervalForSchedulingPolicy_Test() {

    }

    @IsTest
    static void getAvailability_Test() {

        Id workTypeId = [SELECT Id FROM WorkType LIMIT 1].Id;

        List<Id> serviceResourceIds = new List<Id>();
        serviceResourceIds.add([SELECT Id FROM ServiceResource LIMIT 1].Id);

        ServiceTerritoryMember stm = new ServiceTerritoryMember();
        stm.ServiceTerritoryId = [SELECT ID FROM ServiceTerritory LImit 1].Id;
        stm.ServiceResourceId = serviceResourceIds[0];
        stm.EffectiveStartDate = Date.today().addYears(-1);
        insert stm;

        Test.setMock(HttpCalloutMock.class, new Test_SembleMock());

        Test.startTest();
        OnlSembleAvailability.getAvailability(
                workTypeId,
                null,
                serviceResourceIds,
                Datetime.now(),
                Datetime.now().addDays(1)
                );
        Test.stopTest();
    }

    global class MockConfig {
        public String body ;
        public String status ;
        public Integer code ;
        public Boolean throwException;

        public MockConfig(
                String body,
                String status,
                Integer code,
                Boolean throwException
        ) {
            this.body = body;
            this.status = status;
            this.code = code;
            this.throwException = throwException;
        }
    }

    global class Test_SembleMock implements HttpCalloutMock {

        public Map<String, MockConfig> mockConfigs;

        global Test_SembleMock()
        {
            String SEMBLE_LOGIN_RESPONSE = '{"data": { "signIn": { "token": "TOKEN_ID" }}}';
            String SEMBLE_AVAIL_RESPONSE = '{"data": {"availabilities": {"data": [{"start":"2022-01-01T09:00:00.000Z","end":"2122-08-30T15:00:00.000Z"}]}}}';

            this.mockConfigs = new Map<String, MockConfig>{
                    'query availabilities' => new MockConfig(SEMBLE_AVAIL_RESPONSE, 'OK', 200, false),
                    'signIn' => new MockConfig(SEMBLE_LOGIN_RESPONSE, 'OK', 200, false)
            };

        }
        global Test_SembleMock(Map<String, MockConfig> mockConfigs) {
            this.mockConfigs = mockConfigs;
        }

        global HttpResponse respond(HttpRequest req) {
            for (String str : mockConfigs.keySet()) {
                if (req.getBody().contains(str)) {
                    MockConfig mConfig = mockConfigs.get(str);
                    if (mConfig.throwException) {
                        Integer divideByZero = 2 / 0;
                    }
                    HttpResponse res = new HttpResponse();

                    System.assert(req != null);
                    //			System.assertEquals(method, req.getMethod());
                    res.setBody(mConfig.body);
                    res.setStatusCode(mConfig.code);
                    res.setStatus(mConfig.status);
                    return res;
                }
            }
            return null;

        }
    }
}