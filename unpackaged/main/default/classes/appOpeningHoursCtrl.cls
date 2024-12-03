/**
 * Created 12.11.2021..
 */

public with sharing class appOpeningHoursCtrl {

    @AuraEnabled (Cacheable = true)
    public static String getServiceTerritories() {
        List<ServiceTerritory> allSts = [
                SELECT
                        Id,
                        Name,
                        IsActive,
                        Available_for_Click_Collect__c,
                        OperatingHoursId,
                        OperatingHours.Name,
                (SELECT ServiceResourceId, ServiceResource.Name, ServiceResource.IsActive FROM ServiceResources)
                FROM ServiceTerritory
                ORDER BY Name
        ];

        List<TimeSlot> allTimeslots = [
                SELECT Id,
                        OperatingHoursId,
                        DayOfWeek,
                        StartTime,
                        EndTime
                FROM TimeSlot
        ];

        List<ServiceTerritoryWorkType> allStwts = [
                SELECT
                        Id,
                        Name,
                        ServiceTerritoryId,
                        WorkType.Name,
                        WorkType.Id,
                        WorkType.OperatingHours.Name,
                        WorkType.OperatingHoursId
                FROM ServiceTerritoryWorkType
        ];

        List<WorkType> allWorkTypes = ([
                SELECT
                        Id,
                        Name, OperatingHoursId
                FROM WorkType
        ]);

        List<ServiceResource> allServiceResources = ([
                SELECT
                        Id,
                        Name,
                        IsActive, (SELECT SkillId, Skill.MasterLabel FROM ServiceResourceSkills)
                FROM ServiceResource
                WHERE IsActive = TRUE
        ]);


        List<WorkTypeGroup> allWorkTypeGroups = ([
                SELECT
                        Id,
                        Name
                FROM WorkTypeGroup
                WHERE
                        IsActive = TRUE
                ORDER BY Name ASC
        ]);

        List<WorkTypeGroupMember> allWTGMembers = [
                SELECT Id,
                        Name,
                        WorkTypeId,
                        WorkTypeGroupId, WorkType.Name, WorkTypeGroup.Name
                FROM WorkTypeGroupMember
        ];

        MasterWrapper mw = new MasterWrapper();
        mw.wtgMembers = allWTGMembers;
        mw.resources = allServiceResources;
        mw.territories = new List<appOpeningHoursCtrl.ServiceTerritoryWrapper>();

        //for each Service Territory
        for (ServiceTerritory st : allSts) {
            ServiceTerritoryWrapper stw = new ServiceTerritoryWrapper(st);

            //add it's WorkTypes
            for (ServiceTerritoryWorkType stwt : allStwts) {
                if (stwt.ServiceTerritoryId == st.Id) stw.stWorkTypes.add(stwt);
            }

            //add its time slots
            List<TimeSlot> tss = new List<TimeSlot>();

            for (TimeSlot ts : allTimeslots) {
                if (ts.OperatingHoursId == st.OperatingHoursId) tss.add(ts);
            }
            stw.timeSlots = tss;

            mw.territories.add(stw);
        }

        mw.workTypeGroups = allWorkTypeGroups;
        return JSON.serialize(mw);
    }

    public class ServiceTerritoryWrapper {
        public ServiceTerritory serviceTerritory;
        public List<ServiceTerritoryWorkType> stWorkTypes;
        public List<TimeSlot> timeSlots;

        public ServiceTerritoryWrapper(ServiceTerritory st) {
            this.stWorkTypes = new List<ServiceTerritoryWorkType>();
            this.serviceTerritory = st;
        }
    }

    public class MasterWrapper {
        public List<WorkTypeGroupMember> wtgMembers { get; set; }
        public List<WorkTypeGroup> workTypeGroups { get; set; }
        public List<ServiceTerritoryWrapper> territories { get; set; }
        public List<ServiceResource> resources { get; set; }
    }


}