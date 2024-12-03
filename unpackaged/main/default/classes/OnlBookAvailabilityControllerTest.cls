/**
 * Created by Matija on 28.11.2023..
 */

@IsTest
global class OnlBookAvailabilityControllerTest {

    @TestSetup
    static void dataSetup() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';
        update accounts[0];

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical', IsActive = true, Appointment_Type__c = 'CLINIC');
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        Product2 product = new Product2(Name = 'GP 1', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true, Appointment__c = true);
        product.ProductCode = 'T-P-A';
        product.Store_Categories__c = 'GP Consultation';
        product.Business_Unit__c = 'GP';
        insert product;

        insert new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product.Id, IsActive = true, UnitPrice = 10);

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
    static void getAvailableTimeSlots_SF_test() {

        String workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;

        String serviceCenterId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Date slotDate = Date.today();

        List<String> serviceCenterIds = new List<String>();
        serviceCenterIds.add(serviceCenterId);

        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new onl_CheckoutCtrlTest.MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest.onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        Test.startTest();
        String ret = OnlBookAvailabilityController.getAvailableTimeSlots(workTypeGroupId, serviceCenterIds, slotDate, slotDate.addDays(1));
        System.debug('::OBUIT:getAvailableTimeSlots_SF_test:ret:' + ret);
        List<OnlBookDomain.ExtendedTerritorySlot> tsr = (List<OnlBookDomain.ExtendedTerritorySlot>) JSON.deserialize(ret, List<OnlBookDomain.ExtendedTerritorySlot>.class);
        Test.stopTest();

        System.debug('::getAvailableSlotsByWorkTypeGroup:tsr:' + tsr);
    }

    @IsTest
    static void getSchedulingPolicyMinutesForWTG_Test() {
        System.assert(OnlBookAvailabilityController.getSchedulingPolicyMinutesForWTG([SELECT Id FROM WorkTypeGroup LIMIT 1].Id) > 0);
    }

    @IsTest
    static void schedulerPolicyNameIdMap_test() {
        OnlBookAvailabilityController.schedulerPolicyNameIdMap();
    }

    @IsTest
    static void checkForClinicPrioritization_Test() {
        String example = '{\n' +
                '  "territorySlots" : [ {\n' +
                '    "startTime" : "2023-06-07T14:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e000000TNYaCAO" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e000000TNYaCAO" : [ "0Hh8e00000004ioCAA" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-07T14:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-07T15:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-07T15:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-07T15:10:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-07T15:30:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-07T15:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM", "0Hn8e0000008OL4CAM", "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ],\n' +
                '      "0Hn8e0000008OL4CAM" : [ "0Hh4H0000004CZESA2" ],\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-07T15:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-07T15:30:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM", "0Hn8e0000008OL4CAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OL4CAM" : [ "0Hh4H0000004CZESA2" ],\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-07T15:50:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-07T15:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM", "0Hn8e0000008OL4CAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OL4CAM" : [ "0Hh4H0000004CZESA2" ],\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-07T16:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T08:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T08:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T08:30:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T08:50:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T08:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T09:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T08:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T09:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T09:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T09:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T09:10:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T09:30:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T09:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T09:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T09:30:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T09:50:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T09:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T10:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T09:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T10:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T10:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T10:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T10:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM", "0Hn8e000000wkUPCAY" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e000000wkUPCAY" : [ "0Hh4H0000004CZdSAM" ],\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh8e00000004ioCAA" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T11:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T10:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e000000wkUPCAY" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e000000wkUPCAY" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T11:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T11:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e000000wkUPCAY" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e000000wkUPCAY" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T11:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T11:10:00.000Z",\n' +
                '    "resources" : [ "0Hn8e000000wkUPCAY" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e000000wkUPCAY" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T11:30:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T11:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e000000wkUPCAY" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e000000wkUPCAY" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T11:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T12:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKpCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKpCAM" : [ "0Hh4H0000004CZESA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T13:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T13:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2", "0Hn8e0000008OKpCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKpCAM" : [ "0Hh4H0000004CZESA2" ],\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T13:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T13:30:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T13:50:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T13:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T14:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T13:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T14:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T14:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T14:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T14:10:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T14:30:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-08T14:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLACA2" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLACA2" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-08T14:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T09:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T09:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T09:30:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T09:50:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T09:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T10:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T09:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T10:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T10:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T10:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T12:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T13:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T12:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T13:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T13:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T13:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T13:10:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T13:30:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T13:20:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM", "0Hn8e0000008OLsCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OLsCAM" : [ "0Hh4H0000004CZdSAM" ],\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T13:40:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T13:30:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T13:50:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T13:40:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T14:00:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T13:50:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T14:10:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T14:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T14:20:00.000Z"\n' +
                '  }, {\n' +
                '    "startTime" : "2023-06-09T15:00:00.000Z",\n' +
                '    "resources" : [ "0Hn8e0000008OKkCAM" ],\n' +
                '    "resource_locations" : {\n' +
                '      "0Hn8e0000008OKkCAM" : [ "0Hh4H0000004CZFSA2" ]\n' +
                '    },\n' +
                '    "endTime" : "2023-06-09T15:20:00.000Z"\n' +
                '  } ],\n' +
                '  "schedulingPolicyMinutes" : 10\n' +
                '}';

        OnlBookDomain.ExtendedTimeSlotsResponse resp = (OnlBookDomain.ExtendedTimeSlotsResponse) JSON.deserialize(example, OnlBookDomain.ExtendedTimeSlotsResponse.class);
        OnlBookAvailabilityController.checkForClinicPrioritization('0VS8e0000004CsQGAU', resp);
    }

    @IsTest
    static void filterSlotsByDiaryBlockDateRangeAndWTG_Test() {
        String wtgId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        String resId = [SELECT Id FROM ServiceResource LIMIT 1].Id;

        System.debug('::filterSlotsByDiaryBlockDateRangeAndWTG_Test:wtgId' + wtgId);
        System.debug('::filterSlotsByDiaryBlockDateRangeAndWTG_Test:resId' + resId);

        OnlBookDomain.ExtendedTimeSlotsResponse etsr = new OnlBookDomain.ExtendedTimeSlotsResponse();
        OnlBookDomain.ExtendedTimeSlotsResponse etsr2;
        etsr.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

        OnlBookDomain.ExtendedTerritorySlot ts = new OnlBookDomain.ExtendedTerritorySlot();
        ts.startTime = Datetime.now().addHours(5);
        ts.endTime = Datetime.now().addHours(6);
        ts.resources = new List<String>();
        ts.resources.add(resId);

        etsr.territorySlots.add(ts);


        // 1 -test without diary blocks
        System.debug('::testFilter 1');
        etsr2 = OnlBookAvailabilityController.filterSlotsByDiaryBlockDateRangeAndWTG(wtgId, Datetime.now().addDays(-1), Datetime.now().addDays(2), cloneETSR(etsr));

        System.assert(etsr2 != null);
        System.assert(etsr2.territorySlots != null);
        System.assert(etsr2.territorySlots.size() == 1);

        //2 - test with a diary block that blocks the whole resource, but not active
        System.debug('::testFilter 2');
        Diary_Block__c db = new Diary_Block__c();
        db.Is_Active__c = false;
        db.Not_Available_From__c = Datetime.now();
        db.Not_Available_To__c = Datetime.now().addDays(1);
        db.Resource__c = resId;

        insert db;

        Test.startTest();
        etsr2 = OnlBookAvailabilityController.filterSlotsByDiaryBlockDateRangeAndWTG(wtgId, Datetime.now().addDays(-1), Datetime.now().addDays(2), cloneETSR(etsr));

        System.assert(etsr2 != null);
        System.assert(etsr2.territorySlots != null);
        System.assert(etsr2.territorySlots.size() == 1);

        //3 - test with a diary block that blocks the whole resource, this time block is active
        System.debug('::testFilter 3');
        db.Is_Active__c = true;
        update db;

        etsr2 = OnlBookAvailabilityController.filterSlotsByDiaryBlockDateRangeAndWTG(wtgId, Datetime.now().addDays(-1), Datetime.now().addDays(2), cloneETSR(etsr));

        System.assert(etsr2 != null);
        System.assert(etsr2.territorySlots != null);
        System.assert(etsr2.territorySlots.size() == 0);

        //4 - test with a diary block that blocks the whole resource, is active, but allows for this specific work type group id
        System.debug('::testFilter 4');
        db.Do_Not_Block_For__c = wtgId;
        update db;

        etsr2 = OnlBookAvailabilityController.filterSlotsByDiaryBlockDateRangeAndWTG(wtgId, Datetime.now().addDays(-1), Datetime.now().addDays(2), cloneETSR(etsr));

        Test.stopTest();

        System.assert(etsr2 != null);
        System.assert(etsr2.territorySlots != null);
        System.assert(etsr2.territorySlots.size() == 1);
    }

    private static OnlBookDomain.ExtendedTimeSlotsResponse cloneETSR(OnlBookDomain.ExtendedTimeSlotsResponse etsr) {
        return (OnlBookDomain.ExtendedTimeSlotsResponse) JSON.deserialize(JSON.serialize(etsr), OnlBookDomain.ExtendedTimeSlotsResponse.class);
    }

    @IsTest
    static void getServiceCentersForWTG_test() {
        List<ServiceTerritory> sts = OnlBookAvailabilityController.getServiceCentersForWTG([SELECT Id FROM WorkTypeGroup LIMIT 1].Id);
        System.debug((sts.size()));
    }

    @IsTest
    static void test_checkRangesOverlap() {
        // block 1 fully in block 2
        Datetime dt1s = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0));
        Datetime dt1e = Datetime.newInstance(Date.today(), Time.newInstance(8, 20, 0, 0));
        Datetime dt2s = Datetime.newInstance(Date.today(), Time.newInstance(7, 0, 0, 0));
        Datetime dt2e = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == true);

        //block 1 ends in block 2
        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(6, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(8, 20, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(7, 0, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == true);

        //block 1 starts in block 2
        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(7, 0, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == true);

        //block 2 fully in block 1
        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(8, 30, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(9, 30, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == true);

        //block 1 outside block 2, earlier
        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(11, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == false);

        //block 1 after block 2, later

        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(18, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(19, 0, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(11, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == false);

        //block 2 starts right after block 1

        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == false);

        //block 1 starts after block 2

        dt1s = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        dt1e = Datetime.newInstance(Date.today(), Time.newInstance(11, 0, 0, 0));
        dt2s = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        dt2e = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));

        System.assert(OnlBookAvailabilityController.checkRangesOverlap(dt1s, dt1e, dt2s, dt2e) == false);

    }

    @IsTest
    static void getAvailableSlotsByWorkTypeGroup_test() {

        String workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        String serviceCenterId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Date slotDate = Date.today();

        Map<String, MockConfig> mockConfigs = new Map<String, MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };


        Test.setMock(HttpCalloutMock.class, new test_ServiceMock(mockConfigs));

        Test.startTest();
        OnlBookDomain.ExtendedTimeSlotsResponse tsr =
                (OnlBookDomain.ExtendedTimeSlotsResponse)
                        JSON.deserialize(OnlBookAvailabilityController.getAvailableSlots_raw(workTypeGroupId, serviceCenterId, slotDate, slotDate),
                                OnlBookDomain.ExtendedTimeSlotsResponse.class);
        Test.stopTest();
        System.debug('::getAvailableSlots_raw:tsr:' + tsr);
        System.assert(tsr.territorySlots != null);
    }

    @IsTest
    static void filterByOperatingHours_Test() {

        WorkType wt = [SELECT Id FROM WorkType];

        OnlBookDomain.ExtendedTerritorySlot tSlot1 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTerritorySlot tSlot2 = new OnlBookDomain.ExtendedTerritorySlot();

        OnlBookDomain.ExtendedTimeSlotsResponse etsOrig = new OnlBookDomain.ExtendedTimeSlotsResponse();
        List<OnlBookDomain.ExtendedTerritorySlot> tSlots = new List<OnlBookDomain.ExtendedTerritorySlot>();
        tSlots.add(tSlot1);
        tSlots.add(tSlot2);

        tSlot1.startTime = Datetime.newInstance(2023, 5, 5, 12, 0, 0);
        tSlot1.endTime = Datetime.newInstance(2023, 5, 5, 13, 0, 0);
        tSlot2.startTime = Datetime.newInstance(2023, 5, 6, 12, 0, 0);
        tSlot2.endTime = Datetime.newInstance(2023, 5, 6, 13, 0, 0);

        etsOrig.territorySlots = tSlots;
        OnlBookDomain.ExtendedTimeSlotsResponse etsr = OnlBookAvailabilityController.filterByOperatingHours(etsOrig, wt.Id);

        System.assert(etsr?.territorySlots != null);
        System.assert(etsr.territorySlots.size() == etsOrig.territorySlots.size());

        // 1 test operating hours - nothing set in them (no days open)

        OperatingHours oh = [SELECT Id FROM OperatingHours LIMIT 1];
        wt.OperatingHoursId = oh.Id;

        update wt;

        etsr = OnlBookAvailabilityController.filterByOperatingHours(etsOrig, wt.Id);
        System.assert(etsr?.territorySlots != null);
        System.assert(etsr.territorySlots.size() == 0);

        // 2 test operating hours, both days available

        TimeSlot ts1 = new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = tSlot1.startTime?.format('EEEE'),
                StartTime = Time.newInstance(0, 0, 0, 0),
                EndTime = Time.newInstance(23, 0, 0, 0)
        );
        TimeSlot ts2 = new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = tSlot2.startTime?.format('EEEE'),
                StartTime = Time.newInstance(0, 0, 0, 0),
                EndTime = Time.newInstance(23, 0, 0, 0)
        );

        insert ts1;
        insert ts2;

        etsr = OnlBookAvailabilityController.filterByOperatingHours(etsOrig, wt.Id);
        System.assert(etsr?.territorySlots != null);
        System.assert(etsr.territorySlots.size() == etsOrig.territorySlots.size());


        // 2 test available from/to

    }

    @IsTest
    static void filterByOperatingHoursByClinic() {

        WorkType wt = [SELECT Id FROM WorkType];

        OnlBookDomain.ExtendedTerritorySlot tSlot1 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTerritorySlot tSlot2 = new OnlBookDomain.ExtendedTerritorySlot();

        OnlBookDomain.ExtendedTimeSlotsResponse etsOrig = new OnlBookDomain.ExtendedTimeSlotsResponse();
        List<OnlBookDomain.ExtendedTerritorySlot> tSlots = new List<OnlBookDomain.ExtendedTerritorySlot>();
        tSlots.add(tSlot1);
        tSlots.add(tSlot2);

        tSlot1.startTime = Datetime.newInstance(2023, 5, 5, 12, 0, 0);
        tSlot1.endTime = Datetime.newInstance(2023, 5, 5, 13, 0, 0);
        tSlot2.startTime = Datetime.newInstance(2023, 5, 6, 12, 0, 0);
        tSlot2.endTime = Datetime.newInstance(2023, 5, 6, 13, 0, 0);

        tSlot1.resource_locations = new Map<String, Set<String>>();
        Set<String> locations = new Set<String>();
        String locationId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        locations.add(locationId);
        tSlot1.resource_locations.put('someresid', locations);

        tSlot2.resource_locations = tSlot1.resource_locations;


        etsOrig.territorySlots = tSlots;
        OnlBookDomain.ExtendedTimeSlotsResponse etsr = OnlBookAvailabilityController.filterByOperatingHoursByClinic(etsOrig, wt.Id);

        System.assert(etsr?.territorySlots != null);
        System.assert(etsr.territorySlots.size() == etsOrig.territorySlots.size());

        // 1 test operating hours - nothing set in them (no days open)

        OperatingHours oh = [SELECT Id FROM OperatingHours LIMIT 1];
        ServiceTerritoryWorkType serviceTerritoryWorkType = [SELECT Id FROM ServiceTerritoryWorkType WHERE ServiceTerritoryId = :locationId AND WorkTypeId = :wt.Id LIMIT 1];
        serviceTerritoryWorkType.Operating_Hours__c = oh.Id;

        update serviceTerritoryWorkType;

        etsr = OnlBookAvailabilityController.filterByOperatingHours(etsOrig, wt.Id);
        //        System.assert(etsr?.territorySlots != null);
        //        System.assert(etsr.territorySlots.size() == 0);
        //
        // 2 test operating hours, both days available

        TimeSlot ts1 = new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = tSlot1.startTime?.format('EEEE'),
                StartTime = Time.newInstance(0, 0, 0, 0),
                EndTime = Time.newInstance(23, 0, 0, 0)
        );
        TimeSlot ts2 = new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = tSlot2.startTime?.format('EEEE'),
                StartTime = Time.newInstance(0, 0, 0, 0),
                EndTime = Time.newInstance(23, 0, 0, 0)
        );

        insert ts1;
        insert ts2;

        etsr = OnlBookAvailabilityController.filterByOperatingHours(etsOrig, wt.Id);
        //        System.assert(etsr?.territorySlots != null);
        //        System.assert(etsr.territorySlots.size() == etsOrig.territorySlots.size());
        //
        //
        //        // 2 test available from/to

    }

    @IsTest
    static void checkForSkillPrioritization_Test() {
        OnlBookDomain.ExtendedTerritorySlot tSlot1 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTimeSlotsResponse etsOrig = new OnlBookDomain.ExtendedTimeSlotsResponse();
        List<OnlBookDomain.ExtendedTerritorySlot> tSlots = new List<OnlBookDomain.ExtendedTerritorySlot>();
        tSlots.add(tSlot1);

        tSlot1.startTime = Datetime.newInstance(2023, 5, 5, 12, 0, 0); //friday
        tSlot1.endTime = Datetime.newInstance(2023, 5, 5, 13, 0, 0);

        etsOrig.territorySlots = tSlots;

        Skill skillHCA = [SELECT Id FROM Skill WHERE DeveloperName = 'HCA' LIMIT 1];
        Skill skillNurse = [SELECT Id FROM Skill WHERE DeveloperName = 'Nurse' LIMIT 1];
        Skill skillGP = [SELECT Id FROM Skill WHERE DeveloperName = 'GP' LIMIT 1];

        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];

        SkillRequirement skillRequirementGP = new SkillRequirement(RelatedRecordId = wt.Id, SkillId = skillGP.Id);
        SkillRequirement skillRequirementNurse = new SkillRequirement(RelatedRecordId = wt.Id, SkillId = skillNurse.Id);
        SkillRequirement skillRequirementHCA = new SkillRequirement(RelatedRecordId = wt.Id, SkillId = skillHCA.Id);

        insert skillRequirementGP;
        insert skillRequirementNurse;
        insert skillRequirementHCA;

        System.debug('::skill filter TEST 0');
        OnlBookDomain.ExtendedTimeSlotsResponse resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);

        Asset assetHCA = new Asset(Name = 'AHCA');
        insert assetHCA;
        Asset assetNurse = new Asset(Name = 'ANurse');
        insert assetNurse;
        Asset assetGP = new Asset(Name = 'AGP');
        insert assetGP;

        ServiceResource srHca = new ServiceResource();
        srHca.Name = 'SR_HCA';
        srHca.IsActive = true;
        srHca.ResourceType = 'S';
        srHca.AssetId = assetHCA.Id;
        srHca.Heydoc_Id__c = 'mock_hd_sr_id';
        insert srHca;

        ServiceResource srNurse = new ServiceResource();
        srNurse.Name = 'SR_Nurse';
        srNurse.IsActive = true;
        srNurse.ResourceType = 'S';
        srNurse.AssetId = assetNurse.Id;
        srNurse.Heydoc_Id__c = 'mock_hd_sr_id';
        insert srNurse;

        ServiceResource srGP = new ServiceResource();
        srGP.Name = 'SR_GP';
        srGP.IsActive = true;
        srGP.ResourceType = 'S';
        srGP.AssetId = assetGP.Id;
        srGP.Heydoc_Id__c = 'mock_hd_sr_id';
        insert srGP;


        ServiceResourceSkill srsHca = new ServiceResourceSkill(ServiceResourceId = srHca.Id, SkillId = skillHCA.Id, EffectiveStartDate = Date.today().addYears(-1));
        ServiceResourceSkill srsNurse = new ServiceResourceSkill(ServiceResourceId = srNurse.Id, SkillId = skillNurse.Id, EffectiveStartDate = Date.today().addYears(-1));
        ServiceResourceSkill srsGP = new ServiceResourceSkill(ServiceResourceId = srGP.Id, SkillId = skillGP.Id, EffectiveStartDate = Date.today().addYears(-1));
        insert srsHca;
        insert srsNurse;
        insert srsGP;


        // test only HCA on Friday
        System.debug('::skill filter TEST 1');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srHca.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);
        System.assert(resp2.territorySlots[0].resources != null);
        System.assert(resp2.territorySlots[0].resources.size() == 1);
        System.assert(resp2.territorySlots[0].resources[0] == srHca.Id);


        // test HCA and Nurse on Friday - must return only HCA
        System.debug('::skill filter TEST 2');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srNurse.Id);
        etsOrig.territorySlots[0].resources.add(srHca.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);
        System.assert(resp2.territorySlots[0].resources != null);
        System.assert(resp2.territorySlots[0].resources.size() == 1);
        System.assert(resp2.territorySlots[0].resources[0] == srHca.Id);

        // test HCA and Nurse and GP on Friday - must return only HCA
        System.debug('::skill filter TEST 3');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srGP.Id);
        etsOrig.territorySlots[0].resources.add(srNurse.Id);
        etsOrig.territorySlots[0].resources.add(srHca.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);
        System.assert(resp2.territorySlots[0].resources != null);
        System.assert(resp2.territorySlots[0].resources.size() == 1);
        System.assert(resp2.territorySlots[0].resources[0] == srHca.Id);

        // test Nurse and GP on Friday - must return only Nurse
        System.debug('::skill filter TEST 4');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srGP.Id);
        etsOrig.territorySlots[0].resources.add(srNurse.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);
        System.assert(resp2.territorySlots[0].resources != null);
        System.assert(resp2.territorySlots[0].resources.size() == 1);
        System.assert(resp2.territorySlots[0].resources[0] == srNurse.Id);

        // test GP on Friday - must return only GP
        System.debug('::skill filter TEST 5');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srGP.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);
        System.assert(resp2.territorySlots[0].resources != null);
        System.assert(resp2.territorySlots[0].resources.size() == 1);
        System.assert(resp2.territorySlots[0].resources[0] == srGP.Id);

        // test GP on Saturday - must not return timeslot
        etsOrig.territorySlots[0].startTime = Datetime.newInstance(2023, 5, 6, 12, 0, 0); //saturday
        etsOrig.territorySlots[0].endTime = Datetime.newInstance(2023, 5, 6, 13, 0, 0);
        System.debug('::skill filter TEST 6');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srGP.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 0);

        // test GP on Saturday when it's only done by GP - should return  slot
        delete skillRequirementHCA;
        delete skillRequirementNurse;
        etsOrig.territorySlots[0].startTime = Datetime.newInstance(2023, 5, 6, 12, 0, 0); //saturday
        etsOrig.territorySlots[0].endTime = Datetime.newInstance(2023, 5, 6, 13, 0, 0);
        System.debug('::skill filter TEST 7');
        etsOrig.territorySlots[0].resources = new List<String>();
        etsOrig.territorySlots[0].resources.add(srGP.Id);
        resp2 = OnlBookAvailabilityController.checkForSkillPrioritization(etsOrig, wt.Id);

        System.assert(resp2.territorySlots != null);
        System.assert(resp2.territorySlots.size() == 1);
        System.assert(resp2.territorySlots[0].resources != null);
        System.assert(resp2.territorySlots[0].resources.size() == 1);
        System.assert(resp2.territorySlots[0].resources[0] == srGP.Id);


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
    global class test_ServiceMock implements HttpCalloutMock {

        public Map<String, MockConfig> mockConfigs;

        global test_ServiceMock(Map<String, MockConfig> mockConfigs) {
            this.mockConfigs = mockConfigs;
        }

        global HttpResponse respond(HttpRequest req) {
            for (String str : mockConfigs.keySet()) {
                if (req.getEndpoint().contains(str)) {
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