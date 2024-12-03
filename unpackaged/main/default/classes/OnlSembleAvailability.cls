/**
 * Created 23.8.2022..
 */

public without sharing class OnlSembleAvailability {

    public static OnlBookDomain.ExtendedTimeSlotsResponse getAvailability(Id workTypeId, List<Id> serviceTerritoryIds, List<Id> serviceResourceIds, Datetime fromDate, Datetime toDate) {

        if (fromDate < Datetime.now()) fromDate = Datetime.now();

        // round down start time
        fromDate = Datetime.newInstance(fromDate.date(), Time.newInstance(0, 0, 0, 0));

        //limit to max 7 days ahead
        if (fromDate.addDays(7) < toDate) toDate = fromDate.addDays(7);

        // round down end time
        toDate = Datetime.newInstance(toDate.date(), Time.newInstance(0,0,0,0));

        System.debug('::getAvailability:workTypeId=' + workTypeId);

        WorkTypeGroupMember wtgm = [SELECT Id, WorkTypeGroup.Service_Type__c, WorkTypeGroup.Scheduling_Policy__c, WorkType.DurationInMinutes FROM WorkTypeGroupMember WHERE WorkTypeId = :workTypeId LIMIT 1];
        System.debug('::getAvailability:wtg=' + wtgm.WorkTypeGroup);

        Integer appointmentInterval = getIntervalForSchedulingPolicy(wtgm.WorkTypeGroup.Scheduling_Policy__c);
        System.debug('::getAvailability:appointmentInterval=' + appointmentInterval);

        Integer appointmentDuration = 20;
        if (wtgm.WorkType.DurationInMinutes != null && wtgm.WorkType.DurationInMinutes > 0) appointmentDuration = wtgm.WorkType.DurationInMinutes.intValue();
        //System.debug('::getAvailability:appointmentDuration=' + appointmentDuration);

        List<DateTimeRange> defaultTimeSlots = new List<DateTimeRange>();
        //create default time slots
        {
            Datetime dt_start = fromDate;
            Datetime dt_end = toDate;

            Datetime currEnd;

            do {
                Datetime slot_start = dt_start;
                Datetime slot_end = dt_start.addMinutes(appointmentDuration);
                currEnd = slot_end;
                if (slot_start >= Datetime.now().addMinutes(10)) {
                    defaultTimeSlots.add(new DateTimeRange(slot_start, slot_end));
                }
                //                System.debug('::def_ts_:' + slot_start + ' to ' + slot_end);
                dt_start = dt_start.addMinutes(appointmentInterval);

            }
            while (currEnd <= dt_end);
        }

        //if resources have not been specified, get all the resources that have this skill
        Set<Id> resourceIdsSet = new Set<Id>();
        if (serviceResourceIds != null) resourceIdsSet.addAll(serviceResourceIds);
        else resourceIdsSet = OnlBookDomain.getServiceResourcesIdsForWorTypeSkills(workTypeId);

        //if location Ids have not been specified, take all locations with semble Ids
        List<ServiceTerritory> serviceTerritories;
        if (serviceTerritoryIds != null) {
            serviceTerritories = [SELECT Id, Heydoc_Id__c FROM ServiceTerritory WHERE Id IN :serviceTerritoryIds];
        }
        else {
            serviceTerritories = OnlBookDomain.getServiceCentersForWT(workTypeId);
            serviceTerritoryIds = new List<Id>();
            for (ServiceTerritory serviceTerritory : serviceTerritories) {
                serviceTerritoryIds.add(serviceTerritory.Id);
            }
        }

        System.debug('::getAvailability:resourceIdsSet.size=' + resourceIdsSet.size());
        List<ServiceResource> srs = [SELECT Id, Heydoc_Id__c FROM ServiceResource WHERE Id IN :resourceIdsSet AND Heydoc_Id__c != NULL];

        System.debug('::getAvailability:srs.size=' + srs.size());

        //build a map of who's available where
        List<ServiceTerritoryMember> stms = [SELECT Id, ServiceTerritoryId, ServiceResourceId FROM ServiceTerritoryMember WHERE ServiceTerritoryId IN :serviceTerritoryIds];

        //for each location and resource call Semble
        HeyDocService.DateRange dateRange = new HeyDocService.DateRange(fromDate, toDate);
        //dateRange.start = HeyDocService.adjustTimeZoneForHeydoc(dateRange.start);
        //dateRange.end_jsonsafe = HeyDocService.adjustTimeZoneForHeydoc(dateRange.end_jsonsafe);

        Integer num_calls = 0;
        for (ServiceTerritory serviceTerritory : serviceTerritories) {
            if (String.isNotBlank(serviceTerritory.Heydoc_Id__c)) {
                for (ServiceResource serviceResource : srs) {
                    if (String.isNotBlank(serviceResource.Heydoc_Id__c)) {

                        if (checkIsValidServiceTerritoryMember(stms, serviceTerritory.Id, serviceResource.Id)) {
                            num_calls++;
                            if (num_calls < 91) {

                                //QUERY AVAILABILITIES - SEMBLE
                                List<HeyDocService.AvailabilitiesData> adData = HeyDocService.queryAvailabilities(
                                        dateRange,
                                        serviceTerritory.Heydoc_Id__c,
                                        serviceResource.Heydoc_Id__c);

                                System.debug('::getAvailability:@' + num_calls);

                                if (adData == null) continue;
//
//                                //TODO, for serviceTerritory + serviceResource, if there is no availability, add a cache record
//                                if (adData.isEmpty()) {
//                                    addCachedAvailability(serviceTerritory, serviceResource, dateRange, JSON.serialize(adData));
//                                }


                                //iterate over it and fix time (heydoc ignores timezone)
                                for (HeyDocService.AvailabilitiesData ad : adData) {
                                    ad.start = HeyDocService.adjustTimeZoneForHeydocOnReceive(ad.start);
                                    ad.end_jsonsafe = HeyDocService.adjustTimeZoneForHeydocOnReceive(ad.end_jsonsafe);
                                }

                                // System.debug('::getAvailability:adjusted-availability:' + JSON.serialize(adData));

                                //now for all the data received, add to defaultTimeSlots
                                for (HeyDocService.AvailabilitiesData ad : adData) {
                                    for (DateTimeRange defTSR : defaultTimeSlots) {
                                        if (defTSR.isInsideRange(ad.start, ad.end_jsonsafe)) defTSR.addResourceAtLocation(serviceResource.Id, serviceTerritory.Id);
                                    }
                                }
                            }


                        }
                    }
                }
            }
        }
        //System.debug('::getAvailability:defaultTimeSlots:' + JSON.serializePretty(defaultTimeSlots));

        //At the end, convert this to List of ExtendedTimeSlots
        OnlBookDomain.ExtendedTimeSlotsResponse ret = new OnlBookDomain.ExtendedTimeSlotsResponse();
        ret.schedulingPolicyMinutes = appointmentInterval;
        ret.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

        for (DateTimeRange dateTimeRange : defaultTimeSlots) {
            if (dateTimeRange.hasResources()) {
                OnlBookDomain.ExtendedTerritorySlot ets = new OnlBookDomain.ExtendedTerritorySlot();
                ets.startTime = dateTimeRange.startTime;
                ets.endTime = dateTimeRange.endTime;
                ets.resources = new List<String>();
                ets.resources.addAll(dateTimeRange.map_resource_locations.keySet());
                ets.resource_locations = dateTimeRange.map_resource_locations;
                ret.territorySlots.add(ets);
            }
        }

        //System.debug('::getAvailability:returning:' + JSON.serializePretty(ret));
        return ret;
    }

//    @TestVisible
//    private static void addCachedNoAvailability(ServiceTerritory serviceTerritory, ServiceResource serviceResource, HeyDocService.DateRange dateRange, String response) {
//        Date fromDate = dateRange.start.date();
//
//        do
//        {
//            if (fromDate>= dateRange.start.date())
//        }
//                AvailabilityCache__c aCache = new AvailabilityCache__c();
//        aCache.ServiceTerritoryId = serviceTerritory.Id;
//        aCache.ServiceResourceId = serviceResource.Id;
//        aCache.
//    }


    public static Boolean checkIsValidServiceTerritoryMember(List<ServiceTerritoryMember> stms, Id stId, Id srId) {
        if (stms == null || stId == null || srId == null) return false;

        for (ServiceTerritoryMember serviceTerritoryMember : stms) {
            if (stms != null && (serviceTerritoryMember.ServiceResourceId == srId) && (serviceTerritoryMember.ServiceTerritoryId == stId)) return true;
        }
        return false;
    }

    public static Integer getIntervalForSchedulingPolicy(String schedulingPolicy) {

        List<AppointmentSchedulingPolicy> policies = [SELECT Id, AppointmentStartTimeInterval FROM AppointmentSchedulingPolicy WHERE DeveloperName = :schedulingPolicy];
        if (!policies.isEmpty() && policies[0].AppointmentStartTimeInterval != null) {
            Integer ret = Integer.valueOf(policies[0].AppointmentStartTimeInterval);
            if (ret > 0) return ret;
        }

        return 10;
    }


    public class DateTimeRange {
        public Datetime startTime;
        public Datetime endTime;

        public Map<String, Set<String>> map_resource_locations = new Map<String, Set<String>>();

        public DateTimeRange() {

        }

        public DateTimeRange(Datetime startTime, Datetime endTime) {
            this.startTime = startTime;
            this.endTime = endTime;
        }

        public void addResourceAtLocation(String resourceId, String locationId) {
            Set<String> locIds = new Set<String>();
            locIds.add(locationId);
            if (map_resource_locations.get(resourceId) != null) {
                locIds.addAll(map_resource_locations.get(resourceId));
            }
            map_resource_locations.put(resourceId, locIds);
        }

        public Boolean isInsideRange(Datetime rStartTime, Datetime rEndTime) {
            if (this.startTime == null || this.endTime == null || rStartTime == null || rEndTime == null) {
                return false;
            }
            return (this.startTime >= rStartTime && this.endTime <= rEndTime);
        }

        public Boolean hasResources() {
            return this.map_resource_locations.size() > 0;
        }
    }
}