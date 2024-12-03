/**
 * Created by Matija on 28.11.2023..
 */

public without sharing class OnlBookDomain {


    public static ContentVersion createContentVersion(String filename, String base64) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.VersionData = EncodingUtil.base64Decode(base64);
        contentVersion.Title = filename;
        contentVersion.PathOnClient = filename;
        return contentVersion;
    }

    /**
     * Used to construct a new ContentDocumentLink record. Does not insert the record.
     *
     * @param contentVersionId The ID of the ContentVersion which you want to link to a given record
     * @param recordId The ID of the record that you want to link with the specified ContentVersion
     *
     * @return a new instance of ContentDocumentLink with specified ContentDocumentId,
     *          LinkedEntityId, and ShareType set to 'V' (viewer permission).
     */
    public static ContentDocumentLink createContentDocumentLink(String contentVersionId, String recordId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentVersionId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        return cdl;
    }

    /**
     * Fetches a list of active service territories associated with a given work type.
     *
     * This method returns a list of active 'ServiceTerritory' objects which are linked to a provided work type via the 'ServiceTerritoryWorkType' object.
     * The returned 'ServiceTerritory' objects contain the fields: Id, Name, PostalCode, Street, City, Country, Heydoc_Id__c, Aerona_Id__c and are ordered by Name in ascending order.
     *
     * If an exception occurs during the execution (like a QueryException, if the 'workTypeId' parameter is missing or malformed),
     * the stack trace is logged as an error and the method will return null.
     *
     * @param wtId The Id of the 'WorkType' object to find associated service territories for. Note: The input should be a valid 'WorkType' Id.
     *
     * @return A list of 'ServiceTerritory' objects associated with the given work type if any, ordered by their name in ascending order.
     *         If no service territories are found, an empty list will be returned.
     *         If an exception occurs during execution, logging occurs and the method will return null.
     */

    public static List<ServiceTerritory> getServiceCentersForWT(String wtId) {

        try {

            List<ServiceTerritoryWorkType> stwts = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryWorkType WHERE WorkTypeId = :wtId];
            List<String> stIds = new List<String>();
            for (ServiceTerritoryWorkType serviceTerritoryWorkType : stwts) {
                stIds.add(serviceTerritoryWorkType.ServiceTerritoryId);
            }

            return [SELECT Id, Name, PostalCode, Street, City, Country, Heydoc_Id__c, Aerona_Id__c FROM ServiceTerritory WHERE IsActive = TRUE AND Id IN :stIds ORDER BY Name ASC];
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            return null;
        }
    }

    public static Set<Id> getServiceResourcesIdsForWorTypeSkills(String workTypeId) {
        List<SkillRequirement> skills = [SELECT Id, (SELECT Id, Skill.DeveloperName FROM SkillRequirements) FROM WorkType WHERE Id = :workTypeId].SkillRequirements;

        Set<String> skillNames = new Set<String>();
        for (SkillRequirement skillRequirement : skills) {
            if (skillRequirement?.Skill?.DeveloperName != null) skillNames.add(skillRequirement.Skill.DeveloperName);
        }

        List<ServiceResourceSkill> serviceResourceSkills = [SELECT Id, ServiceResourceId FROM ServiceResourceSkill WHERE Skill.DeveloperName IN :skillNames AND ServiceResource.IsActive = TRUE];
        Set<Id> ret = new Set<Id>();
        for (ServiceResourceSkill serviceResourceSkill : serviceResourceSkills) {
            ret.add(serviceResourceSkill.ServiceResourceId);
        }
        return ret;
    }

    public static List<ServiceResource> getServiceResourcesForWorkTypeGroupSkills(String workTypeGroupId) {

        Set<Id> workTypeIds = new Set<Id>();
        List<WorkTypeGroupMember> workTypeGroupMembers = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :workTypeGroupId];

        for (WorkTypeGroupMember workTypeGroupMember : workTypeGroupMembers) {
            if (workTypeGroupMember.WorkTypeId != null)
                workTypeIds.add(workTypeGroupMember.WorkTypeId);
        }

        List<SkillRequirement> skills = [SELECT Id, (SELECT Id, Skill.DeveloperName FROM SkillRequirements) FROM WorkType WHERE Id IN :workTypeIds].SkillRequirements;

        Set<String> skillNames = new Set<String>();
        for (SkillRequirement skillRequirement : skills) {
            if (skillRequirement?.Skill?.DeveloperName != null) skillNames.add(skillRequirement.Skill.DeveloperName);
        }

        List<ServiceResourceSkill> serviceResourceSkills = [SELECT Id, ServiceResourceId, ServiceResource.Id, ServiceResource.Name FROM ServiceResourceSkill WHERE Skill.DeveloperName IN :skillNames AND ServiceResource.IsActive = TRUE];
        List<ServiceResource> ret = new List<ServiceResource>();

        for (ServiceResourceSkill serviceResourceSkill : serviceResourceSkills) {
            ret.add(new ServiceResource(Id = serviceResourceSkill.ServiceResourceId, Name = cleanUpName(serviceResourceSkill.ServiceResource.Name)));
        }

        ret.sort();

        return ret;
    }

    private static String cleanUpName(String clinicianName)
    {
        if (String.isBlank(clinicianName)) return '';
        return clinicianName.replace('Dr ', '').replace('Dr. ', '');

    }

    public class TimeSlotsResponse {
        public List<SchedulerAPI.TerritorySlot> territorySlots;
        public Integer schedulingPolicyMinutes;
    }

    public class ExtendedTimeSlotsResponse {
        public List<ExtendedTerritorySlot> territorySlots;
        public Integer schedulingPolicyMinutes;
    }

    public class ExtendedTerritorySlot implements Comparable {
        public Datetime endTime;
        public Datetime startTime;
        public List<String> resources;
        public Map<String, Set<String>> resource_locations;

        public ExtendedTerritorySlot() {
            this.resources = new List<String>();
            this.resource_locations = new Map<String, Set<String>>();
        }

        public ExtendedTerritorySlot(String territoryId, SchedulerAPI.TerritorySlot ts) {
            this.startTime = ts.startTime;
            this.endTime = ts.endTime;
            this.resources = ts.resources;
            this.resource_locations = new Map<String, Set<String>>();
            for (String res : ts.resources) {
                Set<String> locations = this.resource_locations.get(res);
                if (locations == null) locations = new Set<String>();
                locations.add(territoryId);
                this.resource_locations.put(res, locations);
            }
        }

        public void appendTerritorySlot(String territoryId, SchedulerAPI.TerritorySlot ts) {
            Set<String> combinedResources = new Set<String>();
            combinedResources.addAll(this.resources);
            combinedResources.addAll(ts.resources);
            this.resources = new List<String>();
            this.resources.addAll(combinedResources);
            for (String res : ts.resources) {
                Set<String> locations = this.resource_locations.get(res);
                if (locations == null) locations = new Set<String>();
                locations.add(territoryId);
                this.resource_locations.put(res, locations);
            }
        }

        // for sorting by start time
        public Integer compareTo(Object compareToObj) {

            ExtendedTerritorySlot compareTo = (ExtendedTerritorySlot) compareToObj;

            // Cast argument to OpportunityWrapper
            if ((this.startTime == compareTo.startTime)) {
                return 0;
            }
            else if (this.startTime == null && compareTo != null) {
                return -1;
            }
            else if (this.startTime != null && compareTo.startTime == null) {
                return 1;
            }
            else if (this.startTime > compareTo.startTime) {
                // Set return value to a positive value.
                return 1;
            }
            else if (this.startTime < compareTo.startTime) {
                return -1;
            }
            return 0;
        }
    }

    public class OptionWrapper {
        public String label;
        public String value;
        public String wtgId;
        public String wtId;
        public Boolean isVideoOrTel;
        public String flags = '';

        public OptionWrapper() {

        }

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
            this.wtgId = null;
            this.wtId = null;
            this.isVideoOrTel = false;
        }
        public OptionWrapper(String label, String value, String wtgId, String wtId, Boolean isVideoOrTel) {
            this.label = label;
            this.value = value;
            this.wtgId = wtgId;
            this.wtId = wtId;
            this.isVideoOrTel = isVideoOrTel;
        }

        public OptionWrapper(String label, String value, Id wtgId, Id wtId) {
            this.label = label;
            this.value = value;
            this.wtgId = wtgId;
            this.wtId = wtId;
            this.isVideoOrTel = null;
        }
    }
}