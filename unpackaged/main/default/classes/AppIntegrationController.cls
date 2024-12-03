/**
 * Created by Matija on 4.9.2023..
 */

public without sharing class AppIntegrationController {

    @AuraEnabled(Cacheable=false)
    public static String aeronaGetAllClinicians() {
        List<ServiceTerritory> serviceTerritories = [SELECT Id, Name FROM ServiceTerritory];
        Map<String, String> map_stId_stName = new Map<String, String>();
        for (ServiceTerritory serviceTerritory : serviceTerritories) {
            map_stId_stName.put(serviceTerritory.Id, serviceTerritory.Name);
        }
        Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>> aeronaResp = AeronaService.getAllClinicians();

        Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>> ret = new Map<String, List<AeronaServiceOASApi.OASAPIClinicianDetails>>();

        for (String stId : aeronaResp.keySet()) {
            ret.put(map_stId_stName.get(stId), aeronaResp.get(stId));
        }

        return JSON.serialize(ret, true);
    }
}