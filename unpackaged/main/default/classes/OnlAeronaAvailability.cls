/**
 * Created 11.10.2022..
 */

public without sharing class OnlAeronaAvailability {

    public static OnlBookDomain.ExtendedTimeSlotsResponse getAvailability(Id workTypeId, List<Id> serviceTerritoryIds, List<Id> serviceResourceIds, Datetime fromDate, Datetime toDate) {

        System.debug('::AE:getAvailability:workTypeId=' + workTypeId + ', stIds:' + serviceTerritoryIds + ', serviceResourceIds:' + serviceResourceIds + ', from:' + fromDate + ', to:' + toDate);
        if (fromDate < Datetime.now()) fromDate = Datetime.now();
        fromDate = Datetime.newInstance(fromDate.date(), Time.newInstance(0, 0, 0, 0));
        toDate = toDate.addDays(1);

        //limit to max 1+2 days ahead
        if (toDate.date() > fromDate.addDays(2).date()) toDate = fromDate.addDays(2);

        System.debug('::AE:getAvailability:workTypeId=' + workTypeId);

        WorkTypeGroupMember wtgm = [SELECT Id,
                WorkTypeGroup.Service_Type__c,
                WorkTypeGroup.Appointment_Type__c,
                WorkTypeGroup.Scheduling_Policy__c,
                WorkType.DurationInMinutes,
                WorkTypeGroup.Aerona_Id__c
        FROM WorkTypeGroupMember
        WHERE WorkTypeId = :workTypeId LIMIT 1];
        System.debug('::AE:getAvailability:wtg=' + wtgm.WorkTypeGroup);

        //get the skills for this WorkType
        List<SkillRequirement> reqSkills = [SELECT Id, RelatedRecordId, Skill.DeveloperName FROM SkillRequirement WHERE RelatedRecordId = :workTypeId];
        List<String> wtSkillNames = new List<String>();
        for (SkillRequirement skillRequirement : reqSkills) {
            if (skillRequirement?.Skill?.DeveloperName != null) wtSkillNames.add(skillRequirement?.Skill?.DeveloperName);
        }
        System.debug('::AE:getAvailability:wt required skills=' + wtSkillNames);

        // mm 23-01-28 hardcoding this to 15
        Integer appointmentInterval = 15;

        Integer appointmentDuration = 30;
        if (wtgm.WorkType.DurationInMinutes != null && wtgm.WorkType.DurationInMinutes > 0) appointmentDuration = wtgm.WorkType.DurationInMinutes.intValue();
        System.debug('::AE:getAvailability:appointmentDuration=' + appointmentDuration);

        //if resources have not been specified, get all the resources that have this skill
        Set<Id> resourceIdsSet = new Set<Id>();
        if (serviceResourceIds != null && serviceResourceIds.size() > 0) resourceIdsSet.addAll(serviceResourceIds);

        System.debug('::AE:getAvailability:provided resourceIdsSet=' + resourceIdsSet);

        //if location Ids have not been specified, take all locations with aerona Ids
        List<ServiceTerritory> serviceTerritories;
        if (serviceTerritoryIds != null && serviceTerritoryIds.size() > 0) {
            serviceTerritories = [SELECT Id, Aerona_Id__c FROM ServiceTerritory WHERE Id IN :serviceTerritoryIds];
        }
        else {
            serviceTerritories = OnlBookDomain.getServiceCentersForWT(workTypeId);
        }

        Set<Id> stIds = new Set<Id>();
        for (ServiceTerritory territory : serviceTerritories) {
            stIds.add(territory.Id);
        }

        System.debug('::AE:getAvailability:searching at territories=' + stIds);

        List<AeronaSlot> allFreeSlots = new List<OnlAeronaAvailability.AeronaSlot>();

        Boolean isVideoOrTel = wtgm.WorkTypeGroup.Appointment_Type__c == 'VIDEO' || wtgm.WorkTypeGroup.Appointment_Type__c == 'TELEPHONE';
        System.debug('::AE:getAvailability:is VIDEO/TEL=' + isVideoOrTel);


        List<ServiceTerritoryMember> stms = new List<ServiceTerritoryMember>();

          //get all serviceTerritoryMembers for service Territories - make a map of it
            if (resourceIdsSet == null || resourceIdsSet.isEmpty()) {
                stms = [
                        SELECT
                                Id,
                                Aerona_Clinician_Id__c,
                                ServiceTerritoryId,
                                ServiceResourceId,
                                ServiceResource.Id,
                                ServiceTerritory.Aerona_Id__c,
                                ServiceTerritory.Aerona_PIN__c
                        FROM ServiceTerritoryMember
                        WHERE ServiceTerritoryId IN :stIds
                        AND ServiceTerritory.Aerona_Id__c != NULL
                        AND Aerona_Clinician_Id__c != NULL
                        AND ServiceResource.IsActive = TRUE
                        ORDER BY ServiceTerritory.Name ASC
                ];
            }
            else {
                stms = [
                        SELECT
                                Id,
                                Aerona_Clinician_Id__c,
                                ServiceTerritoryId,
                                ServiceResourceId,
                                ServiceResource.Id,
                                ServiceTerritory.Aerona_Id__c,
                                ServiceTerritory.Aerona_PIN__c
                        FROM ServiceTerritoryMember
                        WHERE ServiceTerritoryId IN :stIds
                        AND ServiceResourceId IN :resourceIdsSet
                        AND ServiceTerritory.Aerona_Id__c != NULL
                        AND Aerona_Clinician_Id__c != NULL
                        AND ServiceResource.IsActive = TRUE
                        ORDER BY ServiceTerritory.Name ASC
                ];
            }

        System.debug('::AE:getAvailability:members to search for:' + stms.size());

        //get skills of these service resources
        List<Id> potentialServiceResourceIds = new List<Id>();
        for (ServiceTerritoryMember serviceTerritoryMember : stms) {
            potentialServiceResourceIds.add(serviceTerritoryMember.ServiceResourceId);
        }

        List<ServiceResourceSkill> srSkills = [SELECT Id, ServiceResourceId, Skill.DeveloperName FROM ServiceResourceSkill WHERE ServiceResourceId IN :potentialServiceResourceIds];

        Set<Id> filteredServiceResources = new Set<Id>();

        //if SR has any of needed skills, add to filteredResources
        if (!wtSkillNames.isEmpty()) {
            for (ServiceResourceSkill serviceResourceSkill : srSkills) {
                Boolean found = false;
                for (String wtSkill : wtSkillNames) {
                    if (wtSkill.equalsIgnoreCase(serviceResourceSkill.Skill?.DeveloperName)) {
                        found = true;
                        break;
                    }
                }
                if (found) filteredServiceResources.add(serviceResourceSkill.ServiceResourceId);
            }
        }
        else {
            // in cases no skills required
            filteredServiceResources.addAll(potentialServiceResourceIds);
        }

        //for each service territory member (location and resource) ask Aerona for availability
        Date searchDate = fromDate.date();
        for (ServiceTerritoryMember stm : stms) {
            if (!filteredServiceResources.contains(stm.ServiceResourceId)) {
                System.debug('::AE:getAvailability:not searching for resource without needed skills:' + stm.ServiceResourceId);
                continue;
            }
            searchDate = fromDate.date();
            System.debug('::AE:getAvailability:find_for_member:' + JSON.serialize(stm, true));
            if (String.isNotBlank(stm.Aerona_Clinician_Id__c)) {
                //for each date also !
                while (searchDate <= toDate.date()) {
                    System.debug('::AE:getAvailability:find:type= ' + wtgm.WorkTypeGroup.Aerona_Id__c + ', practiceId=' + stm.ServiceTerritory.Aerona_Id__c + ', clinicianId:' + stm.Aerona_Clinician_Id__c + ', date=' + searchDate);
                    //QUERY AVAILABILITIES
                    List<AeronaServiceOASApi.OASAPIFreeAppointmentSlot> freeSlots = AeronaService.findAppointmentSlot(
                            wtgm.WorkTypeGroup.Aerona_Id__c,
                            stm.ServiceTerritory.Aerona_Id__c,
                            stm.ServiceTerritory.Aerona_PIN__c,
                            stm.Aerona_Clinician_Id__c,
                            searchDate);

                    System.debug('::AE:getAvailability:freeSlots:' + freeSlots?.size());

                    //in case of error, try tomorrow
                    if (freeSlots == null) {
                        searchDate = searchDate.addDays(1);
                        continue;
                    }

                    //if not slots found, we should break, because there are no next free 50 slots, so it's going to be the same tomorrow
                    if (freeSlots.size() == 0) {
                        break;
                    }

                    //mitigate number of calls - if free slots contains dates more than "search date + 3", then stop
                    Boolean hasDatesInFuture = false;
                    for (AeronaServiceOASApi.OASAPIFreeAppointmentSlot slot : freeSlots) {
                        if (slot.slotStartTime.date() > toDate.date()) {
                            System.debug('::AE:getAvailability:slot detected after toDate date:' + slot.slotStartTime);
                            hasDatesInFuture = true;
                            break;
                        }
                    }
                    if (hasDatesInFuture) {
                        System.debug('::AE:getAvailability:no need to search further in the future:' + stm.ServiceResourceId);
                        for (AeronaServiceOASApi.OASAPIFreeAppointmentSlot slot : freeSlots) {
                            if ((slot.slotStartTime.date() >= searchDate) && (slot.slotStartTime.date() <= toDate.date())) {
                                allFreeSlots.add(new AeronaSlot(slot.slotStartTime, stm.ServiceResourceId, stm.ServiceTerritoryId));
                            }
                        }
                        break;
                    }


                    //iterate over it and add to final results
                    for (AeronaServiceOASApi.OASAPIFreeAppointmentSlot slot : freeSlots) {
                        if (slot.slotStartTime.date() == searchDate) allFreeSlots.add(new AeronaSlot(slot.slotStartTime, stm.ServiceResourceId, stm.ServiceTerritoryId));
                    }
                    searchDate = searchDate.addDays(1);

                }
            }
        }
        System.debug('::AE:getAvailability:total slots=' + allFreeSlots.size());

        //combine all dates and convert to ExtendedTerritorySlot
        Map<Datetime, List<AeronaSlot>> map_slots = new Map<Datetime, List<AeronaSlot>>();
        for (AeronaSlot aeronaSlot : allFreeSlots) {
            //System.debug('free slot = ' + aeronaSlot.startTime);
            List<AeronaSlot> slots = map_slots.get(aeronaSlot.startTime);
            if (slots == null) slots = new List<OnlAeronaAvailability.AeronaSlot>();

            //only if start time is after now + 10 minutes
            if (aeronaSlot.startTime > Datetime.now().addMinutes(10)) {
                slots.add(aeronaSlot);
                map_slots.put(aeronaSlot.startTime, slots);
            }
        }

        //At the end, convert this to List of ExtendedTimeSlots
        OnlBookDomain.ExtendedTimeSlotsResponse ret = new OnlBookDomain.ExtendedTimeSlotsResponse();
        ret.schedulingPolicyMinutes = appointmentInterval;
        ret.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

        Set<Datetime> keys = map_slots.keySet();
        for (Datetime dt : keys) {
            List<AeronaSlot> slots = map_slots.get(dt);

            OnlBookDomain.ExtendedTerritorySlot ets = new OnlBookDomain.ExtendedTerritorySlot();
            ets.startTime = dt;
            ets.endTime = dt.addMinutes(appointmentDuration);
            ets.resources = new List<String>();

            Map<String, Set<String>> map_resource_locations = new Map<String, Set<String>>();
            for (AeronaSlot aeronaSlot : slots) {
                Set<String> locations = map_resource_locations.get(aeronaSlot.serviceResourceId);
                if (locations == null) locations = new Set<String>();
                locations.add(aeronaSlot.serviceTerritoryId);
                map_resource_locations.put(aeronaSlot.serviceResourceId, locations);
            }

            ets.resources.addAll(map_resource_locations.keySet());
            ets.resource_locations = map_resource_locations;
            ret.territorySlots.add(ets);
        }

        // sort territoryslots by starttime
        ret.territorySlots.sort();

        System.debug('::AE:getAvailability:returning num slots=' + ret.territorySlots.size());
        return ret;
    }

    //    public static Set<Id> getAeronaServiceResourcesForTerritories(List<Id> stIds) {
    //        Set<Id> resourceIds = new Set<Id>();
    //
    //        List<ServiceTerritoryMember> stms = [
    //                SELECT Id, ServiceResourceId, ServiceResource.Id, ServiceResource.Name, Aerona_Clinician_Id__c
    //                FROM ServiceTerritoryMember
    //                WHERE ServiceTerritoryId IN :stIds
    //                AND ServiceResource.IsActive = TRUE
    //                AND Aerona_Clinician_Id__c != NULL
    //        ];
    //
    //        for (ServiceTerritoryMember serviceTerritoryMember : stms) {
    //            resourceIds.add(serviceTerritoryMember.ServiceResourceId);
    //        }
    //
    //        return resourceIds;
    //    }


    public class AeronaSlot {
        public Datetime startTime;
        public String serviceResourceId;
        public String serviceTerritoryId;

        public AeronaSlot(Datetime startTime, String serviceResourceId, String serviceTerritoryId) {
            this.startTime = startTime;
            this.serviceResourceId = serviceResourceId;
            this.serviceTerritoryId = serviceTerritoryId;
        }

    }

}