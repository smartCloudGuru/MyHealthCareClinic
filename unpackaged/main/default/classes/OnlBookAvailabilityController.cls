/**
 * Created by Matija on 28.11.2023..
 */

public without sharing class OnlBookAvailabilityController {

    private static Boolean ctx_insideSF = false;

    public static Map<String, Id> map_SchedulerPolicyDevName_Id;

    public static void setContextIsInsideSF(Boolean insideSF) {
        if (insideSF == null) insideSF = false;
        ctx_insideSF = insideSF;
    }

    public static Map<String, Id> schedulerPolicyNameIdMap() {
        if (map_SchedulerPolicyDevName_Id == null) {
            map_SchedulerPolicyDevName_Id = new Map<String, Id>();
            List<AppointmentSchedulingPolicy> policies = [SELECT Id, DeveloperName FROM AppointmentSchedulingPolicy];
            for (AppointmentSchedulingPolicy appointmentSchedulingPolicy : policies) {
                map_SchedulerPolicyDevName_Id.put(appointmentSchedulingPolicy.DeveloperName, appointmentSchedulingPolicy.Id);
            }
        }

        return map_SchedulerPolicyDevName_Id;
    }

    // 2022-08-24 CHANGED TO USE EXTERNAL AVAILABILITY API!
    public static OnlBookDomain.ExtendedTimeSlotsResponse getAvailableSlots_extendedResponse(String workTypeGroupId, String workTypeId, String serviceCenterIds, Datetime dateFrom, Datetime dateTo) {


        List<WorkTypeGroup> wtgs = [SELECT Id, Appointment_Type__c, Heydoc_Id__c, Aerona_Id__c FROM WorkTypeGroup WHERE Id = :workTypeGroupId];
        if (wtgs.size() == 0) return null;

        List<String> stIds = new List<String>();

        Boolean USE_SEMBLE_AVAILABILITY = false;
        Boolean USE_AERONA_AVAILABILITY = false;

        if (String.isNotBlank(wtgs[0].Heydoc_Id__c)) USE_SEMBLE_AVAILABILITY = true;
        else if (String.isNotBlank(wtgs[0].Aerona_Id__c)) USE_AERONA_AVAILABILITY = true;

        OnlBookDomain.ExtendedTimeSlotsResponse ret = null;

        // SEMBLE
        if (USE_SEMBLE_AVAILABILITY) {
            //check if the worktypegroup is video or telephone - so search all service centers
            if (serviceCenterIds != null) {
                stIds = serviceCenterIds.split(',');
            }

            if (serviceCenterIds == null || wtgs.get(0).Appointment_Type__c == 'VIDEO' || wtgs.get(0).Appointment_Type__c == 'TELEPHONE') {
                stIds = null;
            }


            //fix so we can search for one day
            if (dateTo == dateFrom) dateTo = dateTo.addDays(1);
            ret = OnlSembleAvailability.getAvailability(workTypeId, stIds, null, dateFrom, dateTo);

        }
        //AERONA
        else if (USE_AERONA_AVAILABILITY) {
            if (serviceCenterIds != null) {
                stIds = serviceCenterIds.split(',');
            }
            if (dateTo == dateFrom) dateTo = dateTo.addDays(1);

            if (serviceCenterIds == null || wtgs.get(0).Appointment_Type__c == 'VIDEO' || wtgs.get(0).Appointment_Type__c == 'TELEPHONE') {
                stIds = null;
            }

            ret = OnlAeronaAvailability.getAvailability(workTypeId, stIds, null, dateFrom, dateTo);

        }
        else {
            // USES SALESFORCE SCHEDULING
            OnlBookDomain.ExtendedTimeSlotsResponse resp = new OnlBookDomain.ExtendedTimeSlotsResponse();

            //get minutes for scheduling policy
            resp.schedulingPolicyMinutes = getSchedulingPolicyMinutesForWTG(workTypeGroupId);

            if (serviceCenterIds == null || wtgs.get(0).Appointment_Type__c == 'VIDEO' || wtgs.get(0).Appointment_Type__c == 'TELEPHONE') {
                // search at all locations!
                List<ServiceTerritory> serviceTerritories = getServiceCentersForWTG(workTypeGroupId);
                for (ServiceTerritory serviceTerritory : serviceTerritories) {
                    stIds.add(serviceTerritory.Id);
                }
            }
            else {
                stIds = serviceCenterIds.split(',');
            }

            resp.territorySlots =
                    (List<OnlBookDomain.ExtendedTerritorySlot>)
                            JSON.deserialize(getAvailableTimeSlots(workTypeGroupId, stIds, dateFrom.date(), dateTo.date().addDays(-1)),
                                    List<OnlBookDomain.ExtendedTerritorySlot>.class);

            ret = resp;
        }

        System.debug(LoggingLevel.FINE, '::getAvailableSlots_extendedResponse:ret_phase_0:size:' + ret?.territorySlots?.size());

        //filter by diary blocks
        ret = filterSlotsByDiaryBlockDateRangeAndWTG(workTypeGroupId, dateFrom, dateTo, ret);

        System.debug(LoggingLevel.FINE, '::getAvailableSlots_extendedResponse:ret_phase_1:size:' + ret?.territorySlots?.size());

        //filter the responses by worktype operating hours and eventual start/from datetimes
        ret = filterByOperatingHours(ret, workTypeId);

        //filter additionally if the ServiceTerritoryWorkType has Operating hours set
        ret = filterByOperatingHoursByClinic(ret, workTypeId);

        System.debug(LoggingLevel.FINE, '::getAvailableSlots_extendedResponse:ret_phase_2:size:' + ret?.territorySlots?.size());

        ret = checkForSkillPrioritization(ret, workTypeId);

        System.debug(LoggingLevel.FINE, '::getAvailableSlots_extendedResponse:ret_phase_3:size:' + ret?.territorySlots?.size());

        return ret;
    }

    public static OnlBookDomain.ExtendedTimeSlotsResponse filterSlotsByDiaryBlockDateRangeAndWTG(
            String workTypeGroupId,
            Datetime dtFrom,
            Datetime dtTo,
            OnlBookDomain.ExtendedTimeSlotsResponse etsr) {
        //System.debug('::fsbddbraw:etsr:' + etsr);
        if (etsr == null) return etsr;
        if (etsr.territorySlots == null) return etsr;
        if (etsr.territorySlots.size() == 0) return etsr;

        List<WorkTypeGroup> wtgs = [SELECT Id, Appointment_Type__c FROM WorkTypeGroup WHERE Id = :workTypeGroupId];

        if (wtgs.isEmpty()) return etsr;

        Boolean isVideoOrTel = wtgs[0].Appointment_Type__c == 'VIDEO' || wtgs[0].Appointment_Type__c == 'TELEPHONE';

        //now get the eventual diary blocks
        List<Diary_Block__c> blocks = [
                SELECT Id, Resource__c, Not_Available_From__c, Not_Available_To__c, Do_Not_Block_For__c, Allow_Video_Tel__c
                FROM Diary_Block__c
                WHERE Not_Available_From__c <= :dtTo
                AND Not_Available_To__c >= :dtFrom
                AND Do_Not_Block_For__c != :workTypeGroupId
                AND Is_Active__c = TRUE
        ];

        //System.debug('::fsbddbraw:blocks:' + blocks);

        Boolean slotBlocked = false;
        for (OnlBookDomain.ExtendedTerritorySlot territorySlot : etsr.territorySlots) {
            for (Diary_Block__c diaryBlock : blocks) {
                slotBlocked = false;

                // if allowing video and tel apps, and this is a vedeo/tel app
                if (isVideoOrTel && diaryBlock.Allow_Video_Tel__c) continue;

                if (territorySlot.resources != null && territorySlot.resources.size() > 0 && territorySlot.resources.contains(diaryBlock.Resource__c)) {
                    slotBlocked = checkRangesOverlap(territorySlot.startTime, territorySlot.endTime, diaryBlock.Not_Available_From__c, diaryBlock.Not_Available_To__c);
                    if (slotBlocked) {

                        //remove resource from resources
                        //System.debug('::fsbddbraw:removing slot:' + territorySlot + ' due to Diary Block' + diaryBlock);
                        for (Integer i = (territorySlot.resources.size() - 1); i >= 0; i--) {
                            String s = territorySlot.resources[i];
                            if (s.equalsIgnoreCase(diaryBlock.Resource__c)) {
                                territorySlot.resources.remove(i);
                            }
                        }
                    }
                }
            }
        }

        List<OnlBookDomain.ExtendedTerritorySlot> slots = new List<OnlBookDomain.ExtendedTerritorySlot>();
        for (OnlBookDomain.ExtendedTerritorySlot territorySlot : etsr.territorySlots) {
            if (territorySlot.resources != null && territorySlot.resources.size() > 0) slots.add(territorySlot);
        }

        etsr.territorySlots = slots;

        System.debug('::filterSlotsByDiaryBlockDateRangeAndWTG:post filter num slots=' + slots.size());
        return etsr;

    }


    public static Boolean checkRangesOverlap(Datetime dt1s, Datetime dt1e, Datetime dt2s, Datetime dt2e) {
        return (dt1s >= dt2s
                && dt1s < dt2e)
                ||
                (dt1e > dt2s
                        && dt1e <= dt2e)
                ||
                (dt2s >= dt1s
                        && dt2s < dt1e)
                ||
                (dt2e > dt1s
                        && dt2e <= dt1e);
    }

    public static OnlBookDomain.ExtendedTimeSlotsResponse filterByOperatingHours(OnlBookDomain.ExtendedTimeSlotsResponse ets, Id wtId) {
        if (wtId == null) return ets;

        if (ets == null) return ets;
        if (ets.territorySlots == null) return ets;
        if (ets.territorySlots.size() == 0) return ets;

        List<WorkType> wts = [SELECT Id, OperatingHoursId, Appointment_Booking_Available_From__c, Appointment_Booking_Available_To__c FROM WorkType WHERE Id = :wtId];

        if (wts.isEmpty()) return ets;

        String ohId = wts[0].OperatingHoursId;

        if (String.isEmpty(ohId) && wts[0].Appointment_Booking_Available_From__c == null && wts[0].Appointment_Booking_Available_To__c == null) return ets;


        //List<OperatingHoursHoliday> ohHolidays = new List<OperatingHoursHoliday>();
        //if (ohId != null) ohHolidays = [SELECT Id, Holiday.ActivityDate FROM OperatingHoursHoliday WHERE OperatingHoursId = :ohId];

        Datetime filterStart = wts[0].Appointment_Booking_Available_From__c != null ? wts[0].Appointment_Booking_Available_From__c : Datetime.now().addDays(-1);
        Datetime filterEnd = wts[0].Appointment_Booking_Available_To__c != null ? wts[0].Appointment_Booking_Available_To__c : Datetime.now().addYears(100);

        OnlBookDomain.ExtendedTimeSlotsResponse ret = new OnlBookDomain.ExtendedTimeSlotsResponse();
        ret.schedulingPolicyMinutes = ets.schedulingPolicyMinutes;
        ret.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

        List<TimeSlot> oHTimeSlots = null;

        if (!String.isEmpty(ohId)) oHTimeSlots = [SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlot WHERE OperatingHoursId = :ohId];

        Boolean passedDaysCheck = false;
        Boolean passedWindowCheck = false;
        String dayName = null;

        for (OnlBookDomain.ExtendedTerritorySlot slot : ets.territorySlots) {
            passedDaysCheck = false;
            passedWindowCheck = false;

            if (oHTimeSlots != null) {
                if (slot != null && slot.startTime != null && slot.endTime != null) {
                    dayName = slot.startTime?.format('EEEE');
                    for (TimeSlot ohts : oHTimeSlots) {
                        if (ohts.DayOfWeek == dayName) {
                            if (ohts.StartTime <= slot.startTime.time() && ohts.EndTime >= slot.endTime.time()) {
                                passedDaysCheck = true;
                                break;
                            }
                        }
                    }
                }
            }
            else {
                passedDaysCheck = true;
            }

            if (wts[0].Appointment_Booking_Available_From__c != null || wts[0].Appointment_Booking_Available_To__c != null) {
                if (slot != null && slot.startTime != null && slot.endTime != null) {
                    if (slot.startTime >= filterStart && slot.startTime <= filterEnd) {
                        passedWindowCheck = true;
                    }
                }
            }
            else {
                passedWindowCheck = true;
            }

            if (!passedDaysCheck) System.debug('::filterByOperatingHours:slot failed oh check=' + slot);
            if (!passedWindowCheck) System.debug('::filterByOperatingHours:slot failed window check=' + slot);

            if (passedDaysCheck && passedWindowCheck) ret.territorySlots.add(slot);
        }

        System.debug('::filterByOperatingHours:post filter num slots=' + ret.territorySlots.size());
        return ret;
    }

    /**
     * Added 24-09-29, additionally filter by operating hours specified on ServiceTerritoryWorkType objects
     *
     * @param ets
     * @param wtId
     *
     * @return
     */
    public static OnlBookDomain.ExtendedTimeSlotsResponse filterByOperatingHoursByClinic(OnlBookDomain.ExtendedTimeSlotsResponse ets, Id wtId) {
        try {
            if (wtId == null) return ets;

            if (ets == null) return ets;
            if (ets.territorySlots == null) return ets;
            if (ets.territorySlots.size() == 0) return ets;

            // LIMITATION: we can continue only if there is only one ServiceTerritory in the available time slots list!
            Set<String> allLocations = new Set<String>();
            for (OnlBookDomain.ExtendedTerritorySlot slot : ets.territorySlots) {
                if (slot.resource_locations != null) {
                    for (String key : slot.resource_locations.keySet()) {
                        Set<String> values = slot.resource_locations.get(key);
                        allLocations.addAll(values);
                    }

                }
            }

            if (allLocations.isEmpty()) return ets;

            if (allLocations.size() > 1) {
                System.debug('::filterByOperatingHoursByClinic:cant process with multiple locatins ' + allLocations);
                return ets;
            }

            Id firstLocationId = allLocations.isEmpty() ? null : allLocations.iterator().next(); // Retrieve the first value in allLocations

            //get all ServiceTerritoryWorkType for this wtID
            List<ServiceTerritoryWorkType> stwts = [SELECT Id, Operating_Hours__c, ServiceTerritoryId FROM ServiceTerritoryWorkType WHERE WorkTypeId = :wtId AND ServiceTerritoryId = :firstLocationId];

            if (stwts.isEmpty()) return ets;

            ServiceTerritoryWorkType stwt = stwts.get(0);

            //nothing defined operating hours, so continue
            if (stwt.Operating_Hours__c == null) return ets;

            OnlBookDomain.ExtendedTimeSlotsResponse ret = new OnlBookDomain.ExtendedTimeSlotsResponse();
            ret.schedulingPolicyMinutes = ets.schedulingPolicyMinutes;
            ret.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

            Map<Id, List<TimeSlot>> map_serviceTerritory_operatingHours;
            List<TimeSlot> oHTimeSlots = [SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlot WHERE OperatingHoursId = :stwt.Operating_Hours__c];


            Boolean passedDaysCheck = false;
            String dayName = null;

            for (OnlBookDomain.ExtendedTerritorySlot slot : ets.territorySlots) {
                passedDaysCheck = false;

                if (oHTimeSlots != null) {
                    if (slot != null && slot.startTime != null && slot.endTime != null) {
                        dayName = slot.startTime?.format('EEEE');
                        for (TimeSlot ohts : oHTimeSlots) {
                            if (ohts.DayOfWeek == dayName) {
                                if (ohts.StartTime <= slot.startTime.time() && ohts.EndTime >= slot.endTime.time()) {
                                    passedDaysCheck = true;
                                    break;
                                }
                            }
                        }
                    }
                }
                else {
                    passedDaysCheck = true;
                }

                if (!passedDaysCheck) System.debug('::filterByOperatingHoursByClinic:slot failed oh check=' + slot);
                if (passedDaysCheck) ret.territorySlots.add(slot);
            }

            System.debug('::filterByOperatingHoursByClinic:post filter num slots=' + ret.territorySlots.size());
            return ret;
        }

        catch (Exception ex) {
            return ets;
        }
    }

    /**
     * searches SF Scheduling
     *
     * @param workTypeGroupId
     * @param serviceCenterIds
     * @param dateFrom
     * @param dateTo
     *
     * @return
     */
    public static String getAvailableTimeSlots(String workTypeGroupId, List<String> serviceCenterIds, Date dateFrom, Date dateTo) {
        try {

            OnlineStoreSettings__c storeSettings = OnlineStoreSettingsManager.getStoreSettings();
            Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);

            System.debug('loginResponse:' + loginResponse);

            //get ge0coded postal key
            SchedulerAPI.AvailableTerritorySlotsRequest territorySlotsRequest = new SchedulerAPI.AvailableTerritorySlotsRequest();
            territorySlotsRequest.startTime = Datetime.newInstance(dateFrom, Time.newInstance(0, 0, 0, 0));
            territorySlotsRequest.endTime = Datetime.newInstance(dateTo, Time.newInstance(23, 59, 59, 999));
            territorySlotsRequest.requiredResourceIds = null;
            territorySlotsRequest.workTypeGroupId = workTypeGroupId;
            territorySlotsRequest.territoryIds.addAll(serviceCenterIds);
            WorkTypeGroup wtg = [SELECT Id, Scheduling_Policy__c FROM WorkTypeGroup WHERE Id = :workTypeGroupId LIMIT 1];
            territorySlotsRequest.schedulingPolicyId = schedulerPolicyNameIdMap().get (wtg?.Scheduling_Policy__c);

            System.debug('::OnlBookUI:getAvailableTimeSlots:territorySlotsRequest:' + JSON.serializePretty(territorySlotsRequest));
            SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);
            SchedulerAPI.AvailableTerritorySlotsOutput availableSlots = scheduler.getAvailableTerritorySlots(loginResponse.sessionId, territorySlotsRequest);
            System.debug('::getAvailableTimeSlots:availableSlots:' + JSON.serializePretty(availableSlots));

            if (availableSlots != null && availableSlots.result != null && availableSlots.result.territorySlots != null) {
                for (SchedulerAPI.AvailableTerritorySlots ts : availableSlots.result.territorySlots) {
                    ts.slots = filterSlotsByDiaryBlockDateRange(territorySlotsRequest.startTime, territorySlotsRequest.endTime, ts.territoryId, ts.slots);
                }
                System.debug('::getAvailableTimeSlots:availableSlots after diary blocks:' + JSON.serializePretty(availableSlots));

                List<OnlBookDomain.ExtendedTerritorySlot> ret = new List<OnlBookDomain.ExtendedTerritorySlot>();

                OnlBookDomain.ExtendedTerritorySlot found = null;
                for (SchedulerAPI.AvailableTerritorySlots atslot : availableSlots.result.territorySlots) {
                    for (SchedulerAPI.TerritorySlot ts : atslot.slots) {

                        //find if it already exists in the ret list
                        found = null;
                        for (OnlBookDomain.ExtendedTerritorySlot extendedTerritorySlot : ret) {
                            if (extendedTerritorySlot.startTime == ts.startTime) {
                                found = extendedTerritorySlot;
                                break;
                            }
                        }

                        if (found == null) {
                            ret.add(new OnlBookDomain.ExtendedTerritorySlot(atslot.territoryId, ts));
                        }
                        else {
                            found.appendTerritorySlot(atslot.territoryId, ts);
                        }
                    }
                }


                return JSON.serializePretty(ret, false);
            }
            else {
                return '[]';
            }

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw e;
        }
    }

    public static List<SchedulerAPI.TerritorySlot> filterSlotsByDiaryBlockDateRange(Datetime dtFrom, Datetime dtTo, String serviceCenterId, List<SchedulerAPI.TerritorySlot> territorySlots) {
        if (territorySlots == null) return null;

        //now get the eventual diary blocks
        List<Diary_Block__c> blocks = [
                SELECT Id, Resource__c, Not_Available_From__c, Not_Available_To__c
                FROM Diary_Block__c
                WHERE Service_Territory__c = :serviceCenterId
                AND Not_Available_From__c <= :dtTo
                AND Not_Available_To__c >= :dtFrom
                AND Is_Active__c = TRUE
        ];


        Boolean slotBlocked = false;
        for (SchedulerAPI.TerritorySlot territorySlot : territorySlots) {
            for (Diary_Block__c diaryBlock : blocks) {
                slotBlocked = false;

                if (territorySlot.resources != null && territorySlot.resources.size() > 0 && territorySlot.resources.contains(diaryBlock.Resource__c)) {
                    slotBlocked = checkRangesOverlap(territorySlot.startTime, territorySlot.endTime, diaryBlock.Not_Available_From__c, diaryBlock.Not_Available_To__c);
                    if (slotBlocked) {
                        //remove resource from resources
                        for (Integer i = (territorySlot.resources.size() - 1); i >= 0; i--) {
                            String s = territorySlot.resources[i];
                            if (s.equalsIgnoreCase(diaryBlock.Resource__c)) {
                                territorySlot.resources.remove(i);
                            }
                        }
                    }
                }
            }
        }

        List<SchedulerAPI.TerritorySlot> ret = new List<SchedulerAPI.TerritorySlot>();
        for (SchedulerAPI.TerritorySlot territorySlot : territorySlots) {
            if (territorySlot.resources != null && territorySlot.resources.size() > 0) ret.add(territorySlot);
        }

        territorySlots = ret;
        return territorySlots;

    }


    public static Integer getSchedulingPolicyMinutesForWTG(String wtgId) {
        WorkTypeGroup wtg = [SELECT Id, Scheduling_Policy__c FROM WorkTypeGroup WHERE Id = :wtgId];
        if (wtg.Scheduling_Policy__c != null) {
            List<AppointmentSchedulingPolicy> policies = [SELECT Id, AppointmentStartTimeInterval FROM AppointmentSchedulingPolicy WHERE DeveloperName = :wtg.Scheduling_Policy__c];
            if (!policies.isEmpty() && policies[0].AppointmentStartTimeInterval != null) return Integer.valueOf(policies[0].AppointmentStartTimeInterval);
        }
        return 10;
    }

    public static String getAvailableSlots_raw(String workTypeGroupId, String serviceCenterIds, Datetime dateFrom, Datetime dateTo) {

        System.debug('::getAvailableSlots_raw:' + workTypeGroupId + ':' + serviceCenterIds + ':' + dateFrom + ':' + dateTo);

        List<WorkTypeGroupMember> wtms = [
                SELECT Id,
                        WorkTypeGroupId,
                        WorkTypeId,
                        WorkType.Id,
                        WorkType.Stagger_Bookings_by_Hours__c,
                        WorkTypeGroup.Appointment_Type__c
                FROM WorkTypeGroupMember
                WHERE WorkTypeGroupId = :workTypeGroupId
                LIMIT 1
        ];

        if (wtms.isEmpty()) return null;


        Id workTypeId = wtms.get(0).WorkTypeId;
        OnlBookDomain.ExtendedTimeSlotsResponse resp = getAvailableSlots_extendedResponse(workTypeGroupId, workTypeId, serviceCenterIds, dateFrom, dateTo);

        System.debug('::getAvailableSlots_raw:resp:size:' + resp?.territorySlots?.size());

        if (resp == null) return null;

        //filter out those timeslots potentially out of requested range
        OnlBookDomain.ExtendedTimeSlotsResponse resp2 = new OnlBookDomain.ExtendedTimeSlotsResponse();
        resp2.schedulingPolicyMinutes = resp.schedulingPolicyMinutes;
        resp2.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

        Datetime now = Datetime.now();
        //        System.debug('::getAvailableSlots_raw:resp2:removing slots ot of requested range from:' + dateFrom?.date() + ', to:' + dateTo?.date());

        for (OnlBookDomain.ExtendedTerritorySlot ets : resp.territorySlots) {
            if (ets.startTime != null && ets.startTime.date() >= dateFrom.date() && ets.startTime.date() <= dateTo.date()) {
                if (ctx_insideSF) {
                    resp2.territorySlots.add(ets);
                }
                else //stagger only when "outside of SF"
                {
                    if (wtms.get(0)?.WorkType?.Stagger_Bookings_by_Hours__c != null) {
                        if (ets.startTime > now.addHours(wtms.get(0)?.WorkType?.Stagger_Bookings_by_Hours__c.intValue()).addMinutes(15)) {
                            resp2.territorySlots.add(ets);
                        }
                    }
                    else {
                        resp2.territorySlots.add(ets);
                    }
                }
            }
        }

        resp = resp2;

        //video and tel cases where we need to prioritize newer clinics
        if ((wtms.get(0)?.WorkTypeGroup.Appointment_Type__c == 'TELEPHONE') || (wtms.get(0)?.WorkTypeGroup.Appointment_Type__c == 'VIDEO')) {
            resp = checkForClinicPrioritization(workTypeGroupId, resp);
        }


        return JSON.serializePretty(resp);

    }

    public static OnlBookDomain.ExtendedTimeSlotsResponse checkForClinicPrioritization(String workTypeGroupId, OnlBookDomain.ExtendedTimeSlotsResponse resp) {
        try {

            OnlBookDomain.ExtendedTimeSlotsResponse resp3;

            //order of priority:
            List<String> prioLocationIds = new List<String>();
            // prio clinics by order of ST creation
            List<ServiceTerritory> sts = [SELECT Id, Name FROM ServiceTerritory WHERE IsActive = TRUE ORDER BY CreatedDate DESC];
            for (ServiceTerritory serviceTerritory : sts) {
                prioLocationIds.add(serviceTerritory.Id);
            }

            resp3 = new OnlBookDomain.ExtendedTimeSlotsResponse();
            resp3.schedulingPolicyMinutes = resp.schedulingPolicyMinutes;
            resp3.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

            for (OnlBookDomain.ExtendedTerritorySlot ets : resp.territorySlots) {
                if (ets.resources != null && ets.resource_locations != null && (ets.resources.size() > 1) && (ets.resource_locations.size() > 1)) {

                    String found_prio_location = null;
                    String found_prio_doctor = null;

                    for (String loc : prioLocationIds) {
                        for (String doctor : ets.resource_locations.keySet()) {
                            if (ets.resource_locations.get(doctor) != null) {
                                if (ets.resource_locations.get(doctor).contains(loc)) {
                                    found_prio_location = loc;
                                    found_prio_doctor = doctor;
                                    break;
                                }
                            }
                        }
                        if (found_prio_location != null) break;
                    }

                    if (found_prio_location != null && found_prio_doctor != null) {
                        System.debug('MORE than 1 resource for ' + ets + '\nshould prioritize loc' + found_prio_location);
                        OnlBookDomain.ExtendedTerritorySlot newSlot = new OnlBookDomain.ExtendedTerritorySlot();
                        newSlot.startTime = ets.startTime;
                        newSlot.endTime = ets.endTime;
                        newSlot.resources = new List<String>();
                        newSlot.resources.add(found_prio_doctor);
                        newSlot.resource_locations = new Map<String, Set<String>>();
                        Set<String> locs = new Set<String>();
                        locs.add(found_prio_location);
                        newSlot.resource_locations.put(found_prio_doctor, locs);
                        System.debug('ADDING modified ' + newSlot + '\n\n');
                        resp3.territorySlots.add(newSlot);
                    }
                    else {
                        resp3.territorySlots.add(ets);
                    }
                }
                else {
                    resp3.territorySlots.add(ets);
                }
            }
            return resp3;

        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, '::filter_rx_prio FAILED:' + ex.getMessage());
        }

        return resp;
    }

    public static List<ServiceTerritory> getServiceCentersForWTG(String wtgId) {

        try {

            List<WorkTypeGroupMember> wtgms = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :wtgId];
            List<String> wtIds = new List<String>();
            for (WorkTypeGroupMember workTypeGroupMember : wtgms) {
                wtIds.add(workTypeGroupMember.WorkTypeId);
            }
            List<ServiceTerritoryWorkType> stwts = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryWorkType WHERE WorkTypeId IN :wtIds];
            List<String> stIds = new List<String>();
            for (ServiceTerritoryWorkType serviceTerritoryWorkType : stwts) {
                stIds.add(serviceTerritoryWorkType.ServiceTerritoryId);
            }


            return [SELECT Id, Name, PostalCode, Street, City, Country FROM ServiceTerritory WHERE IsActive = TRUE AND Id IN :stIds ORDER BY Name ASC];
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            return null;
        }
    }

    public static Boolean checkIsHoliday(Date dte, List<OperatingHoursHoliday> holidays) {
        if (holidays == null) return false;
        for (OperatingHoursHoliday hDay : holidays) {
            if ((hDay?.Holiday?.ActivityDate != null) && (dte.daysBetween(hDay.Holiday.ActivityDate) == 0)) return true;
        }
        return false;
    }


    /* HCA Resources should have priority over Nurses, and GPs. GPs not to be shown on Saturdays if work type also requires nurses or HCAs */
    public static OnlBookDomain.ExtendedTimeSlotsResponse checkForSkillPrioritization(OnlBookDomain.ExtendedTimeSlotsResponse resp, String workTypeId) {

        // get all the resources mentioned
        try {

            //see if work type requires GP + (HCA  or Nurse) or (HCA + Nurse)
            List<SkillRequirement> skills = [SELECT Id, (SELECT Id, Skill.DeveloperName FROM SkillRequirements) FROM WorkType WHERE Id = :workTypeId].SkillRequirements;

            Boolean wtRequires_GP = false;
            Boolean wtRequires_Nurse = false;
            Boolean wtRequires_HCA = false;

            for (SkillRequirement skillRequirement : skills) {
                if (skillRequirement?.Skill?.DeveloperName == 'GP') wtRequires_GP = true;
                else if (skillRequirement?.Skill?.DeveloperName == 'Sexual Health (GP)') wtRequires_GP = true;
                else if (skillRequirement?.Skill?.DeveloperName == 'Nurse') wtRequires_Nurse = true;
                else if (skillRequirement?.Skill?.DeveloperName == 'HCA') wtRequires_HCA = true;
            }

            Boolean proceedWithPrio = false;
            if (wtRequires_GP && (wtRequires_HCA || wtRequires_Nurse)) proceedWithPrio = true;
            if (wtRequires_HCA && wtRequires_Nurse) proceedWithPrio = true;

            if (!proceedWithPrio) return resp;

            OnlBookDomain.ExtendedTimeSlotsResponse resp3;

            resp3 = new OnlBookDomain.ExtendedTimeSlotsResponse();
            resp3.schedulingPolicyMinutes = resp.schedulingPolicyMinutes;
            resp3.territorySlots = new List<OnlBookDomain.ExtendedTerritorySlot>();

            //build a list of resources used in the response
            Set<Id> resourceIds = new Set<Id>();
            for (OnlBookDomain.ExtendedTerritorySlot ets : resp.territorySlots) {
                if (ets.resources != null) {
                    for (String res : ets.resources) {
                        resourceIds.add(res);
                    }
                }
            }

            //find the skills for these resources
            List<ServiceResourceSkill> srSkills = [
                    SELECT
                            Id, ServiceResourceId, Skill.DeveloperName
                    FROM ServiceResourceSkill
                    WHERE
                            ServiceResourceId IN :resourceIds
                            AND EffectiveStartDate <= :Date.today()
                            AND (EffectiveEndDate = NULL OR EffectiveEndDate >= :Date.today())
            ];

            Set<String> nurseResourceIds = new Set<String>();
            Set<String> hcaResourceIds = new Set<String>();
            Set<String> gpResourceIds = new Set<String>();
            for (ServiceResourceSkill srSkill : srSkills) {
                if (srSkill.Skill.DeveloperName == 'HCA') {
                    hcaResourceIds.add(srSkill.ServiceResourceId);
                }
                if (srSkill.Skill.DeveloperName == 'Nurse') {
                    nurseResourceIds.add(srSkill.ServiceResourceId);
                }
                if (srSkill.Skill.DeveloperName == 'GP' || srSkill.Skill.DeveloperName == 'Sexual Health (GP)') {
                    gpResourceIds.add(srSkill.ServiceResourceId);
                }
            }

            //cases where we do not need to do anything
            if ((gpResourceIds.isEmpty() && nurseResourceIds.isEmpty())
                    || (gpResourceIds.isEmpty() && hcaResourceIds.isEmpty())) {
                System.debug('::BUI:Skill-filter:not applicable');
                return resp;
            }

            System.debug('::BUI:filtering by Skill prioritization...');

            //process
            for (OnlBookDomain.ExtendedTerritorySlot ets : resp.territorySlots) {
                if (ets.resources != null && ets.resources.size() > 0) {

                    List<String> found_prio_resources = new List<String>();

                    // prioritize HCA -> NURSE -> GP (GP only if not saturday)
                    for (String resource : ets.resources) {
                        if (hcaResourceIds.contains(resource)) {
                            found_prio_resources.add(resource);
                            System.debug('::BUI:Skill-filter:prioritizing HCA ' + resource);
                            break;
                        }
                    }

                    if (found_prio_resources.isEmpty()) {
                        for (String resource : ets.resources) {
                            if (nurseResourceIds.contains(resource)) {
                                found_prio_resources.add(resource);
                                System.debug('::BUI:Skill-filter:prioritizing Nurse ' + resource);
                                break;
                            }
                        }
                    }

                    if (found_prio_resources.isEmpty() && !isSaturday(ets.startTime)) {
                        for (String resource : ets.resources) {
                            if (gpResourceIds.contains(resource)) {
                                found_prio_resources.add(resource);
                                System.debug('::BUI:Skill-filter:prioritizing GP ' + resource);
                                break;
                            }
                        }
                    }

                    //if resource list is still empty, add the rest of resources
                    if (found_prio_resources.isEmpty()) {
                        for (String resource : ets.resources) {
                            if (!gpResourceIds.contains(resource) && !nurseResourceIds.contains(resource) && !hcaResourceIds.contains(resource)) {
                                System.debug('::BUI:Skill-filter:adding leftover resource ' + resource);
                                found_prio_resources.add(resource);
                            }
                        }
                    }

                    if (found_prio_resources.size() > 0) {
                        System.debug('::BUI:SKill-filter:MORE than 1 resource for ' + ets + '\nshould prioritize resource ' + found_prio_resources);
                        OnlBookDomain.ExtendedTerritorySlot newSlot = new OnlBookDomain.ExtendedTerritorySlot();
                        newSlot.startTime = ets.startTime;
                        newSlot.endTime = ets.endTime;
                        newSlot.resources = new List<String>();
                        newSlot.resources.addAll(found_prio_resources);
                        newSlot.resource_locations = new Map<String, Set<String>>();
                        Set<String> locs = new Set<String>();
                        for (String prioRes : found_prio_resources) {
                            newSlot.resource_locations.put(prioRes, ets.resource_locations.get(prioRes));
                        }
                        System.debug('::BUI:Skill-filter:ADDING modified ' + newSlot + '\n\n');
                        resp3.territorySlots.add(newSlot);
                    }
                }
            }

            return resp3;

        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, '::::BUI:Skill-filter:FAILED:' + ex.getMessage());
        }

        return resp;
    }


    public static Boolean isSaturday(Datetime dt) {
        return (dt != null && dt.format('EEEE') == 'Saturday');
    }

}