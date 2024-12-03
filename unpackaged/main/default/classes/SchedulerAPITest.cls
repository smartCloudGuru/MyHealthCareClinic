/**
* @author Zoran Zunko
* @date 3/15/21
*
*/
@IsTest global class SchedulerAPITest {

    @IsTest static void test_getTerritoriesURL() {
        SchedulerAPI scheduler = new SchedulerAPI('');

        SchedulerAPI.GetServiceTerritoriesRequest serviceTerritoriesRequest = new SchedulerAPI.GetServiceTerritoriesRequest(
                //get the workTypeGroup from available products, the products should all point to the same work type group id
                '12312312',
                //get ge0coded postal key
                System.Location.newInstance(51.464845307901356, -0.18559826695977732),
                '10'
        );

        System.assertEquals('mi', serviceTerritoriesRequest.radiusUnit);
        System.assertEquals('Distance', serviceTerritoriesRequest.sortBy);
        System.assertEquals('asc', serviceTerritoriesRequest.sortOrder);

        System.assertEquals('/services/data/v51.0/connect' +
                '/scheduling/service-territories?' +
                'workTypeGroupId=12312312&' +
                'latitude=51.464845307901356&' +
                'longitude=-0.18559826695977732&' +
                'radius=10&' +
                'radiusUnit=mi&' +
                'sortBy=Distance&' +
                'sortOrder=asc',
                scheduler.getTerritoriesURL(serviceTerritoriesRequest));
    }

    @IsTest static void test_getTerritorySlotsURL() {
        SchedulerAPI scheduler = new SchedulerAPI('');

        System.assertEquals('/services/data/v51.0/connect/scheduling/available-territory-slots',
                scheduler.getTerritorySlotsURL());
    }

    @IsTest static void test_ctors() {
        SchedulerAPI.ServiceTerritoriesListResult serviceTerritoriesList = new SchedulerAPI.ServiceTerritoriesListResult();
        System.assert(serviceTerritoriesList.serviceTerritories != null);

        SchedulerAPI.AvailableTerritorySlotsList territorySlotsList = new SchedulerAPI.AvailableTerritorySlotsList();
        System.assert(territorySlotsList.territorySlots != null);

        SchedulerAPI.AvailableTerritorySlots availableTerritorySlots = new SchedulerAPI.AvailableTerritorySlots();
        System.assert(availableTerritorySlots.slots != null);

        SchedulerAPI.TerritorySlot territorySlot = new SchedulerAPI.TerritorySlot();
        System.assert(territorySlot.resources != null);

        SchedulerAPI.AvailableTerritorySlotsRequest availableTerritorySlotsReq = new SchedulerAPI.AvailableTerritorySlotsRequest();
        System.assert(availableTerritorySlotsReq.territoryIds != null);
        System.assert(availableTerritorySlotsReq.requiredResourceIds != null);
        System.assert(availableTerritorySlotsReq.filterByResources != null);
        System.assert(!availableTerritorySlotsReq.allowConcurrentScheduling);

        SchedulerAPI.ServiceAppointmentRequest serviceAppointmentReq = new SchedulerAPI.ServiceAppointmentRequest();
        System.assert(serviceAppointmentReq.serviceAppointment != null);
        System.assert(serviceAppointmentReq.assignedResources != null);
    }

    @IsTest static void test_getServiceAppointmentsURL() {
        SchedulerAPI scheduler = new SchedulerAPI('');

        System.assertEquals('/services/data/v51.0/connect/scheduling/service-appointments',
                scheduler.getServiceAppointmentsURL());
    }

    @IsTest static void test_getHTTPRequest() {
        SchedulerAPI scheduler = new SchedulerAPI('');
        HttpRequest request = scheduler.getHTTPRequest('/services/data/v51.0/connect/scheduling/service-appointments',
                '12312', 'GET');

        System.assertEquals(request.getHeader('Authorization'), 'OAuth 12312');
        System.assertEquals(request.getMethod(), 'GET');
    }

    @IsTest static void test_getServiceTerritories() {
        SchedulerAPI scheduler = new SchedulerAPI('');

        SchedulerAPI.GetServiceTerritoriesRequest serviceTerritoriesRequest = new SchedulerAPI.GetServiceTerritoriesRequest(
                //get the workTypeGroup from available products, the products should all point to the same work type group id
                '12312312',
                //get ge0coded postal key
                System.Location.newInstance(51.464845307901356, -0.18559826695977732),
                '10'
        );


        Test.setMock(HttpCalloutMock.class, new Scehduler_ServiceMock(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 200, 'Created', 'GET'));

        Test.startTest();
        SchedulerAPI.ServiceTerritoriesOutput territoriesOutput = scheduler.getServiceTerritories('12345', serviceTerritoriesRequest);
        Test.stopTest();

        System.assert(territoriesOutput.result != null);
        System.assertEquals(4, territoriesOutput.result.serviceTerritories.size());
    }

    @IsTest static void test_getAvailableTerritorySlots() {
        SchedulerAPI scheduler = new SchedulerAPI('');

        SchedulerAPI.AvailableTerritorySlotsRequest territorySlotsRequest = new SchedulerAPI.AvailableTerritorySlotsRequest();
        territorySlotsRequest.startTime = Datetime.now();
        territorySlotsRequest.requiredResourceIds = null;
        territorySlotsRequest.workTypeGroupId = '12312312312';
        territorySlotsRequest.endTime = territorySlotsRequest.startTime.addDays(1);
        territorySlotsRequest.territoryIds.addAll(new List<String> {'12312312', '112312312'});


        Test.setMock(HttpCalloutMock.class, new Scehduler_ServiceMock(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 201, 'Created', 'POST'));

        Test.startTest();
        SchedulerAPI.AvailableTerritorySlotsOutput availableTerritorySlots = scheduler.getAvailableTerritorySlots('12345', territorySlotsRequest);
        Test.stopTest();

        System.assert(availableTerritorySlots.result != null);
        System.assertEquals(4, availableTerritorySlots.result.territorySlots.size());
    }


    @IsTest static void test_bookAppointment() {
        SchedulerAPI scheduler = new SchedulerAPI('');

        SchedulerAPI.ServiceAppointmentRequest appointmentRequest = new SchedulerAPI.ServiceAppointmentRequest();
        appointmentRequest.serviceAppointment.parentRecordId = 'parentRecordId';
        appointmentRequest.serviceAppointment.workTypeId = 'workTypeId';
        appointmentRequest.serviceAppointment.serviceTerritoryId = 'serviceTerritoryId';
        appointmentRequest.serviceAppointment.schedStartTime = 'startTime';
        appointmentRequest.serviceAppointment.schedEndTime = 'endTime';

        SchedulerAPI.AssignedResourceInput assignedResource = new SchedulerAPI.AssignedResourceInput();
        assignedResource.isPrimaryResource = true;
        assignedResource.isRequiredResource = true;
        assignedResource.serviceResourceId = 'serviceResourceId';
        appointmentRequest.assignedResources.add(assignedResource);


        Test.setMock(HttpCalloutMock.class, new Scehduler_ServiceMock(TestDataFactory.BOOK_APPOINTMENT_RESPONSE, 201, 'Created', 'POST'));

        Test.startTest();
        SchedulerAPI.ServiceAppointmentOutput serviceAppointment = scheduler.bookAppointment('12345', appointmentRequest);
        Test.stopTest();

        System.assert(serviceAppointment.result != null);
        System.assertEquals('08p3H000000ASeQQAW', serviceAppointment.result.serviceAppointmentId);
    }

    global class Scehduler_ServiceMock implements HttpCalloutMock {

        public String body { get; private set; }
        public String method { get; private set; }
        public String status { get; private set; }
        public Integer code { get; private set; }
        public Boolean throwException { get; private set; }

        global Scehduler_ServiceMock(String body, Integer code, String status, String method) {
            this(body, code, status, method, false);
        }
        global Scehduler_ServiceMock(String body, Integer code, String status, String method, Boolean throwException) {
            this.body = body;
            this.code = code;
            this.method = method;
            this.status = status;
            this.throwException = throwException;
        }

        global HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (throwException) {
                Integer divideByZero = 2 / 0;
            }
            System.assert(req != null);
//			System.assertEquals(method, req.getMethod());
            res.setBody(body);
            res.setStatusCode(code);
            res.setStatus(status);
            return res;
        }
    }

}