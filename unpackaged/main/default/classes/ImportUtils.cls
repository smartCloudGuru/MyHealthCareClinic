/**
 * Created 15.11.2022..
 */

public without sharing class ImportUtils {

    public static void aerona_importAllClinicians(Set<String> excludedIds) {
        Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>> clinicians = AeronaService.getAllClinicians();

        if (excludedIds!=null)
        {
            for (String excludedId : excludedIds) {
                clinicians.remove(excludedId);
            }
        }

        System.debug(JSON.serializePretty(clinicians, true));

        //
        // 1) update current Assets with eventual new ones
        //
        Map<String, Asset> map_assets_by_name = getCurrentAssetsByName();
        System.debug('Current assets: ' + map_assets_by_name.size());

        //find assets that need to be created
       List<Asset> assetsToInsert = new List<Asset>();
        Set<String> newAssetNames = new Set<String>();

        Set<String> aeronaServiceTerritoryIds = clinicians.keySet();

        for (String stId : clinicians.keySet()) {
            List<AeronaServiceOASApi.OASAPIClinicianDetails> clinicianDetails = clinicians.get(stId);
            for (AeronaServiceOASApi.OASAPIClinicianDetails user : clinicianDetails) {
                if (map_assets_by_name.get(user.clinicianName + ' Asset') == null && !newAssetNames.contains(user.clinicianName + ' Asset')) {
                    assetsToInsert.add(new Asset(Name = user.clinicianName + ' Asset'));
                    newAssetNames.add(user.clinicianName + ' Asset');
                }
            }
        }

        System.debug('assets to insert:' + assetsToInsert.size());
        System.debug('newAssetNames:' + JSON.serializePretty(newAssetNames));

        insert assetsToInsert;

        map_assets_by_name = getCurrentAssetsByName();
        System.debug('Current assets: ' + map_assets_by_name.size());


        //
        // 2) update current Service Resources with eventual new ones
        //
        Map<String, ServiceResource> map_srs_by_name = getCurrentServiceResourcesByName();
        System.debug('Current SRs: ' + map_srs_by_name.size());

        //find assets that need to be created
        List<ServiceResource> srsToInsert = new List<ServiceResource>();
        Set<String> newSrNames = new Set<String>();

        for (String stId : clinicians.keySet()) {
            List<AeronaServiceOASApi.OASAPIClinicianDetails> clinicianDetails = clinicians.get(stId);
            for (AeronaServiceOASApi.OASAPIClinicianDetails user : clinicianDetails) {
                if (map_srs_by_name.get(user.clinicianName) == null && !newSrNames.contains(user.clinicianName)) {
                    ServiceResource sr = new ServiceResource();
                    sr.Name = user.clinicianName;
                    sr.IsActive = true;
                    sr.ResourceType = 'S';
                    sr.AssetId = map_assets_by_name.get(user.clinicianName + ' Asset').Id;
                    srsToInsert.add(sr);
                    newSrNames.add(user.clinicianName);
                }
            }
        }

        System.debug('srs to insert:' + srsToInsert.size());
        System.debug('newSrNames:' + JSON.serializePretty(newSrNames));


        insert srsToInsert;

        map_srs_by_name = getCurrentServiceResourcesByName();
        System.debug('Current SRs: ' + map_srs_by_name.size());

        //attach the Service Resources to their Service Territories, and assign them their IDs

        List<ServiceTerritoryMember> serviceTerritoryMembersToUpsert = new List<ServiceTerritoryMember>();
        for (String stid : aeronaServiceTerritoryIds) {
            //get current ServiceTerritoryMembers
            List<ServiceTerritoryMember> currentSTMs = [SELECT Id, ServiceResourceId, ServiceTerritoryId, ServiceResource.Name, EffectiveStartDate FROM ServiceTerritoryMember WHERE ServiceTerritoryId = :stid];
            System.debug('Current STMs for ' + stid + ': ' + currentSTMs.size());

            for (AeronaServiceOASApi.OASAPIClinicianDetails clinician : clinicians.get(stid)) {
                ServiceTerritoryMember stm = new ServiceTerritoryMember(
                        ServiceTerritoryId = stid,
                        ServiceResourceId = map_srs_by_name.get(clinician.clinicianName).Id,
                        Aerona_Clinician_Id__c = '' + clinician.id,
                        TerritoryType = 'S',
                        EffectiveStartDate = Datetime.now().addMonths(-1)
                );
                //is there already a STM for this clinician? If so, set ID so it can be upserted
                for (ServiceTerritoryMember serviceTerritoryMember : currentSTMs) {
                    if (serviceTerritoryMember.ServiceResourceId == stm.ServiceResourceId) {
                        stm.Id = serviceTerritoryMember.Id;
                        stm.EffectiveStartDate = serviceTerritoryMember.EffectiveStartDate; //retain old effective start date
                        break;
                    }
                }
                serviceTerritoryMembersToUpsert.add(stm);
            }
        }

        System.debug('serviceTerritoryMembersToUpsert: ' + JSON.serializePretty(serviceTerritoryMembersToUpsert, true));
        upsert serviceTerritoryMembersToUpsert;

        Skill dental = [SELECT Id FROM Skill WHERE DeveloperName = 'Dental'];
        List<ServiceResourceSkill> skillsToInsert = new List<ServiceResourceSkill>();
        Set<Id> serviceResourceIds = new Set<Id>();
        for (ServiceTerritoryMember serviceTerritoryMember : serviceTerritoryMembersToUpsert) {
            serviceResourceIds.add(serviceTerritoryMember.ServiceResourceId);
        }
        for (Id serviceTerritoryId : serviceResourceIds) {
            ServiceResourceSkill srSkill = new ServiceResourceSkill();
            srSkill.SkillId = dental.Id;
            srSkill.ServiceResourceId = serviceTerritoryId;
            srSkill.EffectiveStartDate = Datetime.newInstance(2022,1,1);
            skillsToInsert.add(srSkill);
        }

        System.debug('skillsToInsert:' + JSON.serializePretty(skillsToInsert));
        //insert skillsToInsert;
        Database.insert(skillsToInsert, false);



    }

    public static Map<String, Asset> getCurrentAssetsByName() {
        List<Asset> assets = [SELECT Id, Name FROM Asset];
        Map<String, Asset> map_assetName_asset = new Map<String, Asset>();

        for (Asset asset : assets) {
            map_assetName_asset.put(asset.Name, asset);
        }

        return map_assetName_asset;
    }

    public static Map<String, ServiceResource> getCurrentServiceResourcesByName() {
        List<ServiceResource> srs = [SELECT Id, Name FROM ServiceResource];
        Map<String, ServiceResource> map_srName_asset = new Map<String, ServiceResource>();

        for (ServiceResource sr : srs) {
            map_srName_asset.put(sr.Name, sr);
        }

        return map_srName_asset;
    }
}