/**
 * Wrapper class for all the Lightning Scheduler API
 * <p>
 *     Please check the following resources:
 *     <ul>
 *         <li>https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_lightning_scheduler.htm</li>
 *         <li>https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_ls_intro.htm</li>
 *     </ul>
 * </p>
* @author Zoran Zunko
* @date 3/11/21
*
*/
public class SchedulerAPI {
    @TestVisible
    final static String connectUrl = '/services/data/v51.0/connect';

    @TestVisible
    final static String territoriesURL = '/scheduling/service-territories?workTypeGroupId={0}&latitude={1}&longitude={2}&radius={3}&radiusUnit={4}&sortBy={5}&sortOrder={6}';
    @TestVisible String getTerritoriesURL(GetServiceTerritoriesRequest territoriesRequest) {
        return salesforceBaseURL + connectUrl + String.format(
                territoriesURL,
                new List<String>{
                        territoriesRequest.workTypeGroupId,
                        territoriesRequest.radiusLocation.Latitude + '',
                        territoriesRequest.radiusLocation.Longitude + '',
                        territoriesRequest.radius,
                        territoriesRequest.radiusUnit,
                        territoriesRequest.sortBy,
                        territoriesRequest.sortOrder
                });
    }

    @TestVisible
    String territorySlotsURL = '/scheduling/available-territory-slots';
    @TestVisible String getTerritorySlotsURL() {
        return salesforceBaseURL + connectUrl + territorySlotsURL;
    }

    @TestVisible
    String serviceAppointmentsURL = '/scheduling/service-appointments';
    @TestVisible String getServiceAppointmentsURL() {
        return salesforceBaseURL + connectUrl + serviceAppointmentsURL;
    }

    @TestVisible
    String salesforceBaseURL;

    //region Inner classes
    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_service_territories_output.htm
     */
    public class ServiceTerritoriesOutput {
        public ServiceTerritoriesListResult result;

        public ServiceTerritoriesOutput() {
            result = new ServiceTerritoriesListResult();
        }
    }
    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_service_territories_list_result.htm
     */
    public class ServiceTerritoriesListResult {
        public List<ServiceTerritoriesResult> serviceTerritories;

        public ServiceTerritoriesListResult() {
            this.serviceTerritories = new List<ServiceTerritoriesResult>();
        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_service_territories_result.htm
     */
    public class ServiceTerritoriesResult {
        public String city;
        public String country;
        public String id;
        public Decimal latitude;
        public Decimal longitude;
        public String name;
        public String operatingHoursId;
        public String postalCode;
        public String state;
        public String street;
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_available_territory_slots_output.htm
     */
    public class AvailableTerritorySlotsOutput {
        public AvailableTerritorySlotsList result;
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_available_territory_slots_list.htm
     */
    public class AvailableTerritorySlotsList {
        public List<AvailableTerritorySlots> territorySlots;

        public AvailableTerritorySlotsList() {
            this.territorySlots = new List<AvailableTerritorySlots>();
        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_available_territory_slots.htm
     */
    public class AvailableTerritorySlots {
        public String territoryId;
        public List<TerritorySlot> slots;

        public AvailableTerritorySlots() {
            this.slots = new List<TerritorySlot>();
        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_available_territory_slots.htm
     */
    public class TerritorySlot {
        public Datetime endTime;
        public Datetime startTime;
        public List<String> resources;

        public TerritorySlot() {
            this.resources = new List<String>();
        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_available_territory_slots.htm
     */
    public class AvailableTerritorySlotsRequest {
        public Datetime startTime;
        public Datetime endTime;
        public String workTypeGroupId;
        public String accountId;
        public Boolean allowConcurrentScheduling;
        public String schedulingPolicyId;
        public List<String> territoryIds;
        public List<String> requiredResourceIds;
        public List<String> filterByResources;

        public AvailableTerritorySlotsRequest() {
            territoryIds = new List<String>();
            requiredResourceIds = new List<String>();
            filterByResources = new List<String>();
            allowConcurrentScheduling = false;
        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_service_appointments.htm
     */
    public class ServiceAppointmentRequest {
        public ServiceAppointmentInput serviceAppointment;
        public List<AssignedResourceInput> assignedResources;
        public String schedulingPolicyId;

        public ServiceAppointmentRequest() {
            this.serviceAppointment = new ServiceAppointmentInput();
            this.assignedResources = new List<SchedulerAPI.AssignedResourceInput>();
        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_requests_service_appointment_input.htm
     */
    public class ServiceAppointmentInput {
        public String parentRecordId;
        public String workTypeId;
        public String serviceTerritoryId;
        public String schedStartTime;
        public String schedEndTime;


        public ServiceAppointmentInput() {

        }
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_requests_assigned_resource_input.htm
     */
    public class AssignedResourceInput {
        public String serviceResourceId;
        public Boolean isRequiredResource;
        public Boolean isPrimaryResource;
        public List<ExtendedFieldsInput> extendedFields;

        public AssignedResourceInput() {
            this.extendedFields = new List<SchedulerAPI.ExtendedFieldsInput>();
        }
    }

    public class ExtendedFieldsInput {
        public String name;
        public String value;
    }


    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_service_appointment_output.htm
     */
    public class ServiceAppointmentOutput {
        public ServiceAppointmentResult result;
    }

    /**
     * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_responses_service_appointment_result.htm
     */
    public class ServiceAppointmentResult {
        public List<String> assignedResourceIds;
        public String parentRecordId;
        public String serviceAppointmentId;

        public ServiceAppointmentResult() {
            assignedResourceIds = new List<String>();
        }
    }


    //endregion

    public SchedulerAPI(String salesforceBaseURL) {
        this.salesforceBaseURL = salesforceBaseURL;
    }

    public class GetServiceTerritoriesRequest {
        public String workTypeGroupId;
        public System.Location radiusLocation;
        public String radius;
        public String radiusUnit;
        public String sortBy;
        public String sortOrder;

        public GetServiceTerritoriesRequest(String workTypeGroupId, System.Location radiusLocation, String radius) {
            if(radiusLocation != null) {
                this.workTypeGroupId = workTypeGroupId;
                this.radiusLocation = radiusLocation;
                this.radius = radius;
                this.radiusUnit = 'mi';
                this.sortBy = 'Distance';
                this.sortOrder = 'asc';
            }
            else {
                this.workTypeGroupId = workTypeGroupId;
                this.radiusLocation = System.Location.newInstance(51.518563, -0.1437738);
                this.radius = '1000';
                this.radiusUnit = 'mi';
                this.sortBy = 'Distance';
                this.sortOrder = 'asc';
            }

        }
    }

    /**
     * Queries scheduler resources to get the service centers matching the criteria defined in serviceTerritoriesRequest
     * @see https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_service_territories.htm
     *
     * @param sessionId valid salesforce session id
     * @param serviceTerritoriesRequest request @see SchedulerAPI.GetServiceTerritoriesRequest
     *
     * @return service territories valid for the query @see SchedulerAPI.ServiceTerritoriesOutput
     */
    public ServiceTerritoriesOutput getServiceTerritories(String sessionId, GetServiceTerritoriesRequest serviceTerritoriesRequest) {
        HttpRequest req = getHTTPRequest(getTerritoriesURL(serviceTerritoriesRequest), sessionId, 'GET');
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'res: ' + res);
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatusCode());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatus());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getBody());

        return (ServiceTerritoriesOutput) JSON.deserialize(res.getBody(), ServiceTerritoriesOutput.class);
    }

    /**
     * Retrieves appointment slots available for the defined territory criteria (date, time, worktype)
     * @see https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_available_territory_slots.htm
     *
     * @param sessionId valid salesforce session id
     * @param territorySlotsRequest slots filter configuration @see SchedulerAPI.AvailableTerritorySlotsRequest
     *
     * @return available slots @see SchedulerAPI.AvailableTerritorySlotsOutput
     */
    public AvailableTerritorySlotsOutput getAvailableTerritorySlots(String sessionId, AvailableTerritorySlotsRequest territorySlotsRequest) {
        HttpRequest req = getHTTPRequest(getTerritorySlotsURL(), sessionId, 'POST');
        req.setBody(JSON.serialize(territorySlotsRequest, true));
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'getAvailableTerritorySlots response: ' + res);
        if (res.getStatusCode() > 399) {
            System.debug(LoggingLevel.ERROR, 'getAvailableTerritorySlots response: ' + res);
            System.debug(LoggingLevel.ERROR, 'res: ' + res.getStatusCode());
            System.debug(LoggingLevel.ERROR, 'res: ' + res.getStatus());
            System.debug(LoggingLevel.ERROR, 'res: ' + res.getBody());
            throw new MHCException(res.getBody());
        }


        return (AvailableTerritorySlotsOutput) JSON.deserialize(res.getBody(), AvailableTerritorySlotsOutput.class);
    }

    /**
     * Books the appointment based on the appointmentRequest criteria
     * @see https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_service_appointments.htm
     *
     * @param sessionId valid salesforce session id
     * @param appointmentRequest appointment details @see SchedulerAPI.ServiceAppointmentRequest
     *
     * @return booked appointment @see SchedulerAPI.ServiceAppointmentOutput
     */
    public ServiceAppointmentOutput bookAppointment(String sessionId, ServiceAppointmentRequest appointmentRequest) {
        HttpRequest req = getHTTPRequest(getServiceAppointmentsURL(), sessionId, 'POST');
        req.setBody(JSON.serialize(appointmentRequest, true));
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'res: ' + res);
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatusCode());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatus());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getBody());

        return (ServiceAppointmentOutput) JSON.deserialize(res.getBody(), ServiceAppointmentOutput.class);
    }


    @TestVisible HttpRequest getHTTPRequest(String endpoint, String sessionId, String method) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'OAuth ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);

        return req;
    }
}